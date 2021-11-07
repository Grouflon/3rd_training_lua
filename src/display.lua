-- # api

-- push a persistent set of hitboxes to be drawn on the screen each frame
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

-- push a persistent point to be drawn on the screen each frame
function print_point(_pos_x, _pos_y, _color)
  local _g = {
    type = "point",
    x = _pos_x,
    y = _pos_y,
    color = _color
  }
  table.insert(printed_geometry, _g)
end

function clear_printed_geometry()
  printed_geometry = {}
end

-- # system
printed_geometry = {}

function display_draw_printed_geometry()
  -- printed geometry
  for _i, _geometry in ipairs(printed_geometry) do
    if _geometry.type == "hitboxes" then
      draw_hitboxes(_geometry.x, _geometry.y, _geometry.flip_x, _geometry.boxes, _geometry.filter, _geometry.dilation)
    elseif _geometry.type == "point" then
      draw_point(_geometry.x, _geometry.y, _geometry.color)
    end
  end
end

function display_draw_hitboxes()
  -- players
  for _id, _obj in pairs(player_objects) do
    draw_hitboxes(_obj.pos_x, _obj.pos_y, _obj.flip_x, _obj.boxes)
  end
  -- projectiles
  for _id, _obj in pairs(projectiles) do
    draw_hitboxes(_obj.pos_x, _obj.pos_y, _obj.flip_x, _obj.boxes)
  end
end


function display_draw_life(_player_object)
  local _x = 0
  local _y = 20

  local _t = string.format("%d/160", _player_object.life)

  if _player_object.id == 1 then
    _x = 13
  elseif _player_object.id == 2 then
    _x = screen_width - 11 - get_text_width(_t)
  end

  gui.text(_x, _y, _t, 0xFFFB63FF)
end


function display_draw_meter(_player_object)
  local _x = 0
  local _y = 214

  local _gauge = _player_object.meter_gauge

  if _player_object.meter_count == _player_object.max_meter_count then
    _gauge = _player_object.max_meter_gauge
  end

  local _t = string.format("%d/%d", _gauge, _player_object.max_meter_gauge)

  if _player_object.id == 1 then
    _x = 53
  elseif _player_object.id == 2 then
    _x = screen_width - 51 - get_text_width(_t)
  end

  gui.text(_x, _y, _t, 0x00FFCEFF, 0x001433FF)
end


function display_draw_stun_gauge(_player_object)
  local _x = 0
  local _y = 29

  local _t = string.format("%d/%d", _player_object.stun_bar, _player_object.stun_max)

  if _player_object.id == 1 then
    _x = 118
  elseif _player_object.id == 2 then
    _x = screen_width - 116 - get_text_width(_t)
  end

  gui.text(_x, _y, _t, 0xE70000FF, 0x001433FF)
end

function display_draw_bonuses(_player_object)

  if _player_object.damage_bonus > 0 then
    local _x = 0
    local _y = 7

    local _t = string.format("+%d dmg", _player_object.damage_bonus)

    if _player_object.id == 1 then
      _x = 43
    elseif _player_object.id == 2 then
      _x = screen_width - 40 - get_text_width(_t)
    end

    gui.text(_x, _y, _t, 0xFF7184FF, 0x392031FF)
  end

  if _player_object.defense_bonus > 0 then

    local _x = 0
    local _y = 7

    local _t = string.format("+%d def", _player_object.defense_bonus)

    if _player_object.id == 1 then
      _x = 10
    elseif _player_object.id == 2 then
      _x = screen_width - 7 - get_text_width(_t)
    end

    gui.text(_x, _y, _t, 0xD6E3EFFF, 0x000029FF)
  end

  if _player_object.stun_bonus > 0 then

    local _x = 0
    local _y = 33

    local _t = string.format("+%d stun", _player_object.stun_bonus)

    if _player_object.id == 1 then
      _x = 81
    elseif _player_object.id == 2 then
      _x = screen_width - 79 - get_text_width(_t)
    end

    gui.text(_x, _y, _t, 0xD6E3EFFF, 0x000029FF)
  end

end


function display_draw_distances(_p1_object, _p2_object)
  local _line_color = 0xFFFF63FF
  local _screen_limit_margin_y = screen_height - 20
  local _display_height = 40
  local _vertical_line_margin = 4

  local _p1_screen_x, _p1_screen_y = game_to_screen_space(_p1_object.pos_x, _p1_object.pos_y)
  local _p2_screen_x, _p2_screen_y = game_to_screen_space(_p2_object.pos_x, _p2_object.pos_y)
  _p1_screen_y = math.min(_p1_screen_y, _screen_limit_margin_y)
  _p2_screen_y = math.min(_p2_screen_y, _screen_limit_margin_y)
  local _p1_center_x, _p1_center_y =  game_to_screen_space(_p1_object.pos_x, _p1_object.pos_y + _display_height)
  local _p2_center_x, _p2_center_y = game_to_screen_space(_p2_object.pos_x, _p2_object.pos_y + _display_height)
  _p1_center_y = math.min(_p1_center_y, _screen_limit_margin_y)
  _p2_center_y = math.min(_p2_center_y, _screen_limit_margin_y)
  local _center_x = (_p1_screen_x + _p2_screen_x) * 0.5
  local _distance_str = string.format("%d:%d", math.abs(_p1_object.pos_x - _p2_object.pos_x), math.abs(_p1_object.pos_y - _p2_object.pos_y))
  local _half_distance_str_width = get_text_width(_distance_str) * 0.5
  local _line_y = math.max(_p1_center_y, _p2_center_y)

  draw_point(_p1_screen_x, _p1_screen_y, _line_color)
  draw_point(_p2_screen_x, _p2_screen_y, _line_color)
  draw_horizontal_line(math.min(_p1_screen_x, _p2_screen_x), _center_x - _half_distance_str_width - 3, _line_y, _line_color, 1)
  draw_horizontal_line(_center_x + _half_distance_str_width + 3, math.max(_p1_screen_x, _p2_screen_x), _line_y, _line_color, 1)
  draw_vertical_line(_p1_center_x, math.min(_p1_screen_y, _line_y) - _vertical_line_margin, math.max(_p1_screen_y, _line_y) + _vertical_line_margin, _line_color, 1)
  draw_vertical_line(_p2_center_x, math.min(_p2_screen_y, _line_y) - _vertical_line_margin, math.max(_p2_screen_y, _line_y) + _vertical_line_margin, _line_color, 1)
  gui.text(_center_x - _half_distance_str_width, _line_y - 3, _distance_str, text_default_color, text_default_border_color)
  gui.text(_p1_screen_x + 3, _p1_screen_y + 2, string.format("%d:%d", _p1_object.pos_x, _p1_object.pos_y), text_default_color, text_default_border_color)
  gui.text(_p2_screen_x + 3, _p2_screen_y + 2, string.format("%d:%d", _p2_object.pos_x, _p2_object.pos_y), text_default_color, text_default_border_color)
end
