local function no_undo() reaper.defer(function() end) end

-- 1. Извлечение имени плагина из имени файла
local _, filename = reaper.get_action_context()
local scriptName = filename:match("([^\\/]+)%.lua$") or ""

-- Отсекаем префикс "p2b_InsertFX_"
local fxName = scriptName:match("p2b_InsertFX[_%s]+(.+)") or scriptName

-- Список тулбаров для закрытия
local toolbarsToClose = {41681, 41682, 41683}

-- 2. Определение ОС и префиксов
local os = reaper.GetOS()
local is_mac = os:match("OSX") or os:match("macOS")
local prefixes = is_mac 
    and {"VST3: ", "VST: ", "JS: ", "CLAP: ", "AU: ", ""} 
    or {"VST3: ", "VST: ", "JS: ", "CLAP: ", ""}

-- 3. Функция добавления плагина
local function add_fx_fallback(target, target_type, raw_name)
    local name_variants = {}
    
    -- 1. Исходное имя (как в файле)
    table.insert(name_variants, raw_name)
    
    -- 2. Имя БЕЗ скобок вендора: "UAD Teletronix LA-2A Legacy (Universal Audio, Inc.)" -> "UAD Teletronix LA-2A Legacy"
    local clean_no_brackets = raw_name:gsub("%s*%b()", ""):match("^%s*(.-)%s*$")
    if clean_no_brackets and clean_no_brackets ~= raw_name then
        table.insert(name_variants, clean_no_brackets)
    end
    
    -- 3. Имя с заменой дефисов на пробелы
    if raw_name:find("%-") then
        table.insert(name_variants, (raw_name:gsub("%-", " ")))
        if clean_no_brackets then
            table.insert(name_variants, (clean_no_brackets:gsub("%-", " ")))
        end
    end

    -- Перебор вариантов имен и префиксов
    for _, query in ipairs(name_variants) do
        for _, prefix in ipairs(prefixes) do
            local full_query = prefix .. query
            local idx = (target_type == "take")
                and reaper.TakeFX_AddByName(target, full_query, -1)
                or reaper.TrackFX_AddByName(target, full_query, false, -1)
            
            if idx >= 0 then return idx end
        end
    end
    return -1
end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

-- 4. Определение контекста фокуса (0 = TCP/Tracks, 1 = Arrange/Items)
local focus_context = reaper.GetCursorContext2(true)
local item_count = reaper.CountSelectedMediaItems(0)
local track_count = reaper.CountSelectedTracks(0)

local target_is_item = false

if focus_context == 1 and item_count > 0 then
    target_is_item = true
elseif focus_context == 0 then
    target_is_item = false
elseif item_count > 0 and track_count == 0 then
    target_is_item = true
end

local added_any = false

-- 5. Вставка плагинов
if target_is_item then
    for i = 0, item_count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        if item then
            local take = reaper.GetActiveTake(item)
            if take then
                local idx = add_fx_fallback(take, "take", fxName)
                if idx >= 0 then
                    reaper.TakeFX_Show(take, idx, 3)
                    added_any = true
                end
            end
        end
    end
else
    if track_count > 0 then
        for i = 0, track_count - 1 do
            local track = reaper.GetSelectedTrack(0, i)
            if track then
                local idx = add_fx_fallback(track, "track", fxName)
                if idx >= 0 then
                    reaper.TrackFX_Show(track, idx, 3)
                    added_any = true
                end
            end
        end
    end
end

-- 6. Проверка на ошибку
if not added_any and (item_count > 0 or track_count > 0) then
    reaper.ShowMessageBox("Plugin \"" .. fxName .. "\" not found!", "FX Insert Error", 0)
end

-- 7. Закрытие Toolbars
for _, commandID in ipairs(toolbarsToClose) do
    if reaper.GetToggleCommandState(commandID) == 1 then
        reaper.Main_OnCommand(commandID, 0)
    end
end

reaper.Undo_EndBlock("Insert " .. fxName, -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

no_undo()