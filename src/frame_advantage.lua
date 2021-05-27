move_advantage = {}

-- known bugs:
-- - throws startup and hit frame are sometimes wrong
-- - Undetected moves:
--   - Ken's MK (busy flag is always 0)
--   - Gouki's close MK

function frame_advantage_update(_attacker, _defender)
  local _debug = false

  function has_just_attacked(_player_obj)
    return _player_obj.has_just_attacked or (_player_obj.recovery_time == 0 and _player_obj.freeze_frames == 0 and _player_obj.input_capacity == 0 and _player_obj.previous_input_capacity ~= 0) or (_player_obj.movement_type == 4 and _player_obj.last_movement_type_change_frame == 0)
  end

  function has_ended_attack(_player_obj)
    return (_player_obj.busy_flag == 0  or _player_obj.is_in_jump_startup)
  end

  function has_ended_recovery(_player_obj)
    return (_player_obj.is_idle or has_just_attacked(_player_obj) or _player_obj.is_in_jump_startup)
  end

  if not move_advantage.armed and has_just_attacked(_attacker) then
    move_advantage = {
      armed = true,
      player_id = _attacker.id,
      start_frame = frame_number,
      hitbox_start_frame = nil,
      hit_frame = nil,
      end_frame = nil,
      end_frame_offset = 0,
      opponent_end_frame = nil,
    }

    if _debug then print(string.format("%d - start", frame_number)) end
  end

  if move_advantage.armed then

    if move_advantage.hitbox_start_frame == nil then
      for _, _box in ipairs(_attacker.boxes) do
        if _box.type == "attack" or _box.type == "throw" then
          move_advantage.hitbox_start_frame = frame_number
          move_advantage.end_frame = nil

          if _debug then print(string.format("%d - hitbox", frame_number)) end
          break
        end
      end
      for _, _projectile in pairs(projectiles) do
        if _projectile.emitter_id == _attacker.id and _projectile.has_activated then
          move_advantage.hitbox_start_frame = frame_number + 1
          move_advantage.end_frame = nil
          if _debug then print(string.format("%d(+1) - hitbox", frame_number)) end
          break
        end
      end
    end

    if (_attacker.has_just_hit or _attacker.has_just_been_blocked or _defender.has_just_been_hit or _defender.has_just_blocked) then
      move_advantage.hit_frame = frame_number
      move_advantage.opponent_end_frame = nil
      if move_advantage.hitbox_start_frame == nil then
        move_advantage.hitbox_start_frame = move_advantage.hit_frame
      end
      if _attacker.busy_flag ~= 0 then
        move_advantage.end_frame = nil
      end

      -- all hit advantages are detected 1 frame too late
      if _defender.has_just_been_hit then
        move_advantage.end_frame_offset = -1
        if _debug then print(string.format("%d - end offset %d", frame_number, move_advantage.end_frame_offset)) end
      end

      if _debug then print(string.format("%d - hit", frame_number)) end
    end

    if move_advantage.hit_frame ~= nil then
      if move_advantage.hitbox_start_frame ~= nil and frame_number > move_advantage.hit_frame then
        if move_advantage.end_frame == nil and has_ended_attack(_attacker) then
          if _debug then print(string.format("%d - attacker_end", frame_number)) end
          move_advantage.end_frame = frame_number
          if _attacker.is_in_jump_startup then
            move_advantage.end_frame_offset = 0
        if _debug then print(string.format("%d - end offset %d", frame_number, move_advantage.end_frame_offset)) end
          end
        end

        if move_advantage.opponent_end_frame == nil and frame_number > move_advantage.hit_frame and has_ended_recovery(_defender) then
          if _debug then print(string.format("%d - defender_end", frame_number)) end
          move_advantage.opponent_end_frame = frame_number
        end 
      end
    end

    if (move_advantage.end_frame ~= nil and move_advantage.opponent_end_frame ~= nil) or (has_ended_attack(_attacker) and has_ended_recovery(_defender)) then
      move_advantage.armed = false
      if _debug then print(string.format("%d - unarm", frame_number)) end
      if _debug then print("") end
    end
  end
end

function frame_advantage_display()
  if
    move_advantage.armed == true or
    move_advantage.player_id == nil or
    move_advantage.start_frame == nil or
    move_advantage.hitbox_start_frame == nil
  then
    return
  end

  local _text_width1 = get_text_width("startup: ")
  local _text_width2 = get_text_width("hit frame: ")
  local _text_width3 = get_text_width("advantage: ")

  local _x1 = 0
  local _x2 = 0
  local _x3 = 0
  local _y = 49
  if move_advantage.player_id == 1 then
    _x1 = 51
    _x2 = _x1
    _x3 = _x1
  elseif move_advantage.player_id == 2 then
    local _base = screen_width - 65
    _x1 = _base - _text_width1
    _x2 = _base - _text_width2
    _x3 = _base - _text_width3
  end

  local _startup = move_advantage.hitbox_start_frame - move_advantage.start_frame

  gui.text(_x1, _y, string.format("startup: "))
  gui.text(_x1 + _text_width1, _y, string.format("%d", _startup))

  if move_advantage.hit_frame ~= nil then
    local _hit_frame = move_advantage.hit_frame - move_advantage.start_frame + 1
    gui.text(_x2, _y + 10, string.format("hit frame: "))
    gui.text(_x2 + _text_width2, _y + 10, string.format("%d", _hit_frame))  
  end

  if move_advantage.hit_frame ~= nil and move_advantage.end_frame ~= nil and move_advantage.opponent_end_frame ~= nil then
    local _advantage = move_advantage.opponent_end_frame - (move_advantage.end_frame + move_advantage.end_frame_offset)

    local _sign = ""
    if _advantage > 0 then _sign = "+" end

    local _color = 0xFFFB63FF
    if _advantage < 0 then
      _color = 0xE70000FF
    elseif _advantage > 0 then
      _color = 0x10FB00FF
    end

    gui.text(_x3, _y + 20, "advantage: ")
    gui.text(_x3 + _text_width3, _y + 20, string.format("%s%d", _sign, _advantage), _color, text_default_border_color)
  end
end

function frame_advantage_reset()
  move_advantage = 
  {
    armed = false
  }
end
frame_advantage_reset()