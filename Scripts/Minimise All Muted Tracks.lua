-- @description p2b Minimise All Muted Tracks
-- @version 1.0
-- @provides [main] .
local minHeight = 24 -- Минимальная высота

local function no_undo() reaper.defer(function() end) end

local CountTrack = reaper.CountTracks(0)
if CountTrack == 0 then no_undo() return end

local extname = "MinimizeMutedTracksState"

-- Запоминаем текущее выделение треков, чтобы восстановить в конце
local selectedTracks = {}
for i = 0, CountTrack - 1 do
    local tr = reaper.GetTrack(0, i)
    if reaper.IsTrackSelected(tr) then
        table.insert(selectedTracks, tr)
    end
end

-- Проверяем, есть ли развернутые замьюченные треки
local hasExpandedMuted = false
for i = 0, CountTrack - 1 do
    local tr = reaper.GetTrack(0, i)
    local isMuted = reaper.GetMediaTrackInfo_Value(tr, "B_MUTE") == 1
    local h = reaper.GetMediaTrackInfo_Value(tr, "I_TCPH")
    if isMuted and h > minHeight then
        hasExpandedMuted = true
        break
    end
end

reaper.PreventUIRefresh(1)

-- Снимаем выделение со всех треков
reaper.Main_OnCommand(40297, 0) -- Track: Unselect all tracks

if hasExpandedMuted then
    -- Сворачиваем: выделяем только мьюты и ставим им минимальную высоту
    for i = 0, CountTrack - 1 do
        local tr = reaper.GetTrack(0, i)
        local isMuted = reaper.GetMediaTrackInfo_Value(tr, "B_MUTE") == 1
        if isMuted then
            local currentH = reaper.GetMediaTrackInfo_Value(tr, "I_TCPH")
            local GUID = reaper.GetTrackGUID(tr)
            reaper.SetProjExtState(0, extname, GUID, tostring(currentH))
            reaper.SetTrackSelected(tr, true)
        end
    end
    
    -- Выставляем минимальную высоту для выделенных треков
    for i = 0, CountTrack - 1 do
        local tr = reaper.GetTrack(0, i)
        if reaper.IsTrackSelected(tr) then
            reaper.SetMediaTrackInfo_Value(tr, "I_HEIGHTOVERRIDE", minHeight)
        end
    end
else
    -- Восстанавливаем высоту
    for i = 0, CountTrack - 1 do
        local tr = reaper.GetTrack(0, i)
        local GUID = reaper.GetTrackGUID(tr)
        local retval, valStr = reaper.GetProjExtState(0, extname, GUID)
        
        if retval == 1 and valStr ~= "" then
            local savedH = tonumber(valStr) or 0
            reaper.SetMediaTrackInfo_Value(tr, "I_HEIGHTOVERRIDE", savedH)
            reaper.SetProjExtState(0, extname, GUID, "")
        end
    end
end

-- Восстанавливаем исходное выделение треков
reaper.Main_OnCommand(40297, 0)
for _, tr in ipairs(selectedTracks) do
    if reaper.ValidatePtr(tr, "MediaTrack*") then
        reaper.SetTrackSelected(tr, true)
    end
end

reaper.PreventUIRefresh(-1)
reaper.TrackList_AdjustWindows(false)
reaper.UpdateArrange()

no_undo()
