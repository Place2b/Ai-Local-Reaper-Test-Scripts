-- @description P2b Add Track To MISC BUZZ
-- @version 1.0
-- @provides [main] .
local function no_undo() reaper.defer(function() end) end

local trackName = "MISC BUZZ"
local foundFolderTrack = nil

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

-- 1. Ищем уже существующий трек с именем "MISC BUZZ"
local countTracks = reaper.CountTracks(0)
for i = 0, countTracks - 1 do
    local tr = reaper.GetTrack(0, i)
    local _, name = reaper.GetTrackName(tr)
    if name == trackName then
        foundFolderTrack = tr
        break
    end
end

-- 2. Если трек не найден — создаем папку и дочерний трек
if not foundFolderTrack then
    local insertIdx = countTracks -- вставляем в самый конец проекта
    
    -- Создаем трек-папку MISC BUZZ
    reaper.InsertTrackAtIndex(insertIdx, true)
    foundFolderTrack = reaper.GetTrack(0, insertIdx)
    reaper.GetSetMediaTrackInfo_String(foundFolderTrack, "P_NAME", trackName, true)
    
    -- Делаем трек началом папки (1 = Folder Start)
    reaper.SetMediaTrackInfo_Value(foundFolderTrack, "I_FOLDERDEPTH", 1)
    
    -- Создаем дочерний трек внутри этой папки
    reaper.InsertTrackAtIndex(insertIdx + 1, true)
    local childTrack = reaper.GetTrack(0, insertIdx + 1)
    
    -- Завершаем папку (-1 = Folder End)
    reaper.SetMediaTrackInfo_Value(childTrack, "I_FOLDERDEPTH", -1)
    
    -- Выделяем новый дочерний трек для удобства
    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
    reaper.SetTrackSelected(childTrack, true)
else
    -- Если папка уже существует — просто выделяем ее
    reaper.Main_OnCommand(40297, 0) -- Unselect all tracks
    reaper.SetTrackSelected(foundFolderTrack, true)
end

reaper.Undo_EndBlock("Create MISC BUZZ folder and child track", -1)
reaper.PreventUIRefresh(-1)
reaper.TrackList_AdjustWindows(false)
reaper.UpdateArrange()

no_undo()