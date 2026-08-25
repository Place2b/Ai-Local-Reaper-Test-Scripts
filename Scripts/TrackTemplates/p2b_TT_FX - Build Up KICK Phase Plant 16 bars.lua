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

-- 3. Импорт темплейта
reaper.Main_openProject(template_path)

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

reaper.Undo_EndBlock("Import " .. template_name .. " and Auto Color", -1)