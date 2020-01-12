--
--  3rd_training.lua - v0.1

--  Training mode for Street Fighter III 3rd Strike (USA 990512), on FBA-RR emulator
--  https://github.com/Grouflon/3rd_training_lua
--

-- FBA-RR Scripting reference:
-- http://tasvideos.org/EmulatorResources/VBA/LuaScriptingFunctions.html
-- https://github.com/TASVideos/mame-rr/wiki/Lua-scripting-functions

json = require ("lua_libs/dkjson")

-- players
function make_input_set()
  return {
    up = false,
    down = false,
    left = false,
    right = false,
    LP = false,
    MP = false,
    HP = false,
    LK = false,
    MK = false,
    HK = false,
    start = false,
    coin = false
  }
end

function make_player_object(_id, _base, _prefix)
  return {
    id = _id,
    base = _base,
    prefix = _prefix,
    input = {
      pressed = make_input_set(),
      released = make_input_set(),
      down = make_input_set()
    },
    blocking = {},
    counter = {},
  }
end

player_objects = {
  make_player_object(1, 0x02068C6C, "P1"),
  make_player_object(2, 0x02069104, "P2")
}

P1 = player_objects[1]
P2 = player_objects[2]

function update_input(_player_obj)

  function update_player_input(_input_object, _input_name, _input)
    _input_object.pressed[_input_name] = false
    _input_object.released[_input_name] = false
    if _input_object.down[_input_name] == false and _input then _input_object.pressed[_input_name] = true end
    if _input_object.down[_input_name] == true and _input == false then _input_object.released[_input_name] = true end
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

function queue_input_sequence(_player_obj, _sequence)
  if #_sequence == 0 then
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

function process_pending_input_sequence(_player_obj)
  if _player_obj.pending_input_sequence == nil then
    return
  end

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
  local _input = {}
  local _current_frame_input = _player_obj.pending_input_sequence.sequence[_player_obj.pending_input_sequence.current_frame]
  for i = 1, #_current_frame_input do
    local _input_name = _player_obj.prefix.." "
    if _current_frame_input[i] == "forward" then
      if _player_obj.flip_x then _input_name = _input_name.."Right" else _input_name = _input_name.."Left" end
    elseif _current_frame_input[i] == "back" then
      if _player_obj.flip_x then _input_name = _input_name.."Left" else _input_name = _input_name.."Right" end
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
  joypad.set(_input)

  --print(_s)

  _player_obj.pending_input_sequence.current_frame = _player_obj.pending_input_sequence.current_frame + 1
  if _player_obj.pending_input_sequence.current_frame > #_player_obj.pending_input_sequence.sequence then
    _player_obj.pending_input_sequence = nil
  end
end

function clear_input_sequence(_player_obj)
  _player_obj.pending_input_sequence = nil
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

fast_recovery_mode =
{
  "never",
  "always",
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
}


hit_type =
{
  "normal",
  "low",
  "overhead",
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

-- menu
text_default_color = 0xF7FFF7FF
text_default_border_color = 0x101008FF
text_selected_color = 0xFF0000FF
text_disabled_color = 0x999999FF

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
    gui.text(_x, _y, _prefix..self.name.." : "..tostring(self.object[self.property_name]).._suffix, _c, text_default_border_color)
  end

  function _o:left()
    self.object[self.property_name] = not self.object[self.property_name]
  end

  function _o:right()
    self.object[self.property_name] = not self.object[self.property_name]
  end

  function _o:validate()
  end

  function _o:cancel()
    self.object[self.property_name] = self.default_value
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

  function _o:validate()
  end

  function _o:cancel()
    self.object[self.property_name] = self.default_value
  end

  return _o
end

function integer_menu_item(_name, _object, _property_name, _min, _max, _loop, _default_value)
  if _default_value == nil then _default_value = _min end
  local _o = {}
  _o.name = _name
  _o.object = _object
  _o.property_name = _property_name
  _o.min = _min
  _o.max = _max
  _o.loop = _loop
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

  function _o:validate()
  end

  function _o:cancel()
    self.object[self.property_name] = self.default_value
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

  function _o:validate()
  end

  function _o:cancel()
    training_settings[self.property_name] = ""
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

  function _o:left()
  end

  function _o:right()
  end

  function _o:validate()
    self.last_frame_validated = frame_number
    self.validate_function()
  end

  function _o:cancel()
  end

  return _o
end

-- save/load
training_data_file = "3rd_training_data.txt"
function save_training_data()
  f = io.open(training_data_file, "w")
  for key, value in pairs(training_settings) do
    f:write(key.."="..tostring(value).."\n")
  end
  f:close()
end

function load_training_data()
  f = io.open(training_data_file, "r")
  if f == nil then
    return
  end

  for line in f:lines() do
    local a1 = line:split("=")
    local key = nil
    local value = nil
    if #a1 > 0 then
      key = a1[1]
      value = a1[2]
    end

    if key ~= nil and value ~= nil then
      local type = type(training_settings[key])
      local v = nil
      if type == "boolean" then
        if value == "true" then v = true else v = false end
      elseif type == "number" then
        v = tonumber(value)
      end

      if v ~= nil then
        training_settings[key] = v
      end
    end
  end
  f:close()
end

-- swap inputs
function swap_inputs(_in_input_table, _out_input_table)
  function swap(_input)
    local carry = _in_input_table["P1 ".._input]
    _out_input_table["P1 ".._input] = nil

    --_out_input_table["P1 ".._input] = _in_input_table["P2 ".._input]
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

-- game data
frame_number = 0
is_in_match = false

-- HITBOXES
frame_data = {}
frame_data_meta = {}
for i = 1, #characters do
  frame_data_meta[characters[i]] = {
    moves = {}
  }
end
frame_data_file = "frame_data.json"

function save_frame_data()
  local _f = io.open(frame_data_file, "w")
  local _str = json.encode(frame_data, { indent = true })
  _f:write(_str)
  _f:close()

  print("Saved frame data to \""..frame_data_file.."\"")

end

function load_frame_data()
  local _f = io.open(frame_data_file, "r")
  if _f == nil then
    return
  end

  local pos, err
  frame_data, pos, err = json.decode(_f:read("*all"))
  _f:close()

  if (err) then
    print("Failed to read frame data file: "..err)
  end
end

function reset_current_recording_animation()
  current_recording_animation_previous_pos = {0, 0}
  current_recording_animation = nil
end
reset_current_recording_animation()

function record_framedata(_player_obj)
  local _debug = true
  -- any connecting attack frame data will be ill formed. We discard it immediately to avoid data loss (except for moves tagged as "cancel" that are difficult to record otherwise)
  if (_player_obj.has_just_hit or _player_obj.has_just_been_blocked or _player_obj.has_just_been_parried) then
    if not frame_data_meta[_player_obj.char_str] or not frame_data_meta[_player_obj.char_str].moves[_player_obj.animation] or not frame_data_meta[_player_obj.char_str].moves[_player_obj.animation].cancel then
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
      if (frame_data[_player_obj.char_str] == nil) then
        frame_data[_player_obj.char_str] = {}
      end
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

    if _player_obj.remaining_freeze_frames > 1 then
      _player_obj.current_animation_freeze_frames = _player_obj.current_animation_freeze_frames + 1
    else
      local _frame = frame_number - _player_obj.current_animation_freeze_frames - _player_obj.current_animation_start_frame
      --print(string.format("recording frame %d (%d - %d - %d)", _frame, frame_number, _player_obj.current_animation_freeze_frames, _player_obj.current_animation_start_frame))

      if (_player_obj.has_just_acted) or _player_obj.remaining_freeze_frames == 1 then
        table.insert(current_recording_animation.hit_frames, _frame - #current_recording_animation.hit_frames)
      end

      local _sign = 1
      if _player_obj.flip_x ~= 0 then _sign = -1 end

      current_recording_animation.frames[_frame + 1] = {
        boxes = {},
        movement = {
          (_player_obj.pos_x - current_recording_animation_previous_pos[1]) * _sign,
          (_player_obj.pos_y - current_recording_animation_previous_pos[2]),
        }
      }
      current_recording_animation_previous_pos = { _player_obj.pos_x, _player_obj.pos_y }

      for __, _box in ipairs(_player_obj.boxes) do
        if (_box.type == "attack") then
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
  elseif _obj.projectile then
    _type = projectile_type[_type] or _type
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
    return
  end

  _obj.friends = memory.readbyte(_obj.base + 0x1)
  _obj.flip_x = memory.readbytesigned(_obj.base + 0x0A) -- sprites are facing left by default
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

function update_draw_hitboxes()
  if (not training_settings.display_hitboxes) then
    return
  end

  screen_x = memory.readwordsigned(0x02026CB0)
  screen_y = memory.readwordsigned(0x02026CB4)
  scale = memory.readwordsigned(0x0200DCBA) --FBA can't read from 04xxxxxx
  scale = 0x40/(scale > 0 and scale or 1)
  ground_offset = 23

  draw_hitboxes(player_objects[1].pos_x, player_objects[1].pos_y, player_objects[1].flip_x, player_objects[1].boxes)
  draw_hitboxes(player_objects[2].pos_x, player_objects[2].pos_y, player_objects[2].flip_x, player_objects[2].boxes)

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

function draw_hitboxes(_pos_x, _pos_y, _flip_x, _boxes)
  local _px = _pos_x - screen_x + emu.screenwidth()/2
  local _py = emu.screenheight() - (_pos_y - screen_y) - ground_offset

  for __, _box in ipairs(_boxes) do

    local _c = 0x0000FFFF
    if (_box.type == "attack") then
      _c = 0xFF0000FF
    elseif (_box.type == "throwable") then
      _c = 0x00FF00FF
    elseif (_box.type == "throw") then
      _c = 0x77FF00FF
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

    gui.box(_l, _b, _r, _t, 0x00000000, _c)
  end
end

function test_collision(_defender_x, _defender_y, _defender_flip_x, _defender_boxes, _attacker_x, _attacker_y, _attacker_flip_x, _attacker_boxes, _defender_hitbox_dilation)

  local _debug = false
  if (_defender_hitbox_dilation == nil) then _defender_hitbox_dilation = 0 end

  if _debug then print(string.format("   %d defender boxes, %d attacker boxes", #_defender_boxes, #_attacker_boxes)) end

  for i = 1, #_defender_boxes do
    local _d_box = _defender_boxes[i]
    if _d_box.type == "vulnerability" or _d_box.type == "ext. vulnerability" then
      -- compute defender box bounds
      local _d_l
      if _defender_flip_x == 0 then
        _d_l = _defender_x + _d_box.left - _defender_hitbox_dilation
      else
        _d_l = _defender_x - _d_box.left - _d_box.width - _defender_hitbox_dilation
      end
      local _d_r = _d_l + _d_box.width + _defender_hitbox_dilation
      local _d_b = _defender_y + _d_box.bottom - _defender_hitbox_dilation
      local _d_t = _d_b + _d_box.height + _defender_hitbox_dilation

      for j = 1, #_attacker_boxes do
        local _a_box = _attacker_boxes[j]
        if _a_box.type == "attack" then
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

          if _debug then print(string.format("   testing (%d,%d,%d,%d) against (%d,%d,%d,%d)", _d_t, _d_r, _d_b, _d_l, _a_t, _a_r, _a_b, _a_l)) end

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

  return false
end

-- POSE
function update_pose(_input, _player_obj, _pose)
  -- pose
if is_in_match and not is_menu_open and _player_obj.pending_input_sequence == nil then
  if _pose == 2 and (_player_obj.standing_state == 0x01 or _player_obj.standing_state == 0x02) then -- crouch
    _input[_player_obj.prefix..' Down'] = true
  elseif _pose == 3 and (_player_obj.standing_state == 0x01 or _player_obj.standing_state == 0x02) then -- jump
    _input[_player_obj.prefix..' Up'] = true
  elseif _pose == 4 then -- high jump
    local _on_ground = (_player_obj.standing_state == 0x01 or _player_obj.standing_state == 0x02)
    if _on_ground and _player_obj.pending_input_sequence == nil then
      queue_input_sequence(_player_obj, {{"down"}, {"up"}})
    end
  end
end
end

-- BLOCKING

function update_blocking(_input, _player, _dummy, _mode, _style, _red_parry_hit_count)

  local _debug = false
  if _player.has_animation_just_changed then
    if (
      (
        frame_data[_player.char_str] and
        frame_data[_player.char_str][_player.animation]
      )
      or
      (
        frame_data_meta[_player.char_str] and
        frame_data_meta[_player.char_str].moves[_player.animation] and
        frame_data_meta[_player.char_str].moves[_player.animation].intro and
        frame_data[_player.char_str] and
        frame_data[_player.char_str][frame_data_meta[_player.char_str].moves[_player.animation].intro.next]
      )
    ) then
      _player.blocking.listening = true
      _player.blocking.current_animation_id = _player.animation
      _player.blocking.current_animation_start_frame = _player.animation
      _player.blocking.next_attack_animation_hit_frame = 0
      _player.blocking.next_attack_hit_id = 0
      _player.blocking.last_attack_hit_id = 0

      -- special case for animations that introduce animations that hit at frame 0
      if frame_data_meta[_player.char_str] and frame_data_meta[_player.char_str].moves[_player.animation] and frame_data_meta[_player.char_str].moves[_player.animation].intro then
        _player.blocking.current_animation_id = frame_data_meta[_player.char_str].moves[_player.animation].intro.next
        _player.blocking.current_animation_start_frame = _player.current_animation_start_frame + frame_data_meta[_player.char_str].moves[_player.animation].intro.length
      end

      if _debug then
        print(_player.blocking.current_animation_start_frame..": listening for attack animation \"".._player.blocking.current_animation_id.."\"")
      end
    else
      if _debug and _player.blocking.listening then
        print(string.format("%d: Stopped listening for attack animation", frame_number))
      end
      _player.blocking.listening = false
      _player.blocking.blocked_hit_count = 0
    end
  end

  if _mode == 1 then
    _player.blocking.listening = false
    _player.blocking.blocked_hit_count = 0
  end

  if _player.blocking.listening then
    local _frame = frame_number - _player.current_animation_start_frame - (_player.current_animation_freeze_frames - 1)
    local _frame_data_meta = frame_data_meta[_player.char_str].moves[_player.blocking.current_animation_id]
    local _frame_to_check = math.max(_frame + 1, _frame - _player.remaining_freeze_frames + 2)
    local _current_animation_pos = {_player.pos_x, _player.pos_y}
    local _frame_delta = _frame_to_check - _frame

    --print(string.format("update blocking frame %d (freeze: %d)", _frame, P1_current_animation_freeze_frames - 1))

    local _next_hit_id = 1
    for i = 1, #frame_data[_player.char_str][_player.blocking.current_animation_id].hit_frames do
      if _frame_to_check >= frame_data[_player.char_str][_player.blocking.current_animation_id].hit_frames[i] then
        _next_hit_id = i
      end
    end

    if (_player.blocking.next_attack_animation_hit_frame < frame_number and _frame_to_check < #frame_data[_player.char_str][_player.blocking.current_animation_id].frames) then

      if _debug then
        print(string.format(" comparing frame %d with frame %d (%d freeze frames)(hit %d)", _frame, _frame_to_check, _player.current_animation_freeze_frames, _next_hit_id))
      end
      local _next_frame = frame_data[_player.char_str][_player.blocking.current_animation_id].frames[_frame_to_check + 1]
      local _sign = 1
      if _player.flip_x ~= 0 then _sign = -1 end
      local _next_attacker_pos = copytable(_current_animation_pos)
      local _movement_type = 1
      if _frame_data_meta and _frame_data_meta.movement_type then
        _movement_type = _frame_data_meta.movement_type
      end
      if _movement_type == 1 then -- animation base movement
        for i = _frame + 1, _frame_to_check do
          if i >= 0 then
            _next_attacker_pos[1] = _next_attacker_pos[1] + frame_data[_player.char_str][_player.blocking.current_animation_id].frames[i+1].movement[1] * _sign
            _next_attacker_pos[2] = _next_attacker_pos[2] + frame_data[_player.char_str][_player.blocking.current_animation_id].frames[i+1].movement[2]
          end
        end
      else -- velocity based movement
        local _velocity_x = _player.velocity_x
        local _velocity_y = _player.velocity_y
        for i = 1, _frame_delta do
          _velocity_x = _velocity_x + _player.acc_x
          _velocity_y = _velocity_y + _player.acc_y
          _next_attacker_pos[1] = _next_attacker_pos[1] + _velocity_x
          _next_attacker_pos[2] = _next_attacker_pos[2] + _velocity_y
        end
      end

      local _next_defender_pos = { _dummy.pos_x, _dummy.pos_y }
      local _velocity_x = _dummy.velocity_x
      local _velocity_y = _dummy.velocity_y
      for i = 1, _frame_delta do
        _velocity_x = _velocity_x + _dummy.acc_x
        _velocity_y = _velocity_y + _dummy.acc_y
        _next_defender_pos[1] = _next_defender_pos[1] + _velocity_x
        _next_defender_pos[2] = _next_defender_pos[2] + _velocity_y
      end

      if _next_frame and _next_hit_id > _player.blocking.last_attack_hit_id and test_collision(
        _next_defender_pos[1], _next_defender_pos[2], _dummy.flip_x, _dummy.boxes, -- defender
        _next_attacker_pos[1], _next_attacker_pos[2], _player.flip_x, _next_frame.boxes, -- attacker
        3 -- defender hitbox dilation
      ) then
        _player.blocking.next_attack_animation_hit_frame = frame_number + _player.remaining_freeze_frames + _frame_delta
        _player.blocking.next_attack_hit_id = _next_hit_id
        if _debug then
          print(string.format(" %d: next hit %d at frame %d", frame_number, _player.blocking.next_attack_hit_id, _player.blocking.next_attack_animation_hit_frame))
        end
      end
    end


    if frame_number <= _player.blocking.next_attack_animation_hit_frame and _player.blocking.last_attack_hit_id < _player.blocking.next_attack_hit_id then

      local _hit_type = 1
      local _blocking_style = _style

      if _blocking_style == 3 then -- red parry
        if _player.blocking.blocked_hit_count ~= _red_parry_hit_count then
          _blocking_style = 1
        else
          _blocking_style = 2
        end
      end

      if _frame_data_meta and _frame_data_meta.hits and _frame_data_meta.hits[_player.blocking.next_attack_hit_id] then
        _hit_type = _frame_data_meta.hits[_player.blocking.next_attack_hit_id].type
      end

      if frame_number == _player.blocking.next_attack_animation_hit_frame then
        _player.blocking.last_attack_hit_id = _player.blocking.next_attack_hit_id
        _player.blocking.blocked_hit_count = _player.blocking.blocked_hit_count + 1
      end

      if _blocking_style == 1 then
        if frame_number >= _player.blocking.next_attack_animation_hit_frame - 2 then
          if _dummy.flip_x == 0 then
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

        local _parry_low = _hit_type == 2 --or (_hit_type ~= 3 and training_settings.pose == 2)

        if frame_number == _player.blocking.next_attack_animation_hit_frame - 1 then
          if _parry_low then
            _input[_dummy.prefix..' Down'] = true
          else
            _input[_dummy.prefix..' Right'] = _dummy.flip_x ~= 0
            _input[_dummy.prefix..' Left'] = _dummy.flip_x == 0
          end
        end
      end
    end
  end
end

function update_counter_attack(_input, _attacker, _defender, _stick, _button)

  local _debug = false

  if not is_in_match then return end
  if _stick == 1 and _button == 1 then return end

  if _defender.has_just_parried then
    if _debug then
      print(frame_number.." - init ca")
    end
    _defender.counter.attack_frame = frame_number + 16
    _defender.counter.sequence = make_input_sequence(_dummy, stick_gesture[_stick], button_gesture[_button])
    _defender.counter.ref_time = -1
  elseif _attacker.has_just_hit or _attacker.has_just_been_blocked then
    if _debug then
      print(frame_number.." - init ca")
    end
    _defender.counter.ref_time = _defender.recovery_time
    clear_input_sequence(_defender)
    _defender.counter.sequence = nil
  elseif _defender.has_just_started_wake_up or _defender.has_just_started_fast_wake_up then
    if _debug then
      print(frame_number.." - init ca")
    end
    _defender.counter.attack_frame = frame_number + _defender.wake_up_time
    _defender.counter.sequence = make_input_sequence(stick_gesture[_stick], button_gesture[_button])
    _defender.counter.ref_time = -1
  end

  if not _defender.counter.sequence then
    if _defender.counter.ref_time ~= -1 and _defender.recovery_time ~= _defender.counter.ref_time then
      if _debug then
        print(frame_number.." - setup ca")
      end
      _defender.counter.attack_frame = frame_number + _defender.recovery_time + 2
      _defender.counter.sequence = make_input_sequence(stick_gesture[_stick], button_gesture[_button])
      _defender.counter.ref_time = -1
    end
  end


  if _defender.counter.sequence then
    local _frames_remaining = _defender.counter.attack_frame - frame_number
    if _debug then
      print(_frames_remaining)
    end
    if _frames_remaining <= (#_defender.counter.sequence + 1) then
      if _debug then
        print(frame_number.." - queue ca")
      end
      queue_input_sequence(_defender, _defender.counter.sequence)
      _defender.counter.sequence = nil
    end
  end
end

-- GUI DECLARATION

training_settings = {
  pose = 1,
  blocking_style = 1,
  blocking_mode = 1,
  dummy_player = 2,
  red_parry_hit_count = 1,
  counter_attack_stick = 1,
  counter_attack_button = 1,
  fast_recovery_mode = 1,
  infinite_time = true,
  infinite_life = true,
  infinite_meter = true,
  no_stun = true,
  display_input = true,
  display_hitboxes = false,
}

debug_settings = {
  swap_characters = false,
  record_framedata = false,
  debug_character = "",
  debug_move = "",
}

debug_move_menu_item = map_menu_item("Debug Move", debug_settings, "debug_move", frame_data, nil)

menu = {
  {
    name = "Dummy Settings",
    entries = {
      list_menu_item("Pose", training_settings, "pose", pose),
      list_menu_item("Blocking Style", training_settings, "blocking_style", blocking_style),
      list_menu_item("Blocking", training_settings, "blocking_mode", blocking_mode),
      integer_menu_item("Hits before Red Parry", training_settings, "red_parry_hit_count", 1, 20, true),
      list_menu_item("Counter-Attack Move", training_settings, "counter_attack_stick", stick_gesture),
      list_menu_item("Counter-Attack Button", training_settings, "counter_attack_button", button_gesture),
      list_menu_item("Fast Recovery", training_settings, "fast_recovery_mode", fast_recovery_mode),
    }
  },
  {
    name = "Training Settings",
    entries = {
      checkbox_menu_item("Infinite Time", training_settings, "infinite_time"),
      checkbox_menu_item("Infinite Life", training_settings, "infinite_life"),
      checkbox_menu_item("Infinite Meter", training_settings, "infinite_meter"),
      checkbox_menu_item("No Stun", training_settings, "no_stun"),
      checkbox_menu_item("Display Input", training_settings, "display_input"),
      checkbox_menu_item("Display Hitboxes", training_settings, "display_hitboxes"),
      list_menu_item("Dummy Player", training_settings, "dummy_player", players),
    }
  },
  {
    name = "Debug Settings",
    entries = {
      checkbox_menu_item("Swap Characters", debug_settings, "swap_characters"),
      checkbox_menu_item("Record Frame Data", debug_settings, "record_framedata"),
      button_menu_item("Save Frame Data", save_frame_data),
      map_menu_item("Debug Character", debug_settings, "debug_character", _G, "frame_data"),
      debug_move_menu_item
    }
  },
}

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
end

function write_game_vars()
  -- character swap
  if is_in_match then
    local P1_disable_input_address = 0x02068C74
    if debug_settings.swap_characters then
      swap_inputs(joypad.get(), input)
      memory.writebyte(P1_disable_input_address, 0x01)
    else
      memory.writebyte(P1_disable_input_address, 0x00)
    end
  end

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
end

debug_current_animation = false

P1.debug_state_variables = false
P1.debug_standing_state = false
P1.debug_wake_up = false

P2.debug_state_variables = false
P2.debug_standing_state = false
P2.debug_wake_up = false

function read_player_vars(_player_obj)

-- P1: 0x02068C6C
-- P2: 0x02069104

  if memory.readdword(_player_obj.base + 0x2A0) == 0 then --invalid objects
    return
  end

  update_input(_player_obj)
  update_game_object(_player_obj)

  _player_obj.char_str = characters[_player_obj.char_id]
  _player_obj.is_attacking_ext = memory.readbyte(_player_obj.base + 0x429) > 0
  _player_obj.input_capacity = memory.readword(_player_obj.base + 0x46C)
  _player_obj.action = memory.readdword(_player_obj.base + 0xAC)
  _player_obj.action_ext = memory.readdword(_player_obj.base + 0x12C)
  _player_obj.is_blocking = memory.readbyte(_player_obj.base + 0x3D3) > 0
  _player_obj.remaining_freeze_frames = memory.readbyte(_player_obj.base + 0x45)
  _player_obj.recovery_time = memory.readbyte(_player_obj.base + 0x187)

  local _prev_pos_x = _player_obj.pos_x or 0
  local _prev_pos_y = _player_obj.pos_y or 0
  local _prev_velocity_x = _player_obj.velocity_x or 0
  local _prev_velocity_y = _player_obj.velocity_y or 0
  _player_obj.velocity_x = _player_obj.pos_x - _prev_pos_x
  _player_obj.velocity_y = _player_obj.pos_y - _prev_pos_y
  _player_obj.acc_x = _player_obj.velocity_x - _prev_velocity_x
  _player_obj.acc_y = _player_obj.velocity_y - _prev_velocity_y

  -- ATTACKING
  local _previous_is_attacking = _player_obj.is_attacking or false
  _player_obj.is_attacking = memory.readbyte(_player_obj.base + 0x428) > 0
  _player_obj.has_just_attacked =  _player_obj.is_attacking and not _previous_is_attacking
  if _player_obj.debug_state_variables and _player_obj.has_just_attacked then print(string.format("%d - %s attacked", frame_number, _player_obj.prefix)) end

  -- ACTION
  local _previous_action_count = _player_obj.action_count or 0
  _player_obj.action_count = memory.readbyte(_player_obj.base + 0x459)
  _player_obj.has_just_acted = _player_obj.action_count > _previous_action_count
  if _player_obj.debug_state_variables and _player_obj.has_just_acted then print(string.format("%d - %s acted (%d > %d)", frame_number, _player_obj.prefix, _previous_action_count, _player_obj.action_count)) end

  -- HITS
  local _previous_hit_count = _player_obj.hit_count or 0
  _player_obj.hit_count = memory.readbyte(_player_obj.base + 0x189)
  _player_obj.has_just_hit = _player_obj.hit_count > _previous_hit_count
  if _player_obj.debug_state_variables and _player_obj.has_just_hit then print(string.format("%d - %s hit (%d > %d)", frame_number, _player_obj.prefix, _previous_hit_count, _player_obj.hit_count)) end

  -- BLOCKS
  local _previous_connected_action_count = _player_obj.connected_action_count or 0
  local _previous_blocked_count = _previous_connected_action_count - _previous_hit_count
  _player_obj.connected_action_count = memory.readbyte(_player_obj.base + 0x17B)
  local _blocked_count = _player_obj.connected_action_count - _player_obj.hit_count
  _player_obj.has_just_been_blocked = _blocked_count > _previous_blocked_count
  if _player_obj.debug_state_variables and _player_obj.has_just_been_blocked then print(string.format("%d - %s blocked (%d > %d)", frame_number, _player_obj.prefix, _previous_blocked_count, _blocked_count)) end

  -- LANDING
  _player_obj.previous_standing_state = _player_obj.standing_state or 0
  _player_obj.standing_state = memory.readbyte(_player_obj.base + 0x297)
  _player_obj.has_just_landed = _player_obj.previous_standing_state >= 3 and _player_obj.standing_state < 3
  if _player_obj.debug_state_variables and _player_obj.has_just_landed then print(string.format("%d - %s landed (%d > %d)", frame_number, _player_obj.prefix, _player_obj.previous_standing_state, _player_obj.standing_state)) end
  if _player_obj.debug_standing_state and _player_obj.previous_standing_state ~= _player_obj.standing_state then print(string.format("%d - %s standing state changed (%d > %d)", frame_number, _player_obj.prefix, _player_obj.previous_standing_state, _player_obj.standing_state)) end

  -- ANIMATION
  local _previous_animation = _player_obj.animation or ""
  _player_obj.animation = bit.tohex(memory.readword(_player_obj.base + 0x202), 4)
  _player_obj.has_animation_just_changed = _previous_animation ~= _player_obj.animation
  if _player_obj.debug_state_variables and _player_obj.has_animation_just_changed then print(string.format("%d - %s animation changed (%s -> %s)", frame_number, _player_obj.prefix, _previous_animation, _player_obj.animation)) end

  if _player_obj.has_animation_just_changed then
    _player_obj.current_animation_start_frame = frame_number
    _player_obj.current_animation_freeze_frames = 0
  else
    -- has_just_attacked can change in the middle of an attack (see Alex's QCF Ps) so we need to ensure all hits are past us in order to allow transition to the same animation
    local _all_hits_done = true
    local _frame = frame_number - _player_obj.current_animation_start_frame - (_player_obj.current_animation_freeze_frames - 1)
    if (frame_data[_player_obj.char_str] and frame_data[_player_obj.char_str][_player_obj.animation]) then
      for __, _hit_frame in ipairs(frame_data[_player_obj.char_str][_player_obj.animation].hit_frames) do
        if _frame < _hit_frame then
          _all_hits_done = false
          break
        end
      end
    end
    if _player_obj.has_just_attacked and _all_hits_done then
      _player_obj.has_animation_just_changed = true
      _player_obj.current_animation_start_frame = frame_number
      _player_obj.current_animation_freeze_frames = 0
    end
  end

  if _player_obj.remaining_freeze_frames > 0 then
    _player_obj.current_animation_freeze_frames = _player_obj.current_animation_freeze_frames + 1
  end

  if is_in_match then

    -- WAKE UP
    local _previous_is_waking_up = _player_obj.is_waking_up or false
    local _previous_is_fast_waking_up = _player_obj.is_fast_waking_up or false

    if not _player_obj.is_waking_up and character_specific[_player_obj.char_str].wake_ups then
      for i = 1, #character_specific[_player_obj.char_str].wake_ups do
        if _previous_animation ~= character_specific[_player_obj.char_str].wake_ups[i].animation and _player_obj.animation == character_specific[_player_obj.char_str].wake_ups[i].animation then
          _player_obj.is_waking_up = true
          _player_obj.wake_up_time = character_specific[_player_obj.char_str].wake_ups[i].length
          _player_obj.waking_up_start_frame = frame_number
          _player_obj.wake_up_animation = _player_obj.animation
          break
        end
      end
    end

    if not _player_obj.is_fast_waking_up and character_specific[_player_obj.char_str].fast_wake_ups then
      for i = 1, #character_specific[_player_obj.char_str].fast_wake_ups do
        if _previous_animation ~= character_specific[_player_obj.char_str].fast_wake_ups[i].animation and _player_obj.animation == character_specific[_player_obj.char_str].fast_wake_ups[i].animation then
          _player_obj.is_fast_waking_up = true
          _player_obj.wake_up_time = character_specific[_player_obj.char_str].fast_wake_ups[i].length
          _player_obj.waking_up_start_frame = frame_number
          _player_obj.wake_up_animation = _player_obj.animation
          break
        end
      end
    end

    if _player_obj.debug_wake_up then
      if (_player_obj.is_waking_up or _player_obj.is_fast_waking_up) and (_previous_standing_state == 0x00 and _player_obj.standing_state ~= 0x00) then
        print(string.format("%d - %d %d %s wake_up_time: %d", frame_number, to_bit(_player_obj.is_waking_up), to_bit(_player_obj.is_fast_waking_up), _player_obj.wake_up_animation, (frame_number - P2_waking_up_start_frame) + 1))
      end
      if (_player_obj.has_animation_just_changed) then
        print(string.format("%d - %s", frame_number, _player_obj.animation))
      end
    end

    if (_player_obj.is_waking_up or _player_obj.is_fast_waking_up) and frame_number >= (_player_obj.waking_up_start_frame + _player_obj.wake_up_time) then
      _player_obj.is_waking_up = false
      _player_obj.is_fast_waking_up = false
    end

    _player_obj.has_just_started_wake_up = not _previous_is_waking_up and _player_obj.is_waking_up
    _player_obj.has_just_started_fast_wake_up = not _previous_is_fast_waking_up and _player_obj.is_fast_waking_up
  end
end

function write_player_vars(_player_obj)

  -- P1: 0x02068C6C
  -- P2: 0x02069104

  local _meter_base = 0
  local _stun_base = 0
  if _player_obj.id == 1 then
    _meter_base = 0x020695BD
    _stun_base = 0x020695FD
  elseif _player_obj.id == 2 then
    _meter_base = 0x020695E9
    _stun_base = 0x02069611
  end

  -- LIFE
  if training_settings.infinite_life then
    memory.writebyte(_player_obj.base + 0x9F, 160)
  end

  -- METER
  -- 0x020695BF P1 meter count
  -- 0x020695BD P1 max meter count
  -- 0x020695EB P2 meter count
  -- 0x020695E9 P2 max meter count
  if training_settings.infinite_meter then
    memory.writebyte(_meter_base + 0x2, memory.readbyte(_meter_base))
  end

  -- STUN
  -- 0x020695FD P1 stun timer
  -- 0x020695FF P1 stun bar
  -- 0x02069611 P2 stun timer
  -- 0x02069613 P2 stun bar
  if training_settings.no_stun then
    memory.writebyte(_stun_base, 0); -- Stun timer
    memory.writedword(_stun_base + 0x2, 0); -- Stun bar
  end

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

  -- game
  read_game_vars()
  write_game_vars()

  -- players
  read_player_vars(player_objects[1])
  read_player_vars(player_objects[2])

  write_player_vars(player_objects[1])
  write_player_vars(player_objects[2])

  if training_settings.dummy_player == 2 then
    player = player_objects[1]
    dummy = player_objects[2]
  elseif training_settings.dummy_player == 1 then
    player = player_objects[2]
    dummy = player_objects[1]
  end

  local _input = {}
  -- pose
  update_pose(_input, dummy, training_settings.pose)

  -- blocking
  update_blocking(_input, player, dummy, training_settings.blocking_mode, training_settings.blocking_style, training_settings.red_parry_hit_count)

  -- fast recovery
  if is_in_match and training_settings.fast_recovery_mode == 2 then
    if dummy.previous_standing_state ~= 0x00 and dummy.standing_state == 0x00 then
      _input[dummy.prefix..' Down'] = true
    end
  end

  -- counter attack
  update_counter_attack(_input, player, dummy, training_settings.counter_attack_stick, training_settings.counter_attack_button)

  joypad.set(_input)

  process_pending_input_sequence(player_objects[1])
  process_pending_input_sequence(player_objects[2])

  update_framedata_recording(player_objects[1])
end

is_menu_open = false
main_menu_selected_index = 1
is_main_menu_selected = true
sub_menu_selected_index = 1

function on_gui()

  if is_in_match then
    update_draw_hitboxes()
  end

  if is_in_match and training_settings.display_input then
    local i = joypad.get()
    draw_input(45, 190, i, "P1 ")
    draw_input(280, 190, i, "P2 ")
  end

  if current_animation then
    last_valid_current_animation = current_animation
  end
  if debug_current_animation and last_valid_current_animation then
    local _x = 300
    local _y = 20
    local _line_height = 10
    gui.text(_x + 5 , _y + _line_height * 0 , "animation: "..last_valid_current_animation.id)
    local _freeze_frames = 0
    for i = 1, #last_valid_current_animation.freeze_frames do
      _freeze_frames = _freeze_frames + last_valid_current_animation.freeze_frames[i].length
    end
    gui.text(_x + 5 , _y + _line_height * 1 , "freeze_frames: ".._freeze_frames)

    local _next_hit = last_valid_current_animation.get_next_hit()
    if _next_hit then
      last_valid_next_hit = _next_hit
    end
    if last_valid_next_hit then
      gui.text(_x + 5 , _y + _line_height * 2 , "next_hit: "..(last_valid_next_hit.start - last_valid_current_animation.start_frame)..", "..(last_valid_next_hit.stop - last_valid_current_animation.start_frame))
    end
  end

  if is_in_match then
    if P1.input.pressed.start or P2.input.pressed.start then
      is_menu_open = (not is_menu_open)
    end
  else
    is_menu_open = false
  end

  if is_menu_open then

    if P1.input.pressed.down or P2.input.pressed.down then
      if is_main_menu_selected then
        is_main_menu_selected = false
        sub_menu_selected_index = 1
      else
        sub_menu_selected_index = sub_menu_selected_index + 1
        if sub_menu_selected_index > #menu[main_menu_selected_index].entries then
          is_main_menu_selected = true
        end
      end
    end

    if P1.input.pressed.up or P2.input.pressed.up then
      if is_main_menu_selected then
        is_main_menu_selected = false
        sub_menu_selected_index = #menu[main_menu_selected_index].entries
      else
        sub_menu_selected_index = sub_menu_selected_index - 1
        if sub_menu_selected_index == 0 then
          is_main_menu_selected = true
        end
      end
    end

    if P1.input.pressed.left or P2.input.pressed.left then
      if is_main_menu_selected then
        main_menu_selected_index = main_menu_selected_index - 1
        if main_menu_selected_index == 0 then
          main_menu_selected_index = #menu
        end
      else
        menu[main_menu_selected_index].entries[sub_menu_selected_index]:left()
        save_training_data()
      end
    end

    if P1.input.pressed.right or P2.input.pressed.right then
      if is_main_menu_selected then
        main_menu_selected_index = main_menu_selected_index + 1
        if main_menu_selected_index > #menu then
          main_menu_selected_index = 1
        end
      else
        menu[main_menu_selected_index].entries[sub_menu_selected_index]:right()
        save_training_data()
      end
    end

    if P1.input.pressed.LP or P2.input.pressed.LP then
      if is_main_menu_selected then
      else
        menu[main_menu_selected_index].entries[sub_menu_selected_index]:validate()
        save_training_data()
      end
    end

    if P1.input.pressed.LK or P2.input.pressed.LK then
      if is_main_menu_selected then
      else
        menu[main_menu_selected_index].entries[sub_menu_selected_index]:cancel()
        save_training_data()
      end
    end

    -- screen size 383,223
    gui.box(43,40,340,180, 0x293139FF, 0x840000FF)
    --gui.box(0, 0, 383, 17, 0x000000AA, 0x000000AA)

    local _bar_x = 53
    local _bar_y = 46
    for i = 1, #menu do
      local _c = text_disabled_color
      local _t = menu[i].name
      if is_main_menu_selected and i == main_menu_selected_index then
        _t = "< ".._t.." >"
        _c = text_selected_color
      elseif i == main_menu_selected_index then
        _c = text_default_color
      end
      gui.text(_bar_x + (i - 1) * 100, _bar_y, _t, _c, text_default_border_color)
    end


    local _menu_x = 53
    local _menu_y = 63
    local _menu_y_interval = 10
    for i = 1, #menu[main_menu_selected_index].entries do
      menu[main_menu_selected_index].entries[i]:draw(_menu_x, _menu_y + _menu_y_interval * (i - 1), not is_main_menu_selected and sub_menu_selected_index == i)
    end

    gui.text(53, 168, "LK: Reset value to default", text_disabled_color, text_default_border_color)

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

function string:split(sep)
   local sep, fields = sep or ":", {}
   local pattern = string.format("([^%s]+)", sep)
   self:gsub(pattern, function(c) fields[#fields+1] = c end)
   return fields
end


screen_x = 0
screen_y = 0
scale = 1

-- registers
emu.registerstart(on_start)
emu.registerbefore(before_frame)
gui.register(on_gui)


-- character specific stuff

character_specific = {}
for i = 1, #characters do
  character_specific[characters[i]] = {}
end

-- Characters wake ups

-- wake ups to test (Ibuki) :
--  Cr HK
--  Throw
--  Close HK
--  Jmp HK
--  Raida
--  Neck breaker
-- Always test with LP wake up (specials may have longer buffering times and result in length that do not fit every move)

character_specific.alex.wake_ups = {
  { animation = "362c", length = 36 },
  { animation = "389c", length = 68 },
  { animation = "39bc", length = 68 },
  { animation = "378c", length = 66 },
  { animation = "3a8c", length = 53 },
}
character_specific.alex.fast_wake_ups = {
  { animation = "1fb8", length = 30 },
  { animation = "2098", length = 29 },
}


character_specific.ryu.wake_ups = {
  { animation = "49ac", length = 47 },
  { animation = "4aac", length = 78 },
  { animation = "4dcc", length = 71 },
  { animation = "4f9c", length = 68 },
}
character_specific.ryu.fast_wake_ups = {
  { animation = "c1dc", length = 29 },
  { animation = "c12c", length = 29 },
}


character_specific.yun.wake_ups = {
  { animation = "e980", length = 50 },
  { animation = "ebd0", length = 61 },
  { animation = "eb00", length = 61 },
  { animation = "eca0", length = 50 },
}
character_specific.yun.fast_wake_ups = {
  { animation = "d5dc", length = 27 },
  { animation = "d3bc", length = 33 },
}


character_specific.dudley.wake_ups = {
  { animation = "8ffc", length = 43 },
  { animation = "948c", length = 56 },
  { animation = "915c", length = 56 },
  { animation = "923c", length = 59 },
  { animation = "93ec", length = 53 },
}
character_specific.dudley.fast_wake_ups = {
  { animation = "e0bc", length = 28 },
  { animation = "df7c", length = 31 },
}


character_specific.gouki.wake_ups = {
  { animation = "5cec", length = 78 },
  { animation = "5bec", length = 47 },
  { animation = "600c", length = 71 },
  { animation = "61dc", length = 68 },
}
character_specific.gouki.fast_wake_ups = {
  { animation = "b66c", length = 29 },
  { animation = "b5bc", length = 29 },
}


character_specific.urien.wake_ups = {
  { animation = "32b8", length = 46 },
  { animation = "3b40", length = 77 },
  { animation = "3408", length = 77 },
  { animation = "3378", length = 51 },
}
character_specific.urien.fast_wake_ups = {
  { animation = "86b8", length = 34 },
  { animation = "8618", length = 36 },
}


character_specific.remy.wake_ups = {
  { animation = "56c8", length = 61 },
  { animation = "cf4c", length = 66 },
  { animation = "d25c", length = 57 },
  { animation = "d17c", length = 70 },
  { animation = "48c4", length = 35 },
}
character_specific.remy.fast_wake_ups = {
  { animation = "4e34", length = 28 },
  { animation = "4d84", length = 28 },
}


character_specific.necro.wake_ups = {
  { animation = "38cc", length = 45 },
  { animation = "3a3c", length = 61 },
  { animation = "3b1c", length = 60 },
  { animation = "3bfc", length = 58 },
  { animation = "3d9c", length = 51 },
}
character_specific.necro.fast_wake_ups = {
  { animation = "5bb4", length = 32 },
  { animation = "3d9c", length = 43 },
}


character_specific.q.wake_ups = {
  { animation = "28a8", length = 50 },
  { animation = "2a28", length = 63 },
  { animation = "2b18", length = 73 },
  { animation = "2d48", length = 74 },
  { animation = "2f58", length = 73 },
}
character_specific.q.fast_wake_ups = {
  { animation = "6e68", length = 31 },
  { animation = "6c98", length = 32 },
}


character_specific.oro.wake_ups = {
  { animation = "b928", length = 56 },
  { animation = "bb28", length = 72 },
  { animation = "bc28", length = 70 },
  { animation = "bd18", length = 65 },
  { animation = "be78", length = 58 },
}
character_specific.oro.fast_wake_ups = {
  { animation = "d708", length = 32 },
  { animation = "d678", length = 33 },
}


character_specific.ibuki.wake_ups = {
  { animation = "3f80", length = 43 },
  { animation = "4230", length = 69 },
  { animation = "44d0", length = 61 },
  { animation = "4350", length = 58 },
  { animation = "4420", length = 58 },
}
character_specific.ibuki.fast_wake_ups = {
  { animation = "7ec0", length = 27 },
  { animation = "7c90", length = 27 },
}


character_specific.chunli.wake_ups = {
  { animation = "04d0", length = 44 },
  { animation = "05e0", length = 89 },
  { animation = "07b0", length = 67 },
  { animation = "0920", length = 66 },
}
character_specific.chunli.fast_wake_ups = {
  { animation = "6268", length = 27 },
  { animation = "6148", length = 30 },
}


character_specific.sean.wake_ups = {
  { animation = "03c8", length = 47 },
  { animation = "04c8", length = 78 },
  { animation = "0768", length = 71 },
  { animation = "0938", length = 68 },
}
character_specific.sean.fast_wake_ups = {
  { animation = "5db8", length = 29 },
  { animation = "5d08", length = 29 },
}


character_specific.makoto.wake_ups = {
  { animation = "9b14", length = 52 },
  { animation = "9ca4", length = 72 },
  { animation = "9d94", length = 89 },
  { animation = "9fb4", length = 85 },
}
character_specific.makoto.fast_wake_ups = {
  { animation = "c650", length = 31 },
  { animation = "c4d0", length = 31 },
}


character_specific.elena.wake_ups = {
  { animation = "008c", length = 51 },
  { animation = "0bac", length = 74 },
  { animation = "026c", length = 65 },
  { animation = "035c", length = 65 },
}
character_specific.elena.fast_wake_ups = {
  { animation = "51b8", length = 33 },
  { animation = "4ff8", length = 33 },
}


character_specific.twelve.wake_ups = {
  { animation = "8d44", length = 44 },
  { animation = "8ec4", length = 55 },
  { animation = "8f84", length = 60 },
  { animation = "9054", length = 52 },
  { animation = "91b4", length = 51 },
}
character_specific.twelve.fast_wake_ups = {
  { animation = "d650", length = 30 },
  { animation = "d510", length = 31 },
}


character_specific.hugo.wake_ups = {
  { animation = "c5c0", length = 46 },
  { animation = "dfe8", length = 71 },
  { animation = "e458", length = 70 },
  { animation = "c960", length = 57 },
  { animation = "d0e0", length = 88 },
}
character_specific.hugo.fast_wake_ups = {
  { animation = "c60c", length = 30 },
  { animation = "c55c", length = 30 },
}


character_specific.yang.wake_ups = {
  { animation = "622c", length = 47 },
  { animation = "63fc", length = 58 },
  { animation = "64cc", length = 58 },
  { animation = "659c", length = 47 },
}
character_specific.yang.fast_wake_ups = {
  { animation = "58dc", length = 27 },
  { animation = "56bc", length = 33 },
}


character_specific.ken.wake_ups = {
  { animation = "ec44", length = 47 },
  { animation = "ed44", length = 76 },
  { animation = "efd4", length = 71 },
  { animation = "efd4", length = 71 },
  { animation = "f1a4", length = 68 },
}
character_specific.ken.fast_wake_ups = {
  { animation = "3e7c", length = 29 },
  { animation = "3dcc", length = 29 },
}



-- ALEX
frame_data_meta["alex"].moves["b7fc"] = { hits = {{ type = 2 }} } -- Cr LK
frame_data_meta["alex"].moves["b99c"] = { hits = {{ type = 2 }} } -- Cr MK
frame_data_meta["alex"].moves["babc"] = { hits = {{ type = 2 }} } -- Cr HK

frame_data_meta["alex"].moves["a7dc"] = { hits = {{ type = 3 }} } -- HP

frame_data_meta["alex"].moves["72d4"] = { hits = {{ type = 3 }} } -- UOH

frame_data_meta["alex"].moves["bc0c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LP
frame_data_meta["alex"].moves["bd6c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MP
frame_data_meta["alex"].moves["be7c"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HP

frame_data_meta["alex"].moves["bf94"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air LK
frame_data_meta["alex"].moves["c0e4"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air MK
frame_data_meta["alex"].moves["c1c4"] = { hits = {{ type = 3 }}, movement_type = 2 } -- Air HK

frame_data_meta["alex"].moves["6d24"] = { intro = { length = 23, next = "7044" } } -- VCharge LK
frame_data_meta["alex"].moves["7044"] = { hits = {{ type = 3 }} } -- VCharge LK

frame_data_meta["alex"].moves["6df4"] = { intro = { length = 25, next = "7094" } } -- VCharge MK
frame_data_meta["alex"].moves["7094"] = { hits = {{ type = 3 }} } -- VCharge MK

frame_data_meta["alex"].moves["6ec4"] = { intro = { length = 26, next = "70e4" } } -- VCharge HK
frame_data_meta["alex"].moves["70e4"] = { hits = {{ type = 3 }} } -- VCharge HK

frame_data_meta["alex"].moves["6f94"] = { intro = { length = 26, next = "70e4" } } -- VCharge EXK

-- IBUKI
frame_data_meta["ibuki"].moves["3a48"] = { cancel = true } -- target MP
