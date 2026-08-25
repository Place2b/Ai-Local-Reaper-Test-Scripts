-- @description Select Chord Roots
-- @author Trae AI
-- @version 1.0
-- @about
--   This script selects the root notes of chords in MIDI items
-- @changelog
--   v1.0 - Initial release
-- @provides
--   [midi_editor] .
-- @donation https://example.com

-- Select Chord Roots
-- Script by Trae AI
-- Based on chord database from Lil Chordbox by Ilias Poulakis

function main()
  -- Check if script is running in MIDI editor context
  if not reaper.MIDIEditor_GetActive() then
    reaper.ShowMessageBox("This script must be run from the MIDI editor.", "Error", 0)
    return
  end
  
  -- Get the active MIDI take
  local take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
  if not take or not reaper.TakeIsMIDI(take) then
    reaper.ShowMessageBox("No valid MIDI take found.", "Error", 0)
    return
  end
  
  -- Start undo block
  reaper.Undo_BeginBlock()
  
  -- Clear current selection
  reaper.MIDI_SelectAll(take, false)
  
  -- Get MIDI notes
  local _, notecnt, _, _ = reaper.MIDI_CountEvts(take)
  
  -- Store all notes
  local all_notes = {}
  for i = 0, notecnt - 1 do
    local _, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    table.insert(all_notes, {
      index = i,
      pitch = pitch,
      vel = vel,
      chan = chan,
      startppqpos = startppqpos,
      endppqpos = endppqpos
    })
  end
  
  -- Group notes by position with tolerance
  local tolerance = 5 -- PPQ tolerance for grouping notes
  local chords = {}
  
  for _, note in ipairs(all_notes) do
    local found_group = false
    
    -- Try to find an existing group for this note
    for pos_key, notes_group in pairs(chords) do
      local group_pos = tonumber(pos_key)
      if math.abs(note.startppqpos - group_pos) <= tolerance then
        table.insert(notes_group, note)
        found_group = true
        break
      end
    end
    
    -- If no group found, create a new one
    if not found_group then
      chords[tostring(note.startppqpos)] = {note}
    end
  end
  
  -- Process each chord
  for pos_key, notes in pairs(chords) do
    if #notes >= 2 then -- At least 2 notes to form a chord
      -- Find the root note
      local root_note_index = find_chord_root(notes)
      
      if root_note_index then
        -- Select only this root note
        reaper.MIDI_SetNote(take, root_note_index, true, nil, nil, nil, nil, nil, nil, nil)
      end
    end
  end
  
  -- Update the MIDI editor
  reaper.MIDI_Sort(take)
  
  -- End undo block
  reaper.Undo_EndBlock("Select Chord Roots", -1)
  
  -- Update the MIDI editor view
  reaper.MIDIEditor_OnCommand(reaper.MIDIEditor_GetActive(), 40435) -- Refresh MIDI editor
end

-- Chord definitions
local chord_types = {
  -- Triads
  {name = "Major", intervals = {0, 4, 7}, required = {0, 4}},
  {name = "Minor", intervals = {0, 3, 7}, required = {0, 3}},
  {name = "Diminished", intervals = {0, 3, 6}, required = {0, 3, 6}},
  {name = "Augmented", intervals = {0, 4, 8}, required = {0, 4, 8}},
  {name = "Sus2", intervals = {0, 2, 7}, required = {0, 2}},
  {name = "Sus4", intervals = {0, 5, 7}, required = {0, 5}},
  
  -- Seventh chords
  {name = "Major 7", intervals = {0, 4, 7, 11}, required = {0, 4, 11}},
  {name = "Dominant 7", intervals = {0, 4, 7, 10}, required = {0, 4, 10}},
  {name = "Minor 7", intervals = {0, 3, 7, 10}, required = {0, 3, 10}},
  {name = "Minor Major 7", intervals = {0, 3, 7, 11}, required = {0, 3, 11}},
  {name = "Diminished 7", intervals = {0, 3, 6, 9}, required = {0, 3, 6, 9}},
  {name = "Half-Diminished 7", intervals = {0, 3, 6, 10}, required = {0, 3, 6, 10}},
  {name = "Augmented 7", intervals = {0, 4, 8, 10}, required = {0, 4, 8, 10}},
  {name = "Augmented Major 7", intervals = {0, 4, 8, 11}, required = {0, 4, 8, 11}},
  
  -- Extended chords
  {name = "Major 9", intervals = {0, 4, 7, 11, 14}, required = {0, 4, 11, 14}},
  {name = "Dominant 9", intervals = {0, 4, 7, 10, 14}, required = {0, 4, 10, 14}},
  {name = "Minor 9", intervals = {0, 3, 7, 10, 14}, required = {0, 3, 10, 14}},
  {name = "Major 11", intervals = {0, 4, 7, 11, 14, 17}, required = {0, 4, 11, 17}},
  {name = "Dominant 11", intervals = {0, 4, 7, 10, 14, 17}, required = {0, 4, 10, 17}},
  {name = "Minor 11", intervals = {0, 3, 7, 10, 14, 17}, required = {0, 3, 10, 17}},
  {name = "Major 13", intervals = {0, 4, 7, 11, 14, 17, 21}, required = {0, 4, 11, 21}},
  {name = "Dominant 13", intervals = {0, 4, 7, 10, 14, 17, 21}, required = {0, 4, 10, 21}},
  {name = "Minor 13", intervals = {0, 3, 7, 10, 14, 17, 21}, required = {0, 3, 10, 21}},
  
  -- Added tone chords
  {name = "Add9", intervals = {0, 4, 7, 14}, required = {0, 4, 14}},
  {name = "Add11", intervals = {0, 4, 7, 17}, required = {0, 4, 17}},
  {name = "Add13", intervals = {0, 4, 7, 21}, required = {0, 4, 21}},
  {name = "Minor Add9", intervals = {0, 3, 7, 14}, required = {0, 3, 14}},
  
  -- 6th chords
  {name = "Major 6", intervals = {0, 4, 7, 9}, required = {0, 4, 9}},
  {name = "Minor 6", intervals = {0, 3, 7, 9}, required = {0, 3, 9}},
  {name = "6/9", intervals = {0, 4, 7, 9, 14}, required = {0, 4, 9, 14}},
  
  -- Altered chords
  {name = "7b5", intervals = {0, 4, 6, 10}, required = {0, 4, 6, 10}},
  {name = "7#5", intervals = {0, 4, 8, 10}, required = {0, 4, 8, 10}},
  {name = "7b9", intervals = {0, 4, 7, 10, 13}, required = {0, 4, 10, 13}},
  {name = "7#9", intervals = {0, 4, 7, 10, 15}, required = {0, 4, 10, 15}},
  {name = "7#11", intervals = {0, 4, 7, 10, 18}, required = {0, 4, 10, 18}},
  {name = "7b13", intervals = {0, 4, 7, 10, 20}, required = {0, 4, 10, 20}},
  {name = "7alt", intervals = {0, 4, 7, 10, 13, 18}, required = {0, 4, 10, 13, 18}},
  
  -- Omit chords
  {name = "Minor 7 omit5", intervals = {0, 3, 10}, required = {0, 3, 10}},
  {name = "Major 7 omit5", intervals = {0, 4, 11}, required = {0, 4, 11}},
  {name = "Dominant 7 omit5", intervals = {0, 4, 10}, required = {0, 4, 10}},
}

-- Function to find the root note index of a chord
function find_chord_root(notes)
  if #notes < 2 then return nil end
  
  -- Extract pitches
  local pitches = {}
  local pitch_to_index = {}
  
  for _, note in ipairs(notes) do
    table.insert(pitches, note.pitch)
    pitch_to_index[note.pitch] = note.index
  end
  
  -- Sort pitches
  table.sort(pitches)
  
  -- Find the lowest note (potential bass note for slash chords)
  local bass_pitch = pitches[1]
  
  -- Try each note as potential root
  local best_match = nil
  local best_score = 0
  
  for _, potential_root in ipairs(pitches) do
    -- Create intervals relative to this root
    local intervals = {}
    for _, pitch in ipairs(pitches) do
      local interval = (pitch - potential_root) % 12
      intervals[interval] = true
    end
    
    -- Check against chord types
    for _, chord_type in ipairs(chord_types) do
      local matches = true
      
      -- Check if all required intervals are present
      for _, interval in ipairs(chord_type.required) do
        if not intervals[interval % 12] then
          matches = false
          break
        end
      end
      
      if matches then
        -- Count how many intervals from the full chord definition are present
        local score = 0
        for _, interval in ipairs(chord_type.intervals) do
          if intervals[interval % 12] then
            score = score + 1
          end
        end
        
        -- Prefer chords with more matching intervals
        if score > best_score then
          best_score = score
          best_match = potential_root
        end
      end
    end
  end
  
  -- If we found a match, return the index of the root note
  if best_match then
    return pitch_to_index[best_match]
  end
  
  -- If no chord type matches, default to the lowest note
  return pitch_to_index[bass_pitch]
end

-- Run the script
main()