attack_data = {}

function attack_data_update(_attacker, _defender)
  attack_data.player_id = _attacker.id

  if _attacker.combo == 0 then
    attack_data.defender_health_combo_start = _defender.life
    attack_data.defender_stun_combo_start = _defender.stun_bar
    attack_data.attacker_meter_combo_start = _attacker.meter_gauge
    attack_data.frame = 0
  else
    if attack_data.frame == 1 then
      if _attacker.combo == 1 then
        attack_data.damage = attack_data.defender_health_combo_start - _defender.life
        attack_data.stun = _defender.stun_bar - attack_data.defender_stun_combo_start
        attack_data.meter = _attacker.meter_gauge - attack_data.attacker_meter_combo_start
      else
        attack_data.damage = attack_data.defender_health_combo_start - _defender.life - attack_data.combo_damage
        attack_data.stun = _defender.stun_bar - attack_data.defender_stun_combo_start - attack_data.combo_stun
        attack_data.meter = _attacker.meter_gauge - attack_data.attacker_meter_combo_start - attack_data.combo_meter
      end
      attack_data.combo_damage = attack_data.defender_health_combo_start - _defender.life
      attack_data.combo_stun = _defender.stun_bar - attack_data.defender_stun_combo_start
      attack_data.combo_meter = _attacker.meter_gauge - attack_data.attacker_meter_combo_start
    end

    if (_attacker.combo > attack_data.combo) and (attack_data.frame ~= 0) then
      attack_data.frame = 0
    else
      attack_data.frame = attack_data.frame + 1
    end

    attack_data.combo_display = _attacker.combo
  end

  attack_data.combo = _attacker.combo

  if attack_data.combo > attack_data.max_combo then
    attack_data.max_combo = attack_data.combo
  end
end

function attack_data_display()
  local _text_width1 = get_text_width("damage: ")
  local _text_width2 = get_text_width("stun: ")
  local _text_width3 = get_text_width("meter: ")
  local _text_width4 = get_text_width("combo: ")
  local _text_width5 = get_text_width("combo damage: ")
  local _text_width6 = get_text_width("combo stun: ")
  local _text_width7 = get_text_width("combo meter: ")
  local _text_width8 = get_text_width("max combo: ")

  local _x1 = 0
  local _x2 = 0
  local _x3 = 0
  local _x4 = 0
  local _x5 = 0
  local _x6 = 0
  local _x7 = 0
  local _x8 = 0
  local _y = 49

  if attack_data.player_id == 1 then
    local _base = screen_width - 141
    _x1 = _base - _text_width1
    _x2 = _base - _text_width2
    _x3 = _base - _text_width3
    _x4 = _base - _text_width4
    local _base2 = _base + 80
    _x5 = _base2 - _text_width5
    _x6 = _base2 - _text_width6
    _x7 = _base2 - _text_width7
    _x8 = _base2 - _text_width8
  elseif attack_data.player_id == 2 then
    local _base = 86
    _x1 = _base - _text_width1
    _x2 = _base - _text_width2
    _x3 = _base - _text_width3
    _x4 = _base - _text_width4
    local _base2 = _base + 80
    _x5 = _base2 - _text_width5
    _x6 = _base2 - _text_width6
    _x7 = _base2 - _text_width7
    _x8 = _base2 - _text_width8
  end

  gui.text(_x1, _y, string.format("damage: "))
  gui.text(_x1 + _text_width1, _y, string.format("%d", attack_data.damage))

  gui.text(_x2, _y + 10, string.format("stun: "))
  gui.text(_x2 + _text_width2, _y + 10, string.format("%d", attack_data.stun))

  gui.text(_x3, _y + 20, string.format("meter: "))
  gui.text(_x3 + _text_width3, _y + 20, string.format("%d", attack_data.meter))

  gui.text(_x4, _y + 30, string.format("combo: "))
  gui.text(_x4 + _text_width4, _y + 30, string.format("%d", attack_data.combo_display))

  gui.text(_x5, _y, string.format("combo damage: "))
  gui.text(_x5 + _text_width5, _y, string.format("%d", attack_data.combo_damage))

  gui.text(_x6, _y + 10, string.format("combo stun: "))
  gui.text(_x6 + _text_width6, _y + 10, string.format("%d", attack_data.combo_stun))

  gui.text(_x7, _y + 20, string.format("combo meter: "))
  gui.text(_x7 + _text_width7, _y + 20, string.format("%d", attack_data.combo_meter))

  gui.text(_x8, _y + 30, string.format("max combo: "))
  gui.text(_x8 + _text_width8, _y + 30, string.format("%d", attack_data.max_combo))
end

function attack_data_reset()
  attack_data = {
    player_id = nil,
    combo = 0,
    damage = 0,
    stun = 0,
    meter = 0,
    combo_display = 0,
    combo_damage = 0,
    combo_stun = 0,
    combo_meter = 0,
    max_combo = 0,
    defender_health_combo_start = 0,
    defender_stun_combo_start = 0,
    attacker_meter_combo_start = 0,
    frame = 0,
  }
end
attack_data_reset()