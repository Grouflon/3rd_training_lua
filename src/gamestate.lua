-- # global variables
frame_number = 0
is_in_match = false
player_objects = {}
P1 = nil
P2 = nil

-- # api
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
    meter_gauge = 0,
    meter_count = 0,
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

  P1.charge_1_reset_addr = 0x02025A47 -- Alex_1(Elbow)
  P1.charge_1_addr = 0x02025A49
  P1.charge_2_reset_addr = 0x02025A2B -- Alex_2(Stomp), Urien_2(Knee?)
  P1.charge_2_addr = 0x02025A2D
  P1.charge_3_reset_addr = 0x02025A0F -- Oro_1(Shou), Remy_2(LoVKick?)
  P1.charge_3_addr = 0x02025A11
  P1.charge_4_reset_addr = 0x020259F3 -- Urien_3(headbutt?), Q_2(DashLeg), Remy_1(LoVPunch?)
  P1.charge_4_addr = 0x020259F5
  P1.charge_5_reset_addr = 0x020259D7 -- Oro_2(Yanma), Urien_1(tackle), Chun_4, Q_1(DashHead), Remy_3(Rising)
  P1.charge_5_addr = 0x020259D9

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
  
  P2.charge_1_reset_addr = 0x02025FF7
  P2.charge_1_addr = 0x02025FF9
  P2.charge_2_reset_addr = 0x0202602F
  P2.charge_2_addr = 0x02026031
  P2.charge_3_reset_addr = 0x02026013
  P2.charge_3_addr = 0x02026013
  P2.charge_4_reset_addr = 0x0202604B
  P2.charge_4_addr = 0x0202604D
  P2.charge_5_reset_addr = 0x02026067
  P2.charge_5_addr = 0x02026069
end


-- ## read
function gamestate_read()
  -- game
  read_game_vars()

  -- players
  read_player_vars(player_objects[1])
  read_player_vars(player_objects[2])

  -- projectiles
  read_projectiles()

  if is_in_match then
    update_flip_input(player_objects[1], player_objects[2])
    update_flip_input(player_objects[2], player_objects[1])
  end
end

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


function read_input(_player_obj)

  function read_single_input(_input_object, _input_name, _input)
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
  read_single_input(_player_obj.input, "start", _local_input[_player_obj.prefix.." Start"])
  read_single_input(_player_obj.input, "coin", _local_input[_player_obj.prefix.." Coin"])
  read_single_input(_player_obj.input, "up", _local_input[_player_obj.prefix.." Up"])
  read_single_input(_player_obj.input, "down", _local_input[_player_obj.prefix.." Down"])
  read_single_input(_player_obj.input, "left", _local_input[_player_obj.prefix.." Left"])
  read_single_input(_player_obj.input, "right", _local_input[_player_obj.prefix.." Right"])
  read_single_input(_player_obj.input, "LP", _local_input[_player_obj.prefix.." Weak Punch"])
  read_single_input(_player_obj.input, "MP", _local_input[_player_obj.prefix.." Medium Punch"])
  read_single_input(_player_obj.input, "HP", _local_input[_player_obj.prefix.." Strong Punch"])
  read_single_input(_player_obj.input, "LK", _local_input[_player_obj.prefix.." Weak Kick"])
  read_single_input(_player_obj.input, "MK", _local_input[_player_obj.prefix.." Medium Kick"])
  read_single_input(_player_obj.input, "HK", _local_input[_player_obj.prefix.." Strong Kick"])
end


function read_box(_obj, _ptr, _type)
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

function read_game_object(_obj)
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
      read_box(_obj, memory.readdword(_obj.base + _box.offset) + (i-1)*8, _box.type)
    end
  end
  return true
end


function read_player_vars(_player_obj)

-- P1: 0x02068C6C
-- P2: 0x02069104

  if memory.readdword(_player_obj.base + 0x2A0) == 0 then --invalid objects
    return
  end

  local _debug_state_variables = _player_obj.debug_state_variables

  read_input(_player_obj)

  local _prev_pos_x = _player_obj.pos_x or 0
  local _prev_pos_y = _player_obj.pos_y or 0

  read_game_object(_player_obj)

  local _previous_movement_type = _player_obj.movement_type or 0

  _player_obj.char_str = characters[_player_obj.char_id + 1]

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

  local _previous_action = _player_obj.action or 0x00

  _player_obj.is_attacking_ext = memory.readbyte(_player_obj.base + 0x429) > 0
  _player_obj.previous_input_capacity = _player_obj.input_capacity or 0
  _player_obj.input_capacity = memory.readword(_player_obj.base + 0x46C)
  _player_obj.action = memory.readdword(_player_obj.base + 0xAC)
  _player_obj.action_ext = memory.readdword(_player_obj.base + 0x12C)
  _player_obj.previous_recovery_time = _player_obj.recovery_time or 0
  _player_obj.recovery_time = memory.readbyte(_player_obj.base + 0x187)
  _player_obj.movement_type = memory.readbyte(_player_obj.base + 0x0AD)
  _player_obj.movement_type2 = memory.readbyte(_player_obj.base + 0x0AF) -- seems that we can know which basic movement the player is doing from there
  _player_obj.total_received_projectiles_count = memory.readword(_player_obj.base + 0x430) -- on block or hit

  _player_obj.busy_flag = memory.readword(_player_obj.base + 0x3D1)

  local _previous_is_in_basic_action = _player_obj.is_in_basic_action or false
  _player_obj.is_in_basic_action = _player_obj.action < 0xFF and _previous_action < 0xFF -- this triggers one frame early than it should, so we delay it artificially
  _player_obj.has_just_entered_basic_action = not _previous_is_in_basic_action and _player_obj.is_in_basic_action

  local _previous_recovery_flag = _player_obj.recovery_flag or 1
  _player_obj.recovery_flag = memory.readbyte(_player_obj.base + 0x3B)
  _player_obj.has_just_ended_recovery = _previous_recovery_flag ~= 0 and _player_obj.recovery_flag == 0

  _player_obj.meter_gauge = memory.readbyte(_player_obj.gauge_addr)
  _player_obj.meter_count = memory.readbyte(_player_obj.meter_addr[2])
  if _player_obj.id == 1 then
    _player_obj.max_meter_gauge = memory.readbyte(0x020695B3)
    _player_obj.max_meter_count = memory.readbyte(0x020695BD)
    _player_obj.selected_sa = memory.readbyte(0x0201138B) + 1
    _player_obj.superfreeze_decount = memory.readbyte(0x02069520) -- seems to be in P2 memory space, don't know why
  else
    _player_obj.max_meter_gauge = memory.readbyte(0x020695DF)
    _player_obj.max_meter_count = memory.readbyte(0x020695E9)
    _player_obj.selected_sa = memory.readbyte(0x0201138C) + 1
    _player_obj.superfreeze_decount = memory.readbyte(0x02069088) -- seems to be in P1 memory space, don't know why
  end

  -- LIFE
  _player_obj.life = memory.readbyte(_player_obj.base + 0x9F)

  -- BONUSES
  _player_obj.damage_bonus = memory.readword(_player_obj.base + 0x43A)
  _player_obj.stun_bonus = memory.readword(_player_obj.base + 0x43E)
  _player_obj.defense_bonus = memory.readword(_player_obj.base + 0x440)

  -- THROW
  _player_obj.is_being_thrown = memory.readbyte(_player_obj.base + 0x3CF) ~= 0
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
  _player_obj.is_in_jump_startup = _player_obj.movement_type2 == 0x0C and not _player_obj.is_blocking
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
  local _previous_is_idle = _player_obj.is_idle or false
  _player_obj.idle_time = _player_obj.idle_time or 0
  _player_obj.is_idle = (
    not _player_obj.is_attacking and
    not _player_obj.is_attacking_ext and
    not _player_obj.is_blocking and
    not _player_obj.is_wakingup and
    not _player_obj.is_fast_wakingup and
    not _player_obj.is_being_thrown and
    _player_obj.movement_type ~= 5 and -- leap
    _player_obj.recovery_time == _player_obj.previous_recovery_time and
    _player_obj.remaining_freeze_frames == 0 and
    _player_obj.input_capacity > 0
  )

  if _player_obj.is_idle then
    _player_obj.idle_time = _player_obj.idle_time + 1
  else
    _player_obj.idle_time = 0
  end

  if not _previous_is_idle and _player_obj.is_idle then
    log(_player_obj.prefix, "blocking", string.format("idle"))
  end

  -- ANIMATION
  local _self_cancel = false
  local _previous_animation = _player_obj.animation or ""
  _player_obj.animation = bit.tohex(memory.readword(_player_obj.base + 0x202), 4)
  _player_obj.has_animation_just_changed = _previous_animation ~= _player_obj.animation
  if not _player_obj.has_animation_just_changed then
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
  if _player_obj.has_relevant_animation_just_changed then
    if _debug_state_variables then print(string.format("%d - %s relevant animation changed (%s -> %s)", frame_number, _player_obj.prefix, _previous_relevant_animation, _player_obj.relevant_animation)) end
    log(_player_obj.prefix, "animation", string.format("rel anim %s->%s", _previous_relevant_animation, _player_obj.relevant_animation))
  end


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

-- CHARGE STATE
  -- global game consts
  _player_obj.charge_1 = _player_obj.charge_1 or { name = "Charge1", max_charge = 42, max_reset = 42, enabled = false }
  _player_obj.charge_2 = _player_obj.charge_2 or { name = "Charge2", max_charge = 42, max_reset = 42, enabled = false }
  _player_obj.charge_3 = _player_obj.charge_3 or { name = "Charge3", max_charge = 42, max_reset = 42, enabled = false }


  function read_charge_state(_charge_object, _valid_charge, _charge_addr, _reset_addr)
    if _valid_charge == false then
      _charge_object.charge_time = 0
      _charge_object.reset_time = 0
      return 
    end
    _charge_object.overcharge = _charge_object.overcharge or 0
    _charge_object.last_overcharge = _charge_object.last_overcharge or 0
    _charge_object.overcharge_start = _charge_object.overcharge_start or 0
    _charge_object.enabled = true
    local _previous_charge_time = _charge_object.charge_time or 0
    local _previous_reset_time = _charge_object.reset_time or 0
    _charge_object.charge_time = memory.readbyte(_charge_addr)
    _charge_object.reset_time = memory.readbyte(_reset_addr)
    if _charge_object.charge_time == 0xFF then _charge_object.charge_time = 0 end
    if _charge_object.reset_time == 0xFF then _charge_object.reset_time = 0 end
    if _charge_object.charge_time == 0 then
      if _charge_object.overcharge_start == 0 then
        _charge_object.overcharge_start = frame_number
      else
        _charge_object.overcharge = frame_number - _charge_object.overcharge_start
      end
    end
    if _charge_object.charge_time == _charge_object.max_charge then 
      if _charge_object.overcharge ~= 0 then _charge_object.last_overcharge = _charge_object.overcharge end
        _charge_object.overcharge = 0 
        _charge_object.overcharge_start = 0
    end -- reset overcharge
  end

  if _player_obj.char_str == "alex" then
    _charge_1_addr = _player_obj.charge_1_addr
    _reset_1_addr = _player_obj.charge_1_reset_addr
    _player_obj.charge_1.name= "Elbow"
    _valid_1 = true
    _charge_2_addr = _player_obj.charge_2_addr
    _reset_2_addr = _player_obj.charge_2_reset_addr
    _player_obj.charge_2.name= "Stomp"
    _valid_2 = true
    _charge_3_addr = _player_obj.charge_3_addr
    _reset_3_addr = _player_obj.charge_3_reset_addr
    _valid_3 = false
  elseif _player_obj.char_str == "oro" then
    _charge_1_addr = _player_obj.charge_3_addr
    _reset_1_addr = _player_obj.charge_3_reset_addr
    _player_obj.charge_1.name= "Sun Disk"
    _valid_1 = true
    _charge_2_addr = _player_obj.charge_5_addr
    _reset_2_addr = _player_obj.charge_5_reset_addr
    _player_obj.charge_2.name= "Yanma"
    _valid_2 = true
    _charge_3_addr = _player_obj.charge_3_addr
    _reset_3_addr = _player_obj.charge_3_reset_addr
    _valid_3 = false
  elseif _player_obj.char_str == "urien" then
    _charge_1_addr = _player_obj.charge_5_addr
    _reset_1_addr = _player_obj.charge_5_reset_addr
    _player_obj.charge_1.name= "Tackle"
    _valid_1 = true
    _charge_2_addr = _player_obj.charge_2_addr
    _reset_2_addr = _player_obj.charge_2_reset_addr
    _player_obj.charge_2.name= "Kneedrop"
    _valid_2 = true
    _charge_3_addr = _player_obj.charge_4_addr
    _reset_3_addr = _player_obj.charge_4_reset_addr
    _player_obj.charge_3.name= "Headbutt"
    _valid_3 = True
  elseif _player_obj.char_str == "remy" then
    _charge_1_addr = _player_obj.charge_4_addr
    _reset_1_addr = _player_obj.charge_4_reset_addr
    _player_obj.charge_1.name= "LoV High"
    _valid_1 = true
    _charge_2_addr = _player_obj.charge_3_addr
    _reset_2_addr = _player_obj.charge_3_reset_addr
    _player_obj.charge_2.name= "Lov Low"
    _valid_2 = true
    _charge_3_addr = _player_obj.charge_5_addr
    _reset_3_addr = _player_obj.charge_5_reset_addr
    _player_obj.charge_3.name= "Rising"
    _valid_3 = true
  elseif _player_obj.char_str == "q" then
    _charge_1_addr = _player_obj.charge_5_addr
    _reset_1_addr = _player_obj.charge_5_reset_addr
    _player_obj.charge_1.name= "Dash Atk"
    _valid_1 = true
    _charge_2_addr = _player_obj.charge_4_addr
    _reset_2_addr = _player_obj.charge_4_reset_addr
    _player_obj.charge_2.name= "Dash Low"
    _valid_2 = true
    _charge_3_addr = _player_obj.charge_1_addr
    _reset_3_addr = _player_obj.charge_1_reset_addr
    _valid_3 = false
  elseif _player_obj.char_str == "chunli" then
    _charge_1_addr = _player_obj.charge_5_addr
    _reset_1_addr = _player_obj.charge_5_reset_addr
    _player_obj.charge_1.name= "Bird Kick"
    _valid_1 = true
    _charge_2_addr = _player_obj.charge_1_addr
    _reset_2_addr = _player_obj.charge_1_reset_addr
    _valid_2 = false
    _charge_3_addr = _player_obj.charge_1_addr
    _reset_3_addr = _player_obj.charge_1_reset_addr
    _valid_3 = false
  else
    _charge_1_addr = _player_obj.charge_1_addr
    _reset_1_addr = _player_obj.charge_1_reset_addr
    _valid_1 = false
    _charge_2_addr = _player_obj.charge_1_addr
    _reset_2_addr = _player_obj.charge_1_reset_addr
    _valid_2 = false
    _charge_3_addr = _player_obj.charge_1_addr
    _reset_3_addr = _player_obj.charge_1_reset_addr
    _valid_3 = false
  end

  read_charge_state(_player_obj.charge_1, _valid_1, _charge_1_addr, _reset_1_addr)
  read_charge_state(_player_obj.charge_2, _valid_2, _charge_2_addr, _reset_2_addr)
  read_charge_state(_player_obj.charge_3, _valid_3, _charge_3_addr, _reset_3_addr)
  -- STUN
  _player_obj.stun_max = memory.readbyte(_player_obj.stun_max_addr)
  _player_obj.stun_timer = memory.readbyte(_player_obj.stun_timer_addr)
  _player_obj.stun_bar = bit.rshift(memory.readdword(_player_obj.stun_bar_addr), 24)
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
       _obj.lifetime = 0
       _obj.has_activated = false
       _is_initialization = true
    end
    if read_game_object(_obj) then
      _obj.emitter_id = memory.readbyte(_obj.base + 0x2) + 1

      if _is_initialization then
        _obj.initial_flip_x = _obj.flip_x
        _obj.emitter_animation = player_objects[_obj.emitter_id].animation
      else
        _obj.lifetime = _obj.lifetime + 1
      end

      if #_obj.boxes > 0 then
        _obj.has_activated = true
      end
      _obj.expired = false
      _obj.is_converted = _obj.flip_x ~= _obj.initial_flip_x
      _obj.previous_remaining_hits = _obj.remaining_hits or 0
      _obj.remaining_hits = memory.readbyte(_obj.base + 0x9C + 2)
      if _obj.remaining_hits > 0 then
        _obj.is_forced_one_hit = false
      end
      --_obj.remaining_hits2 = memory.readbyte(_obj.base + 0x49 + 0) -- Looks like attack validity or whatever
      _obj.projectile_type = string.format("%02X", memory.readbyte(_obj.base + 0x91))
      if _is_initialization then
        _obj.projectile_start_type = _obj.projectile_type -- type can change during projectile life (ex: aegis)
      end
      _obj.remaining_freeze_frames = memory.readbyte(_obj.base + 0x45)
      if projectiles[_obj.id] == nil then
        log(player_objects[_obj.emitter_id].prefix, "projectiles", string.format("projectile %s %s 1", _obj.id, _obj.projectile_type))
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


-- ## write
function write_game_vars(_settings)
  -- freeze game
  if _settings.freeze then
    memory.writebyte(0x0201136F, 0xFF)
  else
    memory.writebyte(0x0201136F, 0x00)
  end

  -- timer
  if _settings.infinite_time then
    memory.writebyte(0x02011377, 100)
  end

  -- music
  if _settings.music_volume then
    memory.writebyte(0x02078D06, _settings.music_volume * 8)
  end
end

-- # tools
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


-- # initialize player objects
reset_player_objects()
