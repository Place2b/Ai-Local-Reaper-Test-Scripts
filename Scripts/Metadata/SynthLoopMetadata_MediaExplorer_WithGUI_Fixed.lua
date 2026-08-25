-- SynthLoopMetadata_MediaExplorer_WithGUI_Fixed.lua
-- Lua script for REAPER Media Explorer to find samples and add metadata with GUI
-- Author: Grok, based on user request
-- Licence: MIT
-- Version: 3.3 (Fixed syntax error and added debug logging)

local reaper = reaper

-- Проверка наличия reaper.ImGui
if not reaper.ImGui_CreateContext then
    reaper.ShowMessageBox("Ошибка: reaper.ImGui не поддерживается в вашей версии REAPER.\nОбновите REAPER до версии 6.37 или новее, или используйте версию скрипта без GUI.", "Ошибка", 0)
    return
end

-- GUI с использованием reaper.ImGui
local ctx = reaper.ImGui_CreateContext("Metadata Editor")
local search_pattern = "Synthloops"
local album = "Synth"
local description = "Synth Loop"

-- Функция для получения пути из reaper.ini (секция [reaper_explorer])
local function GetPathFromReaperIni()
    local ini_path = reaper.get_ini_file()
    local file = io.open(ini_path, "r")
    if not file then 
        reaper.ShowConsoleMsg("Ошибка: Не удалось открыть reaper.ini!\n")
        return nil 
    end
    local content = file:read("*all")
    file:close()
    
    -- Ищем lastdir и lastaddpath в секции [reaper_explorer]
    local last_dir, last_add_path
    local in_reaper_explorer = false
    for line in content:gmatch("[^\r\n]+") do
        if line:match("^%[reaper_explorer%]") then
            in_reaper_explorer = true
        elseif in_reaper_explorer and line:match("^lastdir=") then
            last_dir = line:match("lastdir=(.+)")
        elseif in_reaper_explorer and line:match("^lastaddpath=") then
            last_add_path = line:match("lastaddpath=(.+)")
        elseif line:match("^%[.*%]") then
            in_reaper_explorer = false
        end
    end
    
    -- Если lastdir указывает на ReaperFileList, используем lastaddpath
    if last_dir and last_dir:match("%.ReaperFileList$") then
        return last_add_path
    end
    return last_dir or last_add_path
end

-- Функция для получения текущего пути в Media Explorer
local function GetMediaExplorerCurrentPath()
    -- Пробуем использовать JS_MediaExplorer_GetPath, если JS_ReaScriptAPI установлено
    if reaper.JS_MediaExplorer_GetPath then
        local path = reaper.JS_MediaExplorer_GetPath()
        if path and path ~= "" then
            reaper.ShowConsoleMsg("Используется путь из JS_MediaExplorer_GetPath: " .. path .. "\n")
            return path
        end
    end
    
    -- Если JS_ReaScriptAPI не установлено, пробуем получить путь из reaper.ini
    local last_path = GetPathFromReaperIni()
    if last_path and last_path ~= "" then
        reaper.ShowConsoleMsg("Используется путь из reaper.ini: " .. last_path .. "\n")
        return last_path
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
    reaper.ShowConsoleMsg("Используется путь, выбранный пользователем: " .. db_path .. "\n")
    return db_path
end

-- Функция для сканирования файлов в папке (рекурсивно) с отладкой
local function ScanDirectory(path, pattern, file_list)
    file_list = file_list or {}
    local total_files = 0
    local i = 0
    while true do
        local file = reaper.EnumerateFiles(path, i)
        if not file then break end
        total_files = total_files + 1
        reaper.ShowConsoleMsg("Найден файл: " .. path .. "/" .. file .. "\n")
        if file:lower():match(pattern:lower()) then
            reaper.ShowConsoleMsg("Файл соответствует шаблону '" .. pattern .. "': " .. file .. "\n")
            table.insert(file_list, path .. "/" .. file)
        end
        i = i + 1
    end
    
    reaper.ShowConsoleMsg("Всего файлов в папке " .. path .. ": " .. total_files .. "\n")
    
    i = 0
    while true do
        local dir = reaper.EnumerateSubdirectories(path, i)
        if not dir then break end
        reaper.ShowConsoleMsg("Найдена подпапка: " .. path .. "/" .. dir .. "\n")
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
    reaper.ShowConsoleMsg("Вызов Python-скрипта для файла: " .. file_path .. "\n")
    local success = os.execute(cmd)
    if success == nil then
        reaper.ShowConsoleMsg("Ошибка: Не удалось выполнить Python-скрипт! Убедитесь, что Python установлен и add_metadata.py находится в папке Scripts.\n")
    end
end

-- Основная функция обработки
local function ProcessFiles(db_path, search_pattern, album, description)
    if not db_path then return end
    
    -- Сканируем файлы в текущей папке
    local files = ScanDirectory(db_path, search_pattern)
    
    if #files == 0 then
        reaper.ShowMessageBox("Не найдено файлов с '" .. search_pattern .. "' в текущей папке!\nПроверьте консоль REAPER для отладочной информации.", "Информация", 0)
        return
    end
    
    -- Обрабатываем каждый файл
    for _, file_path in ipairs(files) do
        -- Извлекаем имя семпл-пака из имени файла или пути
        local sample_pack = file_path:match(".*/(.*)/[^/]+$") or "Unknown"
        CallPythonScript(file_path, album, description, sample_pack)
    end
    
    -- Пытаемся обновить Media Explorer
    if reaper.APIExists("BR_RefreshMediaExplorer") then
        reaper.BR_RefreshMediaExplorer()
        reaper.ShowConsoleMsg("Media Explorer обновлён с помощью SWS: BR_RefreshMediaExplorer\n")
    else
        reaper.Main_OnCommand(42097, 0) -- Media Explorer: Refresh
        reaper.ShowConsoleMsg("Media Explorer обновлён стандартной командой (42097)\n")
    end
    reaper.ShowMessageBox("Обработано " .. #files .. " файлов!", "Успех", 0)
end

-- GUI функция
local function MainGUI()
    local visible, open = reaper.ImGui_Begin(ctx, "Metadata Editor", true)
    if not visible then
        if open then
            reaper.ImGui_End(ctx)
        end
        return open
    end
    
    -- Поле для ввода шаблона поиска
    reaper.ImGui_Text(ctx, "Шаблон поиска (например, Synthloops):")
    local rv, new_pattern = reaper.ImGui_InputText(ctx, "##SearchPattern", search_pattern)
    if rv then
        search_pattern = new_pattern
    end
    
    -- Поле для ввода Album
    reaper.ImGui_Text(ctx, "Album:")
    local rv, new_album = reaper.ImGui_InputText(ctx, "##Album", album)
    if rv then
        album = new_album
    end
    
    -- Поле для ввода Description
    reaper.ImGui_Text(ctx, "Description:")
    local rv, new_description = reaper.ImGui_InputText(ctx, "##Description", description)
    if rv then
        description = new_description
    end
    
    -- Кнопка для обработки
    if reaper.ImGui_Button(ctx, "Обработать файлы") then
        local db_path = GetMediaExplorerCurrentPath()
        ProcessFiles(db_path, search_pattern, album, description)
    end
    
    reaper.ImGui_End(ctx)
    return open
end

-- Основной цикл GUI
local function RunGUI()
    if MainGUI() then
        reaper.defer(RunGUI)
    else
        reaper.ImGui_DestroyContext(ctx)
    end
end

-- Запуск GUI
RunGUI()