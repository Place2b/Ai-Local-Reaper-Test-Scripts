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
