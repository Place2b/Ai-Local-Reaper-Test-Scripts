local double_press_timeout = 0.5 -- 0.5 сек для дабл-клика

local last_time = tonumber(reaper.GetExtState("P2B_CLOSE", "last_run")) or 0
local current_time = reaper.time_precise()
local is_second_press = (current_time - last_time) < double_press_timeout

reaper.SetExtState("P2B_CLOSE", "last_run", tostring(current_time), false)

reaper.PreventUIRefresh(1)

if not is_second_press then
    ----------------------------------------------------------------------------
    -- ЭТАП 1: Первое нажатие - закрываем ТОЛЬКО фокусное окно
    ----------------------------------------------------------------------------
    if reaper.JS_Window_GetFocus then
        local focus_win = reaper.JS_Window_GetFocus()
        if focus_win then
            reaper.JS_Window_Destroy(focus_win)
        end
    else
        -- Нативный фоллбэк
        reaper.Main_OnCommand(41882, 0)
    end
else
    ----------------------------------------------------------------------------
    -- ЭТАП 2: Второе нажатие - закрываем ВСЕ FX, MIDI и тулбары
    ----------------------------------------------------------------------------
    reaper.Main_OnCommand(41882, 0)

    for i = 0, reaper.CountTracks(0) - 1 do
        local track = reaper.GetTrack(0, i)
        if track then reaper.TrackFX_Show(track, 0, 0) end
    end
    
    local master = reaper.GetMasterTrack(0)
    if master then reaper.TrackFX_Show(master, 0, 0) end

    for i = 0, reaper.CountMediaItems(0) - 1 do
        local item = reaper.GetMediaItem(0, i)
        if item then
            for t = 0, reaper.CountTakes(item) - 1 do
                local take = reaper.GetTake(item, t)
                if take then reaper.TakeFX_Show(take, 0, 0) end
            end
        end
    end

    reaper.Main_OnCommand(40716, 0)

    local toolbars = {41681, 41682, 41683}
    for _, tb in ipairs(toolbars) do
        if reaper.GetToggleCommandState(tb) == 1 then 
            reaper.Main_OnCommand(tb, 0) 
        end
    end
end

reaper.PreventUIRefresh(-1)
reaper.defer(function() end)
