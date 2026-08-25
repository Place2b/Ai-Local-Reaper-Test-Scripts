-- SynthLoopMetadata_MediaExplorer_WithGUI_Debug.lua
-- Lua script for REAPER Media Explorer to find samples and add metadata with GUI and debug info
-- Author: Grok, based on user request
-- Licence: MIT
-- Version: 3.1 (Added debug logging)

local reaper = reaper

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