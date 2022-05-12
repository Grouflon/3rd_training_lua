-- # enums
distance_display_mode =
{
  "none",
  "simple",
  "advanced",
}

distance_display_reference_point =
{
  "origin",
  "hurtbox",
}

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

function draw_horizontal_text_segment(_p1_x, _p2_x, _y, _text, _line_color, _edges_height)

  _edges_height = _edges_height or 3
  local _half_distance_str_width = get_text_width(_text) * 0.5

  local _center_x = (_p1_x + _p2_x) * 0.5
  draw_horizontal_line(math.min(_p1_x, _p2_x), _center_x - _half_distance_str_width - 3, _y, _line_color, 1)
  draw_horizontal_line(_center_x + _half_distance_str_width + 3, math.max(_p1_x, _p2_x), _y, _line_color, 1)
  gui.text(_center_x - _half_distance_str_width, _y - 3, _text, text_default_color, text_default_border_color)

  if _edges_height > 0 then
    draw_vertical_line(_p1_x, _y - _edges_height, _y + _edges_height, _line_color, 1)
    draw_vertical_line(_p2_x, _y - _edges_height, _y + _edges_height, _line_color, 1)
  end
end  

function display_draw_distances(_p1_object, _p2_object, _mid_distance_height, _p1_reference_point, _p2_reference_point)

  function _find_closest_box_at_height(_player_obj, _height, _box_types)

    local _px = _player_obj.pos_x
    local _py = _player_obj.pos_y

    local _left, _right = _px, _px

    if _box_types == nil then
      return false, _left, _right
    end

    local _has_boxes = false
    for __, _box in ipairs(_player_obj.boxes) do

      if _box_types[_box.type] then
        local _l, _r
        if _player_obj.flip_x == 0 then
          _l = _px + _box.left
        else
          _l = _px - _box.left - _box.width
        end
        local _r = _l + _box.width
        local _b = _py + _box.bottom
        local _t = _b + _box.height

        if _height >= _b and _height <= _t then
          _has_boxes = true
          _left = math.min(_left, _l)
          _right = math.max(_right, _r)
        end
      end
    end

    return _has_boxes, _left, _right
  end

  function _get_screen_line_between_boxes(_box1_l, _box1_r, _box2_l, _box2_r)
    if not (
      (_box1_l >= _box2_r) or
      (_box1_r <= _box2_l)
    ) then
      return false
    end

    if _box1_l < _box2_l then
      return true, game_to_screen_space_x(_box1_r), game_to_screen_space_x(_box2_l)
    else
      return true, game_to_screen_space_x(_box2_r), game_to_screen_space_x(_box1_l)
    end
  end

  function _display_distance(_p1_object, _p2_object, _height, _box_types, _p1_reference_point, _p2_reference_point, _color)
    local _y = math.min(_p1_object.pos_y + _height, _p2_object.pos_y + _height)
    local _p1_l, _p1_r, _p2_l, _p2_r
    local _p1_result, _p2_result = false, false
    if _p1_reference_point == 2 then
      _p1_result, _p1_l, _p1_r = _find_closest_box_at_height(_p1_object, _y, _box_types)
    end
    if not _p1_result then
      _p1_l, _p1_r = _p1_object.pos_x, _p1_object.pos_x
    end
    if _p2_reference_point == 2 then
      _p2_result, _p2_l, _p2_r = _find_closest_box_at_height(_p2_object, _y, _box_types)
    end 
    if not _p2_result then
      _p2_l, _p2_r = _p2_object.pos_x, _p2_object.pos_x
    end

    local _line_result, _screen_l, _screen_r = _get_screen_line_between_boxes(_p1_l, _p1_r, _p2_l, _p2_r)

    if _line_result then
      local _screen_y = game_to_screen_space_y(_y)
      local _str = string.format("%d", math.abs(_screen_r - _screen_l))
      draw_horizontal_text_segment(_screen_l, _screen_r, _screen_y, _str, _color)
    end
  end

  -- throw
  _display_distance(_p1_object, _p2_object, 2, { throwable = true }, _p1_reference_point, _p2_reference_point, 0x08CF00FF)

  -- low and mid
  local _hurtbox_types = {}
  _hurtbox_types["vulnerability"] = true
  _hurtbox_types["ext. vulnerability"] = true
  _display_distance(_p1_object, _p2_object, 10, _hurtbox_types, _p1_reference_point, _p2_reference_point, 0x00E7FFFF)
  _display_distance(_p1_object, _p2_object, _mid_distance_height, _hurtbox_types, _p1_reference_point, _p2_reference_point, 0x00E7FFFF)

  -- player positions
  local _line_color = 0xFFFF63FF
  local _p1_screen_x, _p1_screen_y = game_to_screen_space(_p1_object.pos_x, _p1_object.pos_y)
  local _p2_screen_x, _p2_screen_y = game_to_screen_space(_p2_object.pos_x, _p2_object.pos_y)
  draw_point(_p1_screen_x, _p1_screen_y, _line_color)
  draw_point(_p2_screen_x, _p2_screen_y, _line_color)
  gui.text(_p1_screen_x + 3, _p1_screen_y + 2, string.format("%d:%d", _p1_object.pos_x, _p1_object.pos_y), text_default_color, text_default_border_color)
  gui.text(_p2_screen_x + 3, _p2_screen_y + 2, string.format("%d:%d", _p2_object.pos_x, _p2_object.pos_y), text_default_color, text_default_border_color)
end
