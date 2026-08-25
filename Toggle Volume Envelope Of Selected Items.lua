-- @description p2b Toggle Volume Envelope Of Selected Items
-- @version 1.0
-- @provides [main] .
local function no_undo() reaper.defer(function() end) end

local trackMap = {}

-- 1. Собираем уже выделенные треки
local selTrackCount = reaper.CountSelectedTracks(0)
for i = 0, selTrackCount - 1 do
    local tr = reaper.GetSelectedTrack(0, i)
    if tr then trackMap[tr] = true end
end

-- 2. Добавляем треки выделенных айтемов
local selItemCount = reaper.CountSelectedMediaItems(0)
for i = 0, selItemCount - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    if item then
        local tr = reaper.GetMediaItem_Track(item)
        if tr then trackMap[tr] = true end
    end
end

-- Если ничего не выделено — выходим
local hasTracks = false
for _ in pairs(trackMap) do
    hasTracks = true
    break
end
if not hasTracks then no_undo() return end

reaper.PreventUIRefresh(1)

-- 3. Выделяем все собранные треки
reaper.Main_OnCommand(40297, 0) -- Track: Unselect all tracks
for tr in pairs(trackMap) do
    reaper.SetTrackSelected(tr, true)
end

-- 4. Вызываем родной экшен тоггла огибающей громкости
reaper.Main_OnCommand(40052, 0) -- Track: Toggle track volume envelope visible

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

no_undo()
