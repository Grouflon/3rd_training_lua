game_name = "Street Fighter III 3rd Strike (Japan 990512)"
script_version = "v0.10 dev"
fc_version = "v2.0.97.44"
saved_path = "saved/"
rom_name = emu.romname()
is_4rd_strike = false

if rom_name == "sfiii3nr1" then
  -- NOP
elseif rom_name == "sfiii4n" then
  game_name = "Street Fighter III 3rd Strike - 4rd Arrange Edition 2013 (990608)"
  is_4rd_strike = true
else
  print("-----------------------------")
  print("WARNING: You are not using a rom supported by this script. Some of the features might not be working correctly.")
  print("-----------------------------")
  rom_name = "sfiii3nr1"
end
