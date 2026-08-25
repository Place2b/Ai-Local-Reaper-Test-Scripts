-- @description P2B Toolbar Toggle F1
-- @version 1.0
-- @provides [main] .
-- Сохраняем позицию аранжировки
reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SAVEVIEW"), 0)

-- Список тулбаров, которые нужно закрыть, если они открыты
local toolbars_to_close = { 41683, 41681, 41685, 41936, 42726 }

-- Проверяем и закрываем активные тулбары из списка
for _, id in ipairs(toolbars_to_close) do
    local state = reaper.GetToggleCommandState(id)
    if state == 1 then
        reaper.Main_OnCommand(id, 0)
    end
end

-- Переключаем целевой тулбар 
reaper.Main_OnCommand(41682, 0)

-- Восстанавливаем позицию аранжировки
reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTVIEW"), 0)

reaper.UpdateArrange()
