-- SynthLoopMetadata_MediaExplorer_Updated.lua
-- Lua script for REAPER Media Explorer to find samples and add metadata
-- Author: Grok, based on user request
-- Licence: MIT
-- Version: 2.2 (Updated to handle reaper.ini and ReaperFileList)

local reaper = reaper

-- Функция для получения пути из reaper.ini (секция [reaper_explorer])
local function GetPathFromReaperIni()
    local ini_path = reaper.get_ini_file()
    local file = io.open(ini_path, "r")
    if not file then 
        reaper.ShowMessageBox("Не удалось открыть reaper.ini!", "Ошибка", 0)
        return nil 
    end
    local content = file:read("*all")
    file:close()
    
    -- Ищем lastdir в секции [reaper_explorer]
    local last_dir
    local in_reaper_explorer = false
    for line in content:gmatch("[^\r\n]+") do
        if line:match("^%[reaper_explorer%]") then
            in_reaper_explorer = true
        elseif in_reaper_explorer and line:match("^lastdir=") then
            last_dir = line:match("lastdir=(.+)")
            break
        elseif line:match("^%[.*%]") then
            in_reaper_explorer = false
        end
    end
    
    return last_dir
end

-- Функция для получения текущего пути в Media Explorer
local function GetMediaExplorerCurrentPath()
    -- Пробуем использовать JS_MediaExplorer_GetPath, если JS_ReaScriptAPI установлено
    if reaper.JS_MediaExplorer_GetPath then
        local path = reaper.JS_MediaExplorer_GetPath()
        if path and path ~= "" then
            return path
        end
    end
    
    -- Если JS_ReaScriptAPI не установлено, пробуем получить путь из reaper.ini
    local last_dir = GetPathFromReaperIni()
    if last_dir then
        -- Проверяем, является ли last_dir файлом ReaperFileList
        if last_dir:match("%.ReaperFileList$") then
            -- Пытаемся извлечь путь к папке из lastaddpath
            local ini_path = reaper.get_ini_file()
            local file = io.open(ini_path, "r")
            if file then
                local content = file:read("*all")
                file:close()
                local last_add_path
                local in_reaper_explorer = false
                for line in content:gmatch("[^\r\n]+") do
                    if line:match("^%[reaper_explorer%]") then
                        in_reaper_explorer = true
                    elseif in_reaper_explorer and line:match("^lastaddpath=") then
                        last_add_path = line:match("lastaddpath=(.+)")
                        break
                    elseif line:match("^%[.*%]") then
                        in_reaper_explorer = false
                    end
                end
                if last_add_path and last_add_path ~= "" then
                    return last_add_path
                end
            end
        else
            return last_dir
        end
    end
    
    -- Если путь не удалось определить, запрашиваем у пользователя
    local retval, file_path = reaper.BrowseForOpenFiles("Выберите любой файл в папке с семплами", "", "", "", false)
    if not retval then
        reaper.ShowMessageBox("Папка не выбрана!", "Ошибка", 0)
        return nil
    end
    
    -- Извлекаем путь к папке из выбранного файла
    local db_path = file_path:match("^(.*)/[^/]+$")
    if not db_path then
        reaper.ShowMessageBox("Не удалось определить папку!", "Ошибка", 0)
        return nil
    end
    
    return db_path
end

-- Функция для сканирования файлов в папке (рекурсивно)
local function ScanDirectory(path, pattern, file_list)
    file_list = file_list or {}
    local i = 0
    while true do
        local file = reaper.EnumerateFiles(path, i)
        if not file then break end
        if file:lower():match(pattern:lower()) then
            table.insert(file_list, path .. "/" .. file)
        end
        i = i + 1
    end
    
    i = 0
    while true do
        local dir = reaper.EnumerateSubdirectories(path, i)
        if not dir then break end
        ScanDirectory(path .. "/" .. dir, pattern, file_list)
        i = i + 1
    end
    
    return file_list
end

-- Функция для вызова Python-скрипта
local function CallPythonScript(file_path, album, description, comment)
    local python_script = reaper.GetResourcePath() .. "/Scripts/add_metadata.py"
    local cmd = string.format('python "%s" "%s" "%s" "%s" "%s"', 
        python_script, file_path, album, description, comment)
    os.execute(cmd)
end

-- Основная функция
local function Main()
    -- Параметры поиска
    local search_pattern = "Synthloops"
    local album = "Synth"
    local description = "Synth Loop"
    
    -- Получаем текущий путь в Media Explorer
    local db_path = GetMediaExplorerCurrentPath()
    if not db_path then
        return -- Ошибка уже показана в GetMediaExplorerCurrentPath
    end
    
    -- Сканируем файлы в текущей папке
    local files = ScanDirectory(db_path, search_pattern)
    
    if #files == 0 then
        reaper.ShowMessageBox("Не найдено файлов с '" .. search_pattern .. "' в текущей папке!", "Информация", 0)
        return
    end
    
    -- Обрабатываем каждый файл
    for _, file_path in ipairs(files) do
        -- Извлекаем имя семпл-пака из имени файла или пути
        local sample_pack = file_path:match(".*/(.*)/[^/]+$") or "Unknown"
        CallPythonScript(file_path, album, description, sample_pack)
    end
    
    -- Пытаемся обновить Media Explorer
    reaper.Main_OnCommand(42097, 0) -- Media Explorer: Refresh
    reaper.ShowMessageBox("Обработано " .. #files .. " файлов!", "Успех", 0)
end

-- Запуск скрипта
Main()