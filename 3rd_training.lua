-- app data
is_menu_open = false
menu_selected_index = 1
pending_input_sequence = nil

-- game data
frame_number = 0
preparing_counterattack = false
recovery_time = 0
is_in_match = false
knockeddown = false
flying_after_knockdown = false
onground_after_knockdown = false
fastrecovery_countdown = -1

function make_player()
  return {
    character = -1,
    facing_right = false,
    has_active = false,
    pos_x = 0,
    pos_y = 0,
    action = 0,
  }
end
P1 = make_player()
P2 = make_player()

-- input
function make_input_set()
  return {
    up = false,
    down = false,
    left = false,
    right = false,
    LP = false,
    MP = false,
    HP = false,
    LK = false,
    MK = false,
    HK = false,
    start = false,
    coin = false
  }
end

function make_empty_joypad()
  local joy = {}
  joy["P1 Start"] = false
  joy["P1 Coin"] = false
  joy["P1 Up"] = false
  joy["P1 Down"] = false
  joy["P1 Left"] = false
  joy["P1 Right"] = false
  joy["P1 Weak Punch"] = false
  joy["P1 Medium Punch"] = false
  joy["P1 Strong Punch"] = false
  joy["P1 Weak Kick"] = false
  joy["P1 Medium Kick"] = false
  joy["P1 Strong Kick"] = false

  joy["P2 Start"] = false
  joy["P2 Coin"] = false
  joy["P2 Up"] = false
  joy["P2 Down"] = false
  joy["P2 Left"] = false
  joy["P2 Right"] = false
  joy["P2 Weak Punch"] = false
  joy["P2 Medium Punch"] = false
  joy["P2 Strong Punch"] = false
  joy["P2 Weak Kick"] = false
  joy["P2 Medium Kick"] = false
  joy["P2 Strong Kick"] = false

  return joy
end

frame_input = {
  P1 = {
    pressed = make_input_set(),
    released = make_input_set(),
    down = make_input_set()
  },
  P2 = {
    pressed = make_input_set(),
    released = make_input_set(),
    down = make_input_set()
  }
}

function update_input()
  local local_input = joypad.get()
  local P1 = {
    start = local_input["P1 Start"],
    coin = local_input["P1 Coin"],
    up = local_input["P1 Up"],
    down = local_input["P1 Down"],
    left = local_input["P1 Left"],
    right = local_input["P1 Right"],
    LP = local_input["P1 Weak Punch"],
    MP = local_input["P1 Medium Punch"],
    HP = local_input["P1 Strong Punch"],
    LK = local_input["P1 Weak Kick"],
    MK = local_input["P1 Medium Kick"],
    HK = local_input["P1 Strong Kick"]
  }
  local P2 = {
    start = local_input["P2 Start"],
    coin = local_input["P2 Coin"],
    up = local_input["P2 Up"],
    down = local_input["P2 Down"],
    left = local_input["P2 Left"],
    right = local_input["P2 Right"],
    LP = local_input["P2 Weak Punch"],
    MP = local_input["P2 Medium Punch"],
    HP = local_input["P2 Strong Punch"],
    LK = local_input["P2 Weak Kick"],
    MK = local_input["P2 Medium Kick"],
    HK = local_input["P2 Strong Kick"]
  }
  function update_player_input(_player, _input_name, _input)
    _player.pressed[_input_name] = false
    _player.released[_input_name] = false
    if _player.down[_input_name] == false and _input then _player.pressed[_input_name] = true end
    if _player.down[_input_name] == true and _input == false then _player.released[_input_name] = true end
    _player.down[_input_name] = _input
  end

  update_player_input(frame_input.P1, "start", P1.start)
  update_player_input(frame_input.P1, "coin", P1.coin)
  update_player_input(frame_input.P1, "up", P1.up)
  update_player_input(frame_input.P1, "down", P1.down)
  update_player_input(frame_input.P1, "left", P1.left)
  update_player_input(frame_input.P1, "right", P1.right)
  update_player_input(frame_input.P1, "LP", P1.LP)
  update_player_input(frame_input.P1, "MP", P1.MP)
  update_player_input(frame_input.P1, "HP", P1.HP)
  update_player_input(frame_input.P1, "LK", P1.LK)
  update_player_input(frame_input.P1, "MK", P1.MK)
  update_player_input(frame_input.P1, "HK", P1.HK)

  update_player_input(frame_input.P2, "start", P2.start)
  update_player_input(frame_input.P2, "coin", P2.coin)
  update_player_input(frame_input.P2, "up", P2.up)
  update_player_input(frame_input.P2, "down", P2.down)
  update_player_input(frame_input.P2, "left", P2.left)
  update_player_input(frame_input.P2, "right", P2.right)
  update_player_input(frame_input.P2, "LP", P2.LP)
  update_player_input(frame_input.P2, "MP", P2.MP)
  update_player_input(frame_input.P2, "HP", P2.HP)
  update_player_input(frame_input.P2, "LK", P2.LK)
  update_player_input(frame_input.P2, "MK", P2.MK)
  update_player_input(frame_input.P2, "HK", P2.HK)
end

seq_dp = { {"forward"}, {"down"}, {"down", "forward", "HP", "MP"} }

function queue_input_sequence(_player, _sequence)
  if #_sequence == 0 then
    return
  end

  if pending_input_sequence ~= nil then
    return
  end

  local seq = {}
  seq.player = _player
  seq.sequence = copytable(_sequence)
  seq.current_frame = 1

  pending_input_sequence = seq
end

function process_pending_input_sequence()
  if pending_input_sequence == nil then
    return
  end

  local prefix = ""
  local player_data = nil
  if pending_input_sequence.player == 1 then
    prefix = "P1 "
    player_data = P1
  elseif pending_input_sequence.player == 2 then
    prefix = "P2 "
    player_data = P2
  end

  print(player_data.facing_right)

  local s = ""
  local input = {}
  local current_frame_input = pending_input_sequence.sequence[pending_input_sequence.current_frame]
  for i = 1, #current_frame_input do
    local input_name = ""..prefix
    if current_frame_input[i] == "forward" then
      if player_data.facing_right then input_name = input_name.."Right" else input_name = input_name.."Left" end
    elseif current_frame_input[i] == "back" then
      if player_data.facing_right then input_name = input_name.."Left" else input_name = input_name.."Right" end
    elseif current_frame_input[i] == "up" then
      input_name = input_name.."Up"
    elseif current_frame_input[i] == "down" then
      input_name = input_name.."Down"
    elseif current_frame_input[i] == "LP" then
      input_name = input_name.."Weak Punch"
    elseif current_frame_input[i] == "MP" then
      input_name = input_name.."Medium Punch"
    elseif current_frame_input[i] == "HP" then
      input_name = input_name.."Strong Punch"
    elseif current_frame_input[i] == "LK" then
      input_name = input_name.."Weak Kick"
    elseif current_frame_input[i] == "MK" then
      input_name = input_name.."Medium Kick"
    elseif current_frame_input[i] == "HK" then
      input_name = input_name.."Strong Kick"
    end
    input[input_name] = true
    s = s..input_name
  end
  joypad.set(input)

  print(s)

  pending_input_sequence.current_frame = pending_input_sequence.current_frame + 1
  if pending_input_sequence.current_frame > #pending_input_sequence.sequence then
    pending_input_sequence = nil
  end
end

-- training settings
pose = {
  "normal",
  "crouching",
  "jumping",
  "highjumping",
}

stick_gesture = {
  "none",
  "forward",
  "back",
  "down",
  "up",
  "QCF",
  "QCB",
  "HCF",
  "HCB",
  "DPF",
  "DPB",
  "HCharge",
  "VCharge",
  "DQCF",
  "DQCB",
  "back+back",
  "forward+forward",
}

button_gesture =
{
  "none",
  "LP",
  "MP",
  "HP",
  "2P",
  "3P",
  "LK",
  "MK",
  "HK",
  "2K",
  "3K",
}

characters =
{
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
  "chunli",
  "makoto",
  "q",
  "twelve",
  "remy"
}

fast_recovery_mode =
{
  "never",
  "always",
}

blocking_mode =
{
  "never",
  "always",
}


hit_type =
{
  "normal",
  "low",
  "overhead",
}

training_settings = {
  pose = 1,
  blocking_mode = 1,
  fast_recovery_mode = 1,
  infinite_time = true,
  infinite_life = true,
  no_stun = true,
}

-- character specific stuff
function make_character_specific()
  return {
  }
end

character_specific = {}
for i = 1, #characters do
  character_specific[characters[i]] = make_character_specific()
end

-- menu
function checkbox_menu_item(_name, _property_name)
  local o = {}
  o.name = _name
  o.property_name = _property_name

  function o:draw(_x, _y, _selected)
    local c = 0xFFFFFFFF
    local prefix = ""
    local suffix = ""
    if _selected then
      c = 0xFF0000FF
      prefix = "< "
      suffix = " >"
    end
    gui.text(_x, _y, prefix..self.name.." : "..tostring(training_settings[self.property_name])..suffix, c)
  end

  function o:left()
    training_settings[self.property_name] = not training_settings[self.property_name]
  end

  function o:right()
    training_settings[self.property_name] = not training_settings[self.property_name]
  end

  return o
end

function list_menu_item(_name, _property_name, _list)
    local o = {}
    o.name = _name
    o.property_name = _property_name
    o.list = _list

    function o:draw(_x, _y, _selected)
      local c = 0xFFFFFFFF
      local prefix = ""
      local suffix = ""
      if _selected then
        c = 0xFF0000FF
        prefix = "< "
        suffix = " >"
      end
      gui.text(_x, _y, prefix..self.name.." : "..tostring(self.list[training_settings[self.property_name]])..suffix, c)
    end

    function o:left()
      training_settings[self.property_name] = training_settings[self.property_name] - 1
      if training_settings[self.property_name] == 0 then
        training_settings[self.property_name] = #self.list
      end
    end

    function o:right()
      training_settings[self.property_name] = training_settings[self.property_name] + 1
      if training_settings[self.property_name] > #self.list then
        training_settings[self.property_name] = 1
      end
    end

    return o
end

function integer_menu_item(_name, _property_name, _min, _max, _loop)
    local o = {}
    o.name = _name
    o.property_name = _property_name
    o.min = _min
    o.max = _max
    o.loop = _loop

    function o:draw(_x, _y, _selected)
      local c = 0xFFFFFFFF
      local prefix = ""
      local suffix = ""
      if _selected then
        c = 0xFF0000FF
        prefix = "< "
        suffix = " >"
      end
      gui.text(_x, _y, prefix..self.name.." : "..tostring(training_settings[self.property_name])..suffix, c)
    end

    function o:left()
      training_settings[self.property_name] = training_settings[self.property_name] - 1
      if training_settings[self.property_name] < self.min then
        if self.loop then
          training_settings[self.property_name] = self.max
        else
          training_settings[self.property_name] = self.max
        end
      end
    end

    function o:right()
      training_settings[self.property_name] = training_settings[self.property_name] + 1
      if training_settings[self.property_name] > self.max then
        if self.loop then
          training_settings[self.property_name] = self.min
        else
          training_settings[self.property_name] = self.max
        end
      end
    end

    return o
end

menu = {
  list_menu_item("Pose", "pose", pose),
  list_menu_item("Blocking", "blocking_mode", blocking_mode),
  list_menu_item("Fast Recovery", "fast_recovery_mode", fast_recovery_mode),
  checkbox_menu_item("Infinite Time", "infinite_time"),
  checkbox_menu_item("Infinite Life", "infinite_life"),
  checkbox_menu_item("No Stun", "no_stun"),
}

-- program
function before_frame()

  update_input()
  local input = {}

  -- frame number
  frame_number = memory_read(0x02007F00, 4)

  -- is in match
  -- I believe the bytes that are expected to be 0xff means that a character has been locked, while the byte expected to be 0x02 is the current match state. 0x02 means that round has started and players can move
	local p1_locked = memory.readbyte(0x020154C6);
	local p2_locked = memory.readbyte(0x020154C8);
	local match_state = memory.readbyte(0x020154A7);
	is_in_match = ((p1_locked == 0xFF or p2_locked == 0xFF) and match_state == 0x02);

  -- freeze game
  if is_menu_open then
    memory.writebyte(0x0201136F, 0xFF)
  else
    memory.writebyte(0x0201136F, 0x00)
  end

  -- timer
  if training_settings.infinite_time then
    memory.writebyte(0x02011377, 100)
  end

  -- player data
  P1.character = memory.readbyte(0x02011387)
  P1.facing_right = memory.readbyte(0x02068C77) > 0
  P1.has_active = memory.readbyte(0x02069094) > 0
  P1.pos_x = memory_read(0x02068CD0, 2)
  P1.pos_y = memory_read(0x02068CD4, 2)
  P1.action = memory_read(0x02068D19, 3)


  P2.character = memory.readbyte(0x02011388)
  P2.facing_right = memory.readbyte(0x0206910F) > 0
  P2.pos_x = memory_read(0x02069168, 2)
  P2.pos_y = memory_read(0x0206916C, 2)
  P2.action = memory_read(0x020691B1, 3)

  -- life bars
  if training_settings.infinite_life then
    memory.writebyte(0x02068d0b, 160) -- p1
    memory.writebyte(0x020691a3, 160) -- p2
  end

  -- stun
  if training_settings.no_stun then
    memory.writebyte(0x020695FD, 0); -- P1 Stun timer
		memory.writebyte(0x02069611, 0); -- P2 Stun timer
    memory.writebyte(0x020695FF, 0); -- p1 stun bar
    memory.writebyte(0x020695FF+1, 0); -- p1 stun bar
    memory.writebyte(0x020695FF+2, 0); -- p1 stun bar
    memory.writebyte(0x020695FF+3, 0); -- p1 stun bar
    memory.writebyte(0x02069613, 0); -- p2 stun bar
    memory.writebyte(0x02069613+1, 0); -- p2 stun bar
    memory.writebyte(0x02069613+2, 0); -- p2 stun bar
    memory.writebyte(0x02069613+3, 0); -- p2 stun bar
  end

  -- test
  if frame_input.P1.pressed.HK then
    --queue_input_sequence(2, seq_dp)
  end

  -- pose
  if is_in_match and not knockeddown then
    if training_settings.pose == 2 then
      input['P2 Down'] = true
    elseif training_settings.pose == 3 then
      input['P2 Up'] = true
    elseif training_settings.pose == 4 then
      if (frame_number % 2) == 0 then
        input['P2 Down'] = true
      else
        input['P2 Up'] = true
      end
    end
  end

  -- blocking
  if training_settings.blocking_mode == 2 then
    if P1.has_active then
      if P2.facing_right then
        input['P2 Left'] = true
      else
        input['P2 Right'] = true
      end
    end
  end

  -- fast recovery
  if is_in_match then
    knockeddown = (
      (bit.rshift(P2.action, 16) == 0x06) -- first flag at 0x06 means we are knocked down. Last flag means knock down variants
      or (P2.action == 0x030001) -- throws
    )

    if knockeddown then
      --print(string.format("%X", P2.action).."."..P2.pos_y)
    end

    if knockeddown and (not flying_after_knockdown) and (not onground_after_knockdown) and (P2.pos_y > 0) then
      --print("frutu")
      flying_after_knockdown = true
    end

    if flying_after_knockdown and (not onground_after_knockdown) and (P2.pos_y == 0) then
      -- hugo makes a weird bounce for 1 frame, we wait for the second frame in order to skip that
      if fastrecovery_framesonground == 1 then
        fastrecovery_framesonground = 0
        --print("priti")
        flying_after_knockdown = false
        onground_after_knockdown = true
        fastrecovery_countdown = 0
      else
        fastrecovery_framesonground = fastrecovery_framesonground + 1
      end
    else
      fastrecovery_framesonground = 0
    end

    if fastrecovery_countdown == 0 then
      --print("prout")
      if training_settings.fast_recovery_mode == 2 then
        input['P2 Down'] = true
      end
      fastrecovery_countdown = -1
    else
      fastrecovery_countdown = fastrecovery_countdown - 1
    end

    if (not knockeddown) and onground_after_knockdown then
      --print("prat."..string.format("%X", P2.action))
      onground_after_knockdown = false
    end
  end

  -- counter attack
  local local_recovery_time = memory.readbyte(0x0206928B)
  if (local_recovery_time ~= 0) and (recovery_time == 0) then
    recovery_time = local_recovery_time + 1
    preparing_counterattack = true
  end

  if (preparing_counterattack and recovery_time <= (#seq_dp + 1)) then
    --input['P2 Up'] = true
    --queue_input_sequence(2, seq_dp)
    preparing_counterattack = false
  end

  if recovery_time > 0 then
    recovery_time = recovery_time - 1
  end

  joypad.set(input)
  process_pending_input_sequence()
end

function on_gui()

  if is_in_match then
    if frame_input.P1.pressed.start then
      is_menu_open = (not is_menu_open)
    end
  else
    is_menu_open = false
  end

  if is_menu_open then
    local menu_x = 10
    local menu_y = 10
    local menu_y_interval = 9

    if frame_input.P1.pressed.down then
      menu_selected_index = menu_selected_index + 1
      if menu_selected_index > #menu then
        menu_selected_index = 1
      end
    end

    if frame_input.P1.pressed.up then
      menu_selected_index = menu_selected_index - 1
      if menu_selected_index == 0 then
        menu_selected_index = #menu
      end
    end

    if frame_input.P1.pressed.left then
      menu[menu_selected_index]:left()
    end

    if frame_input.P1.pressed.right then
      menu[menu_selected_index]:right()
    end

    gui.box(0,0,383,223, 0x000000AA, 0x000000AA)

    for i = 1, #menu do
      menu[i]:draw(menu_x, menu_y + menu_y_interval * (i - 1), menu_selected_index == i)
    end
  else
    gui.clearuncommitted()
  end
end

emu.registerbefore(before_frame)
gui.register(on_gui)

-- toolbox
function memory_read(_address, _size, _reverse)
  if _reverse == nil then _reverse = true end
  local result = 0
  for i = 1, _size do
    if _reverse then
      result = result + bit.lshift(memory.readbyte(_address + (i - 1)), (_size - i) * 8)
    else
      result = result + bit.lshift(memory.readbyte(_address + (i - 1)), (i - 1) * 8)
    end
  end
  return result
end
