require("src/startup")

print("-----------------------------")
print("  3rd_spectator.lua - "..script_version.."")
print("  Spectator script for "..game_name.."")
print("  Last tested Fightcade version: "..fc_version.."")
print("  project url: https://github.com/Grouflon/3rd_training_lua")
print("-----------------------------")
print("")
print("Command List:")
print("- Lua Hotkey 1 (alt+1) to toggle the menu")
print("- Lua Hotkey 2 (alt+2) to navigate up")
print("- Lua Hotkey 3 (alt+3) to navigate down")
print("- Lua Hotkey 4 (alt+4) to switch option")
print("")

require("src/tools")
require("src/display")
require("src/menu_widgets")
require("src/framedata")
require("src/gamestate")
require("src/input_history")

developer_mode = false

-- settings
spectator_settings_file = "spectator_settings.json"
spectator_settings =
{
  display_input_history = false,
  display_controllers = false,
  display_hitboxes = false,
}

function save_spectator_settings()
  if not write_object_to_json_file(spectator_settings, saved_path..spectator_settings_file) then
    print(string.format("Error: Failed to save spectator settings to \"%s\"", spectator_settings_file))
  end
end


function load_spectator_settings()
  local _spectator_settings = read_object_from_json_file(saved_path..spectator_settings_file)
  if _spectator_settings == nil then
    _spectator_settings = {}
  end

  for _key, _value in pairs(_spectator_settings) do
    spectator_settings[_key] = _value
  end
end
-- !settings

-- menu
is_menu_open = false

menu = make_menu(
  71, 61, 312, 105, -- screen size 383,223
  {
    checkbox_menu_item("Display Input History", spectator_settings, "display_input_history"),
    checkbox_menu_item("Display Controllers", spectator_settings, "display_controllers"),
    checkbox_menu_item("Display Hitboxes", spectator_settings, "display_hitboxes"),
  },
  function()
    save_spectator_settings()
  end,
  false -- no legend
)
-- !menu


function reset_user_input()
  user_input = 
  {
    start = false,
    up = false,
    down = false,
    A = false
  }
end
reset_user_input()

function on_start()
  load_spectator_settings()
end

function on_load_state()
end

function before_frame()

  display_update()
  gamestate_read()

  if developer_mode then
    local _write_game_vars_settings = 
    {
      infinite_time = true,
    }
    write_game_vars(_write_game_vars_settings)
  end

  local _input = joypad.get()

  if is_in_match then
    input_history_update(input_history[1], "P1", _input)
    input_history_update(input_history[2], "P2", _input)
  else
    clear_input_history()
  end

end

function on_gui()

  if user_input.start then
    is_menu_open = not is_menu_open
    if is_menu_open then
      menu_stack_push(menu)
    else
      menu_stack_pop(menu)
    end
  end

  local _input =
  {
    up = user_input.up,
    down = user_input.down,
    left = false,
    right = user_input.A,
    validate = false,
    reset = false
  }
  menu_stack_update(_input)

  if is_in_match then

    if spectator_settings.display_input_history then
      input_history_draw(input_history[1], 4, 50, true)
      input_history_draw(input_history[2], 335, 50, false)
    end

    if spectator_settings.display_hitboxes then
      display_draw_hitboxes()
    end

    if spectator_settings.display_controllers then
      local _i = joypad.get()
      local _p1 = make_input_history_entry("P1", _i)
      local _p2 = make_input_history_entry("P2", _i)
      draw_controller(_p1, 44, 34)
      draw_controller(_p2, 310, 34)
    end
  end

  menu_stack_draw()

  gui.box(0,0,0,0,0,0) -- if we don't draw something, what we drawed from last frame won't be cleared

  reset_user_input()
end

emu.registerstart(on_start)
emu.registerbefore(before_frame)
gui.register(on_gui)
savestate.registerload(on_load_state)


function hotkey1()
  user_input.start = true
end
function hotkey2()
  user_input.up = true
end
function hotkey3()
  user_input.down = true
end
function hotkey4()
  user_input.A = true
end

input.registerhotkey(1, hotkey1) 
input.registerhotkey(2, hotkey2) 
input.registerhotkey(3, hotkey3) 
input.registerhotkey(4, hotkey4) 