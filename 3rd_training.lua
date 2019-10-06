-- http://tasvideos.org/EmulatorResources/VBA/LuaScriptingFunctions.html
-- https://github.com/TASVideos/mame-rr/wiki/Lua-scripting-functions

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

  --print(player_data.facing_right)

  -- Charge moves memory locations
  -- P1
  -- 0x020259D8 H/Urien V/Oro V/Chun H/Q V/Remy
  -- 0x020259F4 (+1C) V/Urien H/Q H/Remy
  -- 0x02025A10 (+38) H/Oro H/Remy
  -- 0x02025A2C (+54) V/Urien V/Alex
  -- 0x02025A48 (+70) H/Alex

  -- P2
  -- 0x02025FF8
  -- 0x02026014
  -- 0x02026030
  -- 0x0202604C
  -- 0x02026068

  local charge_gauges = { { 0x020259D8, 0x020259F4, 0x02025A10, 0x02025A2C, 0x02025A48 }, { 0x02025FF8, 0x02026014, 0x02026030, 0x0202604C, 0x02026068 } }
  local character = player_data.character

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
    elseif current_frame_input[i] == "h_charge" then
      if characters[player_data.character] == "urien" then
        memory.writebyte(charge_gauges[pending_input_sequence.player][1], 0xFF)
        memory.writebyte(charge_gauges[pending_input_sequence.player][1]+1, 0xFF)
      elseif characters[player_data.character] == "oro" then
        memory.writebyte(charge_gauges[pending_input_sequence.player][3], 0xFF)
        memory.writebyte(charge_gauges[pending_input_sequence.player][3]+1, 0xFF)
      elseif characters[player_data.character] == "chunli" then
      elseif characters[player_data.character] == "q" then
        memory.writebyte(charge_gauges[pending_input_sequence.player][1], 0xFF)
        memory.writebyte(charge_gauges[pending_input_sequence.player][1]+1, 0xFF)
        memory.writebyte(charge_gauges[pending_input_sequence.player][2], 0xFF)
        memory.writebyte(charge_gauges[pending_input_sequence.player][2]+1, 0xFF)
      elseif characters[player_data.character] == "remy" then
        memory.writebyte(charge_gauges[pending_input_sequence.player][2], 0xFF)
        memory.writebyte(charge_gauges[pending_input_sequence.player][2]+1, 0xFF)
        memory.writebyte(charge_gauges[pending_input_sequence.player][3], 0xFF)
        memory.writebyte(charge_gauges[pending_input_sequence.player][3]+1, 0xFF)
      elseif characters[player_data.character] == "alex" then
        memory.writebyte(charge_gauges[pending_input_sequence.player][5], 0xFF)
        memory.writebyte(charge_gauges[pending_input_sequence.player][5]+1, 0xFF)
      end
    elseif current_frame_input[i] == "v_charge" then
      if characters[player_data.character] == "urien" then
        memory.writebyte(charge_gauges[pending_input_sequence.player][2], 0xFF)
        memory.writebyte(charge_gauges[pending_input_sequence.player][2]+1, 0xFF)
        memory.writebyte(charge_gauges[pending_input_sequence.player][4], 0xFF)
        memory.writebyte(charge_gauges[pending_input_sequence.player][4]+1, 0xFF)
      elseif characters[player_data.character] == "oro" then
        memory.writebyte(charge_gauges[pending_input_sequence.player][1], 0xFF)
        memory.writebyte(charge_gauges[pending_input_sequence.player][1]+1, 0xFF)
      elseif characters[player_data.character] == "chunli" then
        memory.writebyte(charge_gauges[pending_input_sequence.player][1], 0xFF)
        memory.writebyte(charge_gauges[pending_input_sequence.player][1]+1, 0xFF)
      elseif characters[player_data.character] == "q" then
      elseif characters[player_data.character] == "remy" then
        memory.writebyte(charge_gauges[pending_input_sequence.player][1], 0xFF)
        memory.writebyte(charge_gauges[pending_input_sequence.player][1]+1, 0xFF)
      elseif characters[player_data.character] == "alex" then
        memory.writebyte(charge_gauges[pending_input_sequence.player][4], 0xFF)
        memory.writebyte(charge_gauges[pending_input_sequence.player][4]+1, 0xFF)
      end
    end
    input[input_name] = true
    s = s..input_name
  end
  joypad.set(input)

  --print(s)

  pending_input_sequence.current_frame = pending_input_sequence.current_frame + 1
  if pending_input_sequence.current_frame > #pending_input_sequence.sequence then
    pending_input_sequence = nil
  end
end

function clear_input_sequence()
  pending_input_sequence = nil
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
  "360",
  "DQCF",
  "720",
  "back dash",
  "forward dash",
  "Shun Goku Ratsu", -- Gouki hidden SA1
  "Kongou Kokuretsu Zan", -- Gouki hidden SA2
}

button_gesture =
{
  "none",
  "LP",
  "MP",
  "HP",
  "EXP",
  "LK",
  "MK",
  "HK",
  "EXK",
  "LP+LK",
  "MP+MK",
  "HP+HK",
}

function make_input_sequence(_stick, _button)
  local sequence = {}
  if      _stick == "none"    then sequence = { { } }
  elseif  _stick == "forward" then sequence = { { "forward" } }
  elseif  _stick == "back"    then sequence = { { "back" } }
  elseif  _stick == "down"    then sequence = { { "down" } }
  elseif  _stick == "up"      then sequence = { { "up" } }
  elseif  _stick == "QCF"     then sequence = { { "down" }, {"down", "forward"}, {"forward"} }
  elseif  _stick == "QCB"     then sequence = { { "down" }, {"down", "back"}, {"back"} }
  elseif  _stick == "HCF"     then sequence = { { "back" }, {"down", "back"}, {"down"}, {"down", "forward"}, {"forward"} }
  elseif  _stick == "HCB"     then sequence = { { "forward" }, {"down", "forward"}, {"down"}, {"down", "back"}, {"back"} }
  elseif  _stick == "DPF"     then sequence = { { "forward" }, {"down"}, {"down", "forward"} }
  elseif  _stick == "DPB"     then sequence = { { "back" }, {"down"}, {"down", "back"} }
  elseif  _stick == "HCharge" then sequence = { { "back", "h_charge" }, {"forward"} }
  elseif  _stick == "VCharge" then sequence = { { "down", "v_charge" }, {"up"} }
  elseif  _stick == "360"     then sequence = { { "forward" }, { "forward", "down" }, {"down"}, { "back", "down" }, { "back" }, { "up" } }
  elseif  _stick == "DQCF"    then sequence = { { "down" }, {"down", "forward"}, {"forward"}, { "down" }, {"down", "forward"}, {"forward"} }
  elseif  _stick == "720"     then sequence = { { "forward" }, { "forward", "down" }, {"down"}, { "back", "down" }, { "back" }, { "up" }, { "forward" }, { "forward", "down" }, {"down"}, { "back", "down" }, { "back" } }
  -- full moves special cases
  elseif  _stick == "back dash" then sequence = { { "back" }, {}, { "back" } }
    return sequence
  elseif  _stick == "forward dash" then sequence = { { "forward" }, {}, { "forward" } }
    return sequence
  elseif  _stick == "Shun Goku Ratsu" then sequence = { { "LP" }, {}, {}, { "LP" }, { "forward" }, {"LK"}, {}, { "HP" } }
    return sequence
  elseif  _stick == "Kongou Kokuretsu Zan" then sequence = { { "down" }, {}, { "down" }, {}, { "down", "LP", "MP", "HP" } }
    return sequence
  end

  if     _button == "none" then
  elseif _button == "EXP"  then
    table.insert(sequence[#sequence], "MP")
    table.insert(sequence[#sequence], "HP")
  elseif _button == "EXK"  then
    table.insert(sequence[#sequence], "MK")
    table.insert(sequence[#sequence], "HK")
  elseif _button == "LP+LK" then
    table.insert(sequence[#sequence], "LP")
    table.insert(sequence[#sequence], "LK")
  elseif _button == "MP+MK" then
    table.insert(sequence[#sequence], "MP")
    table.insert(sequence[#sequence], "MK")
  elseif _button == "HP+HK" then
    table.insert(sequence[#sequence], "HP")
    table.insert(sequence[#sequence], "HK")
  else
    table.insert(sequence[#sequence], _button)
  end

  return sequence
end

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
  "gill",
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

blocking_style =
{
  "block",
  "parry",
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

standing_state =
{
  "knockeddown",
  "standing",
  "crouched",
  "airborne",
}

-- character specific stuff
function make_character_specific()
  return {
    half_width = 40,
    height = 40,
    moves = {},
  }
end

character_specific = {}
for i = 1, #characters do
  character_specific[characters[i]] = make_character_specific()
end

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


debug_framedata = true

-- IBUKI
character_specific.ibuki.moves["f5b0"] = { startup = 2, active = 2, range = 84, type = 1 } -- LP
character_specific.ibuki.moves["f690"] = { startup = 6, active = 2, range = 84, type = 1 } -- MP
character_specific.ibuki.moves["f838"] = { -- back MP
  { startup = 6, active = 1, range = 64, type = 1 },
  { startup = 8, active = 5, range = 64, type = 1 },
}
character_specific.ibuki.moves["3a48"] = { -- target MP
  { startup = 6, active = 1, range = 64, type = 1 },
  { startup = 8, active = 7, range = 64, type = 1 },
}
character_specific.ibuki.moves["fc48"] = { -- HP
  { startup = 13, active = 8, range = 64, type = 1 },
  { startup = 18, active = 3, range = 84, type = 1 },
}
character_specific.ibuki.moves["fa10"] = { -- close HP
  { startup = 9, active = 1, range = 34, type = 1 },
  { startup = 12, active = 6, range = 34, type = 1 },
}
character_specific.ibuki.moves["0018"] = { startup = 4, active = 4, range = 74, type = 1 } -- LK
character_specific.ibuki.moves["01a8"] = { -- forward LK (not actual multihit, but self cancellable moves are hard to detect and considering them as multihit does the trick)
  { startup = 5, active = 4, range = 74, type = 1 },
  { startup = 14, active = 4, range = 74, type = 1 },
  { startup = 23, active = 4, range = 74, type = 1 },
  { startup = 34, active = 4, range = 74, type = 1 },
  { startup = 43, active = 4, range = 74, type = 1 },
  { startup = 52, active = 4, range = 74, type = 1 },
  { startup = 61, active = 4, range = 74, type = 1 },
  { startup = 70, active = 4, range = 74, type = 1 }, -- will hit after that if you continue spamming the move, but it's good enough right now
}
character_specific.ibuki.moves["05d0"] = { startup = 5, active = 4, range = 49, type = 1 } -- MK
character_specific.ibuki.moves["36c8"] = { startup = 3, active = 4, range = 49, type = 1 } -- Target MK
character_specific.ibuki.moves["0398"] = { startup = 13, active = 2, range = 105, type = 1 } -- Back MK
character_specific.ibuki.moves["0748"] = { startup = 3, active = 3, range = 74, type = 3 } -- Forward MK
character_specific.ibuki.moves["30a0"] = { startup = 27, active = 3, range = 74, type = 3 } -- Target Forward MK
character_specific.ibuki.moves["0b10"] = { startup = 9, active = 3, range = 99, type = 1 } -- HK
character_specific.ibuki.moves["3828"] = { startup = 6, active = 3, range = 99, type = 1 } -- Taret HK
character_specific.ibuki.moves["0d90"] = { startup = 12, active = 1, range = 104, type = 1 } -- Forward HK
character_specific.ibuki.moves["0920"] = { -- Close HK
  { startup = 5, active = 1, range = 34, type = 1 },
  { startup = 7, active = 6, range = 34, type = 1 },
}
character_specific.ibuki.moves["1058"] = { startup = 3, active = 3, range = 67, type = 1 } -- Cr LP
character_specific.ibuki.moves["1118"] = { startup = 9, active = 7, range = 104, type = 1 } -- Cr MP
character_specific.ibuki.moves["12a8"] = { startup = 8, active = 3, range = 59, type = 1 } -- Cr HP
character_specific.ibuki.moves["14e0"] = { startup = 5, active = 3, range = 75, type = 2 } -- Cr LK
character_specific.ibuki.moves["15f0"] = { startup = 6, active = 5, range = 105, type = 2 } -- Cr MK
character_specific.ibuki.moves["19c0"] = { startup = 10, active = 2, range = 94, type = 2 } -- Cr HK
character_specific.ibuki.moves["1c10"] = { startup = 3, active = 100, range = 79, vertical_range = -66, type = 3 } -- Neutral Air LP
character_specific.ibuki.moves["1d10"] = { startup = 5, active = 7, range = 79, vertical_range = -56, type = 3 } -- Neutral Air MP
character_specific.ibuki.moves["1ee8"] = { startup = 11, active = 5, range = 79, vertical_range = -46, type = 3 } -- Neutral Air HP
character_specific.ibuki.moves["20f0"] = { startup = 4, active = 100, range = 86, vertical_range = -41, type = 3 } -- Neutral Air LK
character_specific.ibuki.moves["2210"] = { startup = 5, active = 7, range = 86, vertical_range = -41, type = 3 } -- Neutral Air MK
character_specific.ibuki.moves["2330"] = { startup = 10, active = 3, range = 89, vertical_range = -46, type = 3 } -- Neutral Air HK

character_specific.ibuki.moves["2450"] = { startup = 3, active = 19, range = 84, vertical_range = -38, type = 3 } -- Air LP
character_specific.ibuki.moves["25b0"] = { startup = 6, active = 13, range = 84, vertical_range = -38, type = 3 } -- Air MP
character_specific.ibuki.moves["1ee8"] = { startup = 11, active = 5, range = 94, type = 3 } -- Air HP
character_specific.ibuki.moves["2748"] = { startup = 3, active = 100, range = 54, type = 3 } -- Air LK
character_specific.ibuki.moves["2878"] = { startup = 7, active = 13, range = 94, type = 3 } -- Air MK
character_specific.ibuki.moves["29a8"] = character_specific.ibuki.moves["2330"] -- Air HK

character_specific.ibuki.moves["7ca0"] = { -- L Hien
  { startup = 22, active = 3, range = 50, type = 3 },
  { startup = 25, active = 8, range = 50, type = 3 },
}
character_specific.ibuki.moves["8100"] = { -- M Hien
  { startup = 25, active = 3, range = 50, type = 3 },
  { startup = 28, active = 8, range = 50, type = 3 },
}
character_specific.ibuki.moves["8560"] = { -- H Hien
  { startup = 28, active = 4, range = 50, type = 3 },
  { startup = 32, active = 8, range = 50, type = 3 },
}
character_specific.ibuki.moves["89c0"] = { -- EX Hien
  { startup = 26, active = 4, range = 50, type = 3 },
  { startup = 30, active = 8, range = 50, type = 3 },
}

character_specific.ibuki.moves["9910"] = { -- L Tsumuji
  { startup = 11, active = 1, range = 105, type = 1 },
  { startup = 26, active = 1, range = 105, type = 1 },
}
character_specific.ibuki.moves["a768"] = { startup = 10, active = 2, range = 105, type = 2 } -- L Tsumuji Kara
character_specific.ibuki.moves["9de8"] = { -- M Tsumuji
  { startup = 13, active = 1, range = 105, type = 1 },
  { startup = 29, active = 2, range = 105, type = 1 },
}
character_specific.ibuki.moves["a428"] = { -- H Tsumuji
  { startup = 14, active = 1, range = 105, type = 1 },
  { startup = 28, active = 2, range = 105, type = 1 },
}
character_specific.ibuki.moves["f980"] = { startup = 6, active = 1, range = 105, type = 1 } -- H Tsumuji Kara
character_specific.ibuki.moves["fc60"] = { startup = 9, active = 2, range = 110, type = 2 } -- H Tsumuji Kara

character_specific.ibuki.moves["e490"] = { startup = 7, active = 1, range = 105, type = 1 } -- Ex Tsumuji (1)
character_specific.ibuki.moves["e6f8"] = { -- Ex Tsumuji Kara (2-3 up)
  { startup = 4, active = 1, range = 90, type = 1 },
  { startup = 14, active = 2, range = 90, type = 1 },
}
character_specific.ibuki.moves["e988"] = { startup = 5, active = 1, range = 110, type = 1 } -- Ex Tsumuji Kara (4 up)
character_specific.ibuki.moves["e810"] = { -- Ex Tsumuji Kara (2-3 down)
  { startup = 9, active = 2, range = 110, type = 2 },
  { startup = 26, active = 2, range = 110, type = 2 },
}
character_specific.ibuki.moves["eb60"] = { startup = 9, active = 2, range = 110, type = 2 } -- Ex Tsumuji Kara (4 down)

character_specific.ibuki.moves["f320"] = { no_hit = true } -- L Kasumi Gake
character_specific.ibuki.moves["f540"] = { no_hit = true } -- L Kasumi Gake
character_specific.ibuki.moves["f760"] = { no_hit = true } -- L Kasumi Gake

-- ALEX
character_specific.alex.moves["a444"] = { startup = 4, active = 3, range = 69, type = 1 } -- LP
character_specific.alex.moves["b224"] = { startup = 16, active = 5, range = 94, type = 1 } -- HK
character_specific.alex.moves["b714"] = { startup = 13, active = 5, range = 94, type = 1 } -- Cr HP
character_specific.alex.moves["5e54"] = { -- Flash Chop (Ex) (does not correspond to the frame data. I don't know why, maybe it's split in several animations)
  { startup = 4, active = 2, range = 94, type = 1 },
  { startup = 8, active = 2, range = 94, type = 1 },
}


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

training_settings = {
  swap_characters = false,
  pose = 1,
  blocking_style = 1,
  blocking_mode = 1,
  counter_attack_stick = 1,
  counter_attack_button = 1,
  fast_recovery_mode = 1,
  infinite_time = true,
  infinite_life = true,
  infinite_meter = true,
  no_stun = true,
  display_input = true,
}

menu = {
  checkbox_menu_item("Swap Characters", "swap_characters"),
  list_menu_item("Pose", "pose", pose),
  list_menu_item("Blocking Style", "blocking_style", blocking_style),
  list_menu_item("Blocking", "blocking_mode", blocking_mode),
  list_menu_item("Counter-Attack Move", "counter_attack_stick", stick_gesture),
  list_menu_item("Counter-Attack Button", "counter_attack_button", button_gesture),
  list_menu_item("Fast Recovery", "fast_recovery_mode", fast_recovery_mode),
  checkbox_menu_item("Infinite Time", "infinite_time"),
  checkbox_menu_item("Infinite Life", "infinite_life"),
  checkbox_menu_item("Infinite Meter", "infinite_meter"),
  checkbox_menu_item("No Stun", "no_stun"),
  checkbox_menu_item("Display Input", "display_input"),
}

-- save/load
training_data_file = "3rd_training_data.txt"
function save_training_data()
  f = io.open(training_data_file, "w")
  for key, value in pairs(training_settings) do
    f:write(key.."="..tostring(value).."\n")
  end
  f:close()
end

function load_training_data()
  f = io.open(training_data_file, "r")
  for line in f:lines() do
    local a1 = line:split("=")
    local key = nil
    local value = nil
    if #a1 > 0 then
      key = a1[1]
      value = a1[2]
    end

    if key ~= nil and value ~= nil then
      local type = type(training_settings[key])
      local v = nil
      if type == "boolean" then
        if value == "true" then v = true else v = false end
      elseif type == "number" then
        v = tonumber(value)
      end

      if v ~= nil then
        training_settings[key] = v
      end
    end
  end
  f:close()
end

-- swap inputs
function swap_inputs(_in_input_table, _out_input_table)
  function swap(_input)
    local carry = _in_input_table["P1 ".._input]
    _out_input_table["P1 ".._input] = nil

    --_out_input_table["P1 ".._input] = _in_input_table["P2 ".._input]
    _out_input_table["P2 ".._input] = carry
  end

  swap("Up")
  swap("Down")
  swap("Left")
  swap("Right")
  swap("Weak Punch")
  swap("Medium Punch")
  swap("Strong Punch")
  swap("Weak Kick")
  swap("Medium Kick")
  swap("Strong Kick")
end

-- app data
is_menu_open = false
menu_selected_index = 1
pending_input_sequence = nil

-- game data
frame_number = 0
counterattack_sequence = nil
recovery_time = 0
is_in_match = false
knockeddown = false
flying_after_knockdown = false
onground_after_knockdown = false
fastrecovery_countdown = -1

P1_previous_is_attacking = false
P1_previous_is_attacking_ext = false
P1_previous_action_ext = nil
P1_previous_action_count = 0
P1_previous_standing_state = 1
P1_current_animation = 0
P1_current_animation_startframe = 0
P1_current_animation_activeframe = 0
P1_current_animation_recoverframe = 0
P1_current_animation_freezeframes = 0

function make_player()
  return {
    character = -1,
    facing_right = false,
    is_attacking = false,
    is_attacking_ext = false, -- for target combos
    input_capacity = 0,
    standing_state = 1,
    pos_x = 0,
    pos_y = 0,
    action = 0,
    action_ext = 0,
    action_count = 0,
    animation = 0,
    is_blocking = false,
  }
end
P1 = make_player()
P2 = make_player()

-- program

function on_start()
  load_training_data()
end

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

  -- character swap
  if is_in_match then
    local P1_disable_input_address = 0x02068C74
    if training_settings.swap_characters then
      swap_inputs(joypad.get(), input)
      memory.writebyte(P1_disable_input_address, 0x01)
    else
      memory.writebyte(P1_disable_input_address, 0x00)
    end
  end

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
  P1.is_attacking = memory.readbyte(0x02069094) > 0
  P1.is_attacking_ext = memory.readbyte(0x02069095) > 0
  P1.input_capacity = memory_read(0x020690D8, 2)
  P1.standing_state = memory.readbyte(0x02068F03)
  P1.pos_x = memory_read(0x02068CD0, 2)
  P1.pos_y = memory_read(0x02068CD4, 2)
  P1.action = memory_read(0x02068D19, 3)
  P1.action_ext = memory_read(0x02068D99, 3)
  P1.action_count = memory.readbyte(0x020690C5)
  P1.animation = bit.tohex(memory_read(0x02068E6E, 2),4)


  P2.character = memory.readbyte(0x02011388)
  P2.facing_right = memory.readbyte(0x0206910F) > 0
  P2.pos_x = memory_read(0x02069168, 2)
  P2.pos_y = memory_read(0x0206916C, 2)
  P2.is_blocking = memory.readbyte(0x020694D7) > 0
  P2.action = memory_read(0x020691B1, 3)

  -- life bars
  if training_settings.infinite_life then
    memory.writebyte(0x02068d0b, 160) -- p1
    memory.writebyte(0x020691a3, 160) -- p2
  end

  -- meter
  if training_settings.infinite_meter then
    -- 0x020695BF P1 meter count
    -- 0x020695BD P1 max meter count
    memory.writebyte(0x020695BF, memory.readbyte(0x020695BD))
    -- 0x020695EB P2 meter count
    -- 0x020695E9 P2 max meter count
    memory.writebyte(0x020695EB, memory.readbyte(0x020695E9))
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

  -- pose
  if is_in_match and not training_settings.swap_characters and not knockeddown and pending_input_sequence == nil then
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
  if is_in_match and not training_settings.swap_characters and training_settings.blocking_mode == 2 and pending_input_sequence == nil then
    if waiting_for_block
    and (frame_number - P1_current_animation_startframe) >= 2
    and (
      (bit.band(P1.input_capacity, 0x0087) == 0x0087 or bit.band(P1.input_capacity, 0x0086) == 0x0086)
      or (P1_previous_standing_state >= 3 and P1.standing_state < 3) -- landing
    )
    then
      waiting_for_block = false
      --print(bit.tohex(P1_current_animation)..": "..(P1_current_animation_activeframe - P1_current_animation_startframe).."/"..(frame_number - P1_current_animation_activeframe))
      if debug_framedata then
        print(P1_current_animation.." : "..(P1_current_animation_activeframe - P1_current_animation_startframe).."/"..(P1_current_animation_recoverframe - P1_current_animation_activeframe).."/"..(frame_number - P1_current_animation_recoverframe))
      end
      --print("end")
    end

    if not waiting_for_block and P1.is_attacking and not P1_previous_is_attacking then
      waiting_for_block = true
      --print("begin")
      P1_current_animation = P1.animation
      P1_current_animation_startframe = frame_number
      P1_current_animation_activeframe = frame_number
      P1_current_animation_recoverframe = frame_number
      P1_current_animation_freezeframes = memory.readbyte(0x02068CB1)
      --print(P1_current_animation_freezeframes)
      P1_has_parried = {}
      --print("1 "..bit.tohex(P1_current_animation))
    end
    --print(bit.tohex(P1.input_capacity))


    if waiting_for_block then
      --print(bit.tohex(P1.input_capacity))

      if P1_current_animation ~= P1.animation then
        if debug_framedata then
          print(P1_current_animation.." : "..(P1_current_animation_activeframe - P1_current_animation_startframe).."/"..(P1_current_animation_recoverframe - P1_current_animation_activeframe).."/"..(frame_number - P1_current_animation_recoverframe))
        end

        --print("begin")
        P1_current_animation = P1.animation
        P1_current_animation_startframe = frame_number
        P1_current_animation_activeframe = frame_number
        P1_current_animation_recoverframe = frame_number
        P1_current_animation_freezeframes = memory.readbyte(0x02068CB1)
        --print(P1_current_animation_freezeframes)
        P1_has_parried = {}
        --sprint("2 "..bit.tohex(P1_current_animation))
      end

      --if (memory.readbyte(0x02068CB1) > 0 or memory.readbyte(0x0206914B) > 0) then
      --  print(memory.readbyte(0x02068CB1).." "..memory.readbyte(0x0206914B).." "..(0xFFFF - memory_read(0x02069148, 2)))
      --end

      if P1.action_count ~= P1_previous_action_count and P1.action_count > P1_previous_action_count then
        P1_current_animation_activeframe = frame_number
        --P1_current_animation_freezeframes = memory.readbyte(0x02068CB1)
        if (debug_framedata) then
          print("[hit] frame: "..(P1_current_animation_activeframe - P1_current_animation_startframe)..", dist: "..(math.abs(P1.pos_x - P2.pos_x) - character_specific[characters[P1.character]].half_width)..","..((P1.pos_y - P2.pos_y) - character_specific[characters[P1.character]].height))
        end
        --print("active")
        --print(P1_current_animation_freezeframes)
      end

      if not P1.is_attacking and P1_previous_is_attacking then
        --print("recover")
        P1_current_animation_recoverframe = frame_number
      end

      function handle_move(_move, _move_index)
        if _move_index == nil then _move_index = 1 end

        if (character_specific[characters[P1.character]].moves[P1_current_animation]) then
          if character_specific[characters[P1.character]].moves[P1_current_animation].no_hit then
            --return
          end
        end

        local distance_from_enemy = math.abs(P1.pos_x - P2.pos_x) - character_specific[characters[P1.character]].half_width
        local vertical_distance_from_enemy = (P1.pos_y - P2.pos_y) - character_specific[characters[P1.character]].height

        local block_startframe = P1_current_animation_startframe + P1_current_animation_freezeframes + _move.startup - 1
        local block_stopframe = P1_current_animation_startframe + P1_current_animation_freezeframes + _move.startup + _move.active
        local parry_count = 0
        for i = 1,(_move_index - 1) do
          if P1_has_parried[i] then parry_count = parry_count + 1 end
        end
        local parry_startframe = block_startframe + (parry_count * 16)
        local parry_stopframe = block_stopframe + (parry_count * 16)

        -- completely release crouch when trying to parry
        if training_settings.blocking_style == 2 and distance_from_enemy <= _move.range and vertical_distance_from_enemy <= _move.vertical_range and frame_number >= (parry_startframe - 1) and frame_number < parry_stopframe then
          input['P2 Down'] = false
        end


        if training_settings.blocking_style == 1 and (distance_from_enemy <= _move.range and vertical_distance_from_enemy <= _move.vertical_range and frame_number >= block_startframe and frame_number < block_stopframe) then
          if P2.facing_right then
            input['P2 Left'] = true
          else
            input['P2 Right'] = true
          end

          if _move.type == 2 then
            input['P2 Down'] = true
          elseif _move.type == 3 then
            input['P2 Down'] = false
          end
        end

        -- Parry

        --print(distance_from_enemy..","..vertical_distance_from_enemy)
        if  training_settings.blocking_style == 2 and distance_from_enemy <= _move.range and vertical_distance_from_enemy <= _move.vertical_range then
          if frame_number >= parry_startframe and frame_number < parry_stopframe and not P1_has_parried[_move_index] then
            P1_has_parried[_move_index] = true
            --print("hop"..(parry_startframe - P1_current_animation_startframe).." "..(frame_number - P1_current_animation_startframe))
            --print("l"..(P1_current_animation_freezeframes).." "..(_move.startup))

            if _move.type == 2 then
              input['P2 Down'] = true
            else
              if P2.facing_right then
                input['P2 Right'] = true
              else
                input['P2 Left'] = true
              end
            end
          end
        end
      end

      local move = {}
      local default_startup = 2
      local default_active = 10
      local default_range = 114
      local default_vertical_range = 500
      local default_type = 1

      if P1.standing_state == 1 then -- STANDING
        default_type = 1
      elseif P1.standing_state == 2 then --CROUCHED
        default_type = 2
      elseif P1.standing_state >= 3 then --AIRBORNE
        default_type = 3
      end

      if (character_specific[characters[P1.character]].moves[P1_current_animation]) then
        local hit_count = #character_specific[characters[P1.character]].moves[P1_current_animation]
        if hit_count > 0 then
          -- multi hit
          for i = 1, hit_count do
            move.startup = character_specific[characters[P1.character]].moves[P1_current_animation][i].startup
            move.active = character_specific[characters[P1.character]].moves[P1_current_animation][i].active
            move.range = character_specific[characters[P1.character]].moves[P1_current_animation][i].range
            move.vertical_range = character_specific[characters[P1.character]].moves[P1_current_animation][i].vertical_range
            move.type = character_specific[characters[P1.character]].moves[P1_current_animation][i].type

            if move.startup == nil then move.startup = default_startup end
            if move.active == nil then move.active = default_active end
            if move.range == nil then move.range = default_range end
            if move.vertical_range == nil then move.vertical_range = default_vertical_range end
            if move.type == nil then move.type = default_type end

            handle_move(move, i)
          end
        else
          -- single hit
          move.startup = character_specific[characters[P1.character]].moves[P1_current_animation].startup
          move.active = character_specific[characters[P1.character]].moves[P1_current_animation].active
          move.range = character_specific[characters[P1.character]].moves[P1_current_animation].range
          move.vertical_range = character_specific[characters[P1.character]].moves[P1_current_animation].vertical_range
          move.type = character_specific[characters[P1.character]].moves[P1_current_animation].type

          if move.startup == nil then move.startup = default_startup end
          if move.active == nil then move.active = default_active end
          if move.range == nil then move.range = default_range end
          if move.vertical_range == nil then move.vertical_range = default_vertical_range end
          if move.type == nil then move.type = default_type end

          handle_move(move)
        end
      else
        -- generic handling
        move.startup = default_startup
        move.active = default_active
        move.range = default_range
        move.vertical_range = default_vertical_range
        move.type = default_type

        handle_move(move)
      end

      --print(P1.action_count)
    end
  end

  P1_previous_is_attacking = P1.is_attacking
  P1_previous_is_attacking_ext = P1.is_attacking_ext
  P1_previous_action_ext = P1.action_ext
  P1_previous_action_count = P1.action_count
  P1_previous_standing_state = P1.standing_state

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
  if is_in_match and (training_settings.counter_attack_stick ~= 1 or training_settings.counter_attack_button ~= 1) then

    local local_recovery_time = 0
    local freeze_time = 0xff - memory.readbyte(0x02069149)
    if training_settings.blocking_style == 2 and freeze_time < 0x20 then
      local_recovery_time = freeze_time
      --print("fr."..freeze_time)
    else
      local_recovery_time = memory.readbyte(0x0206928B)
    end
    if local_recovery_time ~= 0 and local_recovery_time >= recovery_time then
      clear_input_sequence()
      recovery_time = local_recovery_time + 2
      if stick_gesture[training_settings.counter_attack_stick] == "Shun Goku Ratsu" and training_settings.blocking_style == 2 then
        recovery_time = recovery_time + 2 -- timing of this move seems to be so tight we need to adjust the timing in order to put it out after a parry
      end
      counterattack_sequence = make_input_sequence(stick_gesture[training_settings.counter_attack_stick], button_gesture[training_settings.counter_attack_button])
    end
  end

  if (counterattack_sequence and recovery_time <= (#counterattack_sequence + 1)) then
    queue_input_sequence(2, counterattack_sequence)
    counterattack_sequence = nil
  end

  if recovery_time > 0 then
    recovery_time = recovery_time - 1
  end

  if waiting_for_block then
    --print("U:"..to_bit(input["P2 Up"]).." R:"..to_bit(input["P2 Right"]).." D:"..to_bit(input["P2 Down"]).." L:"..to_bit(input["P2 Left"]))
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
      save_training_data()
    end

    if frame_input.P1.pressed.right then
      menu[menu_selected_index]:right()
      save_training_data()
    end

    gui.box(0,0,383,223, 0x000000AA, 0x000000AA)

    for i = 1, #menu do
      menu[i]:draw(menu_x, menu_y + menu_y_interval * (i - 1), menu_selected_index == i)
    end
  else
    gui.clearuncommitted()
  end

  if is_in_match and training_settings.display_input then
    local i = joypad.get()
    draw_input(45, 190, i, "P1 ")
    draw_input(280, 190, i, "P2 ")
  end
end

-- toolbox
function to_bit(_bool)
  if _bool then
    return 1
  else
    return 0
  end
end

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

function draw_input(_x, _y, _input, _prefix)
  local up = _input[_prefix.."Up"]
  local down = _input[_prefix.."Down"]
  local left = _input[_prefix.."Left"]
  local right = _input[_prefix.."Right"]
  local LP = _input[_prefix.."Weak Punch"]
  local MP = _input[_prefix.."Medium Punch"]
  local HP = _input[_prefix.."Strong Punch"]
  local LK = _input[_prefix.."Weak Kick"]
  local MK = _input[_prefix.."Medium Kick"]
  local HK = _input[_prefix.."Strong Kick"]
  local start = _input[_prefix.."Start"]
  local coin = _input[_prefix.."Coin"]
  function col(_value)
    if _value then return 0xFF0000FF else return 0xFFFFFFFF end
  end

  gui.text(_x + 5 , _y + 0 , "^", col(up))
  gui.text(_x + 5 , _y + 10, "v", col(down))
  gui.text(_x + 0 , _y + 5, "<", col(left))
  gui.text(_x + 10, _y + 5, ">", col(right))

  gui.text(_x + 20, _y + 0, "LP", col(LP))
  gui.text(_x + 30, _y + 0, "MP", col(MP))
  gui.text(_x + 40, _y + 0, "HP", col(HP))
  gui.text(_x + 20, _y + 10, "LK", col(LK))
  gui.text(_x + 30, _y + 10, "MK", col(MK))
  gui.text(_x + 40, _y + 10, "HK", col(HK))

  gui.text(_x + 55, _y + 0, "S", col(start))
  gui.text(_x + 55, _y + 10, "C", col(coin))
end

function string:split(sep)
   local sep, fields = sep or ":", {}
   local pattern = string.format("([^%s]+)", sep)
   self:gsub(pattern, function(c) fields[#fields+1] = c end)
   return fields
end

-- registers
emu.registerstart(on_start)
emu.registerbefore(before_frame)
gui.register(on_gui)
