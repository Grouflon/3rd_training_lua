attack_data = {}

function attack_data_update(_attacker, _defender)
  attack_data.player_id = _attacker.id

  if _attacker.combo == nil then
    _attacker.combo = 0
  end

  if _attacker.combo == 0 then
    attack_data.last_hit_combo = 0
  end

  if _attacker.damage_of_next_hit ~= 0 then
    attack_data.damage = _attacker.damage_of_next_hit
    attack_data.stun = _attacker.stun_of_next_hit

    if _attacker.combo > attack_data.last_hit_combo and attack_data.last_hit_combo ~= 0 then
      attack_data.total_damage = attack_data.total_damage + _attacker.damage_of_next_hit
      attack_data.total_stun = attack_data.total_stun + _attacker.stun_of_next_hit
    elseif _attacker.combo == attack_data.last_hit_combo then
      -- Repeated hit, skip
    else
      attack_data.total_damage = _attacker.damage_of_next_hit
      attack_data.total_stun = _attacker.stun_of_next_hit
    end

    attack_data.last_hit_combo = _attacker.combo
  end

  if _attacker.combo ~= 0 then
    attack_data.combo = _attacker.combo
  end
  if _attacker.combo > attack_data.max_combo then
    attack_data.max_combo = _attacker.combo
  end
end

function attack_data_display()
  local _text_width1 = get_text_width("damage: ")
  local _text_width2 = get_text_width("stun: ")
  local _text_width3 = get_text_width("combo: ")
  local _text_width4 = get_text_width("total damage: ")
  local _text_width5 = get_text_width("total stun: ")
  local _text_width6 = get_text_width("max combo: ")

  local _x1 = 0
  local _x2 = 0
  local _x3 = 0
  local _x4 = 0
  local _x5 = 0
  local _x6 = 0
  local _y = 49

  local _x_spacing = 80

  if attack_data.player_id == 1 then
    local _base = screen_width - 138
    _x1 = _base - _text_width1
    _x2 = _base - _text_width2
    _x3 = _base - _text_width3
    local _base2 = _base + _x_spacing
    _x4 = _base2 - _text_width4
    _x5 = _base2 - _text_width5
    _x6 = _base2 - _text_width6
  elseif attack_data.player_id == 2 then
    local _base = 82
    _x1 = _base - _text_width1
    _x2 = _base - _text_width2
    _x3 = _base - _text_width3
    local _base2 = _base + _x_spacing
    _x4 = _base2 - _text_width4
    _x5 = _base2 - _text_width5
    _x6 = _base2 - _text_width6
  end

  gui.text(_x1, _y, string.format("damage: "))
  gui.text(_x1 + _text_width1, _y, string.format("%d", attack_data.damage))

  gui.text(_x2, _y + 10, string.format("stun: "))
  gui.text(_x2 + _text_width2, _y + 10, string.format("%d", attack_data.stun))

  gui.text(_x3, _y + 20, string.format("combo: "))
  gui.text(_x3 + _text_width3, _y + 20, string.format("%d", attack_data.combo))

  gui.text(_x4, _y, string.format("total damage: "))
  gui.text(_x4 + _text_width4, _y, string.format("%d", attack_data.total_damage))

  gui.text(_x5, _y + 10, string.format("total stun: "))
  gui.text(_x5 + _text_width5, _y + 10, string.format("%d", attack_data.total_stun))

  gui.text(_x6, _y + 20, string.format("max combo: "))
  gui.text(_x6 + _text_width6, _y + 20, string.format("%d", attack_data.max_combo))
end

function attack_data_reset()
  attack_data = {
    player_id = nil,
    last_hit_combo = 0,

    damage = 0,
    stun = 0,
    combo = 0,
    total_damage = 0,
    total_stun = 0,
    max_combo = 0,
  }
end
attack_data_reset()