require "gd"

-- # Constants
screen_width = 383
screen_height = 223
ground_offset = 23

-- # Global variables
screen_x = 0
screen_y = 0
scale = 1

-- # Images

img_1_dir_big = gd.createFromPng("images/big/1_dir.png"):gdStr()
img_2_dir_big = gd.createFromPng("images/big/2_dir.png"):gdStr()
img_3_dir_big = gd.createFromPng("images/big/3_dir.png"):gdStr()
img_4_dir_big = gd.createFromPng("images/big/4_dir.png"):gdStr()
img_5_dir_big = gd.createFromPng("images/big/5_dir.png"):gdStr()
img_6_dir_big = gd.createFromPng("images/big/6_dir.png"):gdStr()
img_7_dir_big = gd.createFromPng("images/big/7_dir.png"):gdStr()
img_8_dir_big = gd.createFromPng("images/big/8_dir.png"):gdStr()
img_9_dir_big = gd.createFromPng("images/big/9_dir.png"):gdStr()
img_no_button_big = gd.createFromPng("images/big/no_button.png"):gdStr()
img_L_button_big = gd.createFromPng("images/big/L_button.png"):gdStr()
img_M_button_big = gd.createFromPng("images/big/M_button.png"):gdStr()
img_H_button_big = gd.createFromPng("images/big/H_button.png"):gdStr()
img_dir_big = {
  img_1_dir_big,
  img_2_dir_big,
  img_3_dir_big,
  img_4_dir_big,
  img_5_dir_big,
  img_6_dir_big,
  img_7_dir_big,
  img_8_dir_big,
  img_9_dir_big
}

img_1_dir_small = gd.createFromPng("images/small/1_dir.png"):gdStr()
img_2_dir_small = gd.createFromPng("images/small/2_dir.png"):gdStr()
img_3_dir_small = gd.createFromPng("images/small/3_dir.png"):gdStr()
img_4_dir_small = gd.createFromPng("images/small/4_dir.png"):gdStr()
img_5_dir_small = gd.createFromPng("images/small/5_dir.png"):gdStr()
img_6_dir_small = gd.createFromPng("images/small/6_dir.png"):gdStr()
img_7_dir_small = gd.createFromPng("images/small/7_dir.png"):gdStr()
img_8_dir_small = gd.createFromPng("images/small/8_dir.png"):gdStr()
img_9_dir_small = gd.createFromPng("images/small/9_dir.png"):gdStr()
img_LP_button_small = gd.createFromPng("images/small/LP_button.png"):gdStr()
img_MP_button_small = gd.createFromPng("images/small/MP_button.png"):gdStr()
img_HP_button_small = gd.createFromPng("images/small/HP_button.png"):gdStr()
img_LK_button_small = gd.createFromPng("images/small/LK_button.png"):gdStr()
img_MK_button_small = gd.createFromPng("images/small/MK_button.png"):gdStr()
img_HK_button_small = gd.createFromPng("images/small/HK_button.png"):gdStr()
img_dir_small = {
  img_1_dir_small,
  img_2_dir_small,
  img_3_dir_small,
  img_4_dir_small,
  img_5_dir_small,
  img_6_dir_small,
  img_7_dir_small,
  img_8_dir_small,
  img_9_dir_small
}

-- # System

function draw_read()
  -- screen stuff
  screen_x = memory.readwordsigned(0x02026CB0)
  screen_y = memory.readwordsigned(0x02026CB4)
  scale = memory.readwordsigned(0x0200DCBA) --FBA can't read from 04xxxxxx
  scale = 0x40/(scale > 0 and scale or 1)
end

-- # Tools
function game_to_screen_space(_x, _y)
  local _px = _x - screen_x + emu.screenwidth()/2
  local _py = emu.screenheight() - (_y - screen_y) - ground_offset
  return _px, _py
end


function get_text_width(_text)
  if #_text == 0 then
    return 0
  end

  return #_text * 4
end

-- # Draw functions

-- draws a set of hitboxes
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

-- draws a point
function draw_point(_x, _y, _color)
  local _cross_half_size = 4
  local _l = _x - _cross_half_size
  local _r = _x + _cross_half_size
  local _t = _y - _cross_half_size
  local _b = _y + _cross_half_size

  gui.box(_l, _y, _r, _y, 0x00000000, _color)
  gui.box(_x, _t, _x, _b, 0x00000000, _color)
end

-- draws a controller representation
function draw_controller_big(_entry, _x, _y)
  gui.image(_x, _y, img_dir_big[_entry.direction])

  local _img_LP = img_no_button_big
  local _img_MP = img_no_button_big
  local _img_HP = img_no_button_big
  local _img_LK = img_no_button_big
  local _img_MK = img_no_button_big
  local _img_HK = img_no_button_big
  if _entry.buttons[1] then _img_LP = img_L_button_big end
  if _entry.buttons[2] then _img_MP = img_M_button_big end
  if _entry.buttons[3] then _img_HP = img_H_button_big end
  if _entry.buttons[4] then _img_LK = img_L_button_big end
  if _entry.buttons[5] then _img_MK = img_M_button_big end
  if _entry.buttons[6] then _img_HK = img_H_button_big end

  gui.image(_x + 13, _y, _img_LP)
  gui.image(_x + 18, _y, _img_MP)
  gui.image(_x + 23, _y, _img_HP)
  gui.image(_x + 13, _y + 5, _img_LK)
  gui.image(_x + 18, _y + 5, _img_MK)
  gui.image(_x + 23, _y + 5, _img_HK)
end

-- draws a controller representation
function draw_controller_small(_entry, _x, _y, _is_right)
  local _x_offset = 0
  local _sign = 1
  if _is_right then
    _x_offset = _x_offset - 9
    _sign = -1
  end

  gui.image(_x + _x_offset, _y, img_dir_small[_entry.direction])
  _x_offset = _x_offset + _sign * 2


  local _interval = 8
  _x_offset = _x_offset + _sign * _interval

  if _entry.buttons[1] then
    gui.image(_x + _x_offset, _y, img_LP_button_small)
    _x_offset = _x_offset + _sign * _interval
  end

  if _entry.buttons[2] then
    gui.image(_x + _x_offset, _y, img_MP_button_small)
    _x_offset = _x_offset + _sign * _interval
  end

  if _entry.buttons[3] then
    gui.image(_x + _x_offset, _y, img_HP_button_small)
    _x_offset = _x_offset + _sign * _interval
  end

  if _entry.buttons[4] then
    gui.image(_x + _x_offset, _y, img_LK_button_small)
    _x_offset = _x_offset + _sign * _interval
  end

  if _entry.buttons[5] then
    gui.image(_x + _x_offset, _y, img_MK_button_small)
    _x_offset = _x_offset + _sign * _interval
  end

  if _entry.buttons[6] then
    gui.image(_x + _x_offset, _y, img_HK_button_small)
    _x_offset = _x_offset + _sign * _interval
  end

end

-- draws a gauge
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

-- draws an horizontal line
function draw_horizontal_line(_x_start, _x_end, _y, _color, _thickness)
  _thickness = _thickness or 1.0
  local _l = _x_start - 1
  local _b =  _y + math.ceil(_thickness * 0.5)
  local _r = _x_end + 1
  local _t = _y - math.floor(_thickness * 0.5) - 1
  gui.box(_l, _b, _r, _t, _color, 0x00000000)
end

-- draws a vertical line
function draw_vertical_line(_x, _y_start, _y_end, _color, _thickness)
  _thickness = _thickness or 1.0
  local _l = _x - math.floor(_thickness * 0.5) - 1
  local _b =  _y_end + 1
  local _r = _x + math.ceil(_thickness * 0.5)
  local _t = _y_start - 1
  gui.box(_l, _b, _r, _t, _color, 0x00000000)
end
