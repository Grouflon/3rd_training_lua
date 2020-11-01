function before_frame()

  -- infinite time
  memory.writebyte(0x02011377, 100)

  local _input = joypad.get()

  local _up = _input["P1 Up"]
  local _down = _input["P1 Down"]
  local _left = _input["P1 Left"]
  local _right = _input["P1 Right"]
  local _LP = _input["P1 Weak Punch"]
  local _MP = _input["P1 Medium Punch"]
  local _HP = _input["P1 Strong Punch"]
  local _LK = _input["P1 Weak Kick"]
  local _MK = _input["P1 Medium Kick"]
  local _HK = _input["P1 Strong Kick"]
  local _start = _input["P1 Start"]
  local _coin = _input["P1 Coin"]

  if true then
    _input["P1 Up"] = _input["P2 Up"]
    _input["P1 Down"] = _input["P2 Down"]
    _input["P1 Left"] = _input["P2 Left"]
    _input["P1 Right"] = _input["P2 Right"]
    _input["P1 Weak Punch"] = _input["P2 Weak Punch"]
    _input["P1 Medium Punch"] = _input["P2 Medium Punch"]
    _input["P1 Strong Punch"] = _input["P2 Strong Punch"]
    _input["P1 Weak Kick"] = _input["P2 Weak Kick"]
    _input["P1 Medium Kick"] = _input["P2 Medium Kick"]
    _input["P1 Strong Kick"] = _input["P2 Strong Kick"]
    _input["P1 Start"] = _input["P2 Start"]
    _input["P1 Coin"] = _input["P2 Coin"]
  end

  if true then
    _input["P2 Up"] = _up
    _input["P2 Down"] = _down
    _input["P2 Left"] = _left
    _input["P2 Right"] = _right
    _input["P2 Weak Punch"] = _LP
    _input["P2 Medium Punch"] = _MP
    _input["P2 Strong Punch"] = _HP
    _input["P2 Weak Kick"] = _LK
    _input["P2 Medium Kick"] = _MK
    _input["P2 Strong Kick"] = _HK
    _input["P2 Start"] = _start
    _input["P2 Coin"] = _coin
  end

  joypad.set(_input)
end

emu.registerbefore(before_frame)
