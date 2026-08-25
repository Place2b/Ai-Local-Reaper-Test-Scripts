-- Ищем выделенный трек (или первый, если ничего не выделено)
local track = reaper.GetSelectedTrack(0, 0)

if track then
    reaper.Undo_BeginBlock()
    -- Устанавливаем новое имя
    reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "MISC BUZZ", true)
    reaper.Undo_EndBlock("Rename track to MISC BUZZ", -1)
end
