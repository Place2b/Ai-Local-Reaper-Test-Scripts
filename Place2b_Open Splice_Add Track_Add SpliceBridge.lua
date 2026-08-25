local function no_undo() reaper.defer(function() end) end

local folderName = "MISC BUZZ"
local childTrackName = "Splice Bridge"
local fxName = "Splice Bridge"

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

-- 1. ПРОВЕРЯЕМ, ЕСТЬ ЛИ УЖЕ ТРЕК "Splice Bridge" ИЛИ "MISC BUZZ"
local countTracks = reaper.CountTracks(0)
local foundFolderTrack = nil
local foundChildTrack = nil

for i = 0, countTracks - 1 do
    local tr = reaper.GetTrack(0, i)
    local _, name = reaper.GetTrackName(tr)
    if name == folderName then
        foundFolderTrack = tr
    elseif name == childTrackName then
        foundChildTrack = tr
    end
end

-- 2. ЗАПУСК SPLICE (ТОЛЬКО ЕСЛИ ТРЕКА Splice Bridge ЕЩЕ НЕТ)
if not foundChildTrack then
    local os_name = reaper.GetOS()
    if os_name:find("Win") then
        os.execute('start splice:')
    elseif os_name:find("OSX") or os_name:find("macOS") then
        os.execute('open -a "Splice"')
    end
end

-- 3. СОЗДАНИЕ СТРУКТУРЫ ТРЕКОВ
local targetTrack = foundChildTrack

if not targetTrack then
    if not foundFolderTrack then
        -- Создаем папку MISC BUZZ в конце проекта
        local insertIdx = countTracks
        reaper.InsertTrackAtIndex(insertIdx, true)
        foundFolderTrack = reaper.GetTrack(0, insertIdx)
        reaper.GetSetMediaTrackInfo_String(foundFolderTrack, "P_NAME", folderName, true)
        reaper.SetMediaTrackInfo_Value(foundFolderTrack, "I_FOLDERDEPTH", 1)
        
        -- Создаем трек Splice Bridge внутри папки
        reaper.InsertTrackAtIndex(insertIdx + 1, true)
        targetTrack = reaper.GetTrack(0, insertIdx + 1)
        reaper.SetMediaTrackInfo_Value(targetTrack, "I_FOLDERDEPTH", -1)
    else
        -- Если папка есть, находим ее индекс без вызова CSURF
        local folderIdx = -1
        for i = 0, countTracks - 1 do
            if reaper.GetTrack(0, i) == foundFolderTrack then
                folderIdx = i
                break
            end
        end
        
        -- Вставляем трек прямо под папку
        reaper.InsertTrackAtIndex(folderIdx + 1, true)
        targetTrack = reaper.GetTrack(0, folderIdx + 1)
    end
    
    -- Задаем имя треку
    reaper.GetSetMediaTrackInfo_String(targetTrack, "P_NAME", childTrackName, true)
end

-- 4. ВЫДЕЛЕНИЕ И ДОБАВЛЕНИЕ/ОТКРЫТИЕ ПЛАГИНА
if targetTrack then
    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
    reaper.SetTrackSelected(targetTrack, true)
    
    -- Ищем или добавляем плагин
    local fxIndex = reaper.TrackFX_AddByName(targetTrack, fxName, false, -1)
    if fxIndex >= 0 then
        reaper.TrackFX_Show(targetTrack, fxIndex, 3) -- Показать окно плагина
    end
end

reaper.Undo_EndBlock("Open Splice & Setup Track", -1)
reaper.PreventUIRefresh(-1)
reaper.TrackList_AdjustWindows(false)
reaper.UpdateArrange()

no_undo()
