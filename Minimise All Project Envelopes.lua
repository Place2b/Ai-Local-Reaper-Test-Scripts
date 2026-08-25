local function main()
  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock()

  local track_count = reaper.CountTracks(0)

  for sel_tr = 0, track_count do
    local track
    if sel_tr == 0 then 
      track = reaper.GetMasterTrack(0) 
    else 
      track = reaper.GetTrack(0, sel_tr - 1) 
    end

    if track then
      local env_count = reaper.CountTrackEnvelopes(track)
      for i = 0, env_count - 1 do
        local env = reaper.GetTrackEnvelope(track, i)
        local br_env = reaper.BR_EnvAlloc(env, false)
        local active, visible, armed, inLane, laneHeight, defaultShape, _, _, _, _, faderScaling = reaper.BR_EnvGetProperties(br_env)
        
        -- Меняем свойства только если высота не минимальная
        if laneHeight ~= 1 then
          reaper.BR_EnvSetProperties(br_env, active, visible, armed, inLane, 1, defaultShape, faderScaling)
          reaper.BR_EnvFree(br_env, true) -- Применяем изменения
        else
          reaper.BR_EnvFree(br_env, false) -- Освобождаем память без перезаписи Chunk
        end
      end
    end
  end

  reaper.Undo_EndBlock("Minimize all tracks envelopes heights", -1)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end

main()
