require("src/startup")

print("-----------------------------")
print("  3rd_training.lua - "..script_version.."")
print("  Training mode for "..game_name.."")
print("  Last tested Fightcade version: "..fc_version.."")
print("  project url: https://github.com/Grouflon/3rd_training_lua")
print("-----------------------------")
print("")
print("Command List:")
print("- Enter training menu by pressing \"Start\" while in game")
print("- Enter/exit recording mode by double tapping \"Coin\"")
print("- In recording mode, press \"Coin\" again to start/stop recording")
print("- In normal mode, press \"Coin\" to start/stop replay")
print("")

-- Kudos to indirect contributors:
-- *esn3s* for his work on 3s frame data : http://baston.esn3s.com/
-- *dammit* for his work on 3s hitbox display script : https://dammit.typepad.com/blog/2011/10/improved-3rd-strike-hitboxes.html
-- *furitiem* for his prior work on 3s C# training program : https://www.youtube.com/watch?v=vE27xe0QM64
-- *crytal_cube99* for his prior work on 3s training & trial scripts : https://ameblo.jp/3fv/

-- Thanks to *speedmccool25* for recording all the 4rd strike frame data
-- Thanks to *ProfessorAnon* for the Charge special training mode

-- FBA-RR Scripting reference:
-- http://tasvideos.org/EmulatorResources/VBA/LuaScriptingFunctions.html
-- https://github.com/TASVideos/mame-rr/wiki/Lua-scripting-functions

-- Resources
-- https://github.com/Jesuszilla/mame-rr-scripts/blob/master/framedata.lua

-- Includes
require("src/tools")
require("src/display")
require("src/menu_widgets")
require("src/framedata")
require("src/gamestate")
require("src/input_history")
require("src/frame_advantage")

recording_slot_count = 8

-- debug options
developer_mode = false -- Unlock frame data recording options. Touch at your own risk since you may use those options to fuck up some already recorded frame data
assert_enabled = developer_mode or assert_enabled
debug_wakeup = false
log_enabled = developer_mode or log_enabled
log_categories_display =
{
  input =                     { history = true, print = false },
  projectiles =               { history = false, print = false },
  fight =                     { history = true, print = false },
  animation =                 { history = false, print = false },
  parry_training_FORWARD =    { history = false, print = false },
  blocking =                  { history = true, print = false },
  counter_attack =            { history = false, print = false },
  block_string =              { history = false, print = true },
} or log_categories_display

saved_recordings_path = "saved/recordings/"
training_settings_file = "training_settings.json"

-- players
function queue_input_sequence(_player_obj, _sequence)
  if _sequence == nil or #_sequence == 0 then
    return
  end

  if _player_obj.pending_input_sequence ~= nil then
    return
  end

  local _seq = {}
  _seq.sequence = copytable(_sequence)
  _seq.current_frame = 1

  _player_obj.pending_input_sequence = _seq
end

function process_pending_input_sequence(_player_obj, _input)
  if _player_obj.pending_input_sequence == nil then
    return
  end
  if is_menu_open then
    return
  end
  if not is_in_match then
    return
  end

  -- Cancel all input
  _input[_player_obj.prefix.." Up"] = false
  _input[_player_obj.prefix.." Down"] = false
  _input[_player_obj.prefix.." Left"] = false
  _input[_player_obj.prefix.." Right"] = false
  _input[_player_obj.prefix.." Weak Punch"] = false
  _input[_player_obj.prefix.." Medium Punch"] = false
  _input[_player_obj.prefix.." Strong Punch"] = false
  _input[_player_obj.prefix.." Weak Kick"] = false
  _input[_player_obj.prefix.." Medium Kick"] = false
  _input[_player_obj.prefix.." Strong Kick"] = false

  -- Charge moves memory locations
  -- P1
  -- 0x020259D8 H/Urien V/Oro V/Chun H/Q V/Remy
  -- 0x020259F4 (+1C) V/Urien H/Q H/Remy
  -- 0x02025A10 (+38) H/Oro H/Remy
  -- 0x02025A2C (+54) V/Urien V/Alex
  -- 0x02025A48 (+70) H/Alex

  -- P2
  -- 0x02025FF8
  -- 0x02026014
  -- 0x02026030
  -- 0x0202604C
  -- 0x02026068
  local _gauges_base = 0
  if _player_obj.id == 1 then
    _gauges_base = 0x020259D8
  elseif _player_obj.id == 2 then
    _gauges_base = 0x02025FF8
  end
  local _gauges_offsets = { 0x0, 0x1C, 0x38, 0x54, 0x70 }

  local _s = ""
  local _current_frame_input = _player_obj.pending_input_sequence.sequence[_player_obj.pending_input_sequence.current_frame]
  for i = 1, #_current_frame_input do
    local _input_name = _player_obj.prefix.." "
    if _current_frame_input[i] == "forward" then
      if _player_obj.flip_input then _input_name = _input_name.."Right" else _input_name = _input_name.."Left" end
    elseif _current_frame_input[i] == "back" then
      if _player_obj.flip_input then _input_name = _input_name.."Left" else _input_name = _input_name.."Right" end
    elseif _current_frame_input[i] == "up" then
      _input_name = _input_name.."Up"
    elseif _current_frame_input[i] == "down" then
      _input_name = _input_name.."Down"
    elseif _current_frame_input[i] == "LP" then
      _input_name = _input_name.."Weak Punch"
    elseif _current_frame_input[i] == "MP" then
      _input_name = _input_name.."Medium Punch"
    elseif _current_frame_input[i] == "HP" then
      _input_name = _input_name.."Strong Punch"
    elseif _current_frame_input[i] == "LK" then
      _input_name = _input_name.."Weak Kick"
    elseif _current_frame_input[i] == "MK" then
      _input_name = _input_name.."Medium Kick"
    elseif _current_frame_input[i] == "HK" then
      _input_name = _input_name.."Strong Kick"
    elseif _current_frame_input[i] == "h_charge" then
      if _player_obj.char_str == "urien" then
        memory.writeword(_gauges_base + _gauges_offsets[1], 0xFFFF)
      elseif _player_obj.char_str == "oro" then
        memory.writeword(_gauges_base + _gauges_offsets[3], 0xFFFF)
      elseif _player_obj.char_str == "chunli" then
      elseif _player_obj.char_str == "q" then
        memory.writeword(_gauges_base + _gauges_offsets[1], 0xFFFF)
        memory.writeword(_gauges_base + _gauges_offsets[2], 0xFFFF)
      elseif _player_obj.char_str == "remy" then
        memory.writeword(_gauges_base + _gauges_offsets[2], 0xFFFF)
        memory.writeword(_gauges_base + _gauges_offsets[3], 0xFFFF)
      elseif _player_obj.char_str == "alex" then
        memory.writeword(_gauges_base + _gauges_offsets[5], 0xFFFF)
      end
    elseif _current_frame_input[i] == "v_charge" then
      if _player_obj.char_str == "urien" then
        memory.writeword(_gauges_base + _gauges_offsets[2], 0xFFFF)
        memory.writeword(_gauges_base + _gauges_offsets[4], 0xFFFF)
      elseif _player_obj.char_str == "oro" then
        memory.writeword(_gauges_base + _gauges_offsets[1], 0xFFFF)
      elseif _player_obj.char_str == "chunli" then
        memory.writeword(_gauges_base + _gauges_offsets[1], 0xFFFF)
      elseif _player_obj.char_str == "q" then
      elseif _player_obj.char_str == "remy" then
        memory.writeword(_gauges_base + _gauges_offsets[1], 0xFFFF)
      elseif _player_obj.char_str == "alex" then
        memory.writeword(_gauges_base + _gauges_offsets[4], 0xFFFF)
      end
    end
    _input[_input_name] = true
    _s = _s.._input_name
  end

  --print(_s)

  _player_obj.pending_input_sequence.current_frame = _player_obj.pending_input_sequence.current_frame + 1
  if _player_obj.pending_input_sequence.current_frame > #_player_obj.pending_input_sequence.sequence then
    _player_obj.pending_input_sequence = nil
  end
end

function clear_input_sequence(_player_obj)
  _player_obj.pending_input_sequence = nil
end

function make_input_empty(_input)
  if _input == nil then
    return
  end

  _input["P1 Up"] = false
  _input["P1 Down"] = false
  _input["P1 Left"] = false
  _input["P1 Right"] = false
  _input["P1 Weak Punch"] = false
  _input["P1 Medium Punch"] = false
  _input["P1 Strong Punch"] = false
  _input["P1 Weak Kick"] = false
  _input["P1 Medium Kick"] = false
  _input["P1 Strong Kick"] = false
  _input["P2 Up"] = false
  _input["P2 Down"] = false
  _input["P2 Left"] = false
  _input["P2 Right"] = false
  _input["P2 Weak Punch"] = false
  _input["P2 Medium Punch"] = false
  _input["P2 Strong Punch"] = false
  _input["P2 Weak Kick"] = false
  _input["P2 Medium Kick"] = false
  _input["P2 Strong Kick"] = false
end


-- training settings
pose = {
  "normal",
  "crouching",
  "jumping",
  "highjumping",
}

stick_gesture = {
  "none",
  "forward",
  "back",
  "down",
  "up",
  "QCF",
  "QCB",
  "HCF",
  "HCB",
  "DPF",
  "DPB",
  "HCharge",
  "VCharge",
  "360",
  "DQCF",
  "720",
  "back dash",
  "forward dash",
  "Shun Goku Satsu", -- Gouki hidden SA1
  "Kongou Kokuretsu Zan", -- Gouki hidden SA2
}
if is_4rd_strike then
  table.insert(stick_gesture, "Demon Armageddon") -- Gouki SA3
end

button_gesture =
{
  "none",
  "recording",
  "LP",
  "MP",
  "HP",
  "EXP",
  "LK",
  "MK",
  "HK",
  "EXK",
  "LP+LK",
  "MP+MK",
  "HP+HK",
}

function make_input_sequence(_stick, _button)

  if _button == "recording" then
    return nil
  end

  local _sequence = {}
  if      _stick == "none"    then _sequence = { { } }
  elseif  _stick == "forward" then _sequence = { { "forward" } }
  elseif  _stick == "back"    then _sequence = { { "back" } }
  elseif  _stick == "down"    then _sequence = { { "down" } }
  elseif  _stick == "up"      then _sequence = { { "up" } }
  elseif  _stick == "QCF"     then _sequence = { { "down" }, {"down", "forward"}, {"forward"} }
  elseif  _stick == "QCB"     then _sequence = { { "down" }, {"down", "back"}, {"back"} }
  elseif  _stick == "HCF"     then _sequence = { { "back" }, {"down", "back"}, {"down"}, {"down", "forward"}, {"forward"} }
  elseif  _stick == "HCB"     then _sequence = { { "forward" }, {"down", "forward"}, {"down"}, {"down", "back"}, {"back"} }
  elseif  _stick == "DPF"     then _sequence = { { "forward" }, {"down"}, {"down", "forward"} }
  elseif  _stick == "DPB"     then _sequence = { { "back" }, {"down"}, {"down", "back"} }
  elseif  _stick == "HCharge" then _sequence = { { "back", "h_charge" }, {"forward"} }
  elseif  _stick == "VCharge" then _sequence = { { "down", "v_charge" }, {"up"} }
  elseif  _stick == "360"     then _sequence = { { "forward" }, { "forward", "down" }, {"down"}, { "back", "down" }, { "back" }, { "up" } }
  elseif  _stick == "DQCF"    then _sequence = { { "down" }, {"down", "forward"}, {"forward"}, { "down" }, {"down", "forward"}, {"forward"} }
  elseif  _stick == "720"     then _sequence = { { "forward" }, { "forward", "down" }, {"down"}, { "back", "down" }, { "back" }, { "up" }, { "forward" }, { "forward", "down" }, {"down"}, { "back", "down" }, { "back" } }
  -- full moves special cases
  elseif  _stick == "back dash" then _sequence = { { "back" }, {}, { "back" } }
    return _sequence
  elseif  _stick == "forward dash" then _sequence = { { "forward" }, {}, { "forward" } }
    return _sequence
  elseif  _stick == "Shun Goku Satsu" then _sequence = { { "LP" }, {}, {}, { "LP" }, { "forward" }, {"LK"}, {}, { "HP" } }
    return _sequence
  elseif  _stick == "Kongou Kokuretsu Zan" then _sequence = { { "down" }, {}, { "down" }, {}, { "down", "LP", "MP", "HP" } }
    return _sequence
  elseif  _stick == "Demon Armageddon" then _sequence = { { "up" }, {}, { "up" }, {}, { "up", "LK", "MK" } }
    return _sequence
  end

  if     _button == "none" then
  elseif _button == "EXP"  then
    table.insert(_sequence[#_sequence], "MP")
    table.insert(_sequence[#_sequence], "HP")
  elseif _button == "EXK"  then
    table.insert(_sequence[#_sequence], "MK")
    table.insert(_sequence[#_sequence], "HK")
  elseif _button == "LP+LK" then
    table.insert(_sequence[#_sequence], "LP")
    table.insert(_sequence[#_sequence], "LK")
  elseif _button == "MP+MK" then
    table.insert(_sequence[#_sequence], "MP")
    table.insert(_sequence[#_sequence], "MK")
  elseif _button == "HP+HK" then
    table.insert(_sequence[#_sequence], "HP")
    table.insert(_sequence[#_sequence], "HK")
  else
    table.insert(_sequence[#_sequence], _button)
  end

  return _sequence
end

fast_wakeup_mode =
{
  "never",
  "always",
  "random",
}

blocking_style =
{
  "block",
  "parry",
  "red parry",
}

blocking_mode =
{
  "never",
  "always",
  "first hit",
  "random",
}

tech_throws_mode =
{
  "never",
  "always",
  "random",
}

hit_type =
{
  "normal",
  "low",
  "overhead",
}

life_mode =
{
  "no refill",
  "refill",
  "infinite"
}

meter_mode =
{
  "no refill",
  "refill",
  "infinite"
}

stun_mode =
{
  "normal",
  "no stun",
  "delayed reset"
}

standing_state =
{
  "knockeddown",
  "standing",
  "crouched",
  "airborne",
}

players = {
  "Player 1",
  "Player 2",
}

special_training_mode = {
  "none",
  "parry",
  "charge"
}

function make_recording_slot()
  return {
    inputs = {},
    delay = 0,
    random_deviation = 0,
    weight = 1,
  }
end
recording_slots = {}
for _i = 1, recording_slot_count do
  table.insert(recording_slots, make_recording_slot())
end

recording_slots_names = {}
for _i = 1, #recording_slots do
  table.insert(recording_slots_names, "slot ".._i)
end

slot_replay_mode = {
  "normal",
  "random",
  "repeat",
  "repeat random",
}

-- save/load
function save_training_data()
  backup_recordings()
  if not write_object_to_json_file(training_settings, saved_path..training_settings_file) then
    print(string.format("Error: Failed to save training settings to \"%s\"", training_settings_file))
  end
end

function load_training_data()
  local _training_settings = read_object_from_json_file(saved_path..training_settings_file)
  if _training_settings == nil then
    _training_settings = {}
  end

  -- update old versions data
  if _training_settings.recordings then
    for _key, _value in pairs(_training_settings.recordings) do
      for _i, _slot in ipairs(_value) do
        if _value[_i].inputs == nil then
          _value[_i] = make_recording_slot()
        else
          _slot.delay = _slot.delay or 0
          _slot.random_deviation = _slot.random_deviation or 0
          _slot.weight = _slot.weight or 1
        end
      end
    end
  end

  for _key, _value in pairs(_training_settings) do
    training_settings[_key] = _value
  end

  restore_recordings()
end

function backup_recordings()
  -- Init base table
  if training_settings.recordings == nil then
    training_settings.recordings = {}
    for _key, _value in ipairs(characters) do
      training_settings.recordings[_value] = {}
      for _i = 1, #recording_slots do
        table.insert(training_settings.recordings[_value], make_recording_slot())
      end
    end
  end

  if dummy.char_str ~= "" then
    training_settings.recordings[dummy.char_str] = recording_slots
  end
end

function restore_recordings()
  local _char = player_objects[2].char_str
  if _char and _char ~= "" then
    local _recording_count = #recording_slots
    if training_settings.recordings then
      recording_slots = training_settings.recordings[_char] or {}
    end
    local _missing_slots = _recording_count - #recording_slots
    for _i = 1, _missing_slots do
      table.insert(recording_slots, make_recording_slot())
    end
  end
end

-- swap inputs
function swap_inputs(_out_input_table)
  function swap(_input)
    local carry = _out_input_table["P1 ".._input]
    _out_input_table["P1 ".._input] = _out_input_table["P2 ".._input]
    _out_input_table["P2 ".._input] = carry
  end

  swap("Up")
  swap("Down")
  swap("Left")
  swap("Right")
  swap("Weak Punch")
  swap("Medium Punch")
  swap("Strong Punch")
  swap("Weak Kick")
  swap("Medium Kick")
  swap("Strong Kick")
end


-- POSE

function update_pose(_input, _player_obj, _pose)

if current_recording_state == 4 then -- Replaying
  return
end

  -- pose
if is_in_match and not is_menu_open and _player_obj.pending_input_sequence == nil then
  local _on_ground = is_state_on_ground(_player_obj.standing_state, _player_obj)

  if _pose == 2 and _on_ground then -- crouch
    _input[_player_obj.prefix..' Down'] = true
  elseif _pose == 3 and _on_ground then -- jump
    _input[_player_obj.prefix..' Up'] = true
  elseif _pose == 4 then -- high jump
    if _on_ground and _player_obj.pending_input_sequence == nil then
      queue_input_sequence(_player_obj, {{"down"}, {"up"}})
    end
  end
end
end

-- BLOCKING

function find_move_frame_data(_char_str, _animation_id)
  if not frame_data[_char_str] then return nil end
  return frame_data[_char_str][_animation_id]
end

function predict_object_position(_object, _frames_prediction, _movement_cycle, _lifetime)
  local _result = {
    _object.pos_x,
    _object.pos_y,
  }

  if _frames_prediction == 0 then
    return _result
  end

  -- case of supplied movement pattern
  _lifetime = _lifetime or 0
  if _movement_cycle ~= nil then
    local _sign = 1
    if _object.flip_x ~= 0 then _sign = -1 end
    local _cycle_length = #_movement_cycle
    for _i = _lifetime, _lifetime + _frames_prediction - 1 do
      local _movement_index = (_i % _cycle_length) + 1
      _result[1] = _result[1] + _movement_cycle[_movement_index][1] * _sign
      _result[2] = _result[2] + _movement_cycle[_movement_index][2]
    end
    return _result
  end

  local _last_velocity_sample = _object.velocity_samples[#_object.velocity_samples]
  local _velocity_x = _last_velocity_sample.x + _object.acc.x * _frames_prediction
  local _velocity_y = _last_velocity_sample.y + _object.acc.y * _frames_prediction

  _result[1] = _result[1] + _velocity_x * _frames_prediction
  _result[2] = _result[2] + _velocity_y * _frames_prediction
  return _result
end

function predict_frames_before_landing(_player_obj, _max_lookahead_frames)
  _max_lookahead_frames = _max_lookahead_frames or 15
  if _player_obj.pos_y == 0 then
    return 0
  end

  local _result = -1
  for _i = 1, _max_lookahead_frames do
    local _pos = predict_object_position(_player_obj, _i)
    if _pos[2] <= 3 then
      _result = _i
      break
    end
  end
  return _result
end

function predict_hitboxes(_player_obj, _frames_prediction)
  local _debug = false
  local _result = {
    frame = 0,
    frame_data = nil,
    hit_id = 0,
    pos_x = 0,
    pos_y = 0,
  }

  local _frame_data = find_move_frame_data(_player_obj.char_str, _player_obj.relevant_animation)
  if not _frame_data then return _result end

  local _frame_data_meta = frame_data_meta[_player_obj.char_str].moves[_player_obj.relevant_animation]

  local _frame = _player_obj.relevant_animation_frame
  local _frame_to_check = _frame + _frames_prediction
  local _current_animation_pos = {_player_obj.pos_x, _player_obj.pos_y}
  local _frame_delta = _frame_to_check - _frame

  --print(string.format("update blocking frame %d (freeze: %d)", _frame, _player_obj.current_animation_freeze_frames - 1))

  local _next_hit_id = 1
  for i = 1, #_frame_data.hit_frames do
    if _frame_data.hit_frames[i] ~= nil then
      if type(_frame_data.hit_frames[i]) == "number" then
        if _frame_to_check >= _frame_data.hit_frames[i] then
          _next_hit_id = i
        end
      else
        --print(string.format("%d/%d", _frame_to_check, _frame_data.hit_frames[i].max))
        if _frame_to_check > _frame_data.hit_frames[i].max then
          _next_hit_id = i + 1
        end
      end
    end
  end

  if _next_hit_id > #_frame_data.hit_frames then return _result end

  if _frame_to_check < #_frame_data.frames then
    local _next_frame = _frame_data.frames[_frame_to_check + 1]
    local _sign = 1
    if _player_obj.flip_x ~= 0 then _sign = -1 end
    local _next_attacker_pos = copytable(_current_animation_pos)
    local _movement_type = 1
    if _frame_data_meta and _frame_data_meta.movement_type then
      _movement_type = _frame_data_meta.movement_type
    end
    if _movement_type == 1 then -- animation base movement
      for i = _frame + 1, _frame_to_check do
        if i >= 0 then
          _next_attacker_pos[1] = _next_attacker_pos[1] + _frame_data.frames[i+1].movement[1] * _sign
          _next_attacker_pos[2] = _next_attacker_pos[2] + _frame_data.frames[i+1].movement[2]
        end
      end
    else -- velocity based movement
      _next_attacker_pos = predict_object_position(_player_obj, _frame_delta)
    end

    _result.frame = _frame_to_check
    _result.frame_data = _next_frame
    _result.hit_id = _next_hit_id
    _result.pos_x = _next_attacker_pos[1]
    _result.pos_y = _next_attacker_pos[2]

    if _debug then
      print(string.format(" predicted frame %d: %d hitboxes, hit %d, at %d:%d", _result.frame, #_result.frame_data.boxes, _result.hit_id, _result.pos_x, _result.pos_y))
    end
  end
  return _result
end

function predict_hurtboxes(_player_obj, _frames_prediction)
  -- There don't seem to be a need for exact idle animation hurtboxes prediction, so let's return the current hurtboxes for the general case
  local _result = _player_obj.boxes

  -- If we wake up, we need to foresee the position of the hurtboxes in the frame data so we can block frame 1
  if _player_obj.is_wakingup then
    local _idle_startup_frame_data = frame_data[_player_obj.char_str].wakeup_to_idle
    local _idle_frame_data = frame_data[_player_obj.char_str].idle
    if _idle_startup_frame_data ~= nil and _idle_frame_data ~= nil then
      local _wakeup_frame = _frames_prediction - _player_obj.remaining_wakeup_time
      if _wakeup_frame >= 0 then
        if _wakeup_frame <= #_idle_startup_frame_data.frames then
          _result = _idle_startup_frame_data.frames[_wakeup_frame + 1].boxes
        else
          local _frame_index = ((_wakeup_frame - #_idle_startup_frame_data.frames) % #_idle_frame_data.frames) + 1
          _result = _idle_frame_data.frames[_frame_index].boxes
        end
      end
    end
  end
  return _result
end

function update_blocking(_input, _player, _dummy, _mode, _style, _red_parry_hit_count)

  local _debug = false

  -- ensure variables
  _dummy.blocking.blocked_hit_count = _dummy.blocking.blocked_hit_count or 0
  _dummy.blocking.expected_attack_animation_hit_frame = _dummy.blocking.expected_attack_animation_hit_frame or 0
  _dummy.blocking.expected_attack_hit_id = _dummy.blocking.expected_attack_hit_id or 0
  _dummy.blocking.last_attack_hit_id = _dummy.blocking.last_attack_hit_id or 0
  _dummy.blocking.is_bypassing_freeze_frames = _dummy.blocking.is_bypassing_freeze_frames or false
  _dummy.blocking.bypassed_freeze_frames = _dummy.blocking.bypassed_freeze_frames or 0

  function stop_listening_hits(_player_obj)
    _dummy.blocking.listening = false
    _dummy.blocking.should_block = false
  end

  function stop_listening_projectiles(_player_obj)
    if _dummy.blocking.listening_projectiles then
      log(_dummy.prefix, "blocking", "listening proj 0")
    end
    if _dummy.blocking.should_block_projectile then
      log(_dummy.prefix, "blocking", "block proj 0")
    end
    _dummy.blocking.listening_projectiles = false
    _dummy.blocking.should_block_projectile = false
    _dummy.blocking.expected_projectile = nil
  end

  function reset_parry_cooldowns(_player_obj)
    memory.writebyte(_player_obj.parry_forward_cooldown_time_addr, 0)
    memory.writebyte(_player_obj.parry_down_cooldown_time_addr, 0)
    memory.writebyte(_player_obj.parry_air_cooldown_time_addr, 0)
    memory.writebyte(_player_obj.parry_antiair_cooldown_time_addr, 0)
  end

  if not is_in_match then
    return
  end

  -- exit if playing recording
  if current_recording_state == 4 then
    stop_listening_hits(_dummy)
    stop_listening_projectiles(_dummy)
    return
  end

  if _dummy.is_idle then
    _dummy.blocking.blocked_hit_count = 0
  end

  -- blockstring detection
  if ((_dummy.blocking.should_block and not _dummy.blocking.randomized_out) or (_dummy.blocking.should_block_projectile and not _dummy.blocking.projectile_randomized_out)) and _dummy.blocking.wait_for_block_string then
    _dummy.blocking.block_string = true
    _dummy.blocking.wait_for_block_string = false
    log(_dummy.prefix, "block_string", string.format("blockstring 1"))
  end
  if _dummy.blocking.block_string then
    if _dummy.has_just_parried or _dummy.has_just_been_hit or (_dummy.remaining_freeze_frames == 0 and _dummy.recovery_time == 0 and _dummy.previous_recovery_time == 1 and not _dummy.blocking.should_block) then
      _dummy.blocking.block_string = false
      log(_dummy.prefix, "block_string", string.format("blockstring 0 (%d, %d, %d, %d, %d)", to_bit(_dummy.has_just_parried), to_bit(_dummy.has_just_been_hit), _dummy.blocking.last_attack_hit_id, _dummy.blocking.expected_attack_hit_id, _dummy.recovery_time))
    end
  elseif not _dummy.blocking.wait_for_block_string then
    if (
        _dummy.has_just_parried or 
        ((_dummy.blocking.expected_attack_hit_id == _dummy.blocking.last_attack_hit_id or not _dummy.blocking.listening) and _dummy.is_idle and _dummy.idle_time > 20)
       ) then
      _dummy.blocking.wait_for_block_string = true
      log(_dummy.prefix, "block_string", string.format("wait blockstring (%d, %d, %d)",  _dummy.blocking.expected_attack_hit_id, _dummy.blocking.last_attack_hit_id, _dummy.idle_time))
    end
  end

  if _dummy.blocking.is_bypassing_freeze_frames then
    _dummy.blocking.bypassed_freeze_frames = _dummy.blocking.bypassed_freeze_frames + 1
  end
  local _player_relevant_animation_frame = _player.relevant_animation_frame + _dummy.blocking.bypassed_freeze_frames

  -- new animation
  if _player.has_relevant_animation_just_changed then
    if (
      frame_data[_player.char_str] and
      frame_data[_player.char_str][_player.relevant_animation]
    ) then
      -- known animation, start listening
      _dummy.blocking.listening = true
      _dummy.blocking.expected_attack_animation_hit_frame = 0
      _dummy.blocking.expected_attack_hit_id = 0
      _dummy.blocking.last_attack_hit_id = 0
      if _dummy.blocking.is_bypassing_freeze_frames then
        log(_dummy.prefix, "blocking", string.format("bypassing end&reset"))
      end
      _dummy.blocking.is_bypassing_freeze_frames = false
      _dummy.blocking.bypassed_freeze_frames = 0
      _dummy.blocking.should_block = false
      reset_parry_cooldowns(_dummy)

      log(_dummy.prefix, "blocking", string.format("listening %s", _player.relevant_animation))
      if _debug then
        print(string.format("%d - %s listening for attack animation \"%s\" (starts at frame %d)", frame_number, _dummy.prefix, _player.relevant_animation, _player.relevant_animation_start_frame))
      end
    else
      -- unknown animation, stop listening
      if _dummy.blocking.listening then
        log(_dummy.prefix, "blocking", string.format("stopped listening"))
        if _debug then
          print(string.format("%d - %s stopped listening for attack animation", frame_number, _dummy.prefix))
        end
        stop_listening_hits(_dummy)
      end
    end
  end

  if _mode == 1 or _dummy.throw.listening == true then
    stop_listening_hits(_dummy)
    stop_listening_projectiles(_dummy)
    return
  end

  function get_meta_hit(_character_str, _move_id, _hit_id)
    local _character_meta = frame_data_meta[_character_str]
    if _character_meta == nil then return nil end
    if _character_meta.moves == nil then return nil end
    local _move_meta = _character_meta.moves[_player.relevant_animation]
    if _move_meta == nil then return nil end
    if _move_meta.hits == nil then return nil end
    if _move_meta.hits[_hit_id] == nil then return nil end
    return _move_meta.hits[_hit_id]
  end

  -- update blocked hit count
  if _dummy.has_just_blocked or _dummy.has_just_parried then
    _dummy.blocking.blocked_hit_count = _dummy.blocking.blocked_hit_count + 1
  end


  -- check if the hit we are expecting has expired or not
  local _hit_expired = false
  if _dummy.blocking.expected_attack_hit_id > 0 then
    local _frame_data = find_move_frame_data(_player.char_str, _player.relevant_animation)
    if _frame_data then
      local _hit_frame = _frame_data.hit_frames[_dummy.blocking.expected_attack_hit_id]
      local _last_hit_frame = 0
      if type(_hit_frame) == "number" then
        _last_hit_frame = _hit_frame
      else
        _last_hit_frame = _hit_frame.max
      end
      local _frame = frame_number - _player.current_animation_start_frame - _player.current_animation_freeze_frames
      _hit_expired = _frame > _last_hit_frame
    end
  end
  if _dummy.blocking.should_block_projectile and _dummy.blocking.projectile_hit_frame < frame_number then
    _hit_expired = true
  end

  -- increment hit id
  if _dummy.has_just_blocked or _dummy.has_just_parried or _dummy.has_just_been_hit or _hit_expired then
    log(_dummy.prefix, "blocking", string.format("next hit %d>%d %d", _dummy.blocking.last_attack_hit_id, _dummy.blocking.expected_attack_hit_id, to_bit(_hit_expired)))
    _dummy.blocking.last_attack_hit_id = _dummy.blocking.expected_attack_hit_id
    _dummy.blocking.expected_attack_hit_id = 0
    _dummy.blocking.should_block = false
    _dummy.blocking.should_block_projectile = false
    _dummy.blocking.expected_projectile = nil
    local _relevant_hit = get_meta_hit(_player.char_str, _player.relevant_animation, _player.last_attack_hit_id)
    if _relevant_hit and _player.remaining_freeze_frames > 0 and _relevant_hit.bypass_freeze then
      _dummy.blocking.is_bypassing_freeze_frames = true
      log(_dummy.prefix, "blocking", string.format("bypassing start"))
    elseif _dummy.blocking.is_bypassing_freeze_frames then
      _dummy.blocking.is_bypassing_freeze_frames = false
      log(_dummy.prefix, "blocking", string.format("bypassing end"))
    end
  elseif _dummy.blocking.last_attack_hit_id < _player.next_hit_id - 1 then
    local _next_hit = _player.next_hit_id - 1
    log(_dummy.prefix, "blocking", string.format("missed hit %d>%d", _dummy.blocking.last_attack_hit_id, _next_hit))
    _dummy.blocking.last_attack_hit_id = _next_hit
    _dummy.blocking.expected_attack_hit_id = 0
    _dummy.blocking.should_block = false
    reset_parry_cooldowns(_dummy)
  end

  if _dummy.blocking.listening then
    log(_player.prefix, "blocking", string.format("frame %d", _player_relevant_animation_frame))

    -- move has probably changed, therefore we reset hit id
    if _player.highest_hit_id == 0 and _dummy.blocking.last_attack_hit_id > 0 and _player.remaining_freeze_frames == 0 then
      log(_dummy.prefix, "blocking", string.format("reset hits"))
      if _debug then
        print(string.format("%d - reset last hit (%d, %d)", frame_number, _player.highest_hit_id, _dummy.blocking.last_attack_hit_id))
      end
      _dummy.blocking.last_attack_hit_id = 0
      _dummy.blocking.expected_attack_hit_id = 0
      if _dummy.blocking.is_bypassing_freeze_frames then
        log(_dummy.prefix, "blocking", string.format("bypassing end&reset"))
      end
      _dummy.blocking.is_bypassing_freeze_frames = false
      _dummy.blocking.bypassed_freeze_frames = 0
      _dummy.blocking.should_block = false
      reset_parry_cooldowns(_dummy)
    end

    --if (_dummy.blocking.expected_attack_animation_hit_frame < frame_number or _dummy.blocking.last_attack_hit_id == _dummy.blocking.expected_attack_hit_id) then
    if (_dummy.blocking.expected_attack_hit_id == 0 and not _dummy.blocking.should_block) then
      local _max_prediction_frames = 3
      for i = 1, _max_prediction_frames do
        local predicted_frame_id = i + _dummy.blocking.bypassed_freeze_frames
        local _predicted_hit = predict_hitboxes(_player, predicted_frame_id)
        if _predicted_hit.frame_data then
          local _frame_delta = _predicted_hit.frame - _player_relevant_animation_frame
          local _next_defender_pos = predict_object_position(_dummy, _frame_delta)

          --log(_dummy.prefix, "blocking", string.format("%d,%d", _predicted_hit.frame, _predicted_hit.hit_id))

          local _box_type_matches = {{{"vulnerability", "ext. vulnerability"}, {"attack"}}}
          if frame_data_meta[_player.char_str].moves[_player.relevant_animation] and frame_data_meta[_player.char_str].moves[_player.relevant_animation].hit_throw then
            table.insert(_box_type_matches, {{"throwable"}, {"throw"}})
          end

          -- Add dilation to attacker hit box
          local _meta_hit = get_meta_hit(_player.char_str, _player.relevant_animation, _predicted_hit.hit_id)
          local _attacker_box_dilation = 0
          if _meta_hit and _meta_hit.dilation then
            _attacker_box_dilation = _meta_hit.dilation
          end

          local _defender_boxes = predict_hurtboxes(_dummy, _frame_delta)

          if _predicted_hit.hit_id > _dummy.blocking.last_attack_hit_id and test_collision(
            _next_defender_pos[1], _next_defender_pos[2], _dummy.flip_x, _defender_boxes, -- defender
            _predicted_hit.pos_x, _predicted_hit.pos_y, _player.flip_x, _predicted_hit.frame_data.boxes, -- attacker
            _box_type_matches,
            0, -- defender hitbox dilation x
            4, -- defender hitbox dilation y
            _attacker_box_dilation, -- x
            _attacker_box_dilation -- y
          ) then
            _dummy.blocking.expected_attack_animation_hit_frame = _predicted_hit.frame
            _dummy.blocking.expected_attack_hit_id = _predicted_hit.hit_id
            _dummy.blocking.should_block = true
            _dummy.blocking.randomized_out = false
            _dummy.blocking.has_pre_parried = false
            _dummy.blocking.is_precise_timing = false
            log(_dummy.prefix, "blocking", string.format("block in %d", _dummy.blocking.expected_attack_animation_hit_frame - _player_relevant_animation_frame))

            if _mode == 3 then -- first hit
              if not _dummy.blocking.block_string and not _dummy.blocking.wait_for_block_string then
                _dummy.blocking.should_block = false
              end
            elseif _mode == 4 then -- random
              if not _dummy.blocking.block_string then
                local _r = math.random()
                if _r > 0.5 then
                  _dummy.blocking.randomized_out = true
                  if _debug then
                    print(string.format(" %d: next hit randomized out", frame_number))
                  end
                end
              end
            end

            if _debug then
              print(string.format(" %d: next hit %d at frame %d (%d), last hit %d", frame_number, _dummy.blocking.expected_attack_hit_id, _predicted_hit.frame, _dummy.blocking.expected_attack_animation_hit_frame, _dummy.blocking.last_attack_hit_id))
            end

            break
          end
        end
      end
    end
  end

  -- projectiles
  local _valid_projectiles = {}
  for _id, _projectile_obj in pairs(projectiles) do
    if (_projectile_obj.is_forced_one_hit and _projectile_obj.remaining_hits ~= 0xFF) or _projectile_obj.remaining_hits > 0 then
      if (not _projectile_obj.has_activated or #_projectile_obj.boxes > 0) and (_projectile_obj.emitter_id ~= _dummy.id or (_projectile_obj.emitter_id == _dummy.id and _projectile_obj.is_converted)) then
        table.insert(_valid_projectiles, _projectile_obj)
      end
    end
  end
  if #_valid_projectiles > 0 then
    if not _dummy.blocking.listening_projectiles then
      log(_dummy.prefix, "blocking", "listening proj 1")
    end
    _dummy.blocking.listening_projectiles = true
  else
    stop_listening_projectiles(_dummy)
  end

  if _dummy.blocking.listening_projectiles and not _dummy.blocking.should_block_projectile then
    local _max_prediction_frames = 3
    local _box_type_matches = {{{"vulnerability", "ext. vulnerability"}, {"attack"}}}
    for _i = 1, _max_prediction_frames do
      for _j, _projectile_obj in ipairs(_valid_projectiles) do
        local _frame_delta = _i - _projectile_obj.remaining_freeze_frames
        if _frame_delta >= 0 then
          local _next_defender_pos = predict_object_position(_dummy, _frame_delta)

          local _movement = nil
          local _lifetime = _projectile_obj.lifetime
          local _projectile_meta_data = frame_data_meta[_player.char_str].projectiles[_projectile_obj.projectile_start_type]
          if _projectile_meta_data ~= nil then
            _movement = _projectile_meta_data.movement
          end
          local _next_projectile_pos = predict_object_position(_projectile_obj, _frame_delta, _movement, _lifetime)

          local _projectile_boxes = _projectile_obj.boxes
          -- Look into the frame data for the first frame hitboxes
          local _projectile_frame_data = frame_data[_player.char_str][_projectile_obj.projectile_start_type]
          if _projectile_frame_data ~= nil and _projectile_obj.lifetime < _projectile_frame_data.start_lifetime then
            if (_projectile_obj.lifetime + _frame_delta) >= _projectile_frame_data.start_lifetime then
              _projectile_boxes = _projectile_frame_data.boxes
            end
          end

          local _defender_boxes = predict_hurtboxes(_dummy, _frame_delta)

          if test_collision(_next_defender_pos[1], _next_defender_pos[2], _dummy.flip_x, _defender_boxes,
          _next_projectile_pos[1] , _next_projectile_pos[2], _projectile_obj.flip_x, _projectile_boxes,
          _box_type_matches,
          0, -- defender hitbox dilation
          0, -- defender hitbox dilation
          0,
          0) then
            _dummy.blocking.should_block_projectile = true
            _dummy.blocking.projectile_randomized_out = false
            _dummy.blocking.has_pre_parried = false
            _dummy.blocking.projectile_hit_frame = frame_number + _i
            _dummy.blocking.expected_projectile = _projectile_obj
            _dummy.blocking.is_precise_timing = _movement ~= nil
            log(_dummy.prefix, "blocking", string.format("block proj %s in %d", _projectile_obj.id, _i))

            if _mode == 3 then -- first hit
              if not _dummy.blocking.block_string and not _dummy.blocking.wait_for_block_string then
                _dummy.blocking.should_block_projectile = false
              end
            elseif _mode == 4 then -- random
              if not _dummy.blocking.block_string then
                local _r = math.random()
                if _r > 0.5 then
                  _dummy.blocking.projectile_randomized_out = true
                  if _debug then
                    print(string.format(" %d: next hit randomized out", frame_number))
                  end
                end
              end
            end

            break
          end
        end
      end
      if _dummy.blocking.should_block_projectile then
        break
      end
    end
  end

  if (_dummy.blocking.should_block and not _dummy.blocking.randomized_out) or (_dummy.blocking.should_block_projectile and not _dummy.blocking.projectile_randomized_out) then
    local _hit_type = 1
    local _blocking_style = _style -- 1 is block, 2 is parry

    if _blocking_style == 3 then -- red parry
      if _dummy.blocking.blocked_hit_count ~= _red_parry_hit_count then
        _blocking_style = 1
      else
        _blocking_style = 2
      end
    end

    if _dummy.blocking.should_block then
      local _frame_data_meta = frame_data_meta[_player.char_str].moves[_player.relevant_animation]
      if _frame_data_meta and _frame_data_meta.hits and _frame_data_meta.hits[_dummy.blocking.expected_attack_hit_id] then
        _hit_type = _frame_data_meta.hits[_dummy.blocking.expected_attack_hit_id].type
      end
    elseif _dummy.blocking.should_block_projectile then
      local _frame_data_meta = frame_data_meta[_player.char_str].projectiles[_dummy.blocking.expected_projectile.projectile_type]
      if _frame_data_meta then
        _hit_type = _frame_data_meta.type
      end
    end

    local _animation_frame_delta = 0
    if _dummy.blocking.should_block_projectile then
      _animation_frame_delta = _dummy.blocking.projectile_hit_frame - frame_number
    else
      _animation_frame_delta = _dummy.blocking.expected_attack_animation_hit_frame - _player_relevant_animation_frame
    end

    if _blocking_style == 1 then
      local _blocking_delta_threshold = 2
      if _dummy.blocking.is_precise_timing then
        _blocking_delta_threshold = 1
      end
      if _animation_frame_delta <= _blocking_delta_threshold then
        log(_dummy.prefix, "blocking", string.format("dummy block %d %d %d", _dummy.blocking.expected_attack_hit_id, to_bit(_dummy.blocking.should_block_projectile), _animation_frame_delta))
        if _debug then
          print(string.format("%d - %s blocking", frame_number, _dummy.prefix))
        end

        if not _dummy.flip_input then
          _input[_dummy.prefix..' Right'] = true
          _input[_dummy.prefix..' Left'] = false
        else
          _input[_dummy.prefix..' Right'] = false
          _input[_dummy.prefix..' Left'] = true
        end

        if _hit_type == 2 then
          _input[_dummy.prefix..' Down'] = true
        elseif _hit_type == 3 then
          _input[_dummy.prefix..' Down'] = false
        end
      end
    elseif _blocking_style == 2 then
      _input[_dummy.prefix..' Right'] = false
      _input[_dummy.prefix..' Left'] = false
      _input[_dummy.prefix..' Down'] = false

      local _parry_low = _hit_type == 2

      if not _dummy.blocking.is_bypassing_freeze_frames then
        _animation_frame_delta = _animation_frame_delta + _player.remaining_freeze_frames
      end
      if (_animation_frame_delta == 1) or (_animation_frame_delta == 2 and _dummy.blocking.has_pre_parried) then
        log(_dummy.prefix, "blocking", string.format("parry %d", _dummy.blocking.expected_attack_hit_id))
        if _debug then
          print(string.format("%d - %s parrying", frame_number, _dummy.prefix))
        end

        if _parry_low then
          _input[_dummy.prefix..' Down'] = true
        else
          _input[_dummy.prefix..' Right'] = _dummy.flip_input
          _input[_dummy.prefix..' Left'] = not _dummy.flip_input
        end
      else
        _dummy.blocking.has_pre_parried = true
        log(_dummy.prefix, "blocking", string.format("pre parry %d", _dummy.blocking.expected_attack_hit_id))
      end
    end
  end
end

function update_fast_wake_up(_input, _player, _dummy, _mode)
  if is_in_match and _mode ~= 1 and current_recording_state ~= 4 then
    local _should_tap_down = _dummy.previous_can_fast_wakeup == 0 and _dummy.can_fast_wakeup == 1

    if _should_tap_down then
      local _r = math.random()
      if _mode ~= 3 or _r > 0.5 then
        _input[dummy.prefix..' Down'] = true
      end
    end
  end
end

function update_counter_attack(_input, _attacker, _defender, _stick, _button)

  local _debug = false

  if not is_in_match then return end
  if _stick == 1 and _button == 1 then return end
  if current_recording_state == 4 then return end

  function handle_recording()
    if button_gesture[_button] == "recording" and dummy.id == 2 then
      local _slot_index = training_settings.current_recording_slot
      if training_settings.replay_mode == 2 or training_settings.replay_mode == 4 then
        _slot_index = find_random_recording_slot()
      end
      if _slot_index < 0 then
        return
      end

      _defender.counter.recording_slot = _slot_index

      local _delay = recording_slots[_defender.counter.recording_slot].delay or 0
      local _random_deviation = recording_slots[_defender.counter.recording_slot].random_deviation or 0
      if _random_deviation <= 0 then
        _random_deviation = math.ceil(math.random(_random_deviation - 1, 0))
      else
        _random_deviation = math.floor(math.random(0, _random_deviation + 1))
      end
      if _debug then
        print(string.format("frame offset: %d", _delay + _random_deviation))
      end
      _defender.counter.attack_frame = _defender.counter.attack_frame + _delay + _random_deviation
    end
  end

  if _defender.has_just_parried then
    if _debug then
      print(frame_number.." - init ca (parry)")
    end
    log(_defender.prefix, "counter_attack", "init ca (parry)")
    _defender.counter.attack_frame = frame_number + 15
    _defender.counter.sequence = make_input_sequence(stick_gesture[_stick], button_gesture[_button])
    _defender.counter.ref_time = -1
    handle_recording()

  elseif _defender.has_just_been_hit or _defender.has_just_blocked then
    if _debug then
      print(frame_number.." - init ca (hit/block)")
    end
    log(_defender.prefix, "counter_attack", "init ca (hit/block)")
    _defender.counter.ref_time = _defender.recovery_time
    clear_input_sequence(_defender)
    _defender.counter.attack_frame = -1
    _defender.counter.sequence = nil
    _defender.counter.recording_slot = -1
  elseif _defender.has_just_started_wake_up or _defender.has_just_started_fast_wake_up then
    if _defender.remaining_wakeup_time == 0 then
      return
    end
    if _debug then
      print(frame_number.." - init ca (wake up)")
    end
    log(_defender.prefix, "counter_attack", "init ca (wakeup)")
    _defender.counter.attack_frame = frame_number + _defender.remaining_wakeup_time + 1 -- the +1 here means that there is an error somehere but I don't know where. the remaining wakeup time seems ok
    _defender.counter.sequence = make_input_sequence(stick_gesture[_stick], button_gesture[_button])
    _defender.counter.ref_time = -1
    handle_recording()
  elseif _defender.has_just_entered_air_recovery then
    clear_input_sequence(_defender)
    _defender.counter.ref_time = -1
    _defender.counter.attack_frame = frame_number + 100
    _defender.counter.sequence = make_input_sequence(stick_gesture[_stick], button_gesture[_button])
    _defender.counter.air_recovery = true
    handle_recording()
    log(_defender.prefix, "counter_attack", "init ca (air)")
  end

  if not _defender.counter.sequence then
    if _defender.counter.ref_time ~= -1 and _defender.recovery_time ~= _defender.counter.ref_time then
      if _debug then
        print(frame_number.." - setup ca")
      end
      log(_defender.prefix, "counter_attack", "setup ca")
      _defender.counter.attack_frame = frame_number + _defender.recovery_time + 2
      _defender.counter.sequence = make_input_sequence(stick_gesture[_stick], button_gesture[_button])
      _defender.counter.ref_time = -1
      handle_recording()
    end
  end


  if _defender.counter.sequence then
    if _defender.counter.air_recovery then
      local _frames_before_landing = predict_frames_before_landing(_defender)
      if _frames_before_landing >= 0 then
        _defender.counter.attack_frame = frame_number + _frames_before_landing + 2
      end
    end
    local _frames_remaining = _defender.counter.attack_frame - frame_number
    if _debug then
      print(_frames_remaining)
    end
    if _frames_remaining <= (#_defender.counter.sequence + 1) then
      if _debug then
        print(frame_number.." - queue ca")
      end
      log(_defender.prefix, "counter_attack", string.format("queue ca %d", _frames_remaining))
      queue_input_sequence(_defender, _defender.counter.sequence)
      _defender.counter.sequence = nil
      _defender.counter.attack_frame = -1
      _defender.counter.air_recovery = false
    end
  elseif button_gesture[_button] == "recording" and _defender.counter.recording_slot > 0 then
    if _defender.counter.attack_frame <= (frame_number + 1) then
      if training_settings.replay_mode == 2 or training_settings.replay_mode == 4 then
        override_replay_slot = _defender.counter.recording_slot
      end
      if _debug then
        print(frame_number.." - queue recording")
      end
      log(_defender.prefix, "counter_attack", "queue recording")
      _defender.counter.attack_frame = -1
      _defender.counter.recording_slot = -1
      _defender.counter.air_recovery = false
      set_recording_state(_input, 1)
      set_recording_state(_input, 4)
      override_replay_slot = -1
    end
  end
end

function update_tech_throws(_input, _attacker, _defender, _mode)
  local _debug = false

  if not is_in_match or _mode == 1 then
    _defender.throw.listening = false
    if _debug and _attacker.previous_throw_countdown > 0 then
      print(string.format("%d - %s stopped listening for throws", frame_number, _defender.prefix))
    end
    return
  end

  if _attacker.throw_countdown > _attacker.previous_throw_countdown then
    _defender.throw.listening = true
    if _debug then
      print(string.format("%d - %s listening for throws", frame_number, _defender.prefix))
    end
  end

  if _attacker.throw_countdown == 0 then
    _defender.throw.listening = false
    if _debug and _attacker.previous_throw_countdown > 0  then
      print(string.format("%d - %s stopped listening for throws", frame_number, _defender.prefix))
    end
  end

  if _defender.throw.listening then

    if test_collision(
      _defender.pos_x, _defender.pos_y, _defender.flip_x, _defender.boxes, -- defender
      _attacker.pos_x, _attacker.pos_y, _attacker.flip_x, _attacker.boxes, -- attacker
      {{{"throwable"},{"throw"}}},
      0, -- defender hitbox dilation
      0
    ) then
      _defender.throw.listening = false
      if _debug then
        print(string.format("%d - %s teching throw", frame_number, _defender.prefix))
      end
      local _r = math.random()
      if _mode ~= 3 or _r > 0.5 then
        _input[_defender.prefix..' Weak Punch'] = true
        _input[_defender.prefix..' Weak Kick'] = true
      end
    end
  end
end

-- RECORDING POPUPS

function clear_slot()
  recording_slots[training_settings.current_recording_slot].inputs = {}
  save_training_data()
end

function open_save_popup()
  save_recording_slot_popup.selected_index = 1
  menu_stack_push(save_recording_slot_popup)
  save_file_name = string.gsub(dummy.char_str, "(.*)", string.upper).."_"
end

function open_load_popup()
  load_recording_slot_popup.selected_index = 1
  menu_stack_push(load_recording_slot_popup)

  load_file_index = 1

  local _cmd = "dir /b "..string.gsub(saved_recordings_path, "/", "\\")
  local _f = io.popen(_cmd)
  if _f == nil then
    print(string.format("Error: Failed to execute command \"%s\"", _cmd))
    return
  end
  local _str = _f:read("*all")
  load_file_list = {}
  for _line in string.gmatch(_str, '([^\r\n]+)') do -- Split all lines that have ".json" in them
    if string.find(_line, ".json") ~= nil then
      local _file = _line
      table.insert(load_file_list, _file)
    end
  end
  load_recording_slot_popup.content[1].list = load_file_list
end

function save_recording_slot_to_file()
  if save_file_name == "" then
    print(string.format("Error: Can't save to empty file name"))
    return
  end

  local _path = string.format("%s%s.json",saved_recordings_path, save_file_name)
  if not write_object_to_json_file(recording_slots[training_settings.current_recording_slot].inputs, _path) then
    print(string.format("Error: Failed to save recording to \"%s\"", _path))
  else
    print(string.format("Saved slot %d to \"%s\"", training_settings.current_recording_slot, _path))
  end

  menu_stack_pop(save_recording_slot_popup)
end

function load_recording_slot_from_file()
  if #load_file_list == 0 or load_file_list[load_file_index] == nil then
    print(string.format("Error: Can't load from empty file name"))
    return
  end

  local _path = string.format("%s%s",saved_recordings_path, load_file_list[load_file_index])
  local _recording = read_object_from_json_file(_path)
  if not _recording then
    print(string.format("Error: Failed to load recording from \"%s\"", _path))
  else
    recording_slots[training_settings.current_recording_slot].inputs = _recording
    print(string.format("Loaded \"%s\" to slot %d", _path, training_settings.current_recording_slot))
  end
  save_training_data()

  menu_stack_pop(load_recording_slot_popup)
end

save_file_name = ""
save_recording_slot_popup = make_menu(71, 61, 312, 122, -- screen size 383,223
{
  textfield_menu_item("File Name", _G, "save_file_name", ""),
  button_menu_item("Save", save_recording_slot_to_file),
  button_menu_item("Cancel", function() menu_stack_pop(save_recording_slot_popup) end),
})

load_file_list = {}
load_file_index = 1
load_recording_slot_popup = make_menu(71, 61, 312, 122, -- screen size 383,223
{
  list_menu_item("File", _G, "load_file_index", load_file_list),
  button_menu_item("Load", load_recording_slot_from_file),
  button_menu_item("Cancel", function() menu_stack_pop(load_recording_slot_popup) end),
})

-- GUI DECLARATION

training_settings = {
  pose = 1,
  blocking_style = 1,
  blocking_mode = 1,
  tech_throws_mode = 1,
  red_parry_hit_count = 1,
  counter_attack_stick = 1,
  counter_attack_button = 1,
  fast_wakeup_mode = 1,
  infinite_time = true,
  life_mode = 1,
  meter_mode = 1,
  p1_meter = 0,
  p2_meter = 0,
  infinite_sa_time = false,
  stun_mode = 1,
  p1_stun_reset_value = 0,
  p2_stun_reset_value = 0,
  stun_reset_delay = 20,
  display_input = true,
  display_gauges = false,
  display_p1_input_history = false,
  display_p2_input_history = false,
  display_frame_advantage = false,
  display_hitboxes = false,
  auto_crop_recording = false,
  current_recording_slot = 1,
  replay_mode = 1,
  music_volume = 10,
  life_refill_delay = 20,
  meter_refill_delay = 20,

  -- special training
  special_training_current_mode = 1,
  special_training_follow_character = true,
  special_training_parry_forward_on = true,
  special_training_parry_down_on = true,
  special_training_parry_air_on = true,
  special_training_parry_antiair_on = true,
  special_training_charge_overcharge_on = false,
}

debug_settings = {
  show_predicted_hitbox = false,
  record_framedata = false,
  record_idle_framedata = false,
  record_wakeupdata = false,
  debug_character = "",
  debug_move = "",
}

life_refill_delay_item = integer_menu_item("Life refill delay", training_settings, "life_refill_delay", 1, 100, false, 20)
life_refill_delay_item.is_disabled = function()
  return training_settings.life_mode ~= 2
end

p1_stun_reset_value_gauge_item = gauge_menu_item("P1 Stun reset value", training_settings, "p1_stun_reset_value", 64, 0xFF0000FF)
p2_stun_reset_value_gauge_item = gauge_menu_item("P2 Stun reset value", training_settings, "p2_stun_reset_value", 64, 0xFF0000FF)
p1_stun_reset_value_gauge_item.unit = 1
p2_stun_reset_value_gauge_item.unit = 1
stun_reset_delay_item = integer_menu_item("Stun reset delay", training_settings, "stun_reset_delay", 1, 100, false, 20)
p1_stun_reset_value_gauge_item.is_disabled = function()
  return training_settings.stun_mode ~= 3
end
p2_stun_reset_value_gauge_item.is_disabled = p1_stun_reset_value_gauge_item.is_disabled
stun_reset_delay_item.is_disabled = p1_stun_reset_value_gauge_item.is_disabled

p1_meter_gauge_item = gauge_menu_item("P1 Meter", training_settings, "p1_meter", 2, 0x0000FFFF)
p2_meter_gauge_item = gauge_menu_item("P2 Meter", training_settings, "p2_meter", 2, 0x0000FFFF)
meter_refill_delay_item = integer_menu_item("Meter refill delay", training_settings, "meter_refill_delay", 1, 100, false, 20)

p1_meter_gauge_item.is_disabled = function()
  return training_settings.meter_mode ~= 2
end
p2_meter_gauge_item.is_disabled = p1_meter_gauge_item.is_disabled
meter_refill_delay_item.is_disabled = p1_meter_gauge_item.is_disabled

slot_weight_item = integer_menu_item("Weight", nil, "weight", 0, 100, false, 10)
counter_attack_delay_item = integer_menu_item("Counter-attack delay", nil, "delay", -40, 40, false, 0)
counter_attack_random_deviation_item = integer_menu_item("Counter-attack max random deviation", nil, "random_deviation", -600, 600, false, 0, 1)

parry_forward_on_item = checkbox_menu_item("Forward Parry Helper", training_settings, "special_training_parry_forward_on")
parry_forward_on_item.is_disabled = function() return training_settings.special_training_current_mode ~= 2 end
parry_down_on_item = checkbox_menu_item("Down Parry Helper", training_settings, "special_training_parry_down_on")
parry_down_on_item.is_disabled = parry_forward_on_item.is_disabled
parry_air_on_item = checkbox_menu_item("Air Parry Helper", training_settings, "special_training_parry_air_on")
parry_air_on_item.is_disabled = parry_forward_on_item.is_disabled
parry_antiair_on_item = checkbox_menu_item("Anti-Air Parry Helper", training_settings, "special_training_parry_antiair_on")
parry_antiair_on_item.is_disabled = parry_forward_on_item.is_disabled

charge_overcharge_on_item = checkbox_menu_item("Display Overcharge", training_settings, "special_training_charge_overcharge_on")
charge_overcharge_on_item.is_disabled = function() return training_settings.special_training_current_mode ~= 3 end

hits_before_red_parry_item = integer_menu_item("Hits before Red Parry", training_settings, "red_parry_hit_count", 1, 20, true)
hits_before_red_parry_item.is_disabled = function()
  return training_settings.blocking_style ~= 3
end

main_menu = make_multitab_menu(
  23, 15, 360, 195, -- screen size 383,223
  {
    {
      name = "Dummy",
      entries = {
        list_menu_item("Pose", training_settings, "pose", pose),
        list_menu_item("Blocking Style", training_settings, "blocking_style", blocking_style),
        hits_before_red_parry_item,
        list_menu_item("Blocking", training_settings, "blocking_mode", blocking_mode),
        list_menu_item("Tech Throws", training_settings, "tech_throws_mode", tech_throws_mode),
        list_menu_item("Counter-Attack Move", training_settings, "counter_attack_stick", stick_gesture),
        list_menu_item("Counter-Attack Action", training_settings, "counter_attack_button", button_gesture),
        list_menu_item("Fast Wake Up", training_settings, "fast_wakeup_mode", fast_wakeup_mode),
      }
    },
    {
      name = "Rules",
      entries = {
        checkbox_menu_item("Infinite Time", training_settings, "infinite_time"),
        list_menu_item("Life Refill Mode", training_settings, "life_mode", life_mode),
        life_refill_delay_item,
        list_menu_item("Stun Mode", training_settings, "stun_mode", stun_mode),
        p1_stun_reset_value_gauge_item,
        p2_stun_reset_value_gauge_item,
        stun_reset_delay_item,
        list_menu_item("Meter Refill Mode", training_settings, "meter_mode", meter_mode),
        p1_meter_gauge_item,
        p2_meter_gauge_item,
        meter_refill_delay_item,
        checkbox_menu_item("Infinite Super Art Time", training_settings, "infinite_sa_time"),
      }
    },
    {
      name = "Recording",
      entries = {
        checkbox_menu_item("Auto Crop First Frames", training_settings, "auto_crop_recording"),
        list_menu_item("Replay Mode", training_settings, "replay_mode", slot_replay_mode),
        list_menu_item("Slot", training_settings, "current_recording_slot", recording_slots_names),
        slot_weight_item,
        counter_attack_delay_item,
        counter_attack_random_deviation_item,
        button_menu_item("Clear slot", clear_slot),
        button_menu_item("Save slot to file", open_save_popup),
        button_menu_item("Load slot from file", open_load_popup),
      }
    },
    {
      name = "Display",
      entries = {
        checkbox_menu_item("Display Controllers", training_settings, "display_input"),
        checkbox_menu_item("Display Gauges Numbers", training_settings, "display_gauges"),
        checkbox_menu_item("Display P1 Input History", training_settings, "display_p1_input_history"),
        checkbox_menu_item("Display P2 Input History", training_settings, "display_p2_input_history"),
        checkbox_menu_item("Display Frame Advantage", training_settings, "display_frame_advantage"),
        checkbox_menu_item("Display Hitboxes", training_settings, "display_hitboxes"),
        integer_menu_item("Music Volume", training_settings, "music_volume", 0, 10, false, 10),
      }
    },
    {
      name = "Special Training",
      entries = {
        list_menu_item("Mode", training_settings, "special_training_current_mode", special_training_mode),
        checkbox_menu_item("Follow Character", training_settings, "special_training_follow_character"),
        parry_forward_on_item,
        parry_down_on_item,
        parry_air_on_item,
        parry_antiair_on_item,
        charge_overcharge_on_item
      }
    },
  },
  function ()
    save_training_data()
  end,
  function(_menu)
    -- recording slots special display
    if _menu.main_menu_selected_index == 3 then
      local _t = string.format("%d frames", #recording_slots[training_settings.current_recording_slot].inputs)
      gui.text(_menu.left + 83, _menu.top + 23 + 2 * menu_y_interval, _t, text_disabled_color, text_default_border_color)
    end
  end
)

debug_move_menu_item = map_menu_item("Debug Move", debug_settings, "debug_move", frame_data, nil)
if developer_mode then
  local _debug_settings_menu = {
    name = "Debug",
    entries = {
      checkbox_menu_item("Show Predicted Hitboxes", debug_settings, "show_predicted_hitbox"),
      checkbox_menu_item("Record Frame Data", debug_settings, "record_framedata"),
      checkbox_menu_item("Record Idle Frame Data", debug_settings, "record_idle_framedata"),
      checkbox_menu_item("Record Wake-Up Data", debug_settings, "record_wakeupdata"),
      button_menu_item("Save Frame Data", save_frame_data),
      map_menu_item("Debug Character", debug_settings, "debug_character", _G, "frame_data"),
      debug_move_menu_item
    }
  }
  table.insert(main_menu.content, _debug_settings_menu)
end

-- RECORDING
swap_characters = false
-- 1: Default Mode, 2: Wait for recording, 3: Recording, 4: Replaying
current_recording_state = 1
last_coin_input_frame = -1
override_replay_slot = -1
recording_states =
{
  "none",
  "waiting",
  "recording",
  "playing",
}

function stick_input_to_sequence_input(_player_obj, _input)
  if _input == "Up" then return "up" end
  if _input == "Down" then return "down" end
  if _input == "Weak Punch" then return "LP" end
  if _input == "Medium Punch" then return "MP" end
  if _input == "Strong Punch" then return "HP" end
  if _input == "Weak Kick" then return "LK" end
  if _input == "Medium Kick" then return "MK" end
  if _input == "Strong Kick" then return "HK" end

  if _input == "Left" then
    if _player_obj.flip_input then
      return "back"
    else
      return "forward"
    end
  end

  if _input == "Right" then
    if _player_obj.flip_input then
      return "forward"
    else
      return "back"
    end
  end
  return ""
end

function can_play_recording()
  if training_settings.replay_mode == 2 or training_settings.replay_mode == 4 then
    for _i, _value in ipairs(recording_slots) do
      if #_value.inputs > 0 then
        return true
      end
    end
  else
    return recording_slots[training_settings.current_recording_slot].inputs ~= nil and #recording_slots[training_settings.current_recording_slot].inputs > 0
  end
  return false
end

function find_random_recording_slot()
  -- random slot selection
  local _recorded_slots = {}
  for _i, _value in ipairs(recording_slots) do
    if _value.inputs and #_value.inputs > 0 then
      table.insert(_recorded_slots, _i)
    end
  end

  if #_recorded_slots > 0 then
    local _total_weight = 0
    for _i, _value in pairs(_recorded_slots) do
      _total_weight = _total_weight + recording_slots[_value].weight
    end

    local _random_slot_weight = 0
    if _total_weight > 0 then
      _random_slot_weight = math.ceil(math.random(_total_weight))
    end
    local _random_slot = 1
    local _weight_i = 0
    for _i, _value in ipairs(_recorded_slots) do
      if _weight_i <= _random_slot_weight and _weight_i + recording_slots[_value].weight >= _random_slot_weight then
        _random_slot = _i
        break
      end
      _weight_i = _weight_i + recording_slots[_value].weight
    end
    return _recorded_slots[_random_slot]
  end
  return -1
end

function set_recording_state(_input, _state)
  if (_state == current_recording_state) then
    return
  end

  -- exit states
  if current_recording_state == 1 then
  elseif current_recording_state == 2 then
    swap_characters = false
  elseif current_recording_state == 3 then

    if training_settings.auto_crop_recording then
      local _first_input = 1
      local _last_input = 1
      for _i, _value in ipairs(recording_slots[training_settings.current_recording_slot].inputs) do
        if #_value > 0 then
          _last_input = _i
        elseif _first_input == _i then
          _first_input = _first_input + 1
        end
      end

      -- cropping end of animation is actually not a good idea if we want to repeat sequences
      _last_input = #recording_slots[training_settings.current_recording_slot].inputs

      local _cropped_sequence = {}
      for _i = _first_input, _last_input do
        table.insert(_cropped_sequence, recording_slots[training_settings.current_recording_slot].inputs[_i])
      end
      recording_slots[training_settings.current_recording_slot].inputs = _cropped_sequence
    end

    save_training_data()

    swap_characters = false
  elseif current_recording_state == 4 then
    clear_input_sequence(dummy)
  end

  current_recording_state = _state

  -- enter states
  if current_recording_state == 1 then
  elseif current_recording_state == 2 then
    swap_characters = true
    make_input_empty(_input)
  elseif current_recording_state == 3 then
    swap_characters = true
    make_input_empty(_input)
    recording_slots[training_settings.current_recording_slot].inputs = {}
  elseif current_recording_state == 4 then
    local _replay_slot = -1
    if override_replay_slot > 0 then
      _replay_slot = override_replay_slot
    else
      if training_settings.replay_mode == 2 or training_settings.replay_mode == 4 then
        _replay_slot = find_random_recording_slot()
      else
        _replay_slot = training_settings.current_recording_slot
      end
    end

    if _replay_slot > 0 then
      queue_input_sequence(dummy, recording_slots[_replay_slot].inputs)
    end
  end
end

function update_recording(_input)

  local _input_buffer_length = 11
  if is_in_match and not is_menu_open then

    -- manage input
    local _input_pressed = (not swap_characters and player.input.pressed.coin) or (swap_characters and dummy.input.pressed.coin)
    if _input_pressed then
      if frame_number < (last_coin_input_frame + _input_buffer_length) then
        last_coin_input_frame = -1

        -- double tap
        if current_recording_state == 2 or current_recording_state == 3 then
          set_recording_state(_input, 1)
        else
          set_recording_state(_input, 2)
        end

      else
        last_coin_input_frame = frame_number
      end
    end

    if last_coin_input_frame > 0 and frame_number >= last_coin_input_frame + _input_buffer_length then
      last_coin_input_frame = -1

      -- single tap
      if current_recording_state == 1 then
        if can_play_recording() then
          set_recording_state(_input, 4)
        end
      elseif current_recording_state == 2 then
        set_recording_state(_input, 3)
      elseif current_recording_state == 3 then
        set_recording_state(_input, 1)
      elseif current_recording_state == 4 then
        set_recording_state(_input, 1)
      end

    end

    -- tick states
    if current_recording_state == 1 then
    elseif current_recording_state == 2 then
    elseif current_recording_state == 3 then
      local _frame = {}

      for _key, _value in pairs(_input) do
        local _prefix = _key:sub(1, #player.prefix)
        if (_prefix == player.prefix) then
          local _input_name = _key:sub(1 + #player.prefix + 1)
          if (_input_name ~= "Coin" and _input_name ~= "Start") then
            if (_value) then
              local _sequence_input_name = stick_input_to_sequence_input(player, _input_name)
              --print(_input_name.." ".._sequence_input_name)
              table.insert(_frame, _sequence_input_name)
            end
          end
        end
      end

      table.insert(recording_slots[training_settings.current_recording_slot].inputs, _frame)
    elseif current_recording_state == 4 then
      if dummy.pending_input_sequence == nil then
        set_recording_state(_input, 1)
        if can_play_recording() and (training_settings.replay_mode == 3 or training_settings.replay_mode == 4) then
          set_recording_state(_input, 4)
        end
      end
    end
  end

  previous_recording_state = current_recording_state
end

-- PROGRAM

P1.debug_state_variables = false
P1.debug_freeze_frames = false
P1.debug_animation_frames = false
P1.debug_standing_state = false
P1.debug_wake_up = false

P2.debug_state_variables = false
P2.debug_freeze_frames = false
P2.debug_animation_frames = false
P2.debug_standing_state = false
P2.debug_wake_up = false

function write_player_vars(_player_obj)

  -- P1: 0x02068C6C
  -- P2: 0x02069104

  local _wanted_meter = 0
  if _player_obj.id == 1 then
    _wanted_meter = training_settings.p1_meter
  elseif _player_obj.id == 2 then
    _wanted_meter = training_settings.p2_meter
  end

  -- LIFE
  if is_in_match and not is_menu_open then
    local _life = memory.readbyte(_player_obj.base + 0x9F)
    if training_settings.life_mode == 2 then
      if _player_obj.is_idle and _player_obj.idle_time > training_settings.life_refill_delay then
        local _refill_rate = 6
        _life = math.min(_life + _refill_rate, 160)
      end
    elseif training_settings.life_mode == 3 then
      _life = 160
    end
    memory.writebyte(_player_obj.base + 0x9F, _life)
    _player_obj.life = _life
  end

  -- METER
  if is_in_match and not is_menu_open and not _player_obj.is_in_timed_sa then
    -- If the SA is a timed SA, the gauge won't go back to 0 when it reaches max. We have to make special cases for it
    local _is_timed_sa = character_specific[_player_obj.char_str].timed_sa[_player_obj.selected_sa]

    if training_settings.meter_mode == 3 then
      local _previous_meter_count = memory.readbyte(_player_obj.meter_addr[2])
      local _previous_meter_count_slave = memory.readbyte(_player_obj.meter_addr[1])
      if _previous_meter_count ~= _player_obj.max_meter_count and _previous_meter_count_slave ~= _player_obj.max_meter_count then
        local _gauge_value = 0
        if _is_timed_sa then
          _gauge_value = _player_obj.max_meter_gauge
        end
        memory.writebyte(_player_obj.gauge_addr, _gauge_value)
        memory.writebyte(_player_obj.meter_addr[2], _player_obj.max_meter_count)
        memory.writebyte(_player_obj.meter_update_flag, 0x01)
      end
    elseif training_settings.meter_mode == 2 then
      if _player_obj.is_idle and _player_obj.idle_time > training_settings.meter_refill_delay then
        local _previous_gauge = memory.readbyte(_player_obj.gauge_addr)
        local _previous_meter_count = memory.readbyte(_player_obj.meter_addr[2])
        local _previous_meter_count_slave = memory.readbyte(_player_obj.meter_addr[1])

        if _previous_meter_count == _previous_meter_count_slave then
          local _meter = 0
          -- If the SA is a timed SA, the gauge won't go back to 0 when it reaches max
          if _is_timed_sa then
            _meter = _previous_gauge
          else
             _meter = _previous_gauge + _player_obj.max_meter_gauge * _previous_meter_count
          end

          if _meter > _wanted_meter then
            _meter = _meter - 6
            _meter = math.max(_meter, _wanted_meter)
          elseif _meter < _wanted_meter then
            _meter = _meter + 6
            _meter = math.min(_meter, _wanted_meter)
          end

          local _wanted_gauge = _meter % _player_obj.max_meter_gauge
          local _wanted_meter_count = math.floor(_meter / _player_obj.max_meter_gauge)
          local _previous_meter_count = memory.readbyte(_player_obj.meter_addr[2])
          local _previous_meter_count_slave = memory.readbyte(_player_obj.meter_addr[1])

          if character_specific[_player_obj.char_str].timed_sa[_player_obj.selected_sa] and _wanted_meter_count == 1 and _wanted_gauge == 0 then
            _wanted_gauge = _player_obj.max_meter_gauge
          end

          --if _player_obj.id == 1 then
          --  print(string.format("%d: %d/%d/%d (%d/%d)", _wanted_meter, _wanted_gauge, _wanted_meter_count, _player_obj.max_meter_gauge, _previous_gauge, _previous_meter_count))
          --end

          if _wanted_gauge ~= _previous_gauge then
            memory.writebyte(_player_obj.gauge_addr, _wanted_gauge)
          end
          if _previous_meter_count ~= _wanted_meter_count then
            memory.writebyte(_player_obj.meter_addr[2], _wanted_meter_count)
            memory.writebyte(_player_obj.meter_update_flag, 0x01)
          end
        end
      end
    end
  end

  if training_settings.infinite_sa_time and _player_obj.is_in_timed_sa then
    memory.writebyte(_player_obj.gauge_addr, _player_obj.max_meter_gauge)
  end

  -- STUN
  if training_settings.stun_mode == 2 then
    memory.writebyte(_player_obj.stun_timer_addr, 0);
    memory.writedword(_player_obj.stun_bar_addr, 0);
  elseif training_settings.stun_mode == 3 then
    if is_in_match and not is_menu_open and _player_obj.is_idle then
      local _wanted_stun = 0
      if _player_obj.id == 1 then
        _wanted_stun = training_settings.p1_stun_reset_value
      else
        _wanted_stun = training_settings.p2_stun_reset_value
      end
      _wanted_stun = math.max(_wanted_stun, 0)

      if _player_obj.stun_bar < _wanted_stun then
        memory.writedword(_player_obj.stun_bar_addr, bit.lshift(_wanted_stun, 24));
      elseif _player_obj.is_idle and _player_obj.idle_time > training_settings.stun_reset_delay then
        local _stun = _player_obj.stun_bar
        _stun = math.max(_stun - 1, _wanted_stun)
        memory.writedword(_player_obj.stun_bar_addr, bit.lshift(_stun, 24));
      end
    end
  end
end

function on_load_state()
  reset_player_objects()
  read_player_vars(player_objects[1])
  read_player_vars(player_objects[2])

  frame_advantage_reset()

  -- reset recording states in a useful way
  if current_recording_state == 3 then
    set_recording_state({}, 2)
  elseif current_recording_state == 4 and (training_settings.replay_mode == 3 or training_settings.replay_mode == 4) then
    set_recording_state({}, 1)
    set_recording_state({}, 4)
  end

  clear_input_history()
  clear_printed_geometry()
end

function on_start()
  load_training_data()
  load_frame_data()
end

function before_frame()

  -- update debug menu
  if debug_settings.debug_character ~= debug_move_menu_item.map_property then
    debug_move_menu_item.map_object = frame_data
    debug_move_menu_item.map_property = debug_settings.debug_character
    debug_settings.debug_move = ""
  end

  slot_weight_item.object = recording_slots[training_settings.current_recording_slot]
  counter_attack_delay_item.object = recording_slots[training_settings.current_recording_slot]
  counter_attack_random_deviation_item.object = recording_slots[training_settings.current_recording_slot]

  display_update()

  -- gamestate
  local _previous_dummy_char_str = player_objects[2].char_str or ""
  gamestate_read()

  -- load recordings according to P2 character
  if _previous_dummy_char_str ~= player_objects[2].char_str then
    restore_recordings()
  end

  -- cap training settings
  if is_in_match then
    training_settings.p1_meter = math.min(training_settings.p1_meter, player_objects[1].max_meter_count * player_objects[1].max_meter_gauge)
    training_settings.p2_meter = math.min(training_settings.p2_meter, player_objects[2].max_meter_count * player_objects[2].max_meter_gauge)
    p1_meter_gauge_item.gauge_max = player_objects[1].max_meter_gauge * player_objects[1].max_meter_count
    p1_meter_gauge_item.subdivision_count = player_objects[1].max_meter_count
    p2_meter_gauge_item.gauge_max = player_objects[2].max_meter_gauge * player_objects[2].max_meter_count
    p2_meter_gauge_item.subdivision_count = player_objects[2].max_meter_count
    training_settings.p1_stun_reset_value = math.min(training_settings.p1_stun_reset_value, player_objects[1].stun_max)
    training_settings.p2_stun_reset_value = math.min(training_settings.p2_stun_reset_value, player_objects[2].stun_max)
    p1_stun_reset_value_gauge_item.gauge_max = player_objects[1].stun_max
    p2_stun_reset_value_gauge_item.gauge_max = player_objects[2].stun_max
  end

  local _write_game_vars_settings = 
  {
    freeze = is_menu_open,
    infinite_time = training_settings.infinite_time,
    music_volume = training_settings.music_volume,
  }
  write_game_vars(_write_game_vars_settings)

  write_player_vars(player_objects[1])
  write_player_vars(player_objects[2])

  -- input
  local _input = joypad.get()
  if is_in_match and not is_menu_open and swap_characters then
    swap_inputs(_input)
  end

  if not swap_characters then
    player = player_objects[1]
    dummy = player_objects[2]
  else
    player = player_objects[2]
    dummy = player_objects[1]
  end

  -- frame advantage
  frame_advantage_update(player, dummy)

  -- Can't do this inside read_player_vars cause we need both players to have read their stuff
  if dummy.has_just_started_wake_up or dummy.has_just_started_fast_wake_up then
    dummy.wakeup_other_last_act_animation = player.last_act_animation
    dummy.remaining_wakeup_time = find_wake_up(dummy.char_str, dummy.wakeup_animation, dummy.wakeup_other_last_act_animation) or 0
  end
  if dummy.remaining_wakeup_time ~= nil then
    dummy.remaining_wakeup_time = math.max(dummy.remaining_wakeup_time - 1, 0)
  end

  -- pose
  update_pose(_input, dummy, training_settings.pose)

  -- blocking
  update_blocking(_input, player, dummy, training_settings.blocking_mode, training_settings.blocking_style, training_settings.red_parry_hit_count)

  -- fast wake-up
  update_fast_wake_up(_input, player, dummy, training_settings.fast_wakeup_mode)

  -- tech throws
  update_tech_throws(_input, player, dummy, training_settings.tech_throws_mode)

  -- counter attack
  update_counter_attack(_input, player, dummy, training_settings.counter_attack_stick, training_settings.counter_attack_button)

  -- recording
  update_recording(_input)

  process_pending_input_sequence(player_objects[1], _input)
  process_pending_input_sequence(player_objects[2], _input)

  if is_in_match then
    input_history_update(input_history[1], "P1", _input)
    input_history_update(input_history[2], "P2", _input)
  else
    clear_input_history()
    frame_advantage_reset()
  end

  -- Log input
  if previous_input then
    function log_input(_player_object, _name, _short_name)
      _short_name = _short_name or _name
      local _full_name = _player_object.prefix.." ".._name
      if not previous_input[_full_name] and _input[_full_name] then
        log(_player_object.prefix, "input", _short_name.." 1")
      elseif previous_input[_full_name] and not _input[_full_name] then
        log(_player_object.prefix, "input", _short_name.." 0")
      end
    end

    for _i, _o in ipairs(player_objects) do
      log_input(_o, "Left")
      log_input(_o, "Right")
      log_input(_o, "Up")
      log_input(_o, "Down")
      log_input(_o, "Weak Punch", "LP")
      log_input(_o, "Medium Punch", "MP")
      log_input(_o, "Strong Punch", "HP")
      log_input(_o, "Weak Kick", "LK")
      log_input(_o, "Medium Kick", "MK")
      log_input(_o, "Strong Kick", "HK")
    end
  end
  previous_input = _input

  joypad.set(_input)

  update_framedata_recording(player_objects[1], projectiles)
  update_idle_framedata_recording(player_objects[2])
  update_projectiles_recording(projectiles)
  update_wakeupdata_recording(player_objects[2])

  local _debug_position_prediction = false
  if _debug_position_prediction and player.pos_y > 0 then
    local _px, _py = game_to_screen_space(player.pos_x, player.pos_y)
    print_point(_px, _py, 0x00FFFFFF)
    local _prediction = predict_object_position(player, 2)
    _px, _py = game_to_screen_space(_prediction[1], _prediction[2])
    print_point(_px, _py, 0xFF0000FF)
  end

  if _debug_position_prediction then
    for _id, _obj in pairs(projectiles) do
      if #_obj.pos_samples > 1 then
        local _x = _obj.pos_samples[#_obj.pos_samples].x - _obj.pos_samples[#_obj.pos_samples - 1].x
        local _y = _obj.pos_samples[#_obj.pos_samples].y - _obj.pos_samples[#_obj.pos_samples - 1].y
        print(string.format("x: %d, y: %d", _x, _y))
      end

      local _px, _py = game_to_screen_space(_obj.pos_x, _obj.pos_y)
      print_point(_px, _py, 0x00FFFFFF)

      local _movement = nil
      local _lifetime = _obj.lifetime
      local _projectile_meta_data = frame_data_meta[player_objects[_obj.emitter_id].char_str].projectiles[_obj.projectile_type]
      if _projectile_meta_data ~= nil then
        _movement = _projectile_meta_data.movement
      end
      local _prediction = predict_object_position(_obj, 4, _movement, _lifetime)
      _px, _py = game_to_screen_space(_prediction[1], _prediction[2])
      print_point(_px, _py, 0xFF0000FF)
    end
  end

  log_update()
end

is_menu_open = false

function on_gui()

  if P1.input.pressed.start then
    clear_printed_geometry()
  end

  if is_in_match then

    display_draw_printed_geometry()

    if training_settings.display_gauges then
      display_draw_life(player_objects[1])
      display_draw_life(player_objects[2])

      display_draw_meter(player_objects[1])
      display_draw_meter(player_objects[2])

      display_draw_stun_gauge(player_objects[1])
      display_draw_stun_gauge(player_objects[2])

      display_draw_bonuses(player_objects[1])
      display_draw_bonuses(player_objects[2])
    end

    -- hitboxes
    if training_settings.display_hitboxes then
      display_draw_hitboxes()
    end

    -- input history
    if training_settings.display_p1_input_history then input_history_draw(input_history[1], 4, 49, false) end
    if training_settings.display_p2_input_history then input_history_draw(input_history[2], screen_width - 4, 49, true) end

    -- controllers
    if training_settings.display_input then
      local _i = joypad.get()
      local _p1 = make_input_history_entry("P1", _i)
      local _p2 = make_input_history_entry("P2", _i)
      draw_controller_big(_p1, 44, 34)
      draw_controller_big(_p2, 310, 34)
    end

    -- move advantage
    if training_settings.display_frame_advantage then
      frame_advantage_display()
    end

    -- debug
    --  predicted hitboxes
    if debug_settings.show_predicted_hitbox then
      local _predicted_hit = predict_hitboxes(player, 2)
      if _predicted_hit.frame_data then
        draw_hitboxes(_predicted_hit.pos_x, _predicted_hit.pos_y, player.flip_x, _predicted_hit.frame_data.boxes)
      end
    end

    --  move hitboxes
    local _debug_frame_data = frame_data[debug_settings.debug_character]
    if _debug_frame_data then
      local _debug_move = _debug_frame_data[debug_settings.debug_move]
      if _debug_move and _debug_move.frames then
        local _move_frame = frame_number % #_debug_move.frames

        local _debug_pos_x = player.pos_x
        local _debug_pos_y = player.pos_y
        local _debug_flip_x = player.flip_x

        local _sign = 1
        if _debug_flip_x ~= 0 then _sign = -1 end
        for i = 1, _move_frame + 1 do
          _debug_pos_x = _debug_pos_x + _debug_move.frames[i].movement[1] * _sign
          _debug_pos_y = _debug_pos_y + _debug_move.frames[i].movement[2]
        end

        draw_hitboxes(_debug_pos_x, _debug_pos_y, _debug_flip_x, _debug_move.frames[_move_frame + 1].boxes)
      end
    end
  end

  if is_in_match and special_training_mode[training_settings.special_training_current_mode] == "parry" then

    local _player = P1
    local _x = 235 --96
    local _y = 40
    local _flip_gauge = false
    local _gauge_x_scale = 4

    if training_settings.special_training_follow_character then
      local _px = _player.pos_x - screen_x + emu.screenwidth()/2
      local _py = emu.screenheight() - (_player.pos_y - screen_y) - ground_offset
      local _half_width = 23 * _gauge_x_scale * 0.5
      _x = _px - _half_width
      _x = math.max(_x, 4)
      _x = math.min(_x, emu.screenwidth() - (_half_width * 2.0 + 14))
      _y = _py - 100
    end

    local _y_offset = 0
    local _group_y_margin = 6

    function draw_parry_gauge_group(_x, _y, _parry_object)
      local _gauge_height = 4
      --local _gauge_background_color = 0x101008FF
      local _gauge_background_color = 0xD6E7EF77
      local _gauge_valid_fill_color = 0x08CF00FF
      local _gauge_cooldown_fill_color = 0xFF7939FF
      local _success_color = 0x10FB00FF
      local _miss_color = 0xE70000FF

      local _validity_gauge_width = _parry_object.max_validity * _gauge_x_scale
      local _cooldown_gauge_width = _parry_object.max_cooldown * _gauge_x_scale
      local _validity_gauge_left = math.floor(_x + (_cooldown_gauge_width - _validity_gauge_width) * 0.5)
      local _validity_gauge_right = _validity_gauge_left + _validity_gauge_width + 1
      local _cooldown_gauge_left = _x
      local _cooldown_gauge_right = _cooldown_gauge_left + _cooldown_gauge_width + 1
      local _validity_time_text = string.format("%d", _parry_object.validity_time)
      local _cooldown_time_text = string.format("%d", _parry_object.cooldown_time)
      local _validity_text_color = text_default_color
      local _validity_outline_color = text_default_border_color
      if _parry_object.delta then
        if _parry_object.success then
          _validity_text_color = _success_color
          _validity_outline_color = 0x00A200FF
        else
          _validity_text_color = _miss_color
          _validity_outline_color = 0x840000FF
        end
        if _parry_object.delta >= 0 then
          _validity_time_text = string.format("%d", -_parry_object.delta)
        else
          _validity_time_text = string.format("+%d", -_parry_object.delta)
        end
      end

      gui.text(_x + 1, _y, _parry_object.name, text_default_color, text_default_border_color)
      gui.box(_cooldown_gauge_left + 1, _y + 11, _validity_gauge_left, _y + 11, 0x00000000, 0xFFFFFF77)
      gui.box(_cooldown_gauge_left, _y + 10, _cooldown_gauge_left, _y + 12, 0x00000000, 0xFFFFFF77)
      gui.box(_validity_gauge_right, _y + 11, _cooldown_gauge_right - 1, _y + 11, 0x00000000, 0xFFFFFF77)
      gui.box(_cooldown_gauge_right, _y + 10, _cooldown_gauge_right, _y + 12, 0x00000000, 0xFFFFFF77)
      draw_gauge(_validity_gauge_left, _y + 8, _validity_gauge_width, _gauge_height + 1, _parry_object.validity_time / _parry_object.max_validity, _gauge_valid_fill_color, _gauge_background_color, nil, true)
      draw_gauge(_cooldown_gauge_left, _y + 8 + _gauge_height + 2, _cooldown_gauge_width, _gauge_height, _parry_object.cooldown_time / _parry_object.max_cooldown, _gauge_cooldown_fill_color, _gauge_background_color, nil, true)

      gui.box(_validity_gauge_left + 3 * _gauge_x_scale, _y + 8, _validity_gauge_left + 2 + 3 * _gauge_x_scale,  _y + 8 + _gauge_height + 2, 0xFF000077, 0x00000000)

      if _parry_object.delta then
        local _marker_x = _validity_gauge_left + _parry_object.delta * _gauge_x_scale
        _marker_x = math.min(math.max(_marker_x, _x), _cooldown_gauge_right)
        gui.box(_marker_x, _y + 7, _marker_x + _gauge_x_scale, _y + 8 + _gauge_height + 2, _validity_text_color, _validity_outline_color)
      end

      gui.text(_cooldown_gauge_right + 4, _y + 7, _validity_time_text, _validity_text_color, text_default_border_color)
      gui.text(_cooldown_gauge_right + 4, _y + 13, _cooldown_time_text, text_default_color, text_default_border_color)

      return 8 + 5 + (_gauge_height * 2)
    end

    local _parry_array = {
      {
        object = _player.parry_forward,
        enabled = training_settings.special_training_parry_forward_on
      },
      {
        object = _player.parry_down,
        enabled = training_settings.special_training_parry_down_on
      },
      {
        object = _player.parry_air,
        enabled = training_settings.special_training_parry_air_on
      },
      {
        object = _player.parry_antiair,
        enabled = training_settings.special_training_parry_antiair_on
      }
    }

    for _i, _parry in ipairs(_parry_array) do

      if _parry.enabled then
        _y_offset = _y_offset + _group_y_margin + draw_parry_gauge_group(_x, _y + _y_offset, _parry.object)
      end
    end
  end

  -- Charge Meter Drawing
  if is_in_match and special_training_mode[training_settings.special_training_current_mode] == "charge" then

    local _player = P1
    local _x = 276 --96
    local _y = 40
    local _flip_gauge = false
    local _gauge_x_scale = 1

    if training_settings.special_training_follow_character then
      local _px = _player.pos_x - screen_x + emu.screenwidth()/2
      local _py = emu.screenheight() - (_player.pos_y - screen_y) - ground_offset
      local _half_width = 23 * _gauge_x_scale * 0.5
      _x = _px - _half_width
      _x = math.max(_x, 4)
      _x = math.min(_x, emu.screenwidth() - (_half_width * 2.0 + 14))
      _y = _py - 100
    end

    local _y_offset = 0
    local _x_offset = 0
    local _group_y_margin = 6
    local _group_x_margin = 12

    function draw_charge_gauge_group(_x, _y, _charge_object)
      local _gauge_height = 3
      local _gauge_background_color = 0xD6E7EF77
      local _gauge_valid_fill_color = 0x52AAE7FF
      local _gauge_cooldown_fill_color = 0xFF9939FF
      local _success_color = 0x10FB00FF
      local _miss_color = 0xE70000FF

      local _charge_gauge_width = _charge_object.max_charge * _gauge_x_scale
      local _reset_gauge_width = _charge_object.max_reset * _gauge_x_scale
      local _charge_gauge_left = math.floor(_x + (_reset_gauge_width - _charge_gauge_width) * 0.5)
      local _charge_gauge_right = _charge_gauge_left + _charge_gauge_width + 1
      local _reset_gauge_left = _x
      local _reset_gauge_right = _reset_gauge_left + _reset_gauge_width + 1
      local _charge_time_text = string.format("%d", _charge_object.charge_time)
      local _reset_time_text = string.format("%d", _charge_object.reset_time)
      local _charge_text_color = text_default_color
      local _charge_outline_color = text_default_border_color
      if _charge_object.max_charge - _charge_object.charge_time == _charge_object.max_charge then
        _charge_text_color = _success_color
        _charge_outline_color = 0x00A200FF
      else
        _charge_text_color = _miss_color
        _charge_outline_color = 0x840000FF
      end
      
      _charge_time_text = string.format("%d", _charge_object.max_charge - _charge_object.charge_time)
      _overcharge_time_text = string.format("[%d]", _charge_object.overcharge)
      _last_overcharge_time_text = string.format("[%d]", _charge_object.last_overcharge)
      _reset_time_text = string.format("%d", _charge_object.reset_time)


      gui.text(_x + 1, _y, _charge_object.name, text_default_color, text_default_border_color)
      gui.box(_reset_gauge_left + 1, _y + 11, _charge_gauge_left, _y + 11, 0x00000000, 0xFFFFFF77)
      gui.box(_reset_gauge_left, _y + 10, _reset_gauge_left, _y + 12, 0x00000000, 0xFFFFFF77)
      gui.box(_charge_gauge_right, _y + 11, _reset_gauge_right - 1, _y + 11, 0x00000000, 0xFFFFFF77)
      gui.box(_reset_gauge_right, _y + 10, _reset_gauge_right, _y + 12, 0x00000000, 0xFFFFFF77)
      draw_gauge(_charge_gauge_left, _y + 8, _charge_gauge_width, _gauge_height + 1, _charge_object.charge_time / _charge_object.max_charge, _gauge_valid_fill_color, _gauge_background_color, nil, true)
      draw_gauge(_reset_gauge_left, _y + 8 + _gauge_height + 2, _reset_gauge_width, _gauge_height, _charge_object.reset_time / _charge_object.max_reset, _gauge_cooldown_fill_color, _gauge_background_color, nil, true)
      if training_settings.special_training_charge_overcharge_on and _charge_object.overcharge ~=0 and _charge_object.overcharge < 42 then
        draw_gauge(_charge_gauge_left, _y + 8, _charge_gauge_width, _gauge_height + 1, _charge_object.overcharge / _charge_object.max_charge, 0x08FF0044, _gauge_background_color, nil, true)
        gui.text(_reset_gauge_right + 16, _y + 7, _overcharge_time_text, _success_color, text_default_border_color)
      end
      if training_settings.special_training_charge_overcharge_on and _charge_object.overcharge == 0 and _charge_object.last_overcharge > 0 and _charge_object.last_overcharge < 42 then
        gui.text(_reset_gauge_right + 16, _y + 7, _last_overcharge_time_text, _success_color, text_default_border_color)
      end
    

      gui.text(_reset_gauge_right + 4, _y + 7, _charge_time_text, _charge_text_color, text_default_border_color)  
      gui.text(_reset_gauge_right + 4, _y + 13, _reset_time_text, text_default_color, text_default_border_color)

      return 8 + 5 + (_gauge_height * 2)
    end

    local _charge_array = {
      {
        object = _player.charge_1,
        enabled = _player.charge_1.enabled
      },
      {
        object = _player.charge_2,
        enabled = _player.charge_2.enabled
      },
      {
        object = _player.charge_3,
        enabled = _player.charge_3.enabled
      }
    }

    for _i, _charge in ipairs(_charge_array) do
      if _charge.enabled then
        _y_offset = _y_offset + _group_y_margin + draw_charge_gauge_group(_x, _y + _y_offset, _charge.object)
      end
    end
  end

  if is_in_match and current_recording_state ~= 1 then
    local _y = 5
    local _current_recording_size = 0
    if (recording_slots[training_settings.current_recording_slot].inputs) then
      _current_recording_size = #recording_slots[training_settings.current_recording_slot].inputs
    end

    if current_recording_state == 2 then
      local _text = string.format("%s: Wait for recording (%d)", recording_slots_names[training_settings.current_recording_slot], _current_recording_size)
      gui.text(250, _y, _text, text_default_color, text_default_border_color)
    elseif current_recording_state == 3 then
      local _text = string.format("%s: Recording... (%d)", recording_slots_names[training_settings.current_recording_slot], _current_recording_size)
      gui.text(274, _y, _text, text_default_color, text_default_border_color)
    elseif current_recording_state == 4 and dummy.pending_input_sequence and dummy.pending_input_sequence.sequence then
      local _text = ""
      local _x = 0
      if training_settings.replay_mode == 1 or training_settings.replay_mode == 3 then
        _x = 308
        _text = string.format("Playing (%d/%d)", dummy.pending_input_sequence.current_frame, #dummy.pending_input_sequence.sequence)
      else
        _x = 338
        _text = "Playing..."
      end
      gui.text(_x, _y, _text, text_default_color, text_default_border_color)
    end
  end

  if log_enabled then
    log_draw()
  end

  if is_in_match then
    local _should_toggle = P1.input.pressed.start
    if log_enabled then
      _should_toggle = P1.input.released.start
    end
    _should_toggle = not log_start_locked and _should_toggle

    if _should_toggle then
      is_menu_open = (not is_menu_open)
      if is_menu_open then
        menu_stack_push(main_menu)
      else
        menu_stack_clear()
      end
    end
  else
    is_menu_open = false
    menu_stack_clear()
  end

  if is_menu_open then
    local _horizontal_autofire_rate = 4
    local _vertical_autofire_rate = 4

    local _current_entry = menu_stack_top():current_entry()
    if _current_entry ~= nil and _current_entry.autofire_rate ~= nil then
      _horizontal_autofire_rate = _current_entry.autofire_rate
    end

    local _input =
    {
      down = check_input_down_autofire(player_objects[1], "down", _vertical_autofire_rate),
      up = check_input_down_autofire(player_objects[1], "up", _vertical_autofire_rate),
      left = check_input_down_autofire(player_objects[1], "left", _horizontal_autofire_rate),
      right = check_input_down_autofire(player_objects[1], "right", _horizontal_autofire_rate),
      validate = P1.input.pressed.LP,
      reset = P1.input.pressed.MP,
      cancel = P1.input.pressed.LK,
    }

    menu_stack_update(_input)

    menu_stack_draw()
  end

  gui.box(0,0,0,0,0,0) -- if we don't draw something, what we drawed from last frame won't be cleared
end

-- registers
emu.registerstart(on_start)
emu.registerbefore(before_frame)
gui.register(on_gui)
savestate.registerload(on_load_state)
