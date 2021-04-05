assert_enabled = false
function t_assert(_condition, _msg)
  _msg = _msg or "Assertion failed"
  if assert_enabled and not _condition then
    error(_msg, 2)
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

function check_input_down_autofire(_player_object, _input, _autofire_rate, _autofire_time)
  _autofire_rate = _autofire_rate or 4
  _autofire_time = _autofire_time or 23
  if _player_object.input.pressed[_input] or (_player_object.input.down[_input] and _player_object.input.state_time[_input] > _autofire_time and (_player_object.input.state_time[_input] % _autofire_rate) == 0) then
    return true
  end
  return false
end

-- json tools
local json = require ("src/libs/dkjson")

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

-- log
log_enabled = false
log_categories_display = {}

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

function log_draw()
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
