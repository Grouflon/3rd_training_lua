input_history_size_max = 15
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

function input_history_update(_history, _prefix, _input)
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

function input_history_draw(_history, _x, _y, _is_right)
  local _step_y = 10
  local _j = 0
  for _i = #_history, 1, -1 do
    local _current_y = _y + _j * _step_y
    local _entry = _history[_i]

    local _sign = 1
    if _is_right then
      _sign = -1
    end

    local _controller_offset = 14 * _sign
    draw_controller_small(_entry, _x + _controller_offset, _current_y, _is_right)

    local _next_frame = frame_number
    if _i < #_history then
      _next_frame = _history[_i + 1].frame
    end
    local _frame_diff = _next_frame - _entry.frame
    local _text = "-"
    if (_frame_diff < 999) then
      _text = string.format("%d", _frame_diff)
    end

    local _offset = -11
    if not _is_right then
      _offset = 8
      if (_frame_diff < 999) then
        if (_frame_diff >= 100) then _offset = 0
        elseif (_frame_diff >= 10) then _offset = 4 end
      end
    end

    gui.text(_x + _offset, _current_y + 1, _text, 0xd6e3efff, 0x101000ff)

    _j = _j + 1
  end
end

function clear_input_history()
  input_history[1] = {}
  input_history[2] = {}
end
