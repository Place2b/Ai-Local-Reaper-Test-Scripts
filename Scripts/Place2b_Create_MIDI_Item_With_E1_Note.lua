-- Создает MIDI-итем на выбранном треке с нотой E1 (MIDI note 28) длительностью 4 четверти
function main()
  -- Получаем выбранный трек
  local track = reaper.GetSelectedTrack(0, 0)
  if not track then return end

  -- Параметры MIDI-итема и ноты в четвертях
  local note_length_beats = 4 -- Длительность в четвертях (4.0.00 = 4 четверти)
  local start_pos_beats = reaper.GetCursorPositionEx(0) -- Позиция курсора в секундах
  start_pos_beats = reaper.TimeMap2_timeToQN(0, start_pos_beats) -- Конвертируем в четверти
  local end_pos_beats = start_pos_beats + note_length_beats -- Конец в четвертях

  -- Конвертируем обратно в секунды для создания итема
  local start_pos = reaper.TimeMap2_QNToTime(0, start_pos_beats)
  local end_pos = reaper.TimeMap2_QNToTime(0, end_pos_beats)

  -- Проверка параметров
  if start_pos < 0 or (end_pos - start_pos) <= 0 then return end

  -- Создаем MIDI-итем
  local item = reaper.CreateNewMIDIItemInProj(track, start_pos, end_pos, false)
  if not item then return end

  -- Получаем активный тейк
  local take = reaper.GetMediaItemTake(item, 0)
  if not take or not reaper.TakeIsMIDI(take) then return end

  -- Преобразуем время в PPQ для ноты
  local start_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, start_pos)
  local end_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, end_pos)

  -- Параметры ноты: E1 (MIDI note 28), громкость 127, канал 1
  local note_pitch = 28
  local note_velocity = 127
  local note_channel = 1

  -- Добавляем MIDI-ноту
  reaper.MIDI_InsertNote(take,
    true,          -- selected
    false,         -- muted
    start_ppq,     -- start time in PPQ
    end_ppq,       -- end time in PPQ
    note_channel,  -- channel
    note_pitch,    -- pitch
    note_velocity, -- velocity
    true)          -- noSort

  -- Сортируем MIDI-события
  reaper.MIDI_Sort(take)

  -- Обновляем интерфейс
  reaper.UpdateArrange()
  reaper.Undo_OnStateChange("Создан MIDI-итем с нотой E1 (4 четверти)")
end

-- Запускаем скрипт в undo-блоке
reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Создать MIDI-итем с нотой E1 (4 четверти)", -1)
