-- @description Copy selected item as take and split to new item lane
-- @author Grok
-- @version 5.2

-- Начало блока отмены (undo)
reaper.Undo_BeginBlock()

-- Получаем количество выделенных элементов
local item_count = reaper.CountSelectedMediaItems(0)

if item_count == 0 then
    reaper.ShowMessageBox("Please select at least one item!", "Error", 0)
    reaper.Undo_EndBlock("No items selected", -1)
    return
end

-- Проходим по всем выделенным элементам
for i = 0, item_count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    if not item then goto continue end -- Пропускаем, если элемент невалиден
    
    local track = reaper.GetMediaItem_Track(item)
    if not track then goto continue end -- Пропускаем, если трек невалиден
    
    -- Включаем режим Item Lanes для трека и обновляем
    reaper.SetMediaTrackInfo_Value(track, "I_FREEMODE", 2)
    reaper.UpdateArrange()
    
    -- Увеличиваем количество каналов для двух lane'ов (минимум 4 канала)
    local num_channels = reaper.GetMediaTrackInfo_Value(track, "I_NCHAN")
    if num_channels < 4 then
        reaper.SetMediaTrackInfo_Value(track, "I_NCHAN", 4)
    end
    
    -- Устанавливаем высоту трека для отображения lane'ов
    local current_height = reaper.GetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE")
    if current_height < 200 then
        reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", 200)
    end
    
    -- Получаем исходный тейк
    local take = reaper.GetActiveTake(item)
    if not take then goto continue end -- Пропускаем, если тейк невалиден
    
    -- Добавляем новый тейк в элемент
    local new_take = reaper.AddTakeToMediaItem(item)
    if not new_take then goto continue end -- Пропускаем, если тейк не создан
    
    -- Копируем содержимое в новый тейк
    if reaper.TakeIsMIDI(take) then
        -- Для MIDI копируем ноты, CC и другие события
        local _, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts(take)
        for j = 0, notecnt - 1 do
            local _, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, j)
            reaper.MIDI_InsertNote(new_take, sel, muted, startppq, endppq, chan, pitch, vel, false)
        end
        for j = 0, ccevtcnt - 1 do
            local _, sel, muted, ppqpos, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC(take, j)
            reaper.MIDI_InsertCC(new_take, sel, muted, ppqpos, chanmsg, chan, msg2, msg3)
        end
        for j = 0, textsyxevtcnt - 1 do
            local _, sel, muted, ppqpos, msgtype, msg = reaper.MIDI_GetTextSysexEvt(take, j)
            reaper.MIDI_InsertTextSysexEvt(new_take, sel, muted, ppqpos, msgtype, msg)
        end
        reaper.MIDI_Sort(new_take)
    else
        -- Для аудио копируем источник и настройки
        local source = reaper.GetMediaItemTake_Source(take)
        if source then
            reaper.SetMediaItemTake_Source(new_take, source)
            local take_name = reaper.GetTakeName(take)
            reaper.GetSetMediaItemTakeInfo_String(new_take, "P_NAME", take_name, true)
            local offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
            reaper.SetMediaItemTakeInfo_Value(new_take, "D_STARTOFFS", offset)
        end
    end
    
    -- Убедимся, что элемент выделен, и разбиваем тейки на lane'ы
    reaper.SetMediaItemSelected(item, true)
    reaper.Main_OnCommand(42596, 0) -- Item: Split selected items into lanes by take
    reaper.SetMediaItemSelected(item, false)
    
    -- Окрашиваем новый элемент в lane 1 (I_TAKEFX_CHAN=2) в зеленый цвет
    local track_item_count = reaper.CountTrackMediaItems(track)
    for j = 0, track_item_count - 1 do
        local track_item = reaper.GetTrackMediaItem(track, j)
        local track_item_pos = reaper.GetMediaItemInfo_Value(track_item, "D_POSITION")
        if math.abs(track_item_pos - reaper.GetMediaItemInfo_Value(item, "D_POSITION")) < 0.0001 then
            local lane = reaper.GetMediaItemInfo_Value(track_item, "I_TAKEFX_CHAN")
            if lane == 2 then -- Lane 1
                reaper.SetMediaItemInfo_Value(track_item, "I_CUSTOMCOLOR", reaper.ColorToNative(0, 255, 0)|0x1000000) -- Зеленый цвет
            end
        end
    end
    
    ::continue::
end

-- Обновляем интерфейс
reaper.UpdateArrange()
reaper.UpdateTimeline()
reaper.Main_OnCommand(40507, 0) -- View: Refresh track lanes
reaper.Undo_EndBlock("Copy selected item as take to new item lane", -1)