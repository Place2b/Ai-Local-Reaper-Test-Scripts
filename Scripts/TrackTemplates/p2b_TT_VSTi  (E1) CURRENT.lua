reaper.Undo_BeginBlock()

-- 1. Парсим имя FX из названия скрипта
local info = debug.getinfo(1, 'S')
local script_path = info.source:sub(2)
local script_filename = script_path:match("[^/\\]+$")

-- Убираем префикс "p2b_TT_VSTi  (E1) " и расширение ".lua"
local fx_name = script_filename:gsub("^p2b_TT_VSTi%s+%s*%(E1%)%s*", ""):gsub("%.lua$", "")

-- 2. Создаем новый трек в конце списка и выделяем его
local track_idx = reaper.CountTracks(0)
reaper.InsertTrackAtIndex(track_idx, true)
local track = reaper.GetTrack(0, track_idx)

reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
reaper.SetTrackSelected(track, true)

-- 3. Добавляем VSTi на трек
local fx_idx = reaper.TrackFX_AddByName(track, fx_name, false, -1)

-- 4. Определяем имя трека (проверяем спец-имена)
local track_name = fx_name
local lower_fx = fx_name:lower()

if lower_fx:find("current") then
    track_name = "℃"
elseif lower_fx:find("serum 2") or lower_fx:find("serum2") then
    track_name = "★★"
elseif lower_fx:find("serum") then
    track_name = "★"
elseif lower_fx:find("phaseplant") or lower_fx:find("phase plant") then
    track_name = "♥"
end

reaper.GetSetMediaTrackInfo_String(track, "P_NAME", track_name, true)

-- 5. Создаем не-лупованный MIDI-айтем на 2 такта
local start_pos = reaper.GetCursorPosition()
local end_pos = reaper.TimeMap2_beatsToTime(0, 0, 4) + start_pos

local item = reaper.CreateNewMIDIItemInProj(track, start_pos, end_pos, false)

if item then
    -- Отключаем Loop item source (B_LOOPSRC = 0)
    reaper.SetMediaItemInfo_Value(item, "B_LOOPSRC", 0)
    
    local take = reaper.GetActiveTake(item)
    if take then
        -- Имя айтема = имя трека
        reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", track_name, true)
        
        -- E1 (pitch 28), Vel 127, Ch 1
        local start_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, start_pos)
        local end_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, end_pos)
        
        reaper.MIDI_InsertNote(take, false, false, start_ppq, end_ppq, 0, 28, 127, false)
        reaper.MIDI_Sort(take)
    end
end

-- 6. Закрытие тулбаров
local toolbarsToClose = {41681, 41682, 41683}
for _, cmd_id in ipairs(toolbarsToClose) do
    if reaper.GetToggleCommandState(cmd_id) == 1 then
        reaper.Main_OnCommand(cmd_id, 0)
    end
end

-- 7. Применение SWS Auto Color
local autocolor_action = reaper.NamedCommandLookup("_SWSAUTOCOLOR_APPLY")
if autocolor_action ~= 0 then
    reaper.Main_OnCommand(autocolor_action, 0)
end

reaper.Undo_EndBlock("Add " .. fx_name .. " track with MIDI", -1)
