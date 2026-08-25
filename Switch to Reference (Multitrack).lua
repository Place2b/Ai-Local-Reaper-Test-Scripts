local function no_undo() reaper.defer(function() end) end

local itemCount = reaper.CountSelectedMediaItems(0)
if itemCount == 0 then no_undo() return end

-- 1. Собираем уникальные треки выделенных айтемов
local tracks = {}
local trackMap = {}

for i = 0, itemCount - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    if item then
        local track = reaper.GetMediaItem_Track(item)
        if track and not trackMap[track] then
            trackMap[track] = true
            table.insert(tracks, track)
        end
    end
end

if #tracks == 0 then no_undo() return end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

-- Снимаем текущее выделение со всех треков
reaper.Main_OnCommand(40297, 0) -- Track: Unselect all tracks

-- 2. Обрабатываем каждый трек и выделяем его для переноса наверх
for _, track in ipairs(tracks) do
    -- Отключаем посыл на Master Parent
    reaper.SetMediaTrackInfo_Value(track, "B_MAINSEND", 0)
    
    -- Проверяем наличие HW Send на 1/2
    local hasHWSend = false
    local sendCount = reaper.GetTrackNumSends(track, 1) -- 1 = HW Outputs
    
    for s = 0, sendCount - 1 do
        local dstChan = reaper.GetTrackSendInfo_Value(track, 1, s, "I_DSTCHAN")
        if dstChan == 0 then -- Output 1/2
            hasHWSend = true
            break
        end
    end
    
    -- Создаем HW Send на 1/2, если отсутствовал
    if not hasHWSend then
        local newSend = reaper.CreateTrackSend(track, nil)
        reaper.SetTrackSendInfo_Value(track, 1, newSend, "I_DSTCHAN", 0)
    end
    
    -- Имя без цифр
    reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "REFERENCE", true)
    
    -- Цвет #3B3B3B (RGB: 59, 59, 59)
    local color = reaper.ColorToNative(59, 59, 59) | 0x1000000
    reaper.SetTrackColor(track, color)
    
    -- Record Disarm
    reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 0)
    
    -- Выделяем трек для перемещения
    reaper.SetTrackSelected(track, true)
end

-- 3. Перемещаем выделенные треки на самый верх (индекс 0)
if reaper.APIExists("ReorderSelectedTracks") then
    reaper.ReorderSelectedTracks(0, 0)
end

-- 4. Unselect all tracks and items в конце
reaper.Main_OnCommand(40289, 0) -- Item: Unselect all items
reaper.Main_OnCommand(40297, 0) -- Track: Unselect all tracks

reaper.Undo_EndBlock("Set reference tracks, output direct, move to top", -1)
reaper.PreventUIRefresh(-1)
reaper.TrackList_AdjustWindows(false)
reaper.UpdateArrange()

no_undo()
