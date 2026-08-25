reaper.Undo_BeginBlock()

-- 1. Получаем имя текущего скрипта и вырезаем название темплейта
local info = debug.getinfo(1, 'S')
local script_path = info.source:sub(2)
local script_filename = script_path:match("[^/\\]+$")

-- Убираем префикс "p2b_TT_" и расширение ".lua"
local template_name = script_filename:gsub("^p2b_TT_", ""):gsub("%.lua$", "")

-- 2. Собираем путь к темплейту
local resource_path = reaper.GetResourcePath()
local sep = package.config:sub(1,1)
local template_path = resource_path .. sep .. "TrackTemplates" .. sep .. "[RESOURCES]" .. sep .. template_name .. ".RTrackTemplate"

-- Снимаем выделение со всех айтемов и треков перед импортом
reaper.SelectAllMediaItems(0, false)
reaper.Main_OnCommand(40297, 0) -- Track: Unselect all tracks

-- 3. Импорт темплейта (новый трек автоматически становится выделенным)
reaper.Main_openProject(template_path)

local sel_track_count = reaper.CountSelectedTracks(0)

if sel_track_count > 0 then
    for i = 0, sel_track_count - 1 do
        local track = reaper.GetSelectedTrack(0, i)
        
        -- Выделяем все айтемы на импортированном треке
        local item_count = reaper.CountTrackMediaItems(track)
        for j = 0, item_count - 1 do
            local item = reaper.GetTrackMediaItem(track, j)
            reaper.SetMediaItemSelected(item, true)
        end
        
        -- Если на треке есть айтемы
        if item_count > 0 then
            -- Склеиваем выделенные айтемы (Item: Glue items)
            reaper.Main_OnCommand(41588, 0)
            
            -- Получаем имя трека
            local _, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
            
            -- После склейки остается один выделенный айтем, берем его и его активный take
            local glued_item = reaper.GetSelectedMediaItem(0, 0)
            if glued_item then
                local take = reaper.GetActiveTake(glued_item)
                if take then
                    -- Переименовываем take в имя трека
                    reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", track_name, true)
                end
            end
        end
    end
end

-- 4. Закрытие тулбаров, если они открыты
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

reaper.UpdateArrange()
reaper.Undo_EndBlock("Import " .. template_name .. ", Glue & Auto Color", -1)