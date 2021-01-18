print("-----------------------------")
print("  3rd_training.lua - v0.9 dev")
print("  Training mode for Street Fighter III 3rd Strike (Japan 990512), on Fightcade v2.0.91")
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

-- FBA-RR Scripting reference:
-- http://tasvideos.org/EmulatorResources/VBA/LuaScriptingFunctions.html
-- https://github.com/TASVideos/mame-rr/wiki/Lua-scripting-functions

-- Resources
-- https://github.com/Jesuszilla/mame-rr-scripts/blob/master/framedata.lua

json = require ("lua_libs/dkjson")

recording_slot_count = 8

-- debug options
developer_mode = false -- Unlock frame data recording options. Touch at your own risk since you may use those options to fuck up some already recorded frame data
assert_enabled = developer_mode or false
debug_wakeup = false
log_enabled = developer_mode or false
log_categories_display =
{
  input =                     { history = false, print = false },
  projectiles =               { history = true, print = true },
  fight =                     { history = true, print = true },
  animation =                 { history = false, print = false },
  parry_training_FORWARD =    { history = false, print = false },
  blocking =                  { history = true, print = true },
  counter_attack =            { history = false, print = false },
}

function t_assert(_condition, _msg)
  _msg = _msg or "Assertion failed"
  if assert_enabled and not _condition then
    error(_msg, 2)
  end
end

saved_path = "saved/"
framedata_path = "data/framedata/"
saved_recordings_path = "saved/recordings/"
training_settings_file = "training_settings.json"
frame_data_file_ext = "_framedata.json"

-- Images
require "gd"
img_1_dir = gd.createFromPng("images/1_dir.png"):gdStr()
img_2_dir = gd.createFromPng("images/2_dir.png"):gdStr()
img_3_dir = gd.createFromPng("images/3_dir.png"):gdStr()
img_4_dir = gd.createFromPng("images/4_dir.png"):gdStr()
img_5_dir = gd.createFromPng("images/5_dir.png"):gdStr()
img_6_dir = gd.createFromPng("images/6_dir.png"):gdStr()
img_7_dir = gd.createFromPng("images/7_dir.png"):gdStr()
img_8_dir = gd.createFromPng("images/8_dir.png"):gdStr()
img_9_dir = gd.createFromPng("images/9_dir.png"):gdStr()
img_L_button = gd.createFromPng("images/L_button.png"):gdStr()
img_M_button = gd.createFromPng("images/M_button.png"):gdStr()
img_H_button = gd.createFromPng("images/H_button.png"):gdStr()
img_no_button = gd.createFromPng("images/no_button.png"):gdStr()
img_dir = {
  img_1_dir,
  img_2_dir,
  img_3_dir,
  img_4_dir,
  img_5_dir,
  img_6_dir,
  img_7_dir,
  img_8_dir,
  img_9_dir
}

-- json tools
function read_object_from_json_file(_file_path)
  local _f = io.open(_file_path, "r")
  if _f == nil then
    return nil
  end

  local _object
  local _pos, _err
  _object, _pos, _err = json.decode(_f:read("*all"))
  _f:close()

  if (err) then
    print(string.format("Failed to read json file \"%s\" : %s", _file_path, _err))
  end

  return _object
end

function write_object_to_json_file(_object, _file_path)
  local _f, _error, _code = io.open(_file_path, "w")
  if _f == nil then
    print(string.format("Error %d: %s", _code, _error))
    return false
  end

  local _str = json.encode(_object, { indent = true })
  _f:write(_str)
  _f:close()

  return true
end

-- players
function make_input_set(_value)
  return {
    up = _value,
    down = _value,
    left = _value,
    right = _value,
    LP = _value,
    MP = _value,
    HP = _value,
    LK = _value,
    MK = _value,
    HK = _value,
    start = _value,
    coin = _value
  }
end

function make_player_object(_id, _base, _prefix)
  return {
    id = _id,
    base = _base,
    prefix = _prefix,
    input = {
      pressed = make_input_set(false),
      released = make_input_set(false),
      down = make_input_set(false),
      state_time = make_input_set(0),
    },
    blocking = {
      wait_for_block_string = true,
      block_string = false,
    },
    counter = {
      attack_frame = -1,
      ref_time = -1,
      recording_slot = -1,
    },
    throw = {},
    max_meter_gauge = 0,
    max_meter_count = 0,
  }
end

function reset_player_objects()
  player_objects = {
    make_player_object(1, 0x02068C6C, "P1"),
    make_player_object(2, 0x02069104, "P2")
  }

  P1 = player_objects[1]
  P2 = player_objects[2]

  P1.gauge_addr = 0x020695B5
  P1.meter_addr = { 0x020286AB, 0x020695BF } -- 2nd address is the master variable
  P1.stun_max_addr = 0x020695F7
  P1.stun_timer_addr = P1.stun_max_addr + 0x2
  P1.stun_bar_addr = P1.stun_max_addr + 0x6
  P1.meter_update_flag = 0x020157C8
  P1.score_addr = 0x020113A2
  P1.parry_forward_validity_time_addr = 0x02026335
  P1.parry_forward_cooldown_time_addr = 0x02025731
  P1.parry_down_validity_time_addr = 0x02026337
  P1.parry_down_cooldown_time_addr = 0x0202574D
  P1.parry_air_validity_time_addr = 0x02026339
  P1.parry_air_cooldown_time_addr = 0x02025769
  P1.parry_antiair_validity_time_addr = 0x02026347
  P1.parry_antiair_cooldown_time_addr = 0x0202582D

  P2.gauge_addr = 0x020695E1
  P2.meter_addr = { 0x020286DF, 0x020695EB} -- 2nd address is the master variable
  P2.stun_max_addr = 0x0206960B
  P2.stun_timer_addr = P2.stun_max_addr + 0x2
  P2.stun_bar_addr = P2.stun_max_addr + 0x6
  P2.meter_update_flag = 0x020157C9
  P2.score_addr = 0x020113AE
  P2.parry_forward_validity_time_addr = P1.parry_forward_validity_time_addr + 0x406
  P2.parry_forward_cooldown_time_addr = P1.parry_forward_cooldown_time_addr + 0x620
  P2.parry_down_validity_time_addr = P1.parry_down_validity_time_addr + 0x406
  P2.parry_down_cooldown_time_addr = P1.parry_down_cooldown_time_addr + 0x620
  P2.parry_air_validity_time_addr = P1.parry_air_validity_time_addr + 0x406
  P2.parry_air_cooldown_time_addr = P1.parry_air_cooldown_time_addr + 0x620
  P2.parry_antiair_validity_time_addr = P1.parry_antiair_validity_time_addr + 0x406
  P2.parry_antiair_cooldown_time_addr = P1.parry_antiair_cooldown_time_addr + 0x620

end
reset_player_objects()

function update_input(_player_obj)

  function update_player_input(_input_object, _input_name, _input)
    _input_object.pressed[_input_name] = false
    _input_object.released[_input_name] = false
    if _input_object.down[_input_name] == false and _input then _input_object.pressed[_input_name] = true end
    if _input_object.down[_input_name] == true and _input == false then _input_object.released[_input_name] = true end

    if _input_object.down[_input_name] == _input then
      _input_object.state_time[_input_name] = _input_object.state_time[_input_name] + 1
    else
      _input_object.state_time[_input_name] = 0
    end
    _input_object.down[_input_name] = _input
  end

  local _local_input = joypad.get()
  update_player_input(_player_obj.input, "start", _local_input[_player_obj.prefix.." Start"])
  update_player_input(_player_obj.input, "coin", _local_input[_player_obj.prefix.." Coin"])
  update_player_input(_player_obj.input, "up", _local_input[_player_obj.prefix.." Up"])
  update_player_input(_player_obj.input, "down", _local_input[_player_obj.prefix.." Down"])
  update_player_input(_player_obj.input, "left", _local_input[_player_obj.prefix.." Left"])
  update_player_input(_player_obj.input, "right", _local_input[_player_obj.prefix.." Right"])
  update_player_input(_player_obj.input, "LP", _local_input[_player_obj.prefix.." Weak Punch"])
  update_player_input(_player_obj.input, "MP", _local_input[_player_obj.prefix.." Medium Punch"])
  update_player_input(_player_obj.input, "HP", _local_input[_player_obj.prefix.." Strong Punch"])
  update_player_input(_player_obj.input, "LK", _local_input[_player_obj.prefix.." Weak Kick"])
  update_player_input(_player_obj.input, "MK", _local_input[_player_obj.prefix.." Medium Kick"])
  update_player_input(_player_obj.input, "HK", _local_input[_player_obj.prefix.." Strong Kick"])
end

function check_input_down_autofire(_player_object, _input, _autofire_rate, _autofire_time)
  _autofire_rate = _autofire_rate or 4
  _autofire_time = _autofire_time or 23
  if _player_object.input.pressed[_input] or (_player_object.input.down[_input] and _player_object.input.state_time[_input] > _autofire_time and (_player_object.input.state_time[_input] % _autofire_rate) == 0) then
    return true
  end
  return false
end

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
  "Shun Goku Ratsu", -- Gouki hidden SA1
  "Kongou Kokuretsu Zan", -- Gouki hidden SA2
}

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
  elseif  _stick == "Shun Goku Ratsu" then _sequence = { { "LP" }, {}, {}, { "LP" }, { "forward" }, {"LK"}, {}, { "HP" } }
    return _sequence
  elseif  _stick == "Kongou Kokuretsu Zan" then _sequence = { { "down" }, {}, { "down" }, {}, { "down", "LP", "MP", "HP" } }
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

-- History
input_history_size_max = 12
input_history = {
  {},
  {}
}

function make_input_history_entry(_prefix, _input)
  local _up = _input[_prefix.." Up"]
  local _down = _input[_prefix.." Down"]
  local _left = _input[_prefix.." Left"]
  local _right = _input[_prefix.." Right"]
  local _direction = 5
  if _down then
    if _left then _direction = 1
    elseif _right then _direction = 3
    else _direction = 2 end
  elseif _up then
    if _left then _direction = 7
    elseif _right then _direction = 9
    else _direction = 8 end
  else
    if _left then _direction = 4
    elseif _right then _direction = 6
    else _direction = 5 end
  end

  return {
    frame = frame_number,
    direction = _direction,
    buttons = {
      _input[_prefix.." Weak Punch"],
      _input[_prefix.." Medium Punch"],
      _input[_prefix.." Strong Punch"],
      _input[_prefix.." Weak Kick"],
      _input[_prefix.." Medium Kick"],
      _input[_prefix.." Strong Kick"]
    }
  }
end

function is_input_history_entry_equal(_a, _b)
  if (_a.direction ~= _b.direction) then return false end
  if (_a.buttons[1] ~= _b.buttons[1]) then return false end
  if (_a.buttons[2] ~= _b.buttons[2]) then return false end
  if (_a.buttons[3] ~= _b.buttons[3]) then return false end
  if (_a.buttons[4] ~= _b.buttons[4]) then return false end
  if (_a.buttons[5] ~= _b.buttons[5]) then return false end
  if (_a.buttons[6] ~= _b.buttons[6]) then return false end
  return true
end

function update_input_history(_history, _prefix, _input)
  local _entry = make_input_history_entry(_prefix, _input)

  if #_history == 0 then
    table.insert(_history, _entry)
  else
    local _last_entry = _history[#_history]
    if _last_entry.frame ~= frame_number and not is_input_history_entry_equal(_entry, _last_entry) then
      table.insert(_history, _entry)
    end
  end

  while #_history > input_history_size_max do
    table.remove(_history, 1)
  end
end

function draw_input_history_entry(_entry, _x, _y)
  gui.image(_x, _y, img_dir[_entry.direction])

  local _img_LP = img_no_button
  local _img_MP = img_no_button
  local _img_HP = img_no_button
  local _img_LK = img_no_button
  local _img_MK = img_no_button
  local _img_HK = img_no_button
  if _entry.buttons[1] then _img_LP = img_L_button end
  if _entry.buttons[2] then _img_MP = img_M_button end
  if _entry.buttons[3] then _img_HP = img_H_button end
  if _entry.buttons[4] then _img_LK = img_L_button end
  if _entry.buttons[5] then _img_MK = img_M_button end
  if _entry.buttons[6] then _img_HK = img_H_button end

  gui.image(_x + 13, _y, _img_LP)
  gui.image(_x + 18, _y, _img_MP)
  gui.image(_x + 23, _y, _img_HP)
  gui.image(_x + 13, _y + 5, _img_LK)
  gui.image(_x + 18, _y + 5, _img_MK)
  gui.image(_x + 23, _y + 5, _img_HK)
end

function draw_input_history(_history, _x, _y, _is_left)
  local _step_y = 12
  local _j = 0
  for _i = #_history, 1, -1 do
    local _current_y = _y + _j * _step_y
    local _entry = _history[_i]

    local _entry_offset = 0
    if _is_left then _entry_offset = 13 end
    draw_input_history_entry(_entry, _x + _entry_offset, _current_y)

    local _next_frame = frame_number
    if _i < #_history then
      _next_frame = _history[_i + 1].frame
    end
    local _frame_diff = _next_frame - _entry.frame
    local _text = "-"
    if (_frame_diff < 999) then
      _text = string.format("%d", _frame_diff)
    end

    local _offset = 0
    if _is_left then
      _offset = 8
      if (_frame_diff < 999) then
        if (_frame_diff >= 100) then _offset = 0
        elseif (_frame_diff >= 10) then _offset = 4 end
      end
    else
      _offset = 33
    end

    gui.text(_x + _offset, _current_y + 2, _text, 0xd6e3efff, 0x101000ff)

    _j = _j + 1
  end
end

-- !History

characters =
{
  "alex",
  "ryu",
  "yun",
  "dudley",
  "necro",
  "hugo",
  "ibuki",
  "elena",
  "oro",
  "yang",
  "ken",
  "sean",
  "urien",
  "gouki",
  "gill",
  "chunli",
  "makoto",
  "q",
  "twelve",
  "remy"
}

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

frame_data_movement_type = {
  "animation",
  "velocity"
}

special_training_mode = {
  "none",
  "parry"
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

-- menu
text_default_color = 0xF7FFF7FF
text_default_border_color = 0x101008FF
text_selected_color = 0xFF0000FF
text_disabled_color = 0x999999FF

function gauge_menu_item(_name, _object, _property_name, _unit, _fill_color, _gauge_max, _subdivision_count)
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.property_name = _property_name
  _o.player_id = _player_id
  _o.autofire_rate = 1
  _o.unit = _unit or 2
  _o.gauge_max = _gauge_max or 0
  _o.subdivision_count = _subdivision_count or 1
  _o.fill_color = _fill_color or 0x0000FFFF

  function _o:draw(_x, _y, _selected)
    local _c = text_default_color
    local _prefix = ""
    local _suffix = ""
    if _selected then
      _c = text_selected_color
      _prefix = "< "
      _suffix = " >"
    end
    gui.text(_x, _y, _prefix..self.name.." : ", _c, text_default_border_color)

    local _box_width = self.gauge_max / self.unit
    local _box_top = _y + 1
    local _box_left = _x + get_text_width("< "..self.name.." : ") - 1
    local _box_right = _box_left + _box_width
    local _box_bottom = _box_top + 4
    gui.box(_box_left, _box_top, _box_right, _box_bottom, text_default_color, text_default_border_color)
    local _content_width = self.object[self.property_name] / self.unit
    gui.box(_box_left, _box_top, _box_left + _content_width, _box_bottom, self.fill_color, 0x00000000)
    for _i = 1, self.subdivision_count - 1 do
      local _line_x = _box_left + _i * self.gauge_max / (self.subdivision_count * self.unit)
      gui.line(_line_x, _box_top, _line_x, _box_bottom, text_default_border_color)
    end

    gui.text(_box_right + 2, _y, _suffix, _c, text_default_border_color)
  end

  function _o:left()
    self.object[self.property_name] = math.max(self.object[self.property_name] - self.unit, 0)
  end

  function _o:right()
    self.object[self.property_name] = math.min(self.object[self.property_name] + self.unit, self.gauge_max)
  end

  function _o:reset()
    self.object[self.property_name] = 0
  end

  function _o:legend()
    return "MP: Reset to default"
  end

  return _o
end

available_characters = {
  " ",
  "A",
  "B",
  "C",
  "D",
  "E",
  "F",
  "G",
  "H",
  "I",
  "J",
  "K",
  "L",
  "M",
  "N",
  "O",
  "P",
  "Q",
  "R",
  "S",
  "T",
  "U",
  "V",
  "X",
  "Y",
  "Z",
  "0",
  "1",
  "2",
  "3",
  "4",
  "5",
  "6",
  "7",
  "8",
  "9",
  "-",
  "_",
}

function textfield_menu_item(_name, _object, _property_name, _default_value, _max_length)
  _default_value = _default_value or ""
  _max_length = _max_length or 16
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.property_name = _property_name
  _o.default_value = _default_value
  _o.max_length = _max_length
  _o.edition_index = 0
  _o.is_in_edition = false
  _o.content = {}

  function _o:sync_to_var()
    local _str = ""
    for i = 1, #self.content do
      _str = _str..available_characters[self.content[i]]
    end
    self.object[self.property_name] = _str
  end

  function _o:sync_from_var()
    self.content = {}
    for i = 1, #self.object[self.property_name] do
      local _c = self.object[self.property_name]:sub(i,i)
      for j = 1, #available_characters do
        if available_characters[j] == _c then
          table.insert(self.content, j)
          break
        end
      end
    end
  end

  function _o:crop_char_table()
    local _last_empty_index = 0
    for i = 1, #self.content do
      if self.content[i] == 1 then
        _last_empty_index = i
      else
        _last_empty_index = 0
      end
    end

    if _last_empty_index > 0 then
      for i = _last_empty_index, #self.content do
        table.remove(self.content, _last_empty_index)
      end
    end
  end

  function _o:draw(_x, _y, _selected)
    local _c = text_default_color
    local _prefix = ""
    local _suffix = ""
    if self.is_in_edition then
      _c =  0xFFFF00FF
    elseif _selected then
      _c = text_selected_color
    end

    local _value = self.object[self.property_name]

    if self.is_in_edition then
      local _cycle = 100
      if ((frame_number % _cycle) / _cycle) < 0.5 then
        gui.text(_x + (#self.name + 3 + #self.content - 1) * 4, _y + 2, "_", _c, text_default_border_color)
      end
    end

    gui.text(_x, _y, _prefix..self.name.." : ".._value.._suffix, _c, text_default_border_color)
  end

  function _o:left()
    if self.is_in_edition then
      self:reset()
    end
  end

  function _o:right()
    if self.is_in_edition then
      self:validate()
    end
  end

  function _o:up()
    if self.is_in_edition then
      self.content[self.edition_index] = self.content[self.edition_index] + 1
      if self.content[self.edition_index] > #available_characters then
        self.content[self.edition_index] = 1
      end
      self:sync_to_var()
      return true
    else
      return false
    end
  end

  function _o:down()
    if self.is_in_edition then
      self.content[self.edition_index] = self.content[self.edition_index] - 1
      if self.content[self.edition_index] == 0 then
        self.content[self.edition_index] = #available_characters
      end
      self:sync_to_var()
      return true
    else
      return false
    end
  end

  function _o:validate()
    if not self.is_in_edition then
      self:sync_from_var()
      if #self.content < self.max_length then
        table.insert(self.content, 1)
      end
      self.edition_index = #self.content
      self.is_in_edition = true
    else
      if self.content[self.edition_index] ~= 1 then
        if #self.content < self.max_length then
          table.insert(self.content, 1)
          self.edition_index = #self.content
        end
      end
    end
    self:sync_to_var()
  end

  function _o:reset()
    if not self.is_in_edition then
      _o.content = {}
      self.edition_index = 0
    else
      if #self.content > 1 then
        table.remove(self.content, #self.content)
        self.edition_index = #self.content
      else
        self.content[1] = 1
      end
    end
    self:sync_to_var()
  end

  function _o:cancel()
    if self.is_in_edition then
      self:crop_char_table()
      self:sync_to_var()
      self.is_in_edition = false
    end
  end

  function _o:legend()
    if self.is_in_edition then
      return "LP/Right: Next   MP/Left: Previous   LK: Leave edition"
    else
      return "LP: Edit   MP: Reset to default"
    end
  end

  _o:sync_from_var()
  return _o
end

function checkbox_menu_item(_name, _object, _property_name, _default_value)
  if _default_value == nil then _default_value = false end
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.property_name = _property_name
  _o.default_value = _default_value

  function _o:draw(_x, _y, _selected)
    local _c = text_default_color
    local _prefix = ""
    local _suffix = ""
    if _selected then
      _c = text_selected_color
      _prefix = "< "
      _suffix = " >"
    end

    local _value = ""
    if self.object[self.property_name] then
      _value = "yes"
    else
      _value = "no"
    end
    gui.text(_x, _y, _prefix..self.name.." : ".._value.._suffix, _c, text_default_border_color)
  end

  function _o:left()
    self.object[self.property_name] = not self.object[self.property_name]
  end

  function _o:right()
    self.object[self.property_name] = not self.object[self.property_name]
  end

  function _o:reset()
    self.object[self.property_name] = self.default_value
  end

  function _o:legend()
    return "MP: Reset to default"
  end

  return _o
end

function list_menu_item(_name, _object, _property_name, _list, _default_value)
  if _default_value == nil then _default_value = 1 end
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.property_name = _property_name
  _o.list = _list
  _o.default_value = _default_value

  function _o:draw(_x, _y, _selected)
    local _c = text_default_color
    local _prefix = ""
    local _suffix = ""
    if _selected then
      _c = text_selected_color
      _prefix = "< "
      _suffix = " >"
    end
    gui.text(_x, _y, _prefix..self.name.." : "..tostring(self.list[self.object[self.property_name]]).._suffix, _c, text_default_border_color)
  end

  function _o:left()
    self.object[self.property_name] = self.object[self.property_name] - 1
    if self.object[self.property_name] == 0 then
      self.object[self.property_name] = #self.list
    end
  end

  function _o:right()
    self.object[self.property_name] = self.object[self.property_name] + 1
    if self.object[self.property_name] > #self.list then
      self.object[self.property_name] = 1
    end
  end

  function _o:reset()
    self.object[self.property_name] = self.default_value
  end

  function _o:legend()
    return "MP: Reset to default"
  end

  return _o
end

function integer_menu_item(_name, _object, _property_name, _min, _max, _loop, _default_value, _autofire_rate)
  if _default_value == nil then _default_value = _min end
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.property_name = _property_name
  _o.min = _min
  _o.max = _max
  _o.loop = _loop
  _o.default_value = _default_value
  _o.autofire_rate = _autofire_rate

  function _o:draw(_x, _y, _selected)
    local _c = text_default_color
    local _prefix = ""
    local _suffix = ""
    if _selected then
      _c = text_selected_color
      _prefix = "< "
      _suffix = " >"
    end
    gui.text(_x, _y, _prefix..self.name.." : "..tostring(self.object[self.property_name]).._suffix, _c, text_default_border_color)
  end

  function _o:left()
    self.object[self.property_name] = self.object[self.property_name] - 1
    if self.object[self.property_name] < self.min then
      if self.loop then
        self.object[self.property_name] = self.max
      else
        self.object[self.property_name] = self.min
      end
    end
  end

  function _o:right()
    self.object[self.property_name] = self.object[self.property_name] + 1
    if self.object[self.property_name] > self.max then
      if self.loop then
        self.object[self.property_name] = self.min
      else
        self.object[self.property_name] = self.max
      end
    end
  end

  function _o:reset()
    self.object[self.property_name] = self.default_value
  end

  function _o:legend()
    return "MP: Reset to default"
  end

  return _o
end

function map_menu_item(_name, _object, _property_name, _map_object, _map_property)
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.property_name = _property_name
  _o.map_object = _map_object
  _o.map_property = _map_property

  function _o:draw(_x, _y, _selected)
    local _c = text_default_color
    local _prefix = ""
    local _suffix = ""
    if _selected then
      _c = text_selected_color
      _prefix = "< "
      _suffix = " >"
    end

    local _str = string.format("%s%s : %s%s", _prefix, self.name, self.object[self.property_name], _suffix)
    gui.text(_x, _y, _str, _c, text_default_border_color)
  end

  function _o:left()
    if self.map_property == nil or self.map_object == nil or self.map_object[self.map_property] == nil then
      return
    end

    if self.object[self.property_name] == "" then
      for _key, _value in pairs(self.map_object[self.map_property]) do
        self.object[self.property_name] = _key
      end
    else
      local _previous_key = ""
      for _key, _value in pairs(self.map_object[self.map_property]) do
        if _key == self.object[self.property_name] then
          self.object[self.property_name] = _previous_key
          return
        end
        _previous_key = _key
      end
      self.object[self.property_name] = ""
    end
  end

  function _o:right()
    if self.map_property == nil or self.map_object == nil or self.map_object[self.map_property] == nil then
      return
    end

    if self.object[self.property_name] == "" then
      for _key, _value in pairs(self.map_object[self.map_property]) do
        self.object[self.property_name] = _key
        return
      end
    else
      local _previous_key = ""
      for _key, _value in pairs(self.map_object[self.map_property]) do
        if _previous_key == self.object[self.property_name] then
          self.object[self.property_name] = _key
          return
        end
        _previous_key = _key
      end
      self.object[self.property_name] = ""
    end
  end

  function _o:reset()
    self.object[self.property_name] = ""
  end

  function _o:legend()
    return "MP: Reset to default"
  end

  return _o
end

function button_menu_item(_name, _validate_function)
  local _o = {}
  _o.name = _name
  _o.validate_function = _validate_function
  _o.last_frame_validated = 0

  function _o:draw(_x, _y, _selected)
    local _c = text_default_color
    if _selected then
      _c = text_selected_color

      if (frame_number - self.last_frame_validated < 5 ) then
        _c = 0xFFFF00FF
      end
    end

    gui.text(_x, _y,self.name, _c, text_default_border_color)
  end

  function _o:validate()
    self.last_frame_validated = frame_number
    if self.validate_function then
      self.validate_function()
    end
  end

  function _o:legend()
    return "LP: Validate"
  end

  return _o
end

function make_popup(_left, _top, _right, _bottom, _entries)
  local _p = {}
  _p.left = _left
  _p.top = _top
  _p.right = _right
  _p.bottom = _bottom
  _p.entries = _entries

  return _p
end

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
  local _char = player_objects[training_settings.dummy_player].char_str
  if _char and _char ~= "" then
    local _recording_count = #recording_slots
    if training_settings.recordings then
      recording_slots = training_settings.recordings[_char]
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
-- logs
logs = {}
log_sections = {
  global = 1,
  P1 = 2,
  P2 = 3,
}
log_categories = {}
log_recording_on = false
log_category_count = 0
current_entry = 1
log_size_max = 80
log_line_count_max = 25
log_line_offset = 0
function log(_section_name, _category_name, _event_name)
  if not log_enabled then return end

  if log_categories_display[_category_name] and log_categories_display[_category_name].print then
    print(string.format("%d - [%s][%s] %s", frame_number, _section_name, _category_name, _event_name))
  end

  if not log_recording_on then return end

  _event_name = _event_name or ""
  _category_name = _category_name or ""
  _section_name = _section_name or "global"
  if log_sections[_section_name] == nil then _section_name = "global" end

  if not log_categories_display[_category_name] or not log_categories_display[_category_name].history then return end

  -- Add category if it does not exists
  if log_categories[_category_name] == nil then
    log_categories[_category_name] = log_category_count
    log_category_count = log_category_count + 1
  end

  -- Insert frame if it does not exists
  if #logs == 0 or logs[#logs].frame ~= frame_number then
    table.insert(logs, {
      frame = frame_number,
      events = {}
    })
  end

  -- Remove overflowing logs frame
  while #logs > log_size_max do
    table.remove(logs, 1)
  end

  local _current_frame = logs[#logs]
  table.insert(_current_frame.events, {
    name = _event_name,
    section = _section_name,
    category = _category_name,
    color = string_to_color(_event_name)
  })
end

log_filtered = {}
log_start_locked = false
function log_update()
  log_filtered = {}
  if not log_enabled then return end

  -- compute filtered logs
  for _i = 1, #logs do
    local _frame = logs[_i]
    local _filtered_frame = { frame = _frame.frame, events = {}}
    for _j, _event in ipairs(_frame.events) do
      if log_categories_display[_event.category] and log_categories_display[_event.category].history then
        table.insert(_filtered_frame.events, _event)
      end
    end

    if #_filtered_frame.events > 0 then
      table.insert(log_filtered, _filtered_frame)
    end
  end

  -- process input
  if player.input.down.start then
    if player.input.pressed.HP then
      log_start_locked = true
      log_recording_on = not log_recording_on
      if log_recording_on then
        log_line_offset = 0
      end
    end
    if player.input.pressed.HK then
      log_start_locked = true
      log_line_offset = 0
      logs = {}
    end

    if check_input_down_autofire(player, "up", 4) then
      log_start_locked = true
      log_line_offset = log_line_offset - 1
      log_line_offset = math.max(log_line_offset, 0)
    end
    if check_input_down_autofire(player, "down", 4) then
      log_start_locked = true
      log_line_offset = log_line_offset + 1
      log_line_offset = math.min(log_line_offset, math.max(#log_filtered - log_line_count_max - 1, 0))
    end
  end

  if not player.input.down.start and not player.input.released.start then
    log_start_locked = false
  end
end

function history_draw()
  local _log = log_filtered

  if #_log == 0 then return end

  local _line_background = { 0x333333CC, 0x555555CC }
  local _separator_color = 0xAAAAAAFF
  local _width = emu.screenwidth() - 10
  local _height = emu.screenheight() - 10
  local _x_start = 5
  local _y_start = 5
  local _line_height = 8
  local _current_line = 0
  local _columns_start = { 0, 20, 200 }
  local _box_size = 6
  local _box_margin = 2
  gui.box(_x_start, _y_start , _x_start + _width, _y_start, 0x00000000, _separator_color)
  local _last_displayed_frame = 0
  for _i = 0, log_line_count_max do
    local _frame_index = #_log - (_i + log_line_offset)
    if _frame_index < 1 then
      break
    end
    local _frame = _log[_frame_index]
    local _events = {{}, {}, {}}
    for _j, _event in ipairs(_frame.events) do
      if log_categories_display[_event.category] and log_categories_display[_event.category].history then
        table.insert(_events[log_sections[_event.section]], _event)
      end
    end

    local _y = _y_start + _current_line * _line_height
    gui.box(_x_start, _y, _x_start + _width, _y + _line_height, _line_background[(_i % 2) + 1], 0x00000000)
    for _section_i = 1, 3 do
      local _box_x = _x_start + _columns_start[_section_i]
      local _box_y = _y + 1
      for _j, _event in ipairs(_events[_section_i]) do
        gui.box(_box_x, _box_y, _box_x + _box_size, _box_y + _box_size, _event.color, 0x00000000)
        gui.box(_box_x + 1, _box_y + 1, _box_x + _box_size - 1, _box_y + _box_size - 1, 0x00000000, 0x00000022)
        gui.text(_box_x + _box_size + _box_margin, _box_y, _event.name, text_default_color, 0x00000000)
        _box_x = _box_x + _box_size + _box_margin + get_text_width(_event.name) + _box_margin
      end
    end

    if _frame_index > 1 then
      local _frame_diff = _frame.frame - _log[_frame_index - 1].frame
      gui.text(_x_start + 2, _y + 1, string.format("%d", _frame_diff), text_default_color, 0x00000000)
    end
    gui.box(_x_start, _y + _line_height, _x_start + _width, _y + _line_height, 0x00000000, _separator_color)
    _current_line = _current_line + 1
    _last_displayed_frame = _frame_index
  end
end

-- game data
frame_number = 0
is_in_match = false

-- HITBOXES
frame_data = {}
frame_data_file = "frame_data.json"

function save_frame_data()
  for _key, _value in ipairs(characters) do
    if frame_data[_value].dirty then
      frame_data[_value].dirty = nil
      local _file_path = framedata_path.._value..frame_data_file_ext
      if not write_object_to_json_file(frame_data[_value], _file_path) then
        print(string.format("Error: Failed to write frame data to \"%s\"", _file_path))
      else
        print(string.format("Saved frame data to \"%s\"", _file_path))
      end
    end
  end
end

function load_frame_data()
  for _key, _value in ipairs(characters) do
    local _file_path = framedata_path.._value..frame_data_file_ext
    frame_data[_value] = read_object_from_json_file(_file_path) or {}
    frame_data[_value].wakeups = frame_data[_value].wakeups or {}
  end
end

function reset_current_recording_animation()
  current_recording_animation_previous_pos = {0, 0}
  current_recording_animation = nil
end
reset_current_recording_animation()

function record_framedata(_player_obj)
  local _debug = true
  -- any connecting attack frame data may be ill formed. We discard it immediately to avoid data loss (except for moves tagged as "force_recording" that are difficult to record otherwise)
  if (_player_obj.has_just_hit or _player_obj.has_just_been_blocked or _player_obj.has_just_been_parried) then
    if not frame_data_meta[_player_obj.char_str] or not frame_data_meta[_player_obj.char_str].moves[_player_obj.animation] or not frame_data_meta[_player_obj.char_str].moves[_player_obj.animation].force_recording then
      if current_recording_animation and _debug then
        print(string.format("dropped animation because it connected: %s", _player_obj.animation))
      end
      reset_current_recording_animation()
    end
  end

  if (_player_obj.has_animation_just_changed) then
    local _id
    if current_recording_animation then _id = current_recording_animation.id end

    if current_recording_animation and current_recording_animation.attack_box_count > 0 then
      current_recording_animation.attack_box_count = nil -- don't save that
      current_recording_animation.id = nil -- don't save that

      -- compute hit frames range
      for _i, _hit_frame in ipairs(current_recording_animation.hit_frames) do
        local _range_limit_frame = #current_recording_animation.frames - 1
        if _i < #current_recording_animation.hit_frames then
          _range_limit_frame = current_recording_animation.hit_frames[_i + 1] - 1
        end
        local _range_end_frame = _hit_frame
        if _hit_frame < _range_limit_frame then
          for _j = (_hit_frame + 1), _range_limit_frame do
            if #current_recording_animation.frames[_j].boxes > 0 then
              _range_end_frame = _j - 1
            else
              break
            end
          end
        end

        current_recording_animation.hit_frames[_i] = { min = _hit_frame, max = _range_end_frame }
      end

      if (frame_data[_player_obj.char_str] == nil) then
        frame_data[_player_obj.char_str] = {}
      end
      frame_data[_player_obj.char_str].dirty = true
      frame_data[_player_obj.char_str][_id] = current_recording_animation

      if _debug then
        print(string.format("recorded animation: %s", _id))
      end
    elseif current_recording_animation then
      if _debug then
        print(string.format("dropped animation recording: %s", _id))
      end
    end

    current_recording_animation_previous_pos = {_player_obj.pos_x, _player_obj.pos_y}
    current_recording_animation = { frames = {}, hit_frames = {}, attack_box_count = 0, id = _player_obj.animation }
  end

  if (current_recording_animation) then

    local _frame = frame_number - _player_obj.current_animation_freeze_frames - _player_obj.current_animation_start_frame
    if _player_obj.has_just_acted then
      table.insert(current_recording_animation.hit_frames, _frame)
    end

    if _player_obj.remaining_freeze_frames == 0 then
      --print(string.format("recording frame %d (%d - %d - %d)", _frame, frame_number, _player_obj.current_animation_freeze_frames, _player_obj.current_animation_start_frame))

      local _sign = 1
      if _player_obj.flip_input then _sign = -1 end

      current_recording_animation.frames[_frame + 1] = {
        boxes = {},
        movement = {
          (_player_obj.pos_x - current_recording_animation_previous_pos[1]) * _sign,
          (_player_obj.pos_y - current_recording_animation_previous_pos[2]),
        },
        frame_id = _player_obj.animation_frame_id
      }
      current_recording_animation_previous_pos = { _player_obj.pos_x, _player_obj.pos_y }

      for __, _box in ipairs(_player_obj.boxes) do
        if (_box.type == "attack") or (_box.type == "throw") then
          table.insert(current_recording_animation.frames[_frame + 1].boxes, copytable(_box))
          current_recording_animation.attack_box_count = current_recording_animation.attack_box_count + 1
        end
      end
    end
  end
end

function define_box(_obj, _ptr, _type)
  if _obj.friends > 1 then --Yang SA3
    if _type ~= "attack" then
      return
    end
  end

  local _box = {
    left   = memory.readwordsigned(_ptr + 0x0),
    width  = memory.readwordsigned(_ptr + 0x2),
    bottom = memory.readwordsigned(_ptr + 0x4),
    height = memory.readwordsigned(_ptr + 0x6),
    type   = _type,
  }

  if _box.left == 0 and _box.width == 0 and _box.height == 0 and _box.bottom == 0 then
    return
  end

  table.insert(_obj.boxes, _box)
end

function update_game_object(_obj)
  if memory.readdword(_obj.base + 0x2A0) == 0 then --invalid objects
    return false
  end

  _obj.friends = memory.readbyte(_obj.base + 0x1)
  _obj.flip_x = memory.readbytesigned(_obj.base + 0x0A) -- sprites are facing left by default
  _obj.previous_pos_x = _obj.pos_x or 0
  _obj.previous_pos_y = _obj.pos_y or 0
  _obj.pos_x = memory.readwordsigned(_obj.base + 0x64)
  _obj.pos_y = memory.readwordsigned(_obj.base + 0x68)
  _obj.char_id = memory.readword(_obj.base + 0x3C0)

  _obj.boxes = {}
  local _boxes = {
    {initial = 1, offset = 0x2D4, type = "push", number = 1},
    {initial = 1, offset = 0x2C0, type = "throwable", number = 1},
    {initial = 1, offset = 0x2A0, type = "vulnerability", number = 4},
    {initial = 1, offset = 0x2A8, type = "ext. vulnerability", number = 4},
    {initial = 1, offset = 0x2C8, type = "attack", number = 4},
    {initial = 1, offset = 0x2B8, type = "throw", number = 1}
  }

  for _, _box in ipairs(_boxes) do
    for i = _box.initial, _box.number do
      define_box(_obj, memory.readdword(_obj.base + _box.offset) + (i-1)*8, _box.type)
    end
  end
  return true
end

function update_hitboxes()
  update_game_object(player_objects[1])
  update_game_object(player_objects[2])
end

function update_framedata_recording(_player_obj)
  if debug_settings.record_framedata and is_in_match then
    record_framedata(_player_obj)
  else
    reset_current_recording_animation()
  end
end

function find_wake_up(_char_str, _wakeup_animation, _last_act_animation)
  local _wakeup = frame_data[_char_str].wakeups[_wakeup_animation]
  if _wakeup == nil then
    return nil
  end

  if _wakeup.exceptions ~= nil then
    local _exception = _wakeup.exceptions[_last_act_animation]
    if _exception then
      return _exception.duration
    end
  end

  return _wakeup.duration
end

function insert_wake_up(_char_str, _wakeup_animation, _last_act_animation, _duration)
  local _debug = true
  local _char_frame_data = frame_data[_char_str]
  local _wakeup = _char_frame_data.wakeups[_wakeup_animation]

  if _wakeup == nil then
    _char_frame_data.dirty = true
    _char_frame_data.wakeups[_wakeup_animation] = { duration = _duration, exceptions = {} }
    _char_frame_data.wakeups[_wakeup_animation].exceptions[_last_act_animation] = { duration = _duration }
    if _debug then
      print(string.format("Inserted new wakeup \"%s\", %d", _wakeup_animation, _duration))
    end
    return true
  else
    _wakeup.exceptions = _wakeup.exceptions or {}
    if _wakeup.exceptions[_last_act_animation] == nil or _wakeup.exceptions[_last_act_animation].duration ~= _duration then
      if _wakeup.exceptions[_last_act_animation] == nil and _wakeup.duration == _duration then
        return false
      end

      _char_frame_data.dirty = true
      _wakeup.exceptions[_last_act_animation] = { duration = _duration }

      -- recompute default value
      local _durations = {}
      local _max_occurence = 0
      local _exception_count = 0
      for _i, _o in pairs(_wakeup.exceptions) do
        _exception_count = _exception_count + 1
        local _id = tostring(_o.duration)
        _durations[_id] = (_durations[_id] or 0) + 1
        _max_occurence = math.max(_max_occurence, _durations[_id])
      end
      local _final_duration = 0
      for _i, _occurences in pairs(_durations) do
        if _occurences == _max_occurence then
          _final_duration = tonumber(_i)
        end
        if _final_duration == _wakeup.duration then -- if default duration is ex-aequo, it wins
          break
        end
      end
      _wakeup.duration = _final_duration

      if _debug then
        print(string.format("Inserted new exception \"%s\" for wakeup \"%s\", %d. Default is %d",_last_act_animation, _wakeup_animation, _duration, _wakeup.duration))
      end
      return true
    end
  end
  return false
end

function update_wakeupdata_recording(_dummy_obj)
  if not is_in_match then
    return
  end
  -- moves to record to produce a complete set of wake ups:
  -- fast wake ups:
  --  Alex throw
  --  Alex HCB P
  --  Alex HCB K
  --  Oro back throw
  --  Gouki Back throw
  --  Gouki Demon flip P
  -- normal wake ups:
  --  Alex slash Ex
  --  Alex sweep
  --  Alex HCB K
  --  Alex HCB P
  --  Alex stomp
  --  Alex DPF K
  --  Alex HCharge ExK
  --  Ibuki raida
  --  Ibuki air throw
  --  Ibuki neck breaker
  --  Hugo 360 P
  --  Hugo neutral grab
  --  Hugo back breaker
  --  Oro back throw
  --  Oro HCB Px3
  --  Gouki back throw
  --  Gouki demon flip P
  --  Twelve forward, neutral and back throw

  -- Always report missing data
  if _dummy_obj.has_just_woke_up then
    local _wakeup_animation = _dummy_obj.wakeup_animation
    local _wakeup_time = _dummy_obj.wakeup_time
    local _wakeup = frame_data[_dummy_obj.char_str].wakeups[_wakeup_animation]
    local _duration = find_wake_up(_dummy_obj.char_str, _dummy_obj.wakeup_animation, _dummy_obj.wakeup_other_last_act_animation)
    if _duration == nil then
      print(string.format("Unknown wakeup animation: %s", _wakeup_animation))
    elseif _duration ~= _wakeup_time then
      print(string.format("Mismatching wakeup animation time %s: %d against default %d. last act animation: \"%s\"", _wakeup_animation, _wakeup_time, _duration, _dummy_obj.wakeup_other_last_act_animation))
    end
  end

  -- Record
  if debug_settings.record_wakeupdata then
    if _dummy_obj.has_just_woke_up then
      local _char_str = _dummy_obj.char_str
      local _animation = _dummy_obj.wakeup_animation
      local _last_act_animation = _dummy_obj.wakeup_other_last_act_animation
      local _duration = _dummy_obj.wakeup_time
      insert_wake_up(_char_str, _animation, _last_act_animation, _duration)
    end
  end
end

function update_draw_hitboxes()
  if training_settings.display_hitboxes then
    draw_hitboxes(player_objects[1].pos_x, player_objects[1].pos_y, player_objects[1].flip_x, player_objects[1].boxes)
    draw_hitboxes(player_objects[2].pos_x, player_objects[2].pos_y, player_objects[2].flip_x, player_objects[2].boxes)

    for _id, _obj in pairs(projectiles) do
      draw_hitboxes(_obj.pos_x, _obj.pos_y, _obj.flip_x, _obj.boxes)
    end
  end

  if debug_settings.show_predicted_hitbox then
    local _predicted_hit = predict_hitboxes(player, 2)
    if _predicted_hit.frame_data then
      draw_hitboxes(_predicted_hit.pos_x, _predicted_hit.pos_y, player.flip_x, _predicted_hit.frame_data.boxes)
    end
  end

  local _debug_frame_data = frame_data[debug_settings.debug_character]
  if _debug_frame_data then
    local _debug_move = _debug_frame_data[debug_settings.debug_move]
    if _debug_move then
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

function game_to_screen_space(_x, _y)
  local _px = _x - screen_x + emu.screenwidth()/2
  local _py = emu.screenheight() - (_y - screen_y) - ground_offset
  return _px, _py
end

printed_geometry = {}

function print_hitboxes(_pos_x, _pos_y, _flip_x, _boxes, _filter, _dilation)
  local _g = {
    type = "hitboxes",
    x = _pos_x,
    y = _pos_y,
    flip_x = _flip_x,
    boxes = _boxes,
    filter = _filter,
    dilation = _dilation
  }
  table.insert(printed_geometry, _g)
end

function print_point(_pos_x, _pos_y, _color)
  local _g = {
    type = "point",
    x = _pos_x,
    y = _pos_y,
    color = _color
  }
  table.insert(printed_geometry, _g)
end

function draw_hitboxes(_pos_x, _pos_y, _flip_x, _boxes, _filter, _dilation)
  _dilation = _dilation or 0
  local _px, _py = game_to_screen_space(_pos_x, _pos_y)

  for __, _box in ipairs(_boxes) do
    if _filter == nil or _filter[_box.type] == true then
      local _c = 0x0000FFFF
      if (_box.type == "attack") then
        _c = 0xFF0000FF
      elseif (_box.type == "throwable") then
        _c = 0x00FF00FF
      elseif (_box.type == "throw") then
        _c = 0xFFFF00FF
      elseif (_box.type == "push") then
        _c = 0xFF00FFFF
      elseif (_box.type == "ext. vulnerability") then
        _c = 0x00FFFFFF
      end

      local _l, _r
      if _flip_x == 0 then
        _l = _px + _box.left
      else
        _l = _px - _box.left - _box.width
      end
      local _r = _l + _box.width
      local _b = _py - _box.bottom
      local _t = _b - _box.height

      _l = _l - _dilation
      _r = _r + _dilation
      _b = _b + _dilation
      _t = _t - _dilation

      gui.box(_l, _b, _r, _t, 0x00000000, _c)
    end
  end
end

function draw_point(_x, _y, _color)
  local _cross_half_size = 4
  local _l = _x - _cross_half_size
  local _r = _x + _cross_half_size
  local _t = _y - _cross_half_size
  local _b = _y + _cross_half_size

  gui.box(_l, _y, _r, _y, 0x00000000, _color)
  gui.box(_x, _t, _x, _b, 0x00000000, _color)
end

function test_collision(_defender_x, _defender_y, _defender_flip_x, _defender_boxes, _attacker_x, _attacker_y, _attacker_flip_x, _attacker_boxes, _box_type_matches, _defender_hurtbox_dilation, _attacker_hitbox_dilation)

  local _debug = false
  if (_defender_hurtbox_dilation == nil) then _defender_hurtbox_dilation = 0 end
  if (_attacker_hitbox_dilation == nil) then _attacker_hitbox_dilation = 0 end
  if (_test_throws == nil) then _test_throws = false end
  if (_box_type_matches == nil) then _box_type_matches = {{{"vulnerability", "ext. vulnerability"}, {"attack"}}} end

  if (#_box_type_matches == 0 ) then return false end
  if (#_defender_boxes == 0 ) then return false end
  if (#_attacker_boxes == 0 ) then return false end

  if _debug then print(string.format("   %d defender boxes, %d attacker boxes", #_defender_boxes, #_attacker_boxes)) end

  for k = 1, #_box_type_matches do
    local _box_type_match = _box_type_matches[k]
    for i = 1, #_defender_boxes do
      local _d_box = _defender_boxes[i]

      --print("d ".._d_box.type)

      local _defender_box_match = false
      for _key, _value in ipairs(_box_type_match[1]) do
        if _value == _d_box.type then
          _defender_box_match = true
          break
        end
      end

      if _defender_box_match then
        -- compute defender box bounds
        local _d_l
        if _defender_flip_x == 0 then
          _d_l = _defender_x + _d_box.left
        else
          _d_l = _defender_x - _d_box.left - _d_box.width
        end
        local _d_r = _d_l + _d_box.width
        local _d_b = _defender_y + _d_box.bottom
        local _d_t = _d_b + _d_box.height

        _d_l = _d_l - _defender_hurtbox_dilation
        _d_r = _d_r + _defender_hurtbox_dilation
        _d_b = _d_b - _defender_hurtbox_dilation
        _d_t = _d_t + _defender_hurtbox_dilation

        for j = 1, #_attacker_boxes do
          local _a_box = _attacker_boxes[j]

          --print("a ".._a_box.type)

          local _attacker_box_match = false
          for _key, _value in ipairs(_box_type_match[2]) do
            if _value == _a_box.type then
              _attacker_box_match = true
              break
            end
          end
          if _attacker_box_match then
            -- compute attacker box bounds
            local _a_l
            if _attacker_flip_x == 0 then
              _a_l = _attacker_x + _a_box.left
            else
              _a_l = _attacker_x - _a_box.left - _a_box.width
            end
            local _a_r = _a_l + _a_box.width
            local _a_b = _attacker_y + _a_box.bottom
            local _a_t = _a_b + _a_box.height

            _a_l = _a_l - _attacker_hitbox_dilation
            _a_r = _a_r + _attacker_hitbox_dilation
            _a_b = _a_b - _attacker_hitbox_dilation
            _a_t = _a_t + _attacker_hitbox_dilation

            if _debug then print(string.format("   testing (%d,%d,%d,%d)(%s) against (%d,%d,%d,%d)(%s)", _d_t, _d_r, _d_b, _d_l, _d_box.type, _a_t, _a_r, _a_b, _a_l, _a_box.type)) end

            -- check collision
            if not (
              (_a_l >= _d_r) or
              (_a_r <= _d_l) or
              (_a_b >= _d_t) or
              (_a_t <= _d_b)
            ) then
              return true
            end
          end
        end
      end
    end
  end

  return false
end

-- POSE

function is_state_on_ground(_state, _player_obj)
  -- 0x01 is standard standing
  -- 0x02 is standard crouching
  if _state == 0x01 or _state == 0x02 then
    return true
  elseif character_specific[_player_obj.char_str].additional_standing_states ~= nil then
    for _, _standing_state in ipairs(character_specific[_player_obj.char_str].additional_standing_states) do
      if _standing_state == _state then
        return true
      end
    end
  end
end

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

function predict_object_position(_object, _frames_prediction)
  local _result = {
    _object.pos_x,
    _object.pos_y,
  }

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
    --local _px, _py = game_to_screen_space(_pos[1], _pos[2])
    --print_point(_px, _py, 0xFFFF00FF)
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

function update_blocking(_input, _player, _dummy, _mode, _style, _red_parry_hit_count)

  local _debug = false
  local _debug_block_string = false

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
  if _dummy.blocking.block_string then
    if _dummy.remaining_freeze_frames == 0 and _dummy.recovery_time == 0 and _dummy.previous_recovery_time == 1 then
      _dummy.blocking.block_string = false
      if _debug_block_string then
        print(string.format("%d - ended block string (%d, %d, %d)", frame_number, _dummy.blocking.last_attack_hit_id, _dummy.blocking.expected_attack_hit_id, _dummy.recovery_time))
      end
    end
  elseif not _dummy.blocking.wait_for_block_string then
    if ((_dummy.blocking.expected_attack_hit_id == _dummy.blocking.last_attack_hit_id or not _dummy.blocking.listening) and _dummy.is_idle and _dummy.idle_time > 20) then
      _dummy.blocking.wait_for_block_string = true
      if _debug_block_string then
        print(string.format("%d - wait for block string (%d, %d, %d)", frame_number, _dummy.blocking.expected_attack_hit_id, _dummy.blocking.last_attack_hit_id, _dummy.idle_time))
      end
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
      return
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

  -- increment hit id
  if _dummy.has_just_blocked or _dummy.has_just_parried or _dummy.has_just_been_hit or _hit_expired then
    log(_dummy.prefix, "blocking", string.format("next hit %d>%d", _dummy.blocking.last_attack_hit_id, _dummy.blocking.expected_attack_hit_id))
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

          if _predicted_hit.hit_id > _dummy.blocking.last_attack_hit_id and test_collision(
            _next_defender_pos[1], _next_defender_pos[2], _dummy.flip_x, _dummy.boxes, -- defender
            _predicted_hit.pos_x, _predicted_hit.pos_y, _player.flip_x, _predicted_hit.frame_data.boxes, -- attacker
            _box_type_matches,
            4, -- defender hitbox dilation
            _attacker_box_dilation
          ) then
            _dummy.blocking.expected_attack_animation_hit_frame = _predicted_hit.frame
            _dummy.blocking.expected_attack_hit_id = _predicted_hit.hit_id
            _dummy.blocking.should_block = true
            _dummy.blocking.has_pre_parried = false
            log(_dummy.prefix, "blocking", string.format("block in %d", _dummy.blocking.expected_attack_animation_hit_frame - _player_relevant_animation_frame))

            if _mode == 3 then -- first hit
              if not _dummy.blocking.block_string and not _dummy.blocking.wait_for_block_string then
                _dummy.blocking.should_block = false
              end
            elseif _mode == 4 then -- random
              if not _dummy.blocking.block_string then
                if  math.random() > 0.5 then
                  _dummy.blocking.should_block = false
                  if _debug then
                    print(string.format(" %d: next hit randomized out", frame_number))
                  end
                else
                  _dummy.blocking.wait_for_block_string = true
                end
              end
            end

            if _dummy.blocking.wait_for_block_string then
              _dummy.blocking.block_string = true
              _dummy.blocking.wait_for_block_string = false
              if _debug_block_string then
                print(string.format("%d - start block string", frame_number))
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
      if _projectile_obj.emitter_id ~= _dummy.id or (_projectile_obj.emitter_id == _dummy.id and _projectile_obj.is_converted) then
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
    if _dummy.blocking.listening_projectiles then
      log(_dummy.prefix, "blocking", "listening proj 0")
    end
    if _dummy.blocking.should_block_projectile then
      log(_dummy.prefix, "blocking", "block proj 0")
    end
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
          local _next_projectile_pos = predict_object_position(_projectile_obj, _frame_delta)

          if test_collision(_next_defender_pos[1], _next_defender_pos[2], _dummy.flip_x, _dummy.boxes,
          _next_projectile_pos[1] , _next_projectile_pos[2], _projectile_obj.flip_x, _projectile_obj.boxes,
          _box_type_matches,
          0, -- defender hitbox dilation
          2) then
            _dummy.blocking.should_block_projectile = true
            _dummy.blocking.has_pre_parried = false
            _dummy.blocking.projectile_hit_frame = frame_number + _i
            _dummy.blocking.expected_projectile = _projectile_obj
            log(_dummy.prefix, "blocking", string.format("block proj %s in %d", _projectile_obj.id, _i))
            break
          end
        end
      end
      if _dummy.blocking.should_block_projectile then
        break
      end
    end
  end

  if _dummy.blocking.should_block or _dummy.blocking.should_block_projectile then
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
      if _animation_frame_delta <= 2 then
        log(_dummy.prefix, "blocking", string.format("dummy block %d %d", _dummy.blocking.expected_attack_hit_id, to_bit(_dummy.blocking.should_block_projectile)))
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
    local _duration = find_wake_up(_defender.char_str, _defender.wakeup_animation, _defender.wakeup_other_last_act_animation)
    if _duration == nil then
      return
    end
    if _debug then
      print(frame_number.." - init ca (wake up)")
    end
    log(_defender.prefix, "counter_attack", "init ca (wakeup)")
    _defender.counter.attack_frame = frame_number + _duration
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
      0 -- defender hitbox dilation
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

-- RECORDING POPUS

function clear_slot()
  recording_slots[training_settings.current_recording_slot].inputs = {}
  save_training_data()
end

function open_save_popup()
  current_popup = save_recording_slot_popup
  current_popup.selected_index = 1
  save_file_name = string.gsub(dummy.char_str, "(.*)", string.upper).."_"
end

function open_load_popup()
  current_popup = load_recording_slot_popup
  current_popup.selected_index = 1

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
  load_recording_slot_popup.entries[1].list = load_file_list
end

function close_popup()
  current_popup = nil
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

  close_popup()
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
  close_popup()
end

save_file_name = ""
save_recording_slot_popup = make_popup(71, 61, 312, 122, -- screen size 383,223
{
  textfield_menu_item("File Name", _G, "save_file_name", ""),
  button_menu_item("Save", save_recording_slot_to_file),
  button_menu_item("Cancel", close_popup),
})

load_file_list = {}
load_file_index = 1
load_recording_slot_popup = make_popup(71, 61, 312, 122, -- screen size 383,223
{
  list_menu_item("File", _G, "load_file_index", load_file_list),
  button_menu_item("Load", load_recording_slot_from_file),
  button_menu_item("Cancel", close_popup),
})

-- GUI DECLARATION

training_settings = {
  pose = 1,
  blocking_style = 1,
  blocking_mode = 1,
  tech_throws_mode = 1,
  dummy_player = 2,
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
  display_p1_input_history = false,
  display_p2_input_history = false,
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
}

debug_settings = {
  show_predicted_hitbox = false,
  record_framedata = false,
  record_wakeupdata = false,
  debug_character = "",
  debug_move = "",
}

life_refill_delay_item = integer_menu_item("Life refill delay", training_settings, "life_refill_delay", 1, 100, false, 20)
life_refill_delay_item.is_disabled = function()
  return training_settings.life_mode ~= 2
end

p1_stun_reset_value_gauge_item = gauge_menu_item("P1 Stun reset value", training_settings, "p1_stun_reset_value", 0x10000, 0xFF0000FF)
p2_stun_reset_value_gauge_item = gauge_menu_item("P2 Stun reset value", training_settings, "p2_stun_reset_value", 0x10000, 0xFF0000FF)
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

hits_before_red_parry_item = integer_menu_item("Hits before Red Parry", training_settings, "red_parry_hit_count", 1, 20, true)
hits_before_red_parry_item.is_disabled = function()
  return training_settings.blocking_style ~= 3
end

menu = {
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
      checkbox_menu_item("Display P1 Input logs", training_settings, "display_p1_input_history"),
      checkbox_menu_item("Display P2 Input logs", training_settings, "display_p2_input_history"),
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
      parry_antiair_on_item
    }
  },
}

debug_move_menu_item = map_menu_item("Debug Move", debug_settings, "debug_move", frame_data, nil)
if developer_mode then
  local _debug_settings_menu = {
    name = "Debug",
    entries = {
      checkbox_menu_item("Show Predicted Hitboxes", debug_settings, "show_predicted_hitbox"),
      checkbox_menu_item("Record Frame Data", debug_settings, "record_framedata"),
      checkbox_menu_item("Record Wake-Up Data", debug_settings, "record_wakeupdata"),
      button_menu_item("Save Frame Data", save_frame_data),
      map_menu_item("Debug Character", debug_settings, "debug_character", _G, "frame_data"),
      debug_move_menu_item
    }
  }
  table.insert(menu, _debug_settings_menu)
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

function read_game_vars()
  -- frame number
  frame_number = memory.readdword(0x02007F00)

  -- is in match
  -- I believe the bytes that are expected to be 0xff means that a character has been locked, while the byte expected to be 0x02 is the current match state. 0x02 means that round has started and players can move
  local p1_locked = memory.readbyte(0x020154C6);
  local p2_locked = memory.readbyte(0x020154C8);
  local match_state = memory.readbyte(0x020154A7);
  is_in_match = ((p1_locked == 0xFF or p2_locked == 0xFF) and match_state == 0x02);

  -- screen stuff
  screen_x = memory.readwordsigned(0x02026CB0)
  screen_y = memory.readwordsigned(0x02026CB4)
  scale = memory.readwordsigned(0x0200DCBA) --FBA can't read from 04xxxxxx
  scale = 0x40/(scale > 0 and scale or 1)
  ground_offset = 23
end

function write_game_vars()

  -- freeze game
  if is_menu_open then
    memory.writebyte(0x0201136F, 0xFF)
  else
    memory.writebyte(0x0201136F, 0x00)
  end

  -- timer
  if training_settings.infinite_time then
    memory.writebyte(0x02011377, 100)
  end

  -- music
  memory.writebyte(0x02078D06, training_settings.music_volume * 8)
end

function update_object_velocity(_object, _debug)
  _debug = _debug or false
  -- VELOCITY & ACCELERATION
  local _velocity_frame_sampling_count = 10

  _object.pos_samples = _object.pos_samples or {}
  _object.velocity_samples = _object.velocity_samples or {}

  if _object.remaining_freeze_frames > 0 then
    return
  end

  local _pos = { x = _object.pos_x, y = _object.pos_y }
  table.insert(_object.pos_samples, _pos)
  while #_object.pos_samples > _velocity_frame_sampling_count do
    table.remove(_object.pos_samples, 1)
  end
  local _velocity = {
    x = (_pos.x - _object.pos_samples[1].x) / #_object.pos_samples,
    y = (_pos.y - _object.pos_samples[1].y) / #_object.pos_samples,
  }

  table.insert(_object.velocity_samples, _velocity)
  while #_object.velocity_samples > _velocity_frame_sampling_count do
    table.remove(_object.velocity_samples, 1)
  end
  _object.acc = {
    x = (_velocity.x - _object.velocity_samples[1].x) / #_object.velocity_samples,
    y = (_velocity.y - _object.velocity_samples[1].y) / #_object.velocity_samples,
  }
end

function read_projectiles()
  local _MAX_OBJECTS = 30
  projectiles_count = projectiles_count or 0
  projectiles = projectiles or {}

  -- flag everything as expired by default, we will reset the flag it we update the projectile
  for _id, _obj in pairs(projectiles) do
    _obj.expired = true
  end

  -- how we recover hitboxes data for each projectile is taken almost as is from the cps3-hitboxes.lua script
  --object = {initial = 0x02028990, index = 0x02068A96},
  local _index = 0x02068A96
  local _initial = 0x02028990
  local _list = 3
  local _obj_index = memory.readwordsigned(_index + (_list * 2))

  local _obj_slot = 1
  while _obj_slot <= _MAX_OBJECTS and _obj_index ~= -1 do
    local _base = _initial + bit.lshift(_obj_index, 11)
    local _id = string.format("%08X", _base)
    local _obj = projectiles[_id]
    local _is_initialization = false
    if _obj == nil then
       _obj = {base = _base, projectile = _obj_slot}
       _obj.id = _id
       _obj.is_forced_one_hit = true
       _is_initialization = true
    end
    if update_game_object(_obj) then
      if _is_initialization then
        _obj.initial_flip_x = _obj.flip_x
      end

      _obj.expired = false
      _obj.emitter_id = memory.readbyte(_obj.base + 0x2) + 1
      _obj.is_converted = _obj.flip_x ~= _obj.initial_flip_x
      _obj.previous_remaining_hits = _obj.remaining_hits or 0
      _obj.remaining_hits = memory.readbyte(_obj.base + 0x9C + 2)
      if _obj.remaining_hits > 0 then
        _obj.is_forced_one_hit = false
      end
      --_obj.remaining_hits2 = memory.readbyte(_obj.base + 0x49 + 0) -- Looks like attack validity or whatever
      _obj.projectile_type = string.format("%02X", memory.readbyte(_obj.base + 0x91))
      _obj.remaining_freeze_frames = memory.readbyte(_obj.base + 0x45)
      if projectiles[_obj.id] == nil then
        log(player_objects[_obj.emitter_id].prefix, "projectiles", string.format("projectile %s 1", _obj.id))
      end
      projectiles[_obj.id] = _obj
    end

    -- Get the index to the next object in this list.
    _obj_index = memory.readwordsigned(_obj.base + 0x1C)
    _obj_slot = _obj_slot + 1
  end

  -- if a projectile is still expired, we remove it
  projectiles_count = 0
  for _id, _obj in pairs(projectiles) do
    if _obj.expired then
      log(player_objects[_obj.emitter_id].prefix, "projectiles", string.format("projectile %s 0", _id))
      projectiles[_id] = nil
    else
      projectiles_count = projectiles_count + 1
    end
  end

  -- now the list is clean, let's do stuff
  for _id, _obj in pairs(projectiles) do
    update_object_velocity(_obj, true)
  end
end

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

function read_player_vars(_player_obj)

-- P1: 0x02068C6C
-- P2: 0x02069104

  if memory.readdword(_player_obj.base + 0x2A0) == 0 then --invalid objects
    return
  end

  local _debug_state_variables = _player_obj.debug_state_variables

  update_input(_player_obj)

  local _prev_pos_x = _player_obj.pos_x or 0
  local _prev_pos_y = _player_obj.pos_y or 0

  update_game_object(_player_obj)

  local _previous_movement_type = _player_obj.movement_type or 0

  local _previous_char_str = _player_obj.char_str or ""
  _player_obj.char_str = characters[_player_obj.char_id]
  if _player_obj == player_objects[training_settings.dummy_player] and _previous_char_str ~= _player_obj.char_str then
    restore_recordings()
  end

  local _previous_remaining_freeze_frames = _player_obj.remaining_freeze_frames or 0
  _player_obj.remaining_freeze_frames = memory.readbyte(_player_obj.base + 0x45)
  _player_obj.freeze_type = 0
  if _player_obj.remaining_freeze_frames ~= 0 then
    if _player_obj.remaining_freeze_frames < 127 then
      -- inflicted freeze I guess (when the opponent parry you for instance)
      _player_obj.freeze_type = 1
      _player_obj.remaining_freeze_frames = _player_obj.remaining_freeze_frames
    else
      _player_obj.freeze_type = 2
      _player_obj.remaining_freeze_frames = 256 - _player_obj.remaining_freeze_frames
    end
  end
  local _remaining_freeze_frame_diff = _player_obj.remaining_freeze_frames - _previous_remaining_freeze_frames
  if _remaining_freeze_frame_diff > 0 then
    log(_player_obj.prefix, "fight", string.format("freeze %d", _player_obj.remaining_freeze_frames))
    --print(string.format("%d: %d(%d)",  _player_obj.id, _player_obj.remaining_freeze_frames, _player_obj.freeze_type))
  end

  _player_obj.is_attacking_ext = memory.readbyte(_player_obj.base + 0x429) > 0
  _player_obj.input_capacity = memory.readword(_player_obj.base + 0x46C)
  _player_obj.action = memory.readdword(_player_obj.base + 0xAC)
  _player_obj.action_ext = memory.readdword(_player_obj.base + 0x12C)
  _player_obj.previous_recovery_time = _player_obj.recovery_time or 0
  _player_obj.recovery_time = memory.readbyte(_player_obj.base + 0x187)
  _player_obj.movement_type = memory.readbyte(_player_obj.base + 0x0AD)
  _player_obj.total_received_projectiles_count = memory.readword(_player_obj.base + 0x430) -- on block or hit

  if _player_obj.id == 1 then
    _player_obj.max_meter_gauge = memory.readbyte(0x020695B3)
    _player_obj.max_meter_count = memory.readbyte(0x020695BD)
    _player_obj.selected_sa = memory.readbyte(0x0201138B) + 1
    _player_obj.superfreeze_decount = memory.readbyte(0x02069520) -- seems to be in P2 memory space, don't know why

    training_settings.p1_meter = math.min(training_settings.p1_meter, _player_obj.max_meter_count * _player_obj.max_meter_gauge)
    p1_meter_gauge_item.gauge_max = _player_obj.max_meter_gauge * _player_obj.max_meter_count
    p1_meter_gauge_item.subdivision_count = _player_obj.max_meter_count
  else
    _player_obj.max_meter_gauge = memory.readbyte(0x020695DF)
    _player_obj.max_meter_count = memory.readbyte(0x020695E9)
    _player_obj.selected_sa = memory.readbyte(0x0201138C) + 1
    _player_obj.superfreeze_decount = memory.readbyte(0x02069088) -- seems to be in P1 memory space, don't know why

    training_settings.p2_meter = math.min(training_settings.p2_meter, _player_obj.max_meter_count * _player_obj.max_meter_gauge)
    p2_meter_gauge_item.gauge_max = _player_obj.max_meter_gauge * _player_obj.max_meter_count
    p2_meter_gauge_item.subdivision_count = _player_obj.max_meter_count
  end

  -- THROW
  _player_obj.throw_countdown = _player_obj.throw_countdown or 0
  _player_obj.previous_throw_countdown = _player_obj.throw_countdown

  local _throw_countdown = memory.readbyte(_player_obj.base + 0x434)
  if _throw_countdown > _player_obj.previous_throw_countdown then
    _player_obj.throw_countdown = _throw_countdown + 2 -- air throw animations seems to not match the countdown (ie. Ibuki's Air Throw), let's add a few frames to it
  else
    _player_obj.throw_countdown = math.max(_player_obj.throw_countdown - 1, 0)
  end

  if _player_obj.debug_freeze_frames and _player_obj.remaining_freeze_frames > 0 then print(string.format("%d - %d remaining freeze frames", frame_number, _player_obj.remaining_freeze_frames)) end

  update_object_velocity(_player_obj)

  -- ATTACKING
  local _previous_is_attacking = _player_obj.is_attacking or false
  _player_obj.is_attacking = memory.readbyte(_player_obj.base + 0x428) > 0
  _player_obj.has_just_attacked =  _player_obj.is_attacking and not _previous_is_attacking
  if _debug_state_variables and _player_obj.has_just_attacked then print(string.format("%d - %s attacked", frame_number, _player_obj.prefix)) end

  -- ACTION
  local _previous_action_count = _player_obj.action_count or 0
  _player_obj.action_count = memory.readbyte(_player_obj.base + 0x459)
  _player_obj.has_just_acted = _player_obj.action_count > _previous_action_count
  if _debug_state_variables and _player_obj.has_just_acted then print(string.format("%d - %s acted (%d > %d)", frame_number, _player_obj.prefix, _previous_action_count, _player_obj.action_count)) end

  -- LANDING
  _player_obj.previous_standing_state = _player_obj.standing_state or 0
  _player_obj.standing_state = memory.readbyte(_player_obj.base + 0x297)
  _player_obj.has_just_landed = is_state_on_ground(_player_obj.standing_state, _player_obj) and not is_state_on_ground(_player_obj.previous_standing_state, _player_obj)
  if _debug_state_variables and _player_obj.has_just_landed then print(string.format("%d - %s landed (%d > %d)", frame_number, _player_obj.prefix, _player_obj.previous_standing_state, _player_obj.standing_state)) end
  if _player_obj.debug_standing_state and _player_obj.previous_standing_state ~= _player_obj.standing_state then print(string.format("%d - %s standing state changed (%d > %d)", frame_number, _player_obj.prefix, _player_obj.previous_standing_state, _player_obj.standing_state)) end

  -- AIR RECOVERY STATE
  local _debug_air_recovery = false
  local _previous_is_in_air_recovery = _player_obj.is_in_air_recovery or false
  local _r1 = memory.readbyte(_player_obj.base + 0x12F)
  local _r2 = memory.readbyte(_player_obj.base + 0x3C7)
  _player_obj.is_in_air_recovery = _player_obj.standing_state == 0 and _r1 == 0 and _r2 == 0x06 and _player_obj.pos_y ~= 0
  _player_obj.has_just_entered_air_recovery = not _previous_is_in_air_recovery and _player_obj.is_in_air_recovery

  if not _previous_is_in_air_recovery and _player_obj.is_in_air_recovery then
    log(_player_obj.prefix, "fight", string.format("air recovery 1"))
    if _debug_air_recovery then
      print(string.format("%s entered air recovery", _player_obj.prefix))
    end
  end
  if _previous_is_in_air_recovery and not _player_obj.is_in_air_recovery then
    log(_player_obj.prefix, "fight", string.format("air recovery 0"))
    if _debug_air_recovery then
      print(string.format("%s exited air recovery", _player_obj.prefix))
    end
  end

  -- IS IDLE
  _player_obj.idle_time = _player_obj.idle_time or 0
  _player_obj.is_idle = (
    not _player_obj.is_attacking and
    not _player_obj.is_attacking_ext and
    not _player_obj.is_blocking and
    not _player_obj.is_wakingup and
    not _player_obj.is_fast_wakingup and
    _player_obj.recovery_time == _player_obj.previous_recovery_time and
    _player_obj.remaining_freeze_frames == 0 and
    _player_obj.input_capacity > 0
  )

  if _player_obj.is_idle then
    _player_obj.idle_time = _player_obj.idle_time + 1
  else
    _player_obj.idle_time = 0
  end

  -- ANIMATION
  local _self_cancel = false
  local _previous_animation = _player_obj.animation or ""
  _player_obj.animation = bit.tohex(memory.readword(_player_obj.base + 0x202), 4)
  _player_obj.has_animation_just_changed = _previous_animation ~= _player_obj.animation
  if not _player_obj.has_animation_just_changed and not debug_settings.record_framedata then -- no self cancel handling if we record animations, this can lead to tenacious ill formed frame data in the database
    if (frame_data[_player_obj.char_str] and frame_data[_player_obj.char_str][_player_obj.animation]) then
      local _all_hits_done = true
      local _frame = frame_number - _player_obj.current_animation_start_frame - _player_obj.current_animation_freeze_frames
      for __, _hit_frame in ipairs(frame_data[_player_obj.char_str][_player_obj.animation].hit_frames) do
        local _last_hit_frame = 0
        if type(_hit_frame) == "number" then
          _last_hit_frame = _hit_frame
        else
          _last_hit_frame = _hit_frame.max
        end

        if _frame <= _last_hit_frame then
          _all_hits_done = false
          break
        end
      end
      if _player_obj.has_just_attacked and _all_hits_done then
        _player_obj.has_animation_just_changed = true
        _self_cancel = true
        log(_player_obj.prefix, "blocking", string.format("self cancel"))
      end
    end
  end

  if _player_obj.has_animation_just_changed then
    _player_obj.current_animation_start_frame = frame_number
    _player_obj.current_animation_freeze_frames = 0
  end
  if _debug_state_variables and _player_obj.has_animation_just_changed then print(string.format("%d - %s animation changed (%s -> %s)", frame_number, _player_obj.prefix, _previous_animation, _player_obj.animation)) end

  -- special case for animations that introduce animations that hit at frame 0 (Alex's VChargeK for instance)
  -- Note: It's unlikely that intro animation will ever have freeze frames, so I don't think we need to handle that
  local _previous_relevant_animation = _player_obj.relevant_animation or ""
  if _player_obj.has_animation_just_changed then
    _player_obj.relevant_animation = _player_obj.animation
    _player_obj.relevant_animation_start_frame = _player_obj.current_animation_start_frame
    if frame_data_meta[_player_obj.char_str] and frame_data_meta[_player_obj.char_str].moves[_player_obj.animation] and frame_data_meta[_player_obj.char_str].moves[_player_obj.animation].proxy then
      _player_obj.relevant_animation = frame_data_meta[_player_obj.char_str].moves[_player_obj.animation].proxy.id
      _player_obj.relevant_animation_start_frame = _player_obj.current_animation_start_frame -
       frame_data_meta[_player_obj.char_str].moves[_player_obj.animation].proxy.offset
    end
  end
  _player_obj.has_relevant_animation_just_changed = _self_cancel or _player_obj.relevant_animation ~= _previous_relevant_animation

  if _player_obj.has_relevant_animation_just_changed then
    _player_obj.relevant_animation_freeze_frames = 0
  end
  if _debug_state_variables and _player_obj.has_relevant_animation_just_changed then print(string.format("%d - %s relevant animation changed (%s -> %s)", frame_number, _player_obj.prefix, _previous_relevant_animation, _player_obj.relevant_animation)) end

  if _player_obj.remaining_freeze_frames > 0 then
    _player_obj.current_animation_freeze_frames = _player_obj.current_animation_freeze_frames + 1
    _player_obj.relevant_animation_freeze_frames = _player_obj.relevant_animation_freeze_frames + 1
  end

  _player_obj.animation_frame_id = memory.readword(_player_obj.base + 0x21A)
  _player_obj.animation_frame = frame_number - _player_obj.current_animation_start_frame - _player_obj.current_animation_freeze_frames
  _player_obj.relevant_animation_frame = frame_number - _player_obj.relevant_animation_start_frame - _player_obj.relevant_animation_freeze_frames

  _player_obj.relevant_animation_frame_data = nil
  if frame_data[_player_obj.char_str] then
    _player_obj.relevant_animation_frame_data = frame_data[_player_obj.char_str][_player_obj.relevant_animation]
  end

  _player_obj.highest_hit_id = 0
  _player_obj.next_hit_id = 0
  if _player_obj.relevant_animation_frame_data ~= nil then

    -- Resync animation
    if _player_obj.relevant_animation_frame >= 0
    and _player_obj.remaining_freeze_frames == 0
    and _player_obj.relevant_animation_frame_data.frames[_player_obj.relevant_animation_frame + 1] ~= nil
    and _player_obj.relevant_animation_frame_data.frames[_player_obj.relevant_animation_frame + 1].frame_id ~= nil
    and _player_obj.relevant_animation_frame_data.frames[_player_obj.relevant_animation_frame + 1].frame_id ~= _player_obj.animation_frame_id
    then
      local _frame_count =  #_player_obj.relevant_animation_frame_data.frames
      local _resync_range_begin = -1
      local _resync_range_end = -1
      local _resync_target = -1

      for _i = 1, _frame_count do
        local _frame_index = _i
        local _frame = _player_obj.relevant_animation_frame_data.frames[_frame_index]
        if _frame.frame_id == _player_obj.animation_frame_id then
          if _resync_range_begin == -1 then
            _resync_range_begin = _frame_index
          end
          _resync_range_end = _frame_index
        end
      end

      -- if behind, always go th the range begin, else go at end unless it has been wrapping
      if _resync_range_begin >= 0 then
        if _player_obj.relevant_animation_frame < _resync_range_begin then
          _resync_target = _resync_range_begin
        else
          local _delta = math.abs(_player_obj.relevant_animation_frame - _resync_range_end)
          if _delta > _frame_count * 0.5 then
            _resync_target = _resync_range_begin
          else
            _resync_target = _resync_range_end
          end
        end
      end

      if _resync_target >= 0 then
        log(_player_obj.prefix, "animation", string.format("resynced %s (%d->%d)", _player_obj.relevant_animation, _player_obj.relevant_animation_frame, (_resync_target - 1)))
        if _player_obj.debug_animation_frames then
          print(string.format("%d: resynced anim %s from frame %d to %d (%d -> %d)", frame_number, _player_obj.relevant_animation, _player_obj.relevant_animation_frame_data.frames[_player_obj.relevant_animation_frame + 1].frame_id, _frame.frame_id, _player_obj.relevant_animation_frame, (_resync_target - 1)))
        end

        _player_obj.relevant_animation_frame = (_resync_target - 1)
        _player_obj.relevant_animation_start_frame = frame_number - (_resync_target - 1 + _player_obj.relevant_animation_freeze_frames)
      end
    end

    -- find current attack id
    for _index, _hit_frame in ipairs(_player_obj.relevant_animation_frame_data.hit_frames) do
      if type(_hit_frame) == "number" then

        if _player_obj.relevant_animation_frame >= _hit_frame then
          _player_obj.highest_hit_id = _index
        end
      else
        if _player_obj.relevant_animation_frame >= _hit_frame.min then
          _player_obj.highest_hit_id = _index
        end
      end
    end

    for _index = #_player_obj.relevant_animation_frame_data.hit_frames, 1, -1 do
      local _hit_frame = _player_obj.relevant_animation_frame_data.hit_frames[_index]
      if type(_hit_frame) == "number" then
        if _player_obj.relevant_animation_frame <= _hit_frame then
          _player_obj.next_hit_id = _index
        end
      else
        if _player_obj.relevant_animation_frame <= _hit_frame.max then
          _player_obj.next_hit_id = _index
        end
      end
    end

    if _player_obj.debug_animation_frames then
      print(string.format("%d - %d, %d, %d, %d", frame_number, _player_obj.relevant_animation_frame, _player_obj.remaining_freeze_frames, _player_obj.animation_frame_id, _player_obj.highest_hit_id))
    end
  end
  if _player_obj.has_just_acted then
    _player_obj.last_act_animation = _player_obj.animation
  end

  -- RECEIVED HITS/BLOCKS/PARRYS
  local _previous_total_received_hit_count = _player_obj.total_received_hit_count or nil
  _player_obj.total_received_hit_count = memory.readword(_player_obj.base + 0x33E)
  local _total_received_hit_count_diff = 0
  if _previous_total_received_hit_count then
    if _previous_total_received_hit_count == 0xFFFF then
      _total_received_hit_count_diff = 1
    else
      _total_received_hit_count_diff = _player_obj.total_received_hit_count - _previous_total_received_hit_count
    end
  end

  local _previous_received_connection_marker = _player_obj.received_connection_marker or 0
  _player_obj.received_connection_marker = memory.readword(_player_obj.base + 0x32E)
  _player_obj.received_connection = _previous_received_connection_marker == 0 and _player_obj.received_connection_marker ~= 0

  _player_obj.last_movement_type_change_frame = _player_obj.last_movement_type_change_frame or 0
  if _player_obj.movement_type ~= _previous_movement_type then
    _player_obj.last_movement_type_change_frame = frame_number
  end

  -- is blocking/has just blocked/has just been hit/has_just_parried
  _player_obj.blocking_id = memory.readbyte(_player_obj.base + 0x3D3)
  _player_obj.has_just_blocked = false
  if _player_obj.received_connection and _player_obj.received_connection_marker ~= 0xFFF1 and _total_received_hit_count_diff == 0 then --0xFFF1 is parry
    _player_obj.has_just_blocked = true
    log(_player_obj.prefix, "fight", "block")
    if _debug_state_variables then
      print(string.format("%d - %s blocked", frame_number, _player_obj.prefix))
    end
  end
  _player_obj.is_blocking = _player_obj.blocking_id > 0 and _player_obj.blocking_id < 5 or _player_obj.has_just_blocked

  _player_obj.has_just_been_hit = false
  if _total_received_hit_count_diff > 0 then
    _player_obj.has_just_been_hit = true
    log(_player_obj.prefix, "fight", "hit")
  end

  _player_obj.has_just_parried = false
  if _player_obj.received_connection and _player_obj.received_connection_marker == 0xFFF1 and _total_received_hit_count_diff == 0 then
    _player_obj.has_just_parried = true
    log(_player_obj.prefix, "fight", "parry")
    if _debug_state_variables then print(string.format("%d - %s parried", frame_number, _player_obj.prefix)) end
  end

  -- HITS
  local _previous_hit_count = _player_obj.hit_count or 0
  _player_obj.hit_count = memory.readbyte(_player_obj.base + 0x189)
  _player_obj.has_just_hit = _player_obj.hit_count > _previous_hit_count
  if _player_obj.has_just_hit then
    log(_player_obj.prefix, "fight", "has hit")
    if _debug_state_variables then
      print(string.format("%d - %s hit (%d > %d)", frame_number, _player_obj.prefix, _previous_hit_count, _player_obj.hit_count))
    end
  end

  -- BLOCKS
  local _previous_connected_action_count = _player_obj.connected_action_count or 0
  local _previous_blocked_count = _previous_connected_action_count - _previous_hit_count
  _player_obj.connected_action_count = memory.readbyte(_player_obj.base + 0x17B)
  local _blocked_count = _player_obj.connected_action_count - _player_obj.hit_count
  _player_obj.has_just_been_blocked = _blocked_count > _previous_blocked_count
  if _debug_state_variables and _player_obj.has_just_been_blocked then print(string.format("%d - %s blocked (%d > %d)", frame_number, _player_obj.prefix, _previous_blocked_count, _blocked_count)) end

  if is_in_match then

    -- WAKE UP
    _player_obj.previous_can_fast_wakeup = _player_obj.can_fast_wakeup or 0
    _player_obj.can_fast_wakeup = memory.readbyte(_player_obj.base + 0x402)

    local _previous_fast_wakeup_flag = _player_obj.fast_wakeup_flag or 0
    _player_obj.fast_wakeup_flag = memory.readbyte(_player_obj.base + 0x403)

    local _previous_is_flying_down_flag = _player_obj.is_flying_down_flag or 0
    _player_obj.is_flying_down_flag = memory.readbyte(_player_obj.base + 0x8D) -- does not reset to 0 after air reset landings, resets to 0 after jump start

    _player_obj.previous_is_wakingup = _player_obj.is_wakingup or false
    _player_obj.is_wakingup = _player_obj.is_wakingup or false
    _player_obj.wakeup_time = _player_obj.wakeup_time or 0
    if _previous_is_flying_down_flag == 1 and _player_obj.is_flying_down_flag == 0 and _player_obj.standing_state == 0 and
      (
        _player_obj.movement_type ~= 2 -- movement type 2 is hugo's running grab
        and _player_obj.movement_type ~= 5 -- movement type 5 is ryu's reversal DP on landing
      ) then
      _player_obj.is_wakingup = true
      _player_obj.wakeup_time = 0
      _player_obj.wakeup_animation = _player_obj.animation
      if debug_wakeup then
        print(string.format("%d - %s wakeup started", frame_number, _player_obj.prefix))
      end
    end

    _player_obj.previous_is_fast_wakingup = _player_obj.is_fast_wakingup or false
    _player_obj.is_fast_wakingup = _player_obj.is_fast_wakingup or false
    if _player_obj.is_wakingup and _previous_fast_wakeup_flag == 1 and _player_obj.fast_wakeup_flag == 0 then
      _player_obj.is_fast_wakingup = true
      _player_obj.wakeup_time = 0
      _player_obj.wakeup_animation = _player_obj.animation
      if debug_wakeup then
        print(string.format("%d - %s fast wakeup started", frame_number, _player_obj.prefix))
      end
    end

    if _player_obj.is_wakingup then
      _player_obj.wakeup_time = _player_obj.wakeup_time + 1
    end

    if _player_obj.is_wakingup and _player_obj.previous_standing_state == 0x00 and (_player_obj.standing_state ~= 0x00 or _player_obj.is_attacking) then
      if debug_wakeup then
        print(string.format("%d - %s wake up: %d, %s, %d", frame_number, _player_obj.prefix, to_bit(_player_obj.is_fast_wakingup), _player_obj.wakeup_animation, _player_obj.wakeup_time))
      end
      _player_obj.is_wakingup = false
      _player_obj.is_fast_wakingup = false
    end

    _player_obj.has_just_started_wake_up = not _player_obj.previous_is_wakingup and _player_obj.is_wakingup
    _player_obj.has_just_started_fast_wake_up = not _player_obj.previous_is_fast_wakingup and _player_obj.is_fast_wakingup
    _player_obj.has_just_woke_up = _player_obj.previous_is_wakingup and not _player_obj.is_wakingup

    if _player_obj.has_just_started_wake_up then
      log(_player_obj.prefix, "fight", string.format("wakeup 1"))
    end
    if _player_obj.has_just_started_fast_wake_up then
      log(_player_obj.prefix, "fight", string.format("fwakeup 1"))
    end
    if _player_obj.has_just_woke_up then
      log(_player_obj.prefix, "fight", string.format("wakeup 0"))
    end
  end

  -- TIMED SA
  if character_specific[_player_obj.char_str].timed_sa[_player_obj.selected_sa] then
    if _player_obj.superfreeze_decount > 0 then
      _player_obj.is_in_timed_sa = true
    elseif _player_obj.is_in_timed_sa and memory.readbyte(_player_obj.gauge_addr) == 0 then
      _player_obj.is_in_timed_sa = false
    end
  else
    _player_obj.is_in_timed_sa = false
  end

  -- PARRY BUFFERS
  -- global game consts
  _player_obj.parry_forward = _player_obj.parry_forward or { name = "FORWARD", max_validity = 10, max_cooldown = 23 }
  _player_obj.parry_down = _player_obj.parry_down or { name = "DOWN", max_validity = 10, max_cooldown = 23 }
  _player_obj.parry_air = _player_obj.parry_air or { name = "AIR", max_validity = 7, max_cooldown = 20 }
  _player_obj.parry_antiair = _player_obj.parry_antiair or { name = "ANTI-AIR", max_validity = 5, max_cooldown = 18 }

  function read_parry_state(_parry_object, _validity_addr, _cooldown_addr)
    -- read data
    _parry_object.last_hit_or_block_frame =  _parry_object.last_hit_or_block_frame or 0
    if _player_obj.has_just_blocked or _player_obj.has_just_been_hit then
      _parry_object.last_hit_or_block_frame = frame_number
    end
    _parry_object.last_validity_start_frame = _parry_object.last_validity_start_frame or 0
    local _previous_validity_time = _parry_object.validity_time or 0
    _parry_object.validity_time = memory.readbyte(_validity_addr)
    _parry_object.cooldown_time = memory.readbyte(_cooldown_addr)
    if _parry_object.cooldown_time == 0xFF then _parry_object.cooldown_time = 0 end
    if _previous_validity_time == 0 and _parry_object.validity_time ~= 0 then
      _parry_object.last_validity_start_frame = frame_number
      _parry_object.delta = nil
      _parry_object.success = nil
      _parry_object.armed = true
      log(_player_obj.prefix, "parry_training_".._parry_object.name, "armed")
    end

    -- check success/miss
    if _parry_object.armed then
      if _player_obj.has_just_parried then
        -- right
        _parry_object.delta = frame_number - _parry_object.last_validity_start_frame
        _parry_object.success = true
        _parry_object.armed = false
        _parry_object.last_hit_or_block_frame = 0
        log(_player_obj.prefix, "parry_training_".._parry_object.name, "success")
      elseif _parry_object.last_validity_start_frame == frame_number - 1 and (frame_number - _parry_object.last_hit_or_block_frame) < 20 then
        local _delta = _parry_object.last_hit_or_block_frame - frame_number + 1
        if _parry_object.delta == nil or math.abs(_parry_object.delta) > math.abs(_delta) then
          _parry_object.delta = _delta
          _parry_object.success = false
        end
        log(_player_obj.prefix, "parry_training_".._parry_object.name, "late")
      elseif _player_obj.has_just_blocked or _player_obj.has_just_been_hit then
        local _delta = frame_number - _parry_object.last_validity_start_frame
        if _parry_object.delta == nil or math.abs(_parry_object.delta) > math.abs(_delta) then
          _parry_object.delta = _delta
          _parry_object.success = false
        end
        log(_player_obj.prefix, "parry_training_".._parry_object.name, "early")
      end
    end
    if frame_number - _parry_object.last_validity_start_frame > 30 and _parry_object.armed then

      _parry_object.armed = false
      _parry_object.last_hit_or_block_frame = 0
      log(_player_obj.prefix, "parry_training_".._parry_object.name, "reset")
    end
  end

  read_parry_state(_player_obj.parry_forward, _player_obj.parry_forward_validity_time_addr, _player_obj.parry_forward_cooldown_time_addr)
  read_parry_state(_player_obj.parry_down, _player_obj.parry_down_validity_time_addr, _player_obj.parry_down_cooldown_time_addr)
  read_parry_state(_player_obj.parry_air, _player_obj.parry_air_validity_time_addr, _player_obj.parry_air_cooldown_time_addr)
  read_parry_state(_player_obj.parry_antiair, _player_obj.parry_antiair_validity_time_addr, _player_obj.parry_antiair_cooldown_time_addr)

  -- STUN
  _player_obj.stun_max = bit.lshift(memory.readbyte(_player_obj.stun_max_addr) + 1, 16)
  _player_obj.stun_timer = memory.readbyte(_player_obj.stun_timer_addr)
  _player_obj.stun_bar = bit.rshift(memory.readdword(_player_obj.stun_bar_addr), 8)

  local _gauge_item = nil
  if _player_obj.id == 1 then
    _gauge_item = p1_stun_reset_value_gauge_item
    training_settings.p1_stun_reset_value = math.min(training_settings.p1_stun_reset_value, _player_obj.stun_max)
  else
    _gauge_item = p2_stun_reset_value_gauge_item
    training_settings.p2_stun_reset_value = math.min(training_settings.p2_stun_reset_value, _player_obj.stun_max)
  end
  _gauge_item.gauge_max = _player_obj.stun_max
end

function update_flip_input(_player, _other_player)
  local _debug = false
  if _player.flip_input == nil then
    _player.flip_input = _other_player.pos_x >= _player.pos_x
    return
  end

  local _previous_flip_input = _player.flip_input
  local _flip_hysteresis = 0
  local _diff = _other_player.pos_x - _player.pos_x
  if math.abs(_diff) >= _flip_hysteresis then
    _player.flip_input = _other_player.pos_x >= _player.pos_x
  end

  if _previous_flip_input ~= _player.flip_input then
    log(_player.prefix, "fight", "flip input")
  end

end

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
      _wanted_stun = math.max(_wanted_stun - 1, 0)

      if _player_obj.stun_bar < _wanted_stun then
        memory.writedword(_player_obj.stun_bar_addr, bit.lshift(_wanted_stun, 8));
      elseif _player_obj.is_idle and _player_obj.idle_time > training_settings.stun_reset_delay then
        local _stun = _player_obj.stun_bar
        _stun = math.max(_stun - 0x30000, _wanted_stun)
        memory.writedword(_player_obj.stun_bar_addr, bit.lshift(_stun, 8));
      end
    end
  end
end

function on_load_state()
  reset_player_objects()
  read_player_vars(player_objects[1])
  read_player_vars(player_objects[2])
  input_history[1] = {}
  input_history[2] = {}
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

  -- game
  read_game_vars()
  write_game_vars()

  -- players
  read_player_vars(player_objects[1])
  read_player_vars(player_objects[2])

  -- projectiles
  read_projectiles()

  if is_in_match then
    update_flip_input(player_objects[1], player_objects[2])
    update_flip_input(player_objects[2], player_objects[1])
  end

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

  if dummy.has_just_started_wake_up or dummy.has_just_started_fast_wake_up then
    dummy.wakeup_other_last_act_animation = player.last_act_animation
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
    update_input_history(input_history[1], "P1", _input)
    update_input_history(input_history[2], "P2", _input)
  else
    input_history[1] = {}
    input_history[2] = {}
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

  update_framedata_recording(player_objects[1])
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
      local _px, _py = game_to_screen_space(_obj.pos_x, _obj.pos_y)
      print_point(_px, _py, 0x00FFFFFF)
      local _prediction = predict_object_position(_obj, 4)
      _px, _py = game_to_screen_space(_prediction[1], _prediction[2])
      print_point(_px, _py, 0xFF0000FF)
    end
  end

  log_update()
end

is_menu_open = false
main_menu_selected_index = 1
is_main_menu_selected = true
sub_menu_selected_index = 1
current_popup = nil

function on_gui()

  if is_in_match then
    if training_settings.display_p1_input_history then draw_input_history(input_history[1], 4, 50, true) end
    if training_settings.display_p2_input_history then draw_input_history(input_history[2], 335, 50, false) end
  end

  if is_in_match then
    update_draw_hitboxes()

    if P1.input.pressed.start then
      printed_geometry = {}
    end

    for _i, _geometry in ipairs(printed_geometry) do
      if _geometry.type == "hitboxes" then
        draw_hitboxes(_geometry.x, _geometry.y, _geometry.flip_x, _geometry.boxes, _geometry.filter, _geometry.dilation)
      elseif _geometry.type == "point" then
        draw_point(_geometry.x, _geometry.y, _geometry.color)
      end
    end
  end

  if is_in_match and training_settings.display_input then
    local _i = joypad.get()
    local _p1 = make_input_history_entry("P1", _i)
    local _p2 = make_input_history_entry("P2", _i)
    draw_input_history_entry(_p1, 44, 34)
    draw_input_history_entry(_p2, 310, 34)
  end

  if is_in_match and special_training_mode[training_settings.special_training_current_mode] == "parry" then

    local _player = P1
    local _x = 65
    local _y = 48
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
    history_draw()
  end

  if is_in_match then
    local _should_toggle = P1.input.pressed.start
    if log_enabled then
      _should_toggle = P1.input.released.start
    end
    _should_toggle = not log_start_locked and _should_toggle
    if _should_toggle then
      is_menu_open = (not is_menu_open)
      if current_popup ~= nil then
        close_popup()
      end
    end
  else
    is_menu_open = false
  end

  if is_menu_open then
    local _current_entry = menu[main_menu_selected_index].entries[sub_menu_selected_index]

    if current_popup then
      _current_entry = current_popup.entries[current_popup.selected_index]
    end
    local _horizontal_autofire_rate = 4
    local _vertical_autofire_rate = 4
    if not is_main_menu_selected then
      if _current_entry.autofire_rate then
        _horizontal_autofire_rate = _current_entry.autofire_rate
      end
    end

    function _sub_menu_down()
      sub_menu_selected_index = sub_menu_selected_index + 1
      _current_entry = menu[main_menu_selected_index].entries[sub_menu_selected_index]
      if sub_menu_selected_index > #menu[main_menu_selected_index].entries then
        is_main_menu_selected = true
      elseif _current_entry.is_disabled ~= nil and _current_entry.is_disabled() then
        _sub_menu_down()
      end
    end

    function _sub_menu_up()
      sub_menu_selected_index = sub_menu_selected_index - 1
      _current_entry = menu[main_menu_selected_index].entries[sub_menu_selected_index]
      if sub_menu_selected_index == 0 then
        is_main_menu_selected = true
      elseif _current_entry.is_disabled ~= nil and _current_entry.is_disabled() then
        _sub_menu_up()
      end
    end

    if check_input_down_autofire(player_objects[1], "down", _vertical_autofire_rate) or check_input_down_autofire(player_objects[2], "down", _vertical_autofire_rate) then
      if is_main_menu_selected then
        is_main_menu_selected = false
        sub_menu_selected_index = 0
        _sub_menu_down()
      elseif _current_entry.down and _current_entry:down() then
        save_training_data()
      elseif current_popup then
        current_popup.selected_index = current_popup.selected_index + 1
        if current_popup.selected_index > #current_popup.entries then
          current_popup.selected_index = 1
        end
      else
        _sub_menu_down()
      end
    end

    if check_input_down_autofire(player_objects[1], "up", _vertical_autofire_rate) or check_input_down_autofire(player_objects[2], "up", _vertical_autofire_rate) then
      if is_main_menu_selected then
        is_main_menu_selected = false
        sub_menu_selected_index = #menu[main_menu_selected_index].entries + 1
        _sub_menu_up()
      elseif _current_entry.up and _current_entry:up() then
          save_training_data()
      elseif current_popup then
        current_popup.selected_index = current_popup.selected_index - 1
        if current_popup.selected_index == 0 then
          current_popup.selected_index = #current_popup.entries
        end
      else
        _sub_menu_up()
      end
    end

    if check_input_down_autofire(player_objects[1], "left", _horizontal_autofire_rate) or check_input_down_autofire(player_objects[2], "left", _horizontal_autofire_rate) then
      if is_main_menu_selected then
        main_menu_selected_index = main_menu_selected_index - 1
        if main_menu_selected_index == 0 then
          main_menu_selected_index = #menu
        end
      elseif _current_entry.left then
        _current_entry:left()
        save_training_data()
      end
    end

    if check_input_down_autofire(player_objects[1], "right", _horizontal_autofire_rate) or check_input_down_autofire(player_objects[2], "right", _horizontal_autofire_rate) then
      if is_main_menu_selected then
        main_menu_selected_index = main_menu_selected_index + 1
        if main_menu_selected_index > #menu then
          main_menu_selected_index = 1
        end
      elseif _current_entry.right then
        _current_entry:right()
        save_training_data()
      end
    end

    if P1.input.pressed.LP then
      if is_main_menu_selected then
      elseif _current_entry.validate then
        _current_entry:validate()
        save_training_data()
      end
    end

    if P1.input.pressed.MP then
      if is_main_menu_selected then
      elseif _current_entry.reset then
        _current_entry:reset()
        save_training_data()
      end
    end

    if P1.input.pressed.LK then
      if is_main_menu_selected then
      elseif _current_entry.cancel then
        _current_entry:cancel()
        save_training_data()
      end
    end

    -- screen size 383,223
    local _gui_box_bg_color = 0x293139FF
    local _gui_box_outline_color = 0x840000FF
    local _menu_box_left = 23
    local _menu_box_top = 15
    local _menu_box_right = 360
    local _menu_box_bottom = 195
    gui.box(_menu_box_left, _menu_box_top, _menu_box_right, _menu_box_bottom, _gui_box_bg_color, _gui_box_outline_color)

    local _bar_x = _menu_box_left + 10
    local _bar_y = _menu_box_top + 6
    local _base_offset = 0
    for i = 1, #menu do
      local _offset = 0
      local _c = text_disabled_color
      local _t = menu[i].name
      if is_main_menu_selected and i == main_menu_selected_index then
        _t = "< ".._t.." >"
        _c = text_selected_color
      elseif i == main_menu_selected_index then
        _c = text_default_color
        _offset = 8
      else
        _offset = 8
      end
      gui.text(_bar_x + _offset + _base_offset, _bar_y, _t, _c, text_default_border_color)
      _base_offset = _base_offset + (#menu[i].name + 5) * 4
    end


    local _menu_x = _menu_box_left + 10
    local _menu_y = _menu_box_top + 23
    local _menu_y_interval = 10
    local _draw_index = 0
    for i = 1, #menu[main_menu_selected_index].entries do
      if menu[main_menu_selected_index].entries[i].is_disabled == nil or not menu[main_menu_selected_index].entries[i].is_disabled() then
        menu[main_menu_selected_index].entries[i]:draw(_menu_x, _menu_y + _menu_y_interval * _draw_index, not is_main_menu_selected and not current_popup and sub_menu_selected_index == i)
        _draw_index = _draw_index + 1
      end
    end

    -- recording slots special display
    if main_menu_selected_index == 3 then
      local _t = string.format("%d frames", #recording_slots[training_settings.current_recording_slot].inputs)
      gui.text(_menu_box_left + 83, _menu_y + 2 * _menu_y_interval, _t, text_disabled_color, text_default_border_color)
    end

    if not is_main_menu_selected then
      if menu[main_menu_selected_index].entries[sub_menu_selected_index].legend then
        gui.text(_menu_x, _menu_box_bottom - 12, menu[main_menu_selected_index].entries[sub_menu_selected_index]:legend(), text_disabled_color, text_default_border_color)
      end
    end

    -- popup
    if current_popup then
      gui.box(current_popup.left, current_popup.top, current_popup.right, current_popup.bottom, _gui_box_bg_color, _gui_box_outline_color)

      _menu_x = current_popup.left + 10
      _menu_y = current_popup.top + 9
      _draw_index = 0

      for i = 1, #current_popup.entries do
        if current_popup.entries[i].is_disabled == nil or not current_popup.entries[i].is_disabled() then
          current_popup.entries[i]:draw(_menu_x, _menu_y + _menu_y_interval * _draw_index, current_popup.selected_index == i)
          _draw_index = _draw_index + 1
        end
      end

      if current_popup.entries[current_popup.selected_index].legend then
        gui.text(_menu_x, current_popup.bottom - 12, current_popup.entries[current_popup.selected_index]:legend(), text_disabled_color, text_default_border_color)
      end
    end

  else
    gui.box(0,0,0,0,0,0) -- if we don't draw something, what we drawed from last frame won't be cleared
  end
end

-- toolbox
function to_bit(_bool)
  if _bool then
    return 1
  else
    return 0
  end
end

function memory_readword_reverse(_addr)
  local _1 = memory.readbyte(_addr)
  local _2 = memory.readbyte(_addr + 1)
  return  bit.bor(bit.lshift(_2, 8), _1)
end

function clamp01(_number)
  return math.max(math.min(_number, 1.0), 0.0)
end

function get_text_width(_text)
  if #_text == 0 then
    return 0
  end

  return #_text * 4
end

function draw_input(_x, _y, _input, _prefix)
  local up = _input[_prefix.."Up"]
  local down = _input[_prefix.."Down"]
  local left = _input[_prefix.."Left"]
  local right = _input[_prefix.."Right"]
  local LP = _input[_prefix.."Weak Punch"]
  local MP = _input[_prefix.."Medium Punch"]
  local HP = _input[_prefix.."Strong Punch"]
  local LK = _input[_prefix.."Weak Kick"]
  local MK = _input[_prefix.."Medium Kick"]
  local HK = _input[_prefix.."Strong Kick"]
  local start = _input[_prefix.."Start"]
  local coin = _input[_prefix.."Coin"]
  function col(_value)
    if _value then return text_selected_color else return text_default_color end
  end

  gui.text(_x + 5 , _y + 0 , "^", col(up), text_default_border_color)
  gui.text(_x + 5 , _y + 10, "v", col(down), text_default_border_color)
  gui.text(_x + 0 , _y + 5, "<", col(left), text_default_border_color)
  gui.text(_x + 10, _y + 5, ">", col(right), text_default_border_color)

  gui.text(_x + 20, _y + 0, "LP", col(LP), text_default_border_color)
  gui.text(_x + 30, _y + 0, "MP", col(MP), text_default_border_color)
  gui.text(_x + 40, _y + 0, "HP", col(HP), text_default_border_color)
  gui.text(_x + 20, _y + 10, "LK", col(LK), text_default_border_color)
  gui.text(_x + 30, _y + 10, "MK", col(MK), text_default_border_color)
  gui.text(_x + 40, _y + 10, "HK", col(HK), text_default_border_color)

  gui.text(_x + 55, _y + 0, "S", col(start), text_default_border_color)
  gui.text(_x + 55, _y + 10, "C", col(coin), text_default_border_color)
end

function draw_gauge(_x, _y, _width, _height, _fill_ratio, _fill_color, _bg_color, _border_color, _reverse_fill)
  _bg_color = _bg_color or 0x00000000
  _border_color = _border_color or 0xFFFFFFFF
  _reverse_fill = _reverse_fill or false

  _width = _width + 1
  _height = _height + 1

  gui.box(_x, _y, _x + _width, _y + _height, _bg_color, _border_color)
  if _reverse_fill then
    gui.box(_x + _width, _y, _x + _width - _width * clamp01(_fill_ratio), _y + _height, _fill_color, 0x00000000)
  else
    gui.box(_x, _y, _x + _width * clamp01(_fill_ratio), _y + _height, _fill_color, 0x00000000)
  end
end

function string:split(sep)
   local sep, fields = sep or ":", {}
   local pattern = string.format("([^%s]+)", sep)
   self:gsub(pattern, function(c) fields[#fields+1] = c end)
   return fields
end

function string_hash(_str)
	if #_str == 0 then
		return 0
  end

  local _DJB2_INIT = 5381;
	local _hash = _DJB2_INIT
  for _i = 1, #_str do
    local _c = _str.byte(_i)
    _hash = bit.lshift(_hash, 5) + _hash + _c
  end
	return _hash
end

function string_to_color(_str)
  local _HRange = { 0.0, 360.0 }
	local _SRange = { 0.8, 1.0 }
	local _LRange = { 0.7, 1.0 }

	local _HAmplitude = _HRange[2] - _HRange[1];
	local _SAmplitude = _SRange[2] - _SRange[1];
	local _LAmplitude = _LRange[2] - _LRange[1];

  local _hash = string_hash(_str)

  local _HI = bit.rshift(bit.band(_hash, 0xFF000000), 24)
  local _SI = bit.rshift(bit.band(_hash, 0x00FF0000), 16)
	local _LI = bit.rshift(bit.band(_hash, 0x0000FF00), 8)
	local _base = bit.lshift(1, 8)

	local _H = _HRange[1] + (_HI / _base) * _HAmplitude;
	local _S = _SRange[1] + (_SI / _base) * _SAmplitude;
	local _L = _LRange[1] + (_LI / _base) * _LAmplitude;

	local _HDiv60 = _H / 60.0
	local _HDiv60_Floor = math.floor(_HDiv60);
	local _HDiv60_Fraction = _HDiv60 - _HDiv60_Floor;

	local _RGBValues = {
		_L,
		_L * (1.0 - _S),
		_L * (1.0 - (_HDiv60_Fraction * _S)),
		_L * (1.0 - ((1.0 - _HDiv60_Fraction) * _S))
	}

	local _RGBSwizzle = {
		{1, 4, 2},
		{3, 1, 2},
		{2, 1, 4},
		{2, 3, 1},
		{4, 2, 1},
		{1, 2, 3},
	}
	local _SwizzleIndex = (_HDiv60_Floor % 6) + 1
  local _R = _RGBValues[_RGBSwizzle[_SwizzleIndex][1]]
  local _G = _RGBValues[_RGBSwizzle[_SwizzleIndex][2]]
  local _B = _RGBValues[_RGBSwizzle[_SwizzleIndex][3]]

  --print(string.format("H:%.1f, S:%.1f, L:%.1f | R:%.1f, G:%.1f, B:%.1f", _H, _S, _L, _R, _G, _B))

  local _color = bit.lshift(math.floor(_R * 255), 24) + bit.lshift(math.floor(_G * 255), 16) + bit.lshift(math.floor(_B * 255), 8) + 0xFF
  return _color
end

screen_x = 0
screen_y = 0
scale = 1

-- registers
emu.registerstart(on_start)
emu.registerbefore(before_frame)
gui.register(on_gui)
savestate.registerload(on_load_state)


-- character specific stuff
character_specific = {}
for i = 1, #characters do
  character_specific[characters[i]] = { timed_sa = {false, false, false} }
end

-- Character approximate dimensions
character_specific.alex.half_width = 45
character_specific.chunli.half_width = 39
character_specific.dudley.half_width = 29
character_specific.elena.half_width = 44
character_specific.gouki.half_width = 33
character_specific.hugo.half_width = 43
character_specific.ibuki.half_width = 34
character_specific.ken.half_width = 30
character_specific.makoto.half_width = 42
character_specific.necro.half_width = 26
character_specific.oro.half_width = 40
character_specific.q.half_width = 25
character_specific.remy.half_width = 32
character_specific.ryu.half_width = 31
character_specific.sean.half_width = 29
character_specific.twelve.half_width = 33
character_specific.urien.half_width = 36
character_specific.yang.half_width = 41
character_specific.yun.half_width = 37

character_specific.alex.height = 104
character_specific.chunli.height = 97
character_specific.dudley.height = 109
character_specific.elena.height = 88
character_specific.gouki.height = 107
character_specific.hugo.height = 137
character_specific.ibuki.height = 92
character_specific.ken.height = 107
character_specific.makoto.height = 90
character_specific.necro.height = 89
character_specific.oro.height = 88
character_specific.q.height = 130
character_specific.remy.height = 114
character_specific.ryu.height = 101
character_specific.sean.height = 103
character_specific.twelve.height = 91
character_specific.urien.height = 121
character_specific.yang.height = 89
character_specific.yun.height = 89

-- Characters standing states
character_specific.oro.additional_standing_states = { 3 } -- 3 is crouching
character_specific.dudley.additional_standing_states = { 6 } -- 6 is crouching
character_specific.makoto.additional_standing_states = { 7 } -- 7 happens during Oroshi
character_specific.necro.additional_standing_states = { 13 } -- 13 happens during CrLK

-- Charcters timed SA
character_specific.oro.timed_sa[1] = true;
character_specific.oro.timed_sa[3] = true;
character_specific.q.timed_sa[3] = true;
character_specific.makoto.timed_sa[3] = true;
character_specific.twelve.timed_sa[3] = true;
character_specific.yang.timed_sa[3] = true;
character_specific.yun.timed_sa[3] = true;

-- ALEX
frame_data_meta = {}
for i = 1, #characters do
  frame_data_meta[characters[i]] = {
    moves = {},
    projectiles = {},
  }
end
frame_data_meta["alex"].moves["b7fc"] = { hits = {{ type = 2 }} } -- Cr LK
frame_data_meta["alex"].moves["b99c"] = { hits = {{ type = 2 }} } -- Cr MK
frame_data_meta["alex"].moves["babc"] = { hits = {{ type = 2 }} } -- Cr HK

frame_data_meta["alex"].moves["a444"] = { force_recording = true } -- LP

frame_data_meta["alex"].moves["a7dc"] = { hits = {{ type = 3 }} } -- HP

frame_data_meta["alex"].moves["72d4"] = { hits = {{ type = 3 }} } -- UOH

frame_data_meta["alex"].moves["bc0c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LP
frame_data_meta["alex"].moves["bd6c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MP
frame_data_meta["alex"].moves["be7c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HP
frame_data_meta["alex"].moves["c324"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air Down HP

frame_data_meta["alex"].moves["bf94"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LK
frame_data_meta["alex"].moves["c0e4"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MK
frame_data_meta["alex"].moves["c1c4"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HK

frame_data_meta["alex"].moves["6d24"] = { proxy = { offset = -23, id = "7044" } } -- VCharge LK
frame_data_meta["alex"].moves["7044"] = { hits = {{ type = 3 }} } -- VCharge LK

frame_data_meta["alex"].moves["6df4"] = { proxy = { offset = -25, id = "7094" } } -- VCharge MK
frame_data_meta["alex"].moves["7094"] = { hits = {{ type = 3 }} } -- VCharge MK

frame_data_meta["alex"].moves["6ec4"] = { proxy = { offset = -26, id = "70e4" } } -- VCharge HK
frame_data_meta["alex"].moves["70e4"] = { hits = {{ type = 3 }} } -- VCharge HK

frame_data_meta["alex"].moves["6f94"] = { proxy = { offset = -26, id = "70e4" } } -- VCharge EXK

frame_data_meta["alex"].moves["ad04"] = {  hit_throw = true } -- Back HP

-- IBUKI
frame_data_meta["ibuki"].moves["14e0"] = { hits = {{ type = 2 }} } -- Cr LK
frame_data_meta["ibuki"].moves["15f0"] = { hits = {{ type = 2 }} } -- Cr MK
frame_data_meta["ibuki"].moves["1740"] = { hits = {{ type = 2 }} } -- Cr Forward MK
frame_data_meta["ibuki"].moves["19c0"] = { hits = {{ type = 2 }} } -- Cr HK

frame_data_meta["ibuki"].moves["a768"] = { hits = {{ type = 2 }} } -- L Kazekiri rekka
frame_data_meta["ibuki"].moves["fc60"] = { hits = {{ type = 2 }} } -- H Kazekiri rekka
frame_data_meta["ibuki"].moves["e810"] = { hits = {{ type = 2 }, { type = 2 }} } -- EX Kazekiri rekka
frame_data_meta["ibuki"].moves["eb60"] = { hits = {{ type = 2 }, { type = 2 }} } -- EX Kazekiri rekka

frame_data_meta["ibuki"].moves["0748"] = { hits = {{ type = 3 }} } -- Forward MK
frame_data_meta["ibuki"].moves["30a0"] = { hits = {{ type = 3 }} } -- Target MK
frame_data_meta["ibuki"].moves["dec0"] = { hits = {{ type = 3 }} } -- UOH
frame_data_meta["ibuki"].moves["2450"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LP
frame_data_meta["ibuki"].moves["25b0"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MP
frame_data_meta["ibuki"].moves["1ee8"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HP
frame_data_meta["ibuki"].moves["2748"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LK
frame_data_meta["ibuki"].moves["2878"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MK
frame_data_meta["ibuki"].moves["29a8"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HK
frame_data_meta["ibuki"].moves["1c10"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LP
frame_data_meta["ibuki"].moves["1d10"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MP
frame_data_meta["ibuki"].moves["20f0"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LK
frame_data_meta["ibuki"].moves["2210"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MK
frame_data_meta["ibuki"].moves["2330"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HK

frame_data_meta["ibuki"].moves["91f8"] = { hit_throw = true, hits = {{ type = 2 }} } -- L Neck Breaker
frame_data_meta["ibuki"].moves["93b8"] = { hit_throw = true, hits = {{ type = 2 }} } -- M Neck Breaker
frame_data_meta["ibuki"].moves["9578"] = { hit_throw = true, hits = {{ type = 2 }} } -- H Neck Breaker
frame_data_meta["ibuki"].moves["9750"] = { hit_throw = true, hits = {{ type = 2 }} } -- EX Neck Breaker

frame_data_meta["ibuki"].moves["8e20"] = { hit_throw = true } -- L Raida
frame_data_meta["ibuki"].moves["8f68"] = { hit_throw = true } -- M Raida
frame_data_meta["ibuki"].moves["90b0"] = { hit_throw = true } -- H Raida

frame_data_meta["ibuki"].moves["7ca0"] = { hits = {{ type = 3 }, { type = 3 }}, force_recording = true } -- L Hien
frame_data_meta["ibuki"].moves["8100"] = { hits = {{ type = 3 }, { type = 3 }}, force_recording = true } -- M Hien
frame_data_meta["ibuki"].moves["8560"] = { hits = {{ type = 3 }, { type = 3 }}, force_recording = true } -- H Hien
frame_data_meta["ibuki"].moves["89c0"] = { hits = {{ type = 3 }, { type = 3 }}, movement_type = 2 , force_recording = true } -- Ex Hien

frame_data_meta["ibuki"].moves["3a48"] = { proxy = { offset = -2, id = "f838" } } -- target MP

frame_data_meta["ibuki"].moves["36c8"] = { proxy = { offset = 0, id = "05d0" } } -- target MK
frame_data_meta["ibuki"].moves["3828"] = { proxy = { offset = 1, id = "0b10" } } -- target HK
frame_data_meta["ibuki"].moves["4290"] = { proxy = { offset = -2, id = "0b10" } } -- target HK
frame_data_meta["ibuki"].moves["3290"] = { proxy = { offset = 5, id = "19c0" } } -- target Cr HK

frame_data_meta["ibuki"].moves["3480"] = { hits = {{ type = 3 }}, movement_type = 2 } -- target Air MK
frame_data_meta["ibuki"].moves["3580"] = { hits = {{ type = 3 }}, movement_type = 2 } -- target Air HP

frame_data_meta["ibuki"].moves["3f28"] = { force_recording = true } -- Target HP

frame_data_meta["ibuki"].moves["75f0"] = { hits = {{}, {}, {}, { dilation = 5 }} } -- DPF HK
frame_data_meta["ibuki"].moves["7888"] = { hits = {{}, {}, {}, { dilation = 5 }} } -- DPF Ex K

-- HUGO
frame_data_meta["hugo"].moves["5060"] = { hits = {{ type = 2 }} } -- Cr LK
frame_data_meta["hugo"].moves["5110"] = { hits = {{ type = 2 }} } -- Cr MK
frame_data_meta["hugo"].moves["51d0"] = { hits = {{ type = 3 }} } -- Cr HK

frame_data_meta["hugo"].moves["4e00"] = { force_recording = true } -- Cr LP
frame_data_meta["hugo"].moves["3fe0"] = { force_recording = true } -- LP

frame_data_meta["hugo"].moves["1cd4"] = { hits = {{ type = 3 }} } -- UOH
frame_data_meta["hugo"].moves["4200"] = { hits = {{ type = 3 }} } -- HP
frame_data_meta["hugo"].moves["48d0"] = { hits = {{ type = 1 }, { type = 3 }} } -- MK
frame_data_meta["hugo"].moves["4c10"] = { hits = {{ type = 3 }}, movement_type = 2 } -- HK

frame_data_meta["hugo"].moves["52a0"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LP
frame_data_meta["hugo"].moves["5370"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MP
frame_data_meta["hugo"].moves["5440"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HP
frame_data_meta["hugo"].moves["5540"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air Down HP
frame_data_meta["hugo"].moves["55f0"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LK
frame_data_meta["hugo"].moves["56c0"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MK
frame_data_meta["hugo"].moves["5790"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HK

-- URIEN
frame_data_meta["urien"].moves["eaf4"] = { hits = {{ type = 2 }} } -- Cr LK
frame_data_meta["urien"].moves["ebc4"] = { hits = {{ type = 2 }} } -- Cr MK
frame_data_meta["urien"].moves["ec84"] = { hits = {{ type = 2 }} } -- Cr HK

frame_data_meta["urien"].moves["d774"] = { force_recording = true } -- LP
frame_data_meta["urien"].moves["e4ac"] = { force_recording = true } -- Cr LP

frame_data_meta["urien"].moves["6784"] = { hits = {{ type = 3 }} } -- UOH
frame_data_meta["urien"].moves["dc1c"] = { hits = {{ type = 3 }} } -- Forward HP
frame_data_meta["urien"].moves["e0b4"] = { hits = {{ type = 3 }, { type = 3 }} } -- HK

frame_data_meta["urien"].moves["4cbc"] = { hits = {{ type = 3 }} } -- L Knee Drop
frame_data_meta["urien"].moves["4e4c"] = { hits = {{ type = 3 }} } -- M Knee Drop
frame_data_meta["urien"].moves["4fdc"] = { hits = {{ type = 3 }} } -- H Knee Drop
frame_data_meta["urien"].moves["516c"] = { hits = {{ type = 3 }, { type = 3 }}, movement_type = 2, force_recording = true } -- EX Knee Drop

frame_data_meta["urien"].moves["ee14"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LP
frame_data_meta["urien"].moves["eeb4"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MP
frame_data_meta["urien"].moves["ef94"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HP
frame_data_meta["urien"].moves["f074"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LK
frame_data_meta["urien"].moves["f114"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MK
frame_data_meta["urien"].moves["f1f4"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HK

-- GOUKI
frame_data_meta["gouki"].moves["1f68"] = { hits = {{ type = 2 }, { type = 2 }, { type = 2 }, { type = 2 }}, force_recording = true } -- Cr LK
frame_data_meta["gouki"].moves["2008"] = { hits = {{ type = 2 }} } -- Cr MK
frame_data_meta["gouki"].moves["20d8"] = { hits = {{ type = 2 }} } -- Cr HK

frame_data_meta["gouki"].moves["1438"] = { force_recording = true } -- LP
frame_data_meta["gouki"].moves["1d28e"] = { force_recording = true } -- Cr LP

frame_data_meta["gouki"].moves["1638"] = { hits = {{ type = 3 }, { type = 3 }}, force_recording = true } -- Forward MP
frame_data_meta["gouki"].moves["98f8"] = { hits = {{ type = 3 }, { type = 3 }} } -- UOH
frame_data_meta["gouki"].moves["1b08"] = { hits = {{ type = 3 }, { type = 3 }} } -- Close HK

frame_data_meta["gouki"].moves["3850"] = { proxy = { offset = -2, id = "1818" } } -- Target HP

frame_data_meta["gouki"].moves["21c8"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LP
frame_data_meta["gouki"].moves["2708"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LP
frame_data_meta["gouki"].moves["22a8"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MP
frame_data_meta["gouki"].moves["2388"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HP
frame_data_meta["gouki"].moves["2800"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HP
frame_data_meta["gouki"].moves["2448"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LK
frame_data_meta["gouki"].moves["28e0"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LK
frame_data_meta["gouki"].moves["2558"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MK
frame_data_meta["gouki"].moves["29c0"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MK
frame_data_meta["gouki"].moves["2628"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HK
frame_data_meta["gouki"].moves["2b30"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HK
frame_data_meta["gouki"].moves["2aa0"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air Down MK

frame_data_meta["gouki"].moves["af08"] = { hits = {{ type = 2 }}, movement_type = 2 } -- Demon flip
frame_data_meta["gouki"].moves["b218"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Demon flip K cancel
frame_data_meta["gouki"].moves["b118"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Demon flip P cancel

-- MAKOTO
frame_data_meta["makoto"].moves["2f10"] = { hits = {{ type = 2 }} } -- Cr LK
frame_data_meta["makoto"].moves["2de0"] = { hits = {{ type = 2 }} } -- Cr HP
frame_data_meta["makoto"].moves["2a20"] = { hits = {{ type = 2 }} } -- Forward HK

frame_data_meta["makoto"].moves["db10"] = { hits = {{ type = 3 }} } -- UOH
frame_data_meta["makoto"].moves["ebb8"] = { hits = {{ type = 3 }} } -- L Oroshi
frame_data_meta["makoto"].moves["ed98"] = { hits = {{ type = 3 }} } -- M Oroshi
frame_data_meta["makoto"].moves["ee98"] = { hits = {{ type = 3 }} } -- H Oroshi
frame_data_meta["makoto"].moves["ef98"] = { hits = {{ type = 3 }} } -- EX Oroshi

frame_data_meta["makoto"].moves["31e0"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LP
frame_data_meta["makoto"].moves["32c0"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MP
frame_data_meta["makoto"].moves["3380"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HP
frame_data_meta["makoto"].moves["3460"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LK
frame_data_meta["makoto"].moves["3520"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MK
frame_data_meta["makoto"].moves["3610"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HK

frame_data_meta["makoto"].moves["3720"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LP
frame_data_meta["makoto"].moves["37e0"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MP
frame_data_meta["makoto"].moves["38e0"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HP
frame_data_meta["makoto"].moves["3a50"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LK
frame_data_meta["makoto"].moves["3b10"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MK
frame_data_meta["makoto"].moves["3c00"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HK

frame_data_meta["makoto"].moves["2190"] = { hits = {{ type = 3 }}, movement_type = 2 } -- L Tsurugi
frame_data_meta["makoto"].moves["2310"] = { hits = {{ type = 3 }}, movement_type = 2 } -- M Tsurugi
frame_data_meta["makoto"].moves["2410"] = { hits = {{ type = 3 }}, movement_type = 2 } -- H Tsurugi
frame_data_meta["makoto"].moves["2510"] = { hits = {{ type = 3 }}, movement_type = 2 } -- EX Tsurugi

-- ORO
frame_data_meta["oro"].moves["5c10"] = { hits = {{ type = 2 }} } -- Cr LK
frame_data_meta["oro"].moves["5da0"] = { hits = {{ type = 2 }} } -- Cr MK
frame_data_meta["oro"].moves["5ed0"] = { hits = {{ type = 2 }} } -- Cr HK

frame_data_meta["oro"].moves["4f08"] = { hits = {{ type = 3 }, { type = 3 }} } -- HP
frame_data_meta["oro"].moves["0fbc"] = { hits = {{ type = 3}} } -- UOH
frame_data_meta["oro"].moves["7a18"] = { proxy = { id = "5378", offset = 0 }} -- target MK

frame_data_meta["oro"].moves["5fc0"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LP
frame_data_meta["oro"].moves["60d0"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MP
frame_data_meta["oro"].moves["6200"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HP
frame_data_meta["oro"].moves["6300"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LK
frame_data_meta["oro"].moves["6460"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MK
frame_data_meta["oro"].moves["6590"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HK

frame_data_meta["oro"].moves["6708"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LP
frame_data_meta["oro"].moves["6888"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MP
frame_data_meta["oro"].moves["6a08"] = { hits = {{ type = 3 }, { type = 3 }}, movement_type = 2 } -- Air HP
frame_data_meta["oro"].moves["6bf8"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LK
frame_data_meta["oro"].moves["6d08"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MK
frame_data_meta["oro"].moves["6ef8"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HK

frame_data_meta["oro"].moves["d71c"] = { hit_throw = true } -- HCB LP
frame_data_meta["oro"].moves["d89c"] = { hit_throw = true } -- HCB LP
frame_data_meta["oro"].moves["d96c"] = { hit_throw = true } -- HCB LP

frame_data_meta["oro"].moves["08bc"] = { hits = {{ type = 3 }, { type = 3 }} } -- QCF LK
frame_data_meta["oro"].moves["0b2c"] = { hits = {{ type = 3 }, { type = 3 }} } -- QCF MK
frame_data_meta["oro"].moves["0c9c"] = { hits = {{ type = 3 }, { type = 3 }} } -- QCF HK
frame_data_meta["oro"].moves["0e0c"] = { force_recording = true, hits = {{ type = 3 }, { type = 3 }, { type = 3 }}, movement_type = 2 } -- QCF EXK

frame_data_meta["oro"].moves["012c"] = { hits = {{ type = 3 }, { type = 3 }, { type = 3 }}} -- Air QCF K
frame_data_meta["oro"].moves["041c"] = { hits = {{ type = 3 }, { type = 3 }, { type = 3 }}} -- Air QCF EXK

-- KEN
frame_data_meta["ken"].moves["b048"] = { hits = {{ type = 2 }, { type = 2 }, { type = 2 }} } -- Cr LK
frame_data_meta["ken"].moves["b0e8"] = { hits = {{ type = 2 }} } -- Cr MK
frame_data_meta["ken"].moves["b1b8"] = { hits = {{ type = 2 }} } -- Cr HK

frame_data_meta["ken"].moves["23ec"] = { hits = {{ type = 3 }} } -- UOH

frame_data_meta["ken"].moves["a980"] = { hits = {{ type = 3 }, { type = 3 }} } -- Back MK
frame_data_meta["ken"].moves["abe8"] = { hits = {{ type = 3 }} } -- Forward HK

frame_data_meta["ken"].moves["c188"] = { proxy = { id = "a470", offset = 0 } } -- Target Close HK

frame_data_meta["ken"].moves["b528"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LK
frame_data_meta["ken"].moves["b648"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MK
frame_data_meta["ken"].moves["b708"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HK
frame_data_meta["ken"].moves["b2a8"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LP
frame_data_meta["ken"].moves["b388"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MP
frame_data_meta["ken"].moves["b468"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HP

frame_data_meta["ken"].moves["ba88"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LK
frame_data_meta["ken"].moves["bb68"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MK
frame_data_meta["ken"].moves["bc48"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HK
frame_data_meta["ken"].moves["b7e8"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LP
frame_data_meta["ken"].moves["b8c8"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MP
frame_data_meta["ken"].moves["b9a8"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HP

frame_data_meta["ken"].moves["1fd4"] = { hits = {{ type = 3 }, { type = 3 }, { type = 3 }, { type = 3 }}, movement_type = 2 } -- Air Tatsu L
frame_data_meta["ken"].moves["2114"] = { hits = {{ type = 3 }, { type = 3 }, { type = 3 }, { type = 3 }, { type = 3 }, { type = 3 }}, movement_type = 2 } -- Air Tatsu M
frame_data_meta["ken"].moves["21f4"] = { hits = {{ type = 3 }, { type = 3 }, { type = 3 }, { type = 3 }, { type = 3 }, { type = 3 }, { type = 3 }, { type = 3 }}, movement_type = 2 } -- Air Tatsu H
frame_data_meta["ken"].moves["22d4"] = { hits = {{ type = 3 }, { type = 3 }, { type = 3 }, { type = 3 }, { type = 3 }, { type = 3 }, { type = 3 }, { type = 3 }, { type = 3 }, { type = 3 }}, movement_type = 2 } -- Air Tatsu Ex

frame_data_meta["ken"].moves["1214"] = { force_recording = true } -- SA 1
frame_data_meta["ken"].moves["15b4"] = { force_recording = true } -- SA 2
frame_data_meta["ken"].moves["1834"] = { force_recording = true } -- SA 3
frame_data_meta["ken"].moves["1d24"] = { force_recording = true } -- SA 3

-- ELENA
frame_data_meta["elena"].moves["bde0"] = { hits = {{ type = 2 }} } -- Cr LK
frame_data_meta["elena"].moves["bf88"] = { hits = {{ type = 2 }} } -- Cr MK
frame_data_meta["elena"].moves["c1d8"] = { hits = {{ type = 2 }} } -- Cr HK
frame_data_meta["elena"].moves["c440"] = { hits = {{ type = 2 }} } -- Cr Forward HK
frame_data_meta["elena"].moves["63d4"] = { hits = {{ type = 2 }, { type = 1 }} } -- Taunt

frame_data_meta["elena"].moves["6354"] = { hits = {{ type = 3 }} } -- UOH
frame_data_meta["elena"].moves["ab98"] = { hits = {{ type = 3 }} } -- Forward MP
frame_data_meta["elena"].moves["b430"] = { hits = {{ type = 3 }} } -- Forward MK

frame_data_meta["elena"].moves["e370"] = { proxy = { id = "b560", offset = 0 }} -- Target HK
frame_data_meta["elena"].moves["e068"] = { proxy = { id = "d798", offset = 0 }} -- Target Air MK
frame_data_meta["elena"].moves["e1f8"] = { proxy = { id = "d448", offset = 6 }} -- Target Air HP

frame_data_meta["elena"].moves["cba0"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LK
frame_data_meta["elena"].moves["cda0"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MK
frame_data_meta["elena"].moves["cef0"] = { hits = {{ type = 3 }, { type = 3 }}, movement_type = 2 } -- Straight Air HK
frame_data_meta["elena"].moves["d608"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LK
frame_data_meta["elena"].moves["d798"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MK
frame_data_meta["elena"].moves["d958"] = { hits = {{ type = 3 }, { type = 3 }}, movement_type = 2 } -- Air HK

frame_data_meta["elena"].moves["c690"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LP
frame_data_meta["elena"].moves["c820"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MP
frame_data_meta["elena"].moves["c9e0"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HP
frame_data_meta["elena"].moves["d0f8"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LP
frame_data_meta["elena"].moves["d288"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MP
frame_data_meta["elena"].moves["d448"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HP

frame_data_meta["elena"].moves["094c"] = { hits = {{ type = 3 }, { type = 3 }} } -- Mallet Smash L
frame_data_meta["elena"].moves["0cec"] = { hits = {{ type = 3 }, { type = 3 }} } -- Mallet Smash M
frame_data_meta["elena"].moves["0eac"] = { hits = {{ type = 3 }, { type = 3 }} } -- Mallet Smash H
frame_data_meta["elena"].moves["fde4"] = { hits = {{ type = 3 }, { type = 3 }} } -- Mallet Smash EX

frame_data_meta["elena"].moves["83cc"] = { hits = {{ type = 2 }, { type = 2 }} } -- Scratch Wheel L
frame_data_meta["elena"].moves["858c"] = { hits = {{ type = 2 }, { type = 2 }} } -- Scratch Wheel M
frame_data_meta["elena"].moves["874c"] = { hits = {{ type = 2 }, { type = 2 }, { type = 2 }, { type = 2 }} } -- Scratch Wheel H
frame_data_meta["elena"].moves["89fc"] = { hits = {{ type = 2 }, { type = 2 }, { type = 2 }, { type = 2 }, { type = 1 }} } -- Scratch Wheel EX

frame_data_meta["elena"].moves["4dc4"] = { force_recording = true, hits = {{ type = 1 }, { type = 1 }, { type = 2 }} } -- SA 2
frame_data_meta["elena"].moves["5074"] = { force_recording = true, hits = {{ type = 1 }, { type = 2 }, { type = 1 }, { type = 2 }, { type = 2 }} } -- SA 2

-- Q
frame_data_meta["q"].moves["e684"] = { hits = {{ type = 2 }} } -- Cr HP
frame_data_meta["q"].moves["e7e4"] = { hits = {{ type = 2 }} } -- Cr LK
frame_data_meta["q"].moves["e8b4"] = { hits = {{ type = 2 }} } -- Cr MK
frame_data_meta["q"].moves["ea14"] = { hits = {{ type = 2 }} } -- Cr HK

frame_data_meta["q"].moves["9074"] = { hits = {{ type = 3 }} } -- UOH

frame_data_meta["q"].moves["eea4"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LK
frame_data_meta["q"].moves["ef94"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MK
frame_data_meta["q"].moves["f074"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HK
frame_data_meta["q"].moves["ec04"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LP
frame_data_meta["q"].moves["eca4"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MP
frame_data_meta["q"].moves["eda4"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HP
frame_data_meta["q"].moves["f194"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LP
frame_data_meta["q"].moves["f234"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MP
frame_data_meta["q"].moves["f334"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HP

frame_data_meta["q"].moves["5cdc"] = { hits = {{ type = 3 }} } -- OH Dash punch L
frame_data_meta["q"].moves["5f44"] = { hits = {{ type = 3 }} } -- OH Dash punch M
frame_data_meta["q"].moves["61ac"] = { hits = {{ type = 3 }} } -- OH Dash punch H

frame_data_meta["q"].moves["518c"] = { hits = {{ type = 2 }} } -- Low Dash punch L
frame_data_meta["q"].moves["5454"] = { hits = {{ type = 2 }} } -- Low Dash punch M
frame_data_meta["q"].moves["5734"] = { hits = {{ type = 2 }} } -- Low Dash punch H
frame_data_meta["q"].moves["5a2c"] = { hits = {{ type = 2 }, { type = 2 }} } -- Low Dash punch EX

frame_data_meta["q"].moves["8304"] = { hits = {{ type = 2 }} } -- SA1
frame_data_meta["q"].moves["8464"] = { force_recording = true } -- SA2

-- RYU
frame_data_meta["ryu"].moves["2304"] = { hits = {{ type = 2 }, { type = 2 }, { type = 2 }} } -- Cr LK
frame_data_meta["ryu"].moves["23a4"] = { hits = {{ type = 2 }} } -- Cr MK
frame_data_meta["ryu"].moves["2474"] = { hits = {{ type = 2 }} } -- Cr HK

frame_data_meta["ryu"].moves["80dc"] = { hits = {{ type = 3 }} } -- UOH
frame_data_meta["ryu"].moves["1984"] = { hits = {{ type = 3 }, { type = 3 }} } -- Forward MP

frame_data_meta["ryu"].moves["27e4"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LK
frame_data_meta["ryu"].moves["28f4"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MK
frame_data_meta["ryu"].moves["29c4"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HK
frame_data_meta["ryu"].moves["2d64"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LK
frame_data_meta["ryu"].moves["2e44"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MK
frame_data_meta["ryu"].moves["2f24"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HK
frame_data_meta["ryu"].moves["2564"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LP
frame_data_meta["ryu"].moves["2644"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MP
frame_data_meta["ryu"].moves["2724"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HP
frame_data_meta["ryu"].moves["2aa4"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LP
frame_data_meta["ryu"].moves["2b84"] = { hits = {{ type = 3 }, { type = 3 }}, movement_type = 2 } -- Air MP
frame_data_meta["ryu"].moves["2c84"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HP

frame_data_meta["ryu"].moves["7cbc"] = { movement_type = 2 } -- Air tatsu L
frame_data_meta["ryu"].moves["7dfc"] = { movement_type = 2 } -- Air tatsu M
frame_data_meta["ryu"].moves["7edc"] = { movement_type = 2 } -- Air tatsu H

frame_data_meta["ryu"].moves["894c"] = { force_recording = true } -- SA2
frame_data_meta["ryu"].moves["8be4"] = { force_recording = true } -- SA2

-- REMY
frame_data_meta["remy"].moves["ab20"] = { hits = {{ type = 2 }} } -- Cr LK
frame_data_meta["remy"].moves["abf0"] = { hits = {{ type = 2 }} } -- Cr MK
frame_data_meta["remy"].moves["acc0"] = { hits = {{ type = 2 }, { type = 2 }} } -- Cr HK

frame_data_meta["remy"].moves["ff48"] = { hits = {{ type = 3 }} } -- UOH
frame_data_meta["remy"].moves["a4b0"] = { hits = {{ type = 3 }} } -- Forward MP

frame_data_meta["remy"].moves["b270"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LK
frame_data_meta["remy"].moves["b370"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MK
frame_data_meta["remy"].moves["b450"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HK
frame_data_meta["remy"].moves["af40"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LP
frame_data_meta["remy"].moves["b040"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MP
frame_data_meta["remy"].moves["b140"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HP

frame_data_meta["remy"].projectiles["80"] = { type = 2 } -- HCharge ExP
frame_data_meta["remy"].projectiles["82"] = { type = 2 } -- HCharge LK
frame_data_meta["remy"].projectiles["83"] = { type = 2 } -- HCharge MK
frame_data_meta["remy"].projectiles["84"] = { type = 2 } -- HCharge LK
frame_data_meta["remy"].projectiles["85"] = { type = 2 } -- HCharge ExK

-- TWELVE
frame_data_meta["twelve"].moves["462c"] = { hits = {{ type = 2 }, { type = 2 }, { type = 2 }} } -- Cr LK
frame_data_meta["twelve"].moves["46fc"] = { hits = {{ type = 2 }} } -- Cr MK
frame_data_meta["twelve"].moves["480c"] = { hits = {{ type = 2 }} } -- Cr HK

frame_data_meta["twelve"].moves["e1b4"] = { hits = {{ type = 3 }} } -- UOH

frame_data_meta["twelve"].moves["4ccc"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LK
frame_data_meta["twelve"].moves["4d9c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MK
frame_data_meta["twelve"].moves["4e9c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HK
frame_data_meta["twelve"].moves["522c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LK
frame_data_meta["twelve"].moves["52fc"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MK
frame_data_meta["twelve"].moves["53fc"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HK
frame_data_meta["twelve"].moves["4a2c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LP
frame_data_meta["twelve"].moves["4aec"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MP
frame_data_meta["twelve"].moves["4bac"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HP
frame_data_meta["twelve"].moves["4f8c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LP
frame_data_meta["twelve"].moves["504c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MP
frame_data_meta["twelve"].moves["510c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HP

frame_data_meta["twelve"].moves["a9dc"] = { hits = {{ type = 3 }} } -- Air QCB LK
frame_data_meta["twelve"].moves["ad34"] = { hits = {{ type = 3 }} } -- Air QCB MK
frame_data_meta["twelve"].moves["af94"] = { hits = {{ type = 3 }} } -- Air QCB HK
frame_data_meta["twelve"].moves["b1f4"] = { hits = {{ type = 3 }} } -- Air QCB EX

-- CHUNLI
frame_data_meta["chunli"].moves["cac4"] = { hits = {{ type = 2 }, { type = 2 }, { type = 2 }} } -- Cr LK
frame_data_meta["chunli"].moves["cbb4"] = { hits = {{ type = 2 }} } -- Cr MK
frame_data_meta["chunli"].moves["cce4"] = { hits = {{ type = 2 }} } -- Cr HK
frame_data_meta["chunli"].moves["c804"] = { hits = {{ type = 2 }} } -- Cr MP

frame_data_meta["chunli"].moves["6a3c"] = { hits = {{ type = 3 }} } -- UOH
frame_data_meta["chunli"].moves["ce8c"] = { hits = {{ type = 3 }} } -- Cr Forward HK

frame_data_meta["chunli"].moves["d38c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LK
frame_data_meta["chunli"].moves["d49c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MK
frame_data_meta["chunli"].moves["d5ac"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HK
frame_data_meta["chunli"].moves["dbbc"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LK
frame_data_meta["chunli"].moves["dc5c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MK
frame_data_meta["chunli"].moves["debc"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HK
frame_data_meta["chunli"].moves["cfdc"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LP
frame_data_meta["chunli"].moves["d0ec"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MP
frame_data_meta["chunli"].moves["d1fc"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HP
frame_data_meta["chunli"].moves["d68c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LP
frame_data_meta["chunli"].moves["d72c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MP
frame_data_meta["chunli"].moves["d7dc"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HP
frame_data_meta["chunli"].moves["dd4c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air Down MK

frame_data_meta["chunli"].moves["6aec"] = { hits = {{ type = 3 }} } -- HCB LK
frame_data_meta["chunli"].moves["6e5c"] = { hits = {{ type = 3 }} } -- HCB MK
frame_data_meta["chunli"].moves["71cc"] = { hits = {{ type = 3 }} } -- HCB HK
frame_data_meta["chunli"].moves["753c"] = { hits = {{ type = 3 }} } -- HCB EXK

-- SEAN
frame_data_meta["sean"].moves["ca3c"] = { hits = {{ type = 2 }, { type = 2 }, { type = 2 }} } -- Cr LK
frame_data_meta["sean"].moves["cadc"] = { hits = {{ type = 2 }} } -- Cr MK
frame_data_meta["sean"].moves["cbac"] = { hits = {{ type = 2 }} } -- Cr HK
frame_data_meta["sean"].moves["1ef0"] = { hits = {{ type = 2 }}, hit_throw = true } -- HCF LP
frame_data_meta["sean"].moves["2060"] = { hits = {{ type = 2 }}, hit_throw = true } -- HCF MP
frame_data_meta["sean"].moves["2130"] = { hits = {{ type = 2 }}, hit_throw = true } -- HCF HP
frame_data_meta["sean"].moves["2200"] = { hits = {{ type = 2 }}, hit_throw = true } -- HCF EXP

frame_data_meta["sean"].moves["dad4"] = { force_recording = true } -- Target HK

frame_data_meta["sean"].moves["3e50"] = { hits = {{ type = 3 }} } -- UOH
frame_data_meta["sean"].moves["c25c"] = { hits = {{ type = 3 }, { type = 3 }} } -- Forward HP
frame_data_meta["sean"].moves["dc7c"] = { proxy = { id = "c25c", offset = 0 } } -- Target Forward HP

frame_data_meta["sean"].moves["28c0"] = { hits = {{ type = 3 }} } -- QCF K
frame_data_meta["sean"].moves["2a10"] = { hits = {{ type = 3 }, { type = 3 }, { type = 3 }} } -- QCF EXK

frame_data_meta["sean"].moves["cf1c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LK
frame_data_meta["sean"].moves["d02c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MK
frame_data_meta["sean"].moves["d0fc"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HK
frame_data_meta["sean"].moves["d47c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LK
frame_data_meta["sean"].moves["d55c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MK
frame_data_meta["sean"].moves["d63c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HK
frame_data_meta["sean"].moves["cc9c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LP
frame_data_meta["sean"].moves["cd7c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MP
frame_data_meta["sean"].moves["ce5c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HP
frame_data_meta["sean"].moves["d1dc"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LP
frame_data_meta["sean"].moves["d2bc"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MP
frame_data_meta["sean"].moves["d39c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HP

-- NECRO
frame_data_meta["necro"].moves["e18c"] = { hits = {{ type = 2 }} } -- Cr LK
frame_data_meta["necro"].moves["e29c"] = { hits = {{ type = 2 }} } -- Cr MK
frame_data_meta["necro"].moves["e444"] = { hits = {{ type = 2 }} } -- Cr HK

frame_data_meta["necro"].moves["7274"] = { hits = {{ type = 2 }}, hit_throw = true } -- Snake Fang L
frame_data_meta["necro"].moves["7374"] = { hits = {{ type = 2 }}, hit_throw = true } -- Snake Fang L
frame_data_meta["necro"].moves["7474"] = { hits = {{ type = 2 }}, hit_throw = true } -- Snake Fang L

frame_data_meta["necro"].moves["7cf4"] = { hits = {{ type = 3 }} } -- UOH
frame_data_meta["necro"].moves["7574"] = { hits = {{ type = 3 }} } -- Flying Viper L
frame_data_meta["necro"].moves["7674"] = { hits = {{ type = 3 }} } -- Flying Viper M
frame_data_meta["necro"].moves["7774"] = { hits = {{ type = 3 }} } -- Flying Viper H
frame_data_meta["necro"].moves["7874"] = { hits = {{ type = 3 }, { type = 3 }} } -- Flying Viper EX
frame_data_meta["necro"].moves["7d94"] = { hits = {{ type = 3 }} } -- Rising Cobra L
frame_data_meta["necro"].moves["7f24"] = { hits = {{ type = 3 }} } -- Rising Cobra M
frame_data_meta["necro"].moves["80b4"] = { hits = {{ type = 3 }} } -- Rising Cobra H
frame_data_meta["necro"].moves["8244"] = { hits = {{ type = 3 }, { type = 3 }} } -- Rising Cobra EX

frame_data_meta["necro"].moves["e954"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LK
frame_data_meta["necro"].moves["ec34"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MK
frame_data_meta["necro"].moves["ed74"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MK
frame_data_meta["necro"].moves["f224"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LK
frame_data_meta["necro"].moves["ec34"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MK
frame_data_meta["necro"].moves["ed74"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HK
frame_data_meta["necro"].moves["e5e4"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LP
frame_data_meta["necro"].moves["e6b4"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MP
frame_data_meta["necro"].moves["e7a4"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HP
frame_data_meta["necro"].moves["eef4"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LP
frame_data_meta["necro"].moves["efa4"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MP
frame_data_meta["necro"].moves["f084"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HP

-- DUDLEY
frame_data_meta["dudley"].moves["48fc"] = { hits = {{ type = 2 }, { type = 2 }, { type = 2 }} } -- Cr LK
frame_data_meta["dudley"].moves["49ec"] = { hits = {{ type = 2 }} } -- Cr MK
frame_data_meta["dudley"].moves["4bf4"] = { hits = {{ type = 2 }} } -- Cr HK

frame_data_meta["dudley"].moves["0a50"] = { hits = {{ type = 3 }} } -- UOH
frame_data_meta["dudley"].moves["4394"] = { hits = {{ type = 3 }} } -- Forward HK

frame_data_meta["dudley"].moves["51d4"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LK
frame_data_meta["dudley"].moves["5314"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MK
frame_data_meta["dudley"].moves["5454"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MK
frame_data_meta["dudley"].moves["5884"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LK
frame_data_meta["dudley"].moves["59c4"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MK
frame_data_meta["dudley"].moves["5b04"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HK
frame_data_meta["dudley"].moves["4ed4"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LP
frame_data_meta["dudley"].moves["4fb4"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MP
frame_data_meta["dudley"].moves["50b4"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HP
frame_data_meta["dudley"].moves["5584"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LP
frame_data_meta["dudley"].moves["5664"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MP
frame_data_meta["dudley"].moves["5764"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HP

frame_data_meta["dudley"].moves["656c"] = { proxy = { id = "3fd4", offset = 0 } } -- Target MK
frame_data_meta["dudley"].moves["675c"] = { proxy = { id = "3914", offset = 0 } } -- Target MP

-- YANG
frame_data_meta["yang"].moves["d45c"] = { hits = {{ type = 2 }, { type = 2 }, { type = 2 }} } -- Cr LK
frame_data_meta["yang"].moves["d52c"] = { hits = {{ type = 2 }} } -- Cr MK
frame_data_meta["yang"].moves["d6a4"] = { hits = {{ type = 2 }} } -- Cr HK
frame_data_meta["yang"].moves["d1c4"] = { hits = {{ type = 2 }} } -- Cr MP

frame_data_meta["yang"].moves["dd18"] = { hits = {{ type = 3 }} } -- UOH
frame_data_meta["yang"].moves["caa4"] = { hits = {{ type = 3 }} } -- Forward MK

frame_data_meta["yang"].moves["f50c"] = { force_recording = true } -- Target HK
frame_data_meta["yang"].moves["ef0c"] = { proxy = { id = "c4c4", offset = 0 } } -- Target HP
frame_data_meta["yang"].moves["f0fc"] = { force_recording = true } -- Target Back HP

frame_data_meta["yang"].moves["dbfc"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LK
frame_data_meta["yang"].moves["dd3c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MK
frame_data_meta["yang"].moves["de8c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HK
frame_data_meta["yang"].moves["e25c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LK
frame_data_meta["yang"].moves["e44c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MK
frame_data_meta["yang"].moves["e65c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HK
frame_data_meta["yang"].moves["d8ac"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LP
frame_data_meta["yang"].moves["d99c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MP
frame_data_meta["yang"].moves["da8c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HP
frame_data_meta["yang"].moves["df8c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LP
frame_data_meta["yang"].moves["e08c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MP
frame_data_meta["yang"].moves["e17c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HP
frame_data_meta["yang"].moves["e39c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Dive L
frame_data_meta["yang"].moves["e5ac"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Dive M
frame_data_meta["yang"].moves["e75c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Dive H

-- YUN
frame_data_meta["yun"].moves["53bc"] = { hits = {{ type = 2 }} } -- Cr LK
frame_data_meta["yun"].moves["548c"] = { hits = {{ type = 2 }} } -- Cr MK
frame_data_meta["yun"].moves["a014"] = { hits = {{ type = 2 }} } -- Cr HK

frame_data_meta["yun"].moves["5e50"] = { hits = {{ type = 3 }} } -- UOH
frame_data_meta["yun"].moves["4d2c"] = { hits = {{ type = 3 }} } -- Forward MK

frame_data_meta["yun"].moves["5b6c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LK
frame_data_meta["yun"].moves["5cac"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MK
frame_data_meta["yun"].moves["5dfc"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HK
frame_data_meta["yun"].moves["61cc"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LK
frame_data_meta["yun"].moves["63bc"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MK
frame_data_meta["yun"].moves["65bc"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HK
frame_data_meta["yun"].moves["580c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air LP
frame_data_meta["yun"].moves["590c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air MP
frame_data_meta["yun"].moves["59fc"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Straight Air HP
frame_data_meta["yun"].moves["5efc"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LP
frame_data_meta["yun"].moves["5ffc"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MP
frame_data_meta["yun"].moves["60ec"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HP
frame_data_meta["yun"].moves["630c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Dive L
frame_data_meta["yun"].moves["650c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Dive M
frame_data_meta["yun"].moves["66bc"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Dive H

frame_data_meta["yun"].moves["6b14"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Target Air HP
frame_data_meta["yun"].moves["748c"] = { proxy = { id = "48bc", offset = 0 } } -- Target LK
frame_data_meta["yun"].moves["75a4"] = { proxy = { id = "415c", offset = 0 } } -- Target MP

frame_data_meta["yun"].moves["8964"] = { hits = {{ type = 2 }} } -- genei Cr LK
frame_data_meta["yun"].moves["8a04"] = { hits = {{ type = 2 }} } -- genei Cr MK
frame_data_meta["yun"].moves["8ae4"] = { hits = {{ type = 2 }} } -- genei Cr HK

frame_data_meta["yun"].moves["62f0"] = { hits = {{ type = 3 }} } -- genei UOH
frame_data_meta["yun"].moves["83ec"] = { hits = {{ type = 3 }} } -- genei Forward MK

frame_data_meta["yun"].moves["8c8c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Genei Straight Air LP
frame_data_meta["yun"].moves["8d6c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Genei Straight Air MP
frame_data_meta["yun"].moves["8e4c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Genei Straight Air HP
frame_data_meta["yun"].moves["a7c0"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Genei Straight Air LK
frame_data_meta["yun"].moves["976c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Genei Straight Air MK
frame_data_meta["yun"].moves["920c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Genei Straight Air HK
frame_data_meta["yun"].moves["92fc"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Genei Air LP
frame_data_meta["yun"].moves["93ec"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Genei Air MP
frame_data_meta["yun"].moves["94cc"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Genei Air HP
frame_data_meta["yun"].moves["959c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Genei Air LK
frame_data_meta["yun"].moves["976c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Genei Air MK
frame_data_meta["yun"].moves["994c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Genei Air HK
frame_data_meta["yun"].moves["96cc"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Genei Dive L
frame_data_meta["yun"].moves["98ac"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Genei Dive M
frame_data_meta["yun"].moves["9a3c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Genei Dive H
frame_data_meta["yun"].moves["9f04"] = { proxy = { id = "920c", offset = 2 } } -- Genei Target Air HP

frame_data_meta["yun"].moves["5c30"] = { hits = {{ bypass_freeze = true }, { bypass_freeze = true }, { bypass_freeze = true }}, movement_type = 2 } -- Genei QCF LP
