reaper.Undo_BeginBlock()

-- 1. Имя темплейта из названия скрипта
local info = debug.getinfo(1, 'S')
local script_path = info.source:sub(2)
local script_filename = script_path:match("[^/\\]+$")
local template_name = script_filename:gsub("^p2b_TT_", ""):gsub("%.lua$", "")

-- 2. Путь к темплейту
local resource_path = reaper.GetResourcePath()
local sep = package.config:sub(1,1)
local template_path = resource_path .. sep .. "TrackTemplates" .. sep .. "[RESOURCES]" .. sep .. template_name .. ".RTrackTemplate"

-- Снимаем выделение со всех треков
reaper.Main_OnCommand(40297, 0)

-- 3. Импорт темплейта
reaper.Main_openProject(template_path)

local sel_track_count = reaper.CountSelectedTracks(0)

if sel_track_count > 0 then
    -- Позиция курсора
    local start_pos = reaper.GetCursorPosition()
    
    -- Расчет длины ровно в 2 такта по сетке текущего темпа проекта
    local end_pos = reaper.TimeMap2_beatsToTime(0, 0, 4) + start_pos
    
    -- E1 = MIDI pitch 28 (при C4 = 60)
    local pitch = 28 
    local vel = 127
    local channel = 0 -- 0 в API = 1-й MIDI канал

    for i = 0, sel_track_count - 1 do
        local track = reaper.GetSelectedTrack(0, i)
        
        -- Получаем имя трека
        local _, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
        
        -- Создаем чистый MIDI-айтем
        local item = reaper.CreateNewMIDIItemInProj(track, start_pos, end_pos, false)
        
        if item then
            -- Включаем Loop item source для айтема
            reaper.SetMediaItemInfo_Value(item, "B_LOOPSRC", 1)
            
            local take = reaper.GetActiveTake(item)
            
            if take then
                -- Ставим имя айтема равным имени трека
                reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", track_name, true)
                
                -- Переводим секунды в PPQ для точной вставки ноты
                local start_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, start_pos)
                local end_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, end_pos)
                
                -- Рисуем ноту E1 во всю длину (2 такта)
                reaper.MIDI_InsertNote(take, false, false, start_ppq, end_ppq, channel, pitch, vel, false)
                reaper.MIDI_Sort(take)
            end
        end
    end
end

-- 4. Закрытие тулбаров
local toolbarsToClose = {41681, 41682, 41683}
for _, cmd_id in ipairs(toolbarsToClose) do
    if reaper.GetToggleCommandState(cmd_id) == 1 then
        reaper.Main_OnCommand(cmd_id, 0)
    end
end

-- 5. Применение SWS Auto Color
local autocolor_action = reaper.NamedCommandLookup("_SWSAUTOCOLOR_APPLY")
if autocolor_action ~= 0 then
    reaper.Main_OnCommand(autocolor_action, 0)
end

reaper.Undo_EndBlock("Import " .. template_name .. " with Looped MIDI", -1)
