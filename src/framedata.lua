data_path = "data/"..rom_name.."/"
framedata_path = data_path.."framedata/"
frame_data_file_ext = "_framedata.json"

characters =
{
  "gill",
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
  "remy",
}
if is_4rd_strike then
  characters[1] = "gill"
  characters[16] = "usean"
end

-- # Character specific stuff
character_specific = {}
for i = 1, #characters do
  character_specific[characters[i]] = { timed_sa = {false, false, false} }
end

-- ## Character approximate dimensions
character_specific.alex.half_width = 45
character_specific.chunli.half_width = 39
character_specific.dudley.half_width = 29
character_specific.elena.half_width = 44
character_specific.gouki.half_width = 33
character_specific.hugo.half_width = 43
character_specific.ibuki.half_width = 34
character_specific.ken.half_width = 30
character_specific.makoto.half_width = 42
character_specific.necro.half_width = 26
character_specific.oro.half_width = 40
character_specific.q.half_width = 25
character_specific.remy.half_width = 32
character_specific.ryu.half_width = 31
character_specific.sean.half_width = 29
character_specific.twelve.half_width = 33
character_specific.urien.half_width = 36
character_specific.yang.half_width = 41
character_specific.yun.half_width = 37

character_specific.alex.height = 104
character_specific.chunli.height = 97
character_specific.dudley.height = 109
character_specific.elena.height = 88
character_specific.gouki.height = 107
character_specific.hugo.height = 137
character_specific.ibuki.height = 92
character_specific.ken.height = 107
character_specific.makoto.height = 90
character_specific.necro.height = 89
character_specific.oro.height = 88
character_specific.q.height = 130
character_specific.remy.height = 114
character_specific.ryu.height = 101
character_specific.sean.height = 103
character_specific.twelve.height = 91
character_specific.urien.height = 121
character_specific.yang.height = 89
character_specific.yun.height = 89

-- ## Characters standing states
character_specific.oro.additional_standing_states = { 3 } -- 3 is crouching
character_specific.dudley.additional_standing_states = { 6 } -- 6 is crouching
character_specific.makoto.additional_standing_states = { 7 } -- 7 happens during Oroshi
character_specific.necro.additional_standing_states = { 13 } -- 13 happens during CrLK

-- ## Characters timed SA
character_specific.oro.timed_sa[1] = true;
character_specific.oro.timed_sa[3] = true;
character_specific.q.timed_sa[3] = true;
character_specific.makoto.timed_sa[3] = true;
character_specific.twelve.timed_sa[3] = true;
character_specific.yang.timed_sa[3] = true;
character_specific.yun.timed_sa[3] = true;

-- ## Frame data meta
frame_data_meta = {}
for i = 1, #characters do
  frame_data_meta[characters[i]] = {
    moves = {},
    projectiles = {},
  }
end
framedata_meta_file_path = data_path.."framedata_meta"
require(framedata_meta_file_path)

-- # Frame data
frame_data = {}

function save_frame_data()
  for _key, _value in ipairs(characters) do
    if frame_data[_value].dirty then
      frame_data[_value].dirty = nil
      local _file_path = framedata_path.._value..frame_data_file_ext
      if not write_object_to_json_file(frame_data[_value], _file_path) then
        print(string.format("Error: Failed to write frame data to \"%s\"", _file_path))
      else
        print(string.format("Saved frame data to \"%s\"", _file_path))
      end
    end
  end
end

function load_frame_data()
  for _key, _value in ipairs(characters) do
    local _file_path = framedata_path.._value..frame_data_file_ext
    frame_data[_value] = read_object_from_json_file(_file_path) or {}
    frame_data[_value].wakeups = frame_data[_value].wakeups or {}
  end
end


-- # Frame data recording
function reset_current_recording_animation()
  current_recording_animation_previous_pos = {0, 0}
  current_recording_animation = nil
end
reset_current_recording_animation()

function record_framedata(_player_obj, _projectiles)
  local _debug = true

  local _force_recording = current_recording_animation and frame_data_meta[_player_obj.char_str].moves[current_recording_animation.id] ~= nil and frame_data_meta[_player_obj.char_str].moves[current_recording_animation.id].force_recording
  -- any connecting attack frame data may be ill formed. We discard it immediately to avoid data loss (except for moves tagged as "force_recording" that are difficult to record otherwise)
  if (_player_obj.has_just_hit or _player_obj.has_just_been_blocked or _player_obj.has_just_been_parried) then
    if not _force_recording then
      if current_recording_animation and _debug then
        print(string.format("dropped animation because it connected: %s", _player_obj.animation))
      end
      reset_current_recording_animation()
    end
  end

  if (_player_obj.has_animation_just_changed) then
    local _id
    if current_recording_animation then _id = current_recording_animation.id end

    if current_recording_animation and (current_recording_animation.attack_box_count > 0 or _force_recording) then
      current_recording_animation.attack_box_count = nil -- don't save that
      current_recording_animation.id = nil -- don't save that

      -- compute hit frames range
      for _i, _hit_frame in ipairs(current_recording_animation.hit_frames) do
        local _range_limit_frame = #current_recording_animation.frames - 1
        if _i < #current_recording_animation.hit_frames then
          _range_limit_frame = current_recording_animation.hit_frames[_i + 1] - 1
        end
        local _range_end_frame = _hit_frame
        if _hit_frame < _range_limit_frame then
          for _j = (_hit_frame + 1), _range_limit_frame do
            if #current_recording_animation.frames[_j].boxes > 0 then
              _range_end_frame = _j - 1
            else
              break
            end
          end
        end

        current_recording_animation.hit_frames[_i] = { min = _hit_frame, max = _range_end_frame }
      end

      if (frame_data[_player_obj.char_str] == nil) then
        frame_data[_player_obj.char_str] = {}
      end
      frame_data[_player_obj.char_str].dirty = true
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

    local _frame = frame_number - _player_obj.current_animation_freeze_frames - _player_obj.current_animation_start_frame
    if _player_obj.has_just_acted then
      table.insert(current_recording_animation.hit_frames, _frame)
    end

    if _player_obj.remaining_freeze_frames == 0 then
      --print(string.format("recording frame %d (%d - %d - %d)", _frame, frame_number, _player_obj.current_animation_freeze_frames, _player_obj.current_animation_start_frame))

      local _sign = 1
      if _player_obj.flip_input then _sign = -1 end

      current_recording_animation.frames[_frame + 1] = {
        boxes = {},
        movement = {
          (_player_obj.pos_x - current_recording_animation_previous_pos[1]) * _sign,
          (_player_obj.pos_y - current_recording_animation_previous_pos[2]),
        },
        frame_id = _player_obj.animation_frame_id,
        hash = _player_obj.animation_frame_hash,
      }
      current_recording_animation_previous_pos = { _player_obj.pos_x, _player_obj.pos_y }

      for __, _box in ipairs(_player_obj.boxes) do
        if (_box.type == "attack") or (_box.type == "throw") then
          table.insert(current_recording_animation.frames[_frame + 1].boxes, copytable(_box))
          current_recording_animation.attack_box_count = current_recording_animation.attack_box_count + 1
        end
      end

      local _move_framedata_meta = frame_data_meta[_player_obj.char_str].moves[current_recording_animation.id]
      if _move_framedata_meta and _move_framedata_meta.record_projectile then
        local _inserted_projectile = false
        for _id, _obj in pairs(_projectiles) do
          if _obj.emitter_animation == current_recording_animation.id then
            local _dx, _dy = _player_obj.pos_x - _obj.pos_x, _player_obj.pos_y - _obj.pos_y
            if _player_obj.flip_x ~= 0 then _dx = _dx * -1 end
            for __, _box in ipairs(_obj.boxes) do
              if (_box.type == "attack") or (_box.type == "throw") then
                local _temp_box = copytable(_box)
                _temp_box.bottom = _temp_box.bottom - _dy
                _temp_box.left = _temp_box.left + _dx
                table.insert(current_recording_animation.frames[_frame + 1].boxes, _temp_box)
                current_recording_animation.attack_box_count = current_recording_animation.attack_box_count + 1
                _inserted_projectile = true
              end
            end
          end
        end

        if _inserted_projectile and #current_recording_animation.hit_frames == 0 then
          table.insert(current_recording_animation.hit_frames, _frame)
        end
      end
    end
  end
end

projectiles_recording = {}
function reset_current_projectiles_recording()
  for _id, _obj in pairs(projectiles_recording) do
    print(string.format("Dropped recording projectile %s", _obj.type))
  end
  projectiles_recording = {}
end

function record_projectiles(_projectiles)
  for _id, _obj in pairs(_projectiles) do
    local _recording = projectiles_recording[_id] or { type = "", start_lifetime = 0, boxes = {}, recorded = false }
    _recording.type = _obj.projectile_start_type
    _recording.char_str = player_objects[_obj.emitter_id].char_str

    if not _recording.recorded then
      if #_recording.boxes == 0 and #_obj.boxes > 0 then
        _recording.recorded = true
        _recording.start_lifetime = _obj.lifetime
        _recording.boxes = _obj.boxes
      end
      projectiles_recording[_id] = _recording
    end
  end

  for _id, _obj in pairs(projectiles_recording) do
    if _projectiles[_id] == nil then
      local _recording = projectiles_recording[_id]
      projectiles_recording[_id] = nil

      frame_data[_recording.char_str][_recording.type] = { start_lifetime = _recording.start_lifetime, boxes = _recording.boxes }
      frame_data[_recording.char_str].dirty = true
      print(string.format("Recorded projectile %s", _obj.type))
    end
  end
end

function reset_current_recording_idle_animation()
  if is_recording_idle_animation then
    print(string.format("Dropped recording idle animation"))
  end
  is_recording_idle_animation = false
  current_recording_idle_startup_animation = nil
  current_recording_idle_animation = nil
  wait_for_idle_start = false
end

function record_idle_framedata(_player_obj)
  -- arm recording
  if _player_obj.is_wakingup then
    wait_for_idle_start = true
  end

  -- start recording
  if wait_for_idle_start and _player_obj.is_idle then
    current_recording_idle_startup_animation = {
      frames = {}
    }
    current_recording_idle_animation = {
      id = _player_obj.animation,
      frames = {}
    }
    wait_for_idle_start = false
    is_recording_idle_animation = true
    print(string.format("Started recording idle animation"))
  end

  if is_recording_idle_animation and not _player_obj.is_idle then
    reset_current_recording_idle_animation()
  elseif is_recording_idle_animation then

    -- if animation has changed, transfer already recorded frame to the startup animation
    if _player_obj.has_animation_just_changed then
      for __, _frame in ipairs(current_recording_idle_animation.frames) do
        table.insert(current_recording_idle_startup_animation.frames, _frame)
      end
      current_recording_idle_animation.id = _player_obj.animation
      current_recording_idle_animation.frames = {}
    end

    -- record frame
    local _frame = {
      id = _player_obj.animation_frame_id,
      boxes = {}
    }
    for __, _box in ipairs(_player_obj.boxes) do
      table.insert(_frame.boxes, copytable(_box))
    end
    table.insert(current_recording_idle_animation.frames, _frame)

    -- detect loop
    local _minimum_loop_size = 5
    local _loop_size = 0
    local _frames = current_recording_idle_animation.frames
    for _i = 2, #_frames do
      if _frames[_i].id == _frames[1].id then
        for _j = 1, #_frames do
          local _looped_index = _i + _j - 1
          if _looped_index > #_frames then
            break
          end
          if _frames[_j].id ~= _frames[_looped_index].id then
            break
          end

          if _j == _i then
            _loop_size = _i - 1
            break
          end
        end
      end
      if _loop_size > _minimum_loop_size then
        break
      end
    end

    -- write into frame data
    -- exceptions
    if #current_recording_idle_animation.frames > 30 and _player_obj.char_str == "makoto" then
      _loop_size = #current_recording_idle_animation.frames
    end
    if #current_recording_idle_animation.frames > 30 and _player_obj.char_str == "hugo" then
      _loop_size = #current_recording_idle_animation.frames
    end
    if _loop_size > _minimum_loop_size then
      while #current_recording_idle_animation.frames > _loop_size do
        table.remove(current_recording_idle_animation.frames)
      end
      frame_data[_player_obj.char_str].wakeup_to_idle = current_recording_idle_startup_animation
      frame_data[_player_obj.char_str].idle = current_recording_idle_animation
      frame_data[_player_obj.char_str].dirty = true
      print(string.format("Recorded idle animation \"%s\" of size %d/%d", current_recording_idle_animation.id, #current_recording_idle_startup_animation.frames, _loop_size))
      is_recording_idle_animation = false
      reset_current_recording_idle_animation()
    end
  end
end

function update_framedata_recording(_player_obj, _projectiles)
  if debug_settings.record_framedata and is_in_match and not is_menu_open then
    record_framedata(_player_obj, _projectiles)
  else
    reset_current_recording_animation()
  end
end

function update_projectiles_recording(_projectiles)
  if debug_settings.record_framedata and is_in_match and not is_menu_open then
    record_projectiles(_projectiles)
  else
    reset_current_projectiles_recording()
  end
end

function update_idle_framedata_recording(_player_obj)
  if debug_settings.record_idle_framedata and is_in_match and not is_menu_open then
    record_idle_framedata(_player_obj)
  else
    reset_current_recording_idle_animation()
  end
end

function find_wake_up(_char_str, _wakeup_animation, _last_act_animation)
  local _wakeup = frame_data[_char_str].wakeups[_wakeup_animation]
  if _wakeup == nil then
    return nil
  end

  if _wakeup.exceptions ~= nil then
    local _exception = _wakeup.exceptions[_last_act_animation]
    if _exception then
      return _exception.duration
    end
  end

  return _wakeup.duration
end

function insert_wake_up(_char_str, _wakeup_animation, _last_act_animation, _duration)
  local _debug = true
  local _char_frame_data = frame_data[_char_str]
  local _wakeup = _char_frame_data.wakeups[_wakeup_animation]

  if _wakeup == nil then
    _char_frame_data.dirty = true
    _char_frame_data.wakeups[_wakeup_animation] = { duration = _duration, exceptions = {} }
    _char_frame_data.wakeups[_wakeup_animation].exceptions[_last_act_animation] = { duration = _duration }
    if _debug then
      print(string.format("Inserted new wakeup \"%s\", %d", _wakeup_animation, _duration))
    end
    return true
  else
    _wakeup.exceptions = _wakeup.exceptions or {}
    if _wakeup.exceptions[_last_act_animation] == nil or _wakeup.exceptions[_last_act_animation].duration ~= _duration then
      if _wakeup.exceptions[_last_act_animation] == nil and _wakeup.duration == _duration then
        return false
      end

      _char_frame_data.dirty = true
      _wakeup.exceptions[_last_act_animation] = { duration = _duration }

      -- recompute default value
      local _durations = {}
      local _max_occurence = 0
      local _exception_count = 0
      for _i, _o in pairs(_wakeup.exceptions) do
        _exception_count = _exception_count + 1
        local _id = tostring(_o.duration)
        _durations[_id] = (_durations[_id] or 0) + 1
        _max_occurence = math.max(_max_occurence, _durations[_id])
      end
      local _final_duration = 0
      for _i, _occurences in pairs(_durations) do
        if _occurences == _max_occurence then
          _final_duration = tonumber(_i)
        end
        if _final_duration == _wakeup.duration then -- if default duration is ex-aequo, it wins
          break
        end
      end
      _wakeup.duration = _final_duration

      if _debug then
        print(string.format("Inserted new exception \"%s\" for wakeup \"%s\", %d. Default is %d",_last_act_animation, _wakeup_animation, _duration, _wakeup.duration))
      end
      return true
    end
  end
  return false
end

function update_wakeupdata_recording(_player_obj, _dummy_obj)
  if not is_in_match then
    return
  end
  -- moves to record to produce a complete set of wake ups:
  -- fast wake ups:
  --  Alex throw
  --  Alex HCB P
  --  Alex HCB K
  --  Oro back throw
  --  Gouki Back throw
  --  Gouki Demon flip P
  -- normal wake ups:
  --  Alex slash Ex
  --  Alex sweep
  --  Alex HCB K
  --  Alex HCB P
  --  Alex stomp
  --  Alex DPF K
  --  Alex HCharge ExK
  --  Ibuki raida
  --  Ibuki air throw
  --  Ibuki neck breaker
  --  Hugo 360 P
  --  Hugo neutral grab
  --  Hugo back breaker
  --  Oro back throw
  --  Oro HCB Px3
  --  Gouki back throw
  --  Gouki demon flip P
  --  Twelve forward, neutral and back throw

  -- Always report missing data
  if _dummy_obj.has_just_woke_up then
    local _wakeup_animation = _dummy_obj.wakeup_animation
    local _wakeup_time = _dummy_obj.wakeup_time
    local _wakeup = frame_data[_dummy_obj.char_str].wakeups[_wakeup_animation]
    local _duration = find_wake_up(_dummy_obj.char_str, _dummy_obj.wakeup_animation, _dummy_obj.wakeup_other_last_act_animation)
    if _duration == nil then
      print(string.format("Unknown wakeup animation: %s", _wakeup_animation))
    elseif _duration ~= _wakeup_time then
      print(string.format("Mismatching %s wakeup animation time %s: %d against default %d. last %s act animation: \"%s\"", _dummy_obj.char_str, _wakeup_animation, _wakeup_time, _duration, _player_obj.char_str, _dummy_obj.wakeup_other_last_act_animation))
    end
  end

  -- Record
  if debug_settings.record_wakeupdata then
    if _dummy_obj.has_just_woke_up then
      local _char_str = _dummy_obj.char_str
      local _animation = _dummy_obj.wakeup_animation
      local _last_act_animation = _dummy_obj.wakeup_other_last_act_animation
      local _duration = _dummy_obj.wakeup_time
      insert_wake_up(_char_str, _animation, _last_act_animation, _duration)
    end
  end
end

function test_collision(_defender_x, _defender_y, _defender_flip_x, _defender_boxes, _attacker_x, _attacker_y, _attacker_flip_x, _attacker_boxes, _box_type_matches, _defender_hurtbox_dilation_x, _defender_hurtbox_dilation_y, _attacker_hitbox_dilation_x, _attacker_hitbox_dilation_y)

  local _debug = false
  if (_defender_hurtbox_dilation_x == nil) then _defender_hurtbox_dilation_x = 0 end
  if (_defender_hurtbox_dilation_y == nil) then _defender_hurtbox_dilation_y = 0 end
  if (_attacker_hitbox_dilation_x == nil) then _attacker_hitbox_dilation_x = 0 end
  if (_attacker_hitbox_dilation_y == nil) then _attacker_hitbox_dilation_y = 0 end
  if (_test_throws == nil) then _test_throws = false end
  if (_box_type_matches == nil) then _box_type_matches = {{{"vulnerability", "ext. vulnerability"}, {"attack"}}} end

  if (#_box_type_matches == 0 ) then return false end
  if (#_defender_boxes == 0 ) then return false end
  if (#_attacker_boxes == 0 ) then return false end

  if _debug then print(string.format("   %d defender boxes, %d attacker boxes", #_defender_boxes, #_attacker_boxes)) end

  for k = 1, #_box_type_matches do
    local _box_type_match = _box_type_matches[k]
    for i = 1, #_defender_boxes do
      local _d_box = _defender_boxes[i]

      --print("d ".._d_box.type)

      local _defender_box_match = false
      for _key, _value in ipairs(_box_type_match[1]) do
        if _value == _d_box.type then
          _defender_box_match = true
          break
        end
      end

      if _defender_box_match then
        -- compute defender box bounds
        local _d_l
        if _defender_flip_x == 0 then
          _d_l = _defender_x + _d_box.left
        else
          _d_l = _defender_x - _d_box.left - _d_box.width
        end
        local _d_r = _d_l + _d_box.width
        local _d_b = _defender_y + _d_box.bottom
        local _d_t = _d_b + _d_box.height

        _d_l = _d_l - _defender_hurtbox_dilation_x
        _d_r = _d_r + _defender_hurtbox_dilation_x
        _d_b = _d_b - _defender_hurtbox_dilation_y
        _d_t = _d_t + _defender_hurtbox_dilation_y

        for j = 1, #_attacker_boxes do
          local _a_box = _attacker_boxes[j]

          --print("a ".._a_box.type)

          local _attacker_box_match = false
          for _key, _value in ipairs(_box_type_match[2]) do
            if _value == _a_box.type then
              _attacker_box_match = true
              break
            end
          end
          if _attacker_box_match then
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

            _a_l = _a_l - _attacker_hitbox_dilation_x
            _a_r = _a_r + _attacker_hitbox_dilation_x
            _a_b = _a_b - _attacker_hitbox_dilation_y
            _a_t = _a_t + _attacker_hitbox_dilation_y

            if _debug then print(string.format("   testing (%d,%d,%d,%d)(%s) against (%d,%d,%d,%d)(%s)", _d_t, _d_r, _d_b, _d_l, _d_box.type, _a_t, _a_r, _a_b, _a_l, _a_box.type)) end

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
  end

  return false
end
