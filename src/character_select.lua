character_select_ids = {
                 yang   = {1,0}, ken    = {2,0},
  alex  = {0,1}, twelve = {1,1}, hugo   = {2,1},
  sean  = {0,2}, makoto = {1,2}, elena  = {2,2},
  ibuki = {0,3}, chunli = {1,3}, dudley = {2,3},
  necro = {0,4}, q      = {1,4}, oro    = {2,4},
  urien = {0,5}, remy   = {1,5}, ryu    = {2,5},
  gouki = {0,6}, yun    = {1,6},
  gill  = {3,1}
}

character_color_inputs = 
{
  { "Weak Punch" },
  { "Medium Punch" },
  { "Strong Punch" },
  { "Weak Kick" },
  { "Medium Kick" },
  { "Strong Kick" },
  { "Weak Punch", "Medium Kick", "Strong Punch" },

    -- apparently those colors do not exist in the arcade version
  --{ "Start", "Weak Punch" },
  --{ "Start", "Medium Punch" },
  --{ "Start", "Strong Punch" },
  --{ "Start", "Weak Kick" },
  --{ "Start", "Medium Kick" },
  --{ "Start", "Strong Kick" },
}

character_select_list = {
  "alex",
  "chunli",
  "dudley",
  "elena",
  "gill",
  "gouki",
  "hugo",
  "ibuki",
  "ken",
  "makoto",
  "necro",
  "oro",
  "q",
  "remy",
  "ryu",
  "sean",
  "twelve",
  "urien",
  "yang",
  "yun",
}

character_select_sa = {
  "I",
  "II",
  "III",
}

character_select_colors = {
  "LP",
  "MP",
  "HP",
  "LK",
  "MK",
  "HK",
  "LP+MP+HK",
}

character_select_settings = 
{
  p1_character = 1,
  p1_sa = 1,
  p1_color = 1,
  p2_character = 1,
  p2_sa = 1,
  p2_color = 1,
}

character_select_coroutine = nil

character_select_popup = make_menu(71, 36, 312, 147, -- screen size 383,223
{
  list_menu_item("P1 Character", character_select_settings, "p1_character", character_select_list),
  list_menu_item("P1 Super Art", character_select_settings, "p1_sa", character_select_sa),
  list_menu_item("P1 Color", character_select_settings, "p1_color", character_select_colors),

  list_menu_item("P2 Character", character_select_settings, "p2_character", character_select_list),
  list_menu_item("P2 Super Art", character_select_settings, "p2_sa", character_select_sa),
  list_menu_item("P2 Color", character_select_settings, "p2_color", character_select_colors),

  button_menu_item("Validate", function() start_character_select_sequence() end),
  button_menu_item("Cancel", function() menu_stack_pop(character_select_popup) end),
})

function co_wait_x_frames(_frame_count)
  local _start_frame = frame_number
  while frame_number < _start_frame + _frame_count do
    coroutine.yield()
  end
end


function co_select_characters()
  local _debug = false
  if _debug then
    print("begin")
  end

  -- load save state
  savestate.load(savestate.create("data/"..rom_name.."/savestates/character_select.fs"))

  -- speed up things
  emu.speedmode("turbo")

  local _p1_character = character_select_list[character_select_settings.p1_character]
  local _p2_character = character_select_list[character_select_settings.p2_character]

  local _p1_color = character_select_settings.p1_color - 1
  local _p2_color = character_select_settings.p2_color - 1

  local _p1_sa = character_select_settings.p1_sa - 1
  local _p2_sa = character_select_settings.p2_sa - 1

  if _debug then
    print(string.format("p1: %s, %d, %d", _p1_character, _p1_sa, _p1_color))
    print(string.format("p2: %s, %d, %d", _p2_character, _p2_sa, _p2_color))
  end

  -- select characters
  memory.writebyte(adresses.players[1].character_select_col, character_select_ids[_p1_character][1])
  memory.writebyte(adresses.players[1].character_select_row, character_select_ids[_p1_character][2])
  memory.writebyte(adresses.players[2].character_select_col, character_select_ids[_p2_character][1])
  memory.writebyte(adresses.players[2].character_select_row, character_select_ids[_p2_character][2])


  -- select colors
  local _input = {}
  make_input_empty(_input)
  for _i, _value in ipairs(character_color_inputs[_p1_color + 1]) do
    _input["P1 ".._value] = true
  end
  for _i, _value in ipairs(character_color_inputs[_p2_color + 1]) do
    _input["P2 ".._value] = true
  end
  joypad.set(_input)

  -- wait for SA intro animation
  co_wait_x_frames(100)

  -- select SA
  function select_sa(_player, _sa)
    local _wait_time = 17
    local _input = {}
    make_input_empty(_input)
    if _sa == 1 then
      _input[_player.." Down"] = true
      joypad.set(_input)
      co_wait_x_frames(_wait_time)
    elseif _sa == 2 then
      _input[_player.." Up"] = true
      joypad.set(_input)
      co_wait_x_frames(_wait_time)
    end
    make_input_empty(_input)
    _input[_player.." Weak Punch"] = true
    joypad.set(_input)
    co_wait_x_frames(1)
  end
  if _debug then
    print("select sa")
  end
  -- TODO: make it simultaneous
  select_sa("P1", _p1_sa)
  select_sa("P2", _p2_sa)

  if _debug then
    print("wait for match")
  end
  while not is_in_match do
    coroutine.yield()
  end

  emu.speedmode("normal")
  if _debug then
    print("end")
  end
end

function start_character_select_sequence()
  character_select_coroutine = coroutine.create(co_select_characters)
end

function open_character_select_menu()
  for _i, _name in ipairs(character_select_list) do
    if _name == player_objects[1].char_str then
      character_select_settings.p1_character = _i
    end
    if _name == player_objects[2].char_str then
      character_select_settings.p2_character = _i
    end
  end

  character_select_settings.p1_sa = player_objects[1].selected_sa
  character_select_settings.p2_sa = player_objects[2].selected_sa

  character_select_settings.p1_color = memory.readbyte(adresses.players[1].character_select_color) + 1
  character_select_settings.p2_color = memory.readbyte(adresses.players[2].character_select_color) + 1

  character_select_popup.selected_index = 1
  menu_stack_push(character_select_popup)
end

function update_character_select()
  if (character_select_coroutine ~= nil) then
    local _input = {}
    make_input_empty(_input)
    joypad.set(_input)
    local _status = coroutine.status(character_select_coroutine)
    if _status == "suspended" then
      local _r, _error = coroutine.resume(character_select_coroutine)
      if not _r then
        print(_error)
      end
    elseif _status == "dead" then
      character_select_coroutine = nil
    end
  end
end