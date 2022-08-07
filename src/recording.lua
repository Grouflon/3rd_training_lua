--[[
  Converts emulator input name to normalized application input name
    - [R] _player_obj : Player object that does the input
    - [R] _input      : Emulator input string
]]
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

--[[
  Updates the given input sequence to a player and generate input accordingly
    - [R]   _player_obj : Player object that should play the sequence
    - [R/W] _sequence   : Sequence object that we are currently playing on the given player
    - [W]   _input      : Input object that should be applied this frame
]]
function process_input_sequence(_player_obj, _sequence, _input)

  if _sequence.current_frame > #_sequence.sequence then
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

  if _sequence.current_frame >= 1 then
    local _s = ""
    local _current_frame_input = _sequence.sequence[_sequence.current_frame]
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
  end
  --print(_s)

  _sequence.current_frame = _sequence.current_frame + 1
end


function record_frame_input(_player_obj, _input, _recorded_inputs)
  local _frame = {}
  for _key, _value in pairs(_input) do
    local _prefix = _key:sub(1, #_player_obj.prefix)
    if (_prefix == _player_obj.prefix) then
      local _input_name = _key:sub(1 + #_player_obj.prefix + 1)
      if (_input_name ~= "Coin" and _input_name ~= "Start") then
        if (_value) then
          local _sequence_input_name = stick_input_to_sequence_input(_player_obj, _input_name)
          --print(_input_name.." ".._sequence_input_name)
          table.insert(_frame, _sequence_input_name)
        end
      end
    end
  end

  table.insert(_recorded_inputs, _frame)
end