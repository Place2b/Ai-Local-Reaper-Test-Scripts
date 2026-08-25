--[[ 
* ReaScript Name: Open_MIDI_With_Zoom_And_ScrollToNotes
* Description: Opens selected MIDI item in MIDI editor, sets default zoom, and scrolls to center notes vertically.
* Version: 1.0
* Author: Adapted from kawa_ and EEL script
--]]

-- Function to deepcopy tables (from kawa_MIDI_VerticalScrollToBottomNote.lua)
function deepcopy(t)
  local o = type(t)
  local e
  if o == 'table' then
    e = {}
    for t, o in next, t, nil do
      e[deepcopy(t)] = deepcopy(o)
    end
    setmetatable(e, deepcopy(getmetatable(t)))
  else
    e = t
  end
  return e
end

-- MIDI Functions (adapted from kawa_MIDI_VerticalScrollToBottomNote.lua)
local function createMIDIFunc3(p)
  local e = {}
  e.allNotes = {}
  e.selectedNotes = {}
  e._editingNotes_Original = {}
  e.editingNotes = {}
  e.editorHwnd = nil
  e.take = nil
  e.mediaItem = nil
  e.mediaTrack = nil
  e._limitMaxCount = 1e3
  e._isSafeLimit = true

  function e:_showLimitNoteMsg()
    reaper.ShowMessageBox("Over " .. tostring(self._limitMaxCount) .. " notes.\nStop process.", "Stop", 0)
  end

  function e:getMidiNotes()
    reaper.PreventUIRefresh(2)
    local i = {}
    local a = {}
    local m, n, s, t, o, c, d, r = reaper.MIDI_GetNote(self.take, 0)
    local e = 0
    while m do
      t = reaper.MIDI_GetProjQNFromPPQPos(self.take, t)
      o = reaper.MIDI_GetProjQNFromPPQPos(self.take, o)
      local l = { selection = n, mute = s, startQn = t, endQn = o, chan = c, pitch = d, vel = r, take = self.take, idx = e, length = o - t }
      table.insert(i, l)
      if n == true then table.insert(a, l) end
      e = e + 1
      m, n, s, t, o, c, d, r = reaper.MIDI_GetNote(self.take, e)
      if e > self._limitMaxCount then
        i = {}
        a = {}
        self:_showLimitNoteMsg()
        self._isSafeLimit = false
        break
      end
    end
    self.m_existMaxNoteIdx = e
    reaper.PreventUIRefresh(-1)
    return i, a
  end

  function e:detectTargetNote()
    if self._isSafeLimit == false then return {} end
    if #self.selectedNotes >= 1 then
      self._editingNotes_Original = deepcopy(self.selectedNotes)
      self.editingNotes = deepcopy(self.selectedNotes)
      return self.editingNotes
    else
      self._editingNotes_Original = deepcopy(self.allNotes)
      self.editingNotes = deepcopy(self.allNotes)
      return self.editingNotes
    end
  end

  function e:_init(take)
    self.editorHwnd = reaper.MIDIEditor_GetActive()
    self.take = take or reaper.MIDIEditor_GetTake(self.editorHwnd)
    if self.take == nil then return end
    self.allNotes, self.selectedNotes = self:getMidiNotes()
    self.mediaItem = reaper.GetMediaItemTake_Item(self.take)
    self.mediaTrack = reaper.GetMediaItemTrack(self.mediaItem)
  end

  e:_init(p)
  return e
end

-- Function to scroll to a specific note row (from kawa_MIDI_VerticalScrollToBottomNote.lua)
local function scrollToNoteRow(editor, target_row)
  local current_row = reaper.MIDIEditor_GetSetting_int(editor, "active_note_row")
  target_row = math.floor(math.min(math.max(0, target_row), 127))
  if current_row == target_row then return end
  local cmd_zoom_in = 40049
  local cmd_zoom_out = 40050
  local cmd = current_row > target_row and cmd_zoom_out or cmd_zoom_in
  local max_attempts = 200
  local attempts = 0
  while attempts < max_attempts do
    current_row = reaper.MIDIEditor_GetSetting_int(editor, "active_note_row")
    current_row = math.floor(math.min(math.max(0, current_row), 127))
    if current_row == target_row then break end
    reaper.MIDIEditor_OnCommand(editor, cmd)
    attempts = attempts + 1
  end
end

-- Main function
local function main()
  -- Step 1: Open selected MIDI item in MIDI editor
  reaper.Main_OnCommand(40153, 0) -- Open selected item in MIDI editor

  -- Step 2: Get active MIDI editor
  local midi_editor = reaper.MIDIEditor_GetActive()
  if not midi_editor then return end

  -- Step 3: Get MIDI take
  local take = reaper.MIDIEditor_GetTake(midi_editor)
  if not take then return end

  -- Step 4: Initialize MIDI functions and get notes
  local midi_func = createMIDIFunc3(take)
  local notes = midi_func.allNotes
  if #notes < 1 then return end

  -- Step 5: Find note range (min and max pitch)
  local min_pitch, max_pitch
  for _, note in ipairs(notes) do
    min_pitch = min_pitch and math.min(min_pitch, note.pitch) or note.pitch
    max_pitch = max_pitch and math.max(max_pitch, note.pitch) or note.pitch
  end

  -- Step 6: Set default zoom levels (adapted from EEL script)
  local default_zoom_level = 16
  local max_zoomed_out_level = 16

  -- Horizontal zoom: Zoom to one loop iteration
  reaper.MIDIEditor_OnCommand(midi_editor, 40468) -- Zoom to one loop iteration

  -- Vertical zoom: Zoom out fully, then zoom in to default level
  for i = 1, max_zoomed_out_level do
    reaper.MIDIEditor_OnCommand(midi_editor, 40112) -- Zoom out vertically
  end
  for i = 1, default_zoom_level do
    reaper.MIDIEditor_OnCommand(midi_editor, 40111) -- Zoom in vertically
  end

  -- Step 7: Scroll to center the note range
  local center_pitch = math.floor((min_pitch + max_pitch) / 2)
  scrollToNoteRow(midi_editor, center_pitch)

  -- Step 8: Ensure notes are in view by adjusting zoom if necessary
  local note_range = max_pitch - min_pitch
  local visible_rows = 128 / (2 ^ (default_zoom_level / 10)) -- Approximate visible rows
  if note_range > visible_rows then
    local extra_zoom_out = math.ceil(math.log2(note_range / visible_rows))
    for i = 1, extra_zoom_out do
      reaper.MIDIEditor_OnCommand(midi_editor, 40112) -- Zoom out vertically
    end
  end
end

-- Run script with undo block
reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Open MIDI with Zoom and Scroll to Notes", -1)