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


