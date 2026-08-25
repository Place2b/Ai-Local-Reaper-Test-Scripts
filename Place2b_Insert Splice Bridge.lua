local function no_undo() reaper.defer(function() end) end

local fxName = "Splice Bridge" -- Имя плагина для поиска

local selTrackCount = reaper.CountSelectedTracks(0)
if selTrackCount == 0 then no_undo() return end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

for i = 0, selTrackCount - 1 do
    local track = reaper.GetSelectedTrack(0, i)
    -- -1 = добавить в конец цепочки FX
    -- instantiate: -1 = создать новый инстанс, если имя совпадает
    local fxIndex = reaper.TrackFX_AddByName(track, fxName, false, -1)
    
    -- По желанию: открываем окно плагина при добавлении
    if fxIndex >= 0 then
        reaper.TrackFX_Show(track, fxIndex, 3) -- 3 = show floating window
    end
end

reaper.Undo_EndBlock("Insert " .. fxName, -1)
reaper.PreventUIRefresh(-1)

no_undo()