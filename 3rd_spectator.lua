require("src/startup")

print("-----------------------------")
print("  3rd_spectator.lua - "..script_version.."")
print("  Spectator script for "..game_name.."")
print("  Last tested Fightcade version: "..fc_version.."")
print("  project url: https://github.com/Grouflon/3rd_training_lua")
print("-----------------------------")
print("")
print("Command List:")
print("- Lua Hotkey 1 (alt+1) to open the settings menu")
print("- Lua Hotkey 2 (alt+2) to go up the settings list")
print("- Lua Hotkey 3 (alt+3) to go down the settings list")
print("- Lua Hotkey 4 (alt+4) to toggle the selected setting")
print("")
print("* settings are saved and kept between sessions")
print("")

require("src/tools")
require("src/draw")
require("src/display")
require("src/framedata")
require("src/gamestate")
require("src/input_history")
require("src/menu_widgets")

developer_mode = false

-- settings
settings_version = 2
spectator_settings_file = "spectator_settings.json"
spectator_settings =
{
  version = settings_version,

  -- 0 is nothing, 1 is both players, 2 is P1 only, 3 is P2 only
  display_controllers = 1,
  display_input_history = 1,
  display_hitboxes = 1,
  display_gauges = 1,
  display_distances = false,
}

hotkey1_pressed = false
hotkey2_pressed = false
hotkey3_pressed = false
hotkey4_pressed = false

is_menu_open = false

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

  if _spectator_settings.version == spectator_settings.version then
    for _key, _value in pairs(_spectator_settings) do
      if type(_value) == "number" then
        spectator_settings[_key] = _value
      end
    end
  end
end
-- !settings

display_mode = {
  "none",
  "P1+P2",
  "P1",
  "P2",
}

-- menu
settings_menu = make_menu(71, 40, 312, 105, -- screen size 383,223
{
  list_menu_item("Display Controllers", spectator_settings, "display_controllers", display_mode),
  list_menu_item("Display Input History", spectator_settings, "display_input_history", display_mode),
  list_menu_item("Display Hitboxes", spectator_settings, "display_hitboxes", display_mode),
  list_menu_item("Display Gauges", spectator_settings, "display_gauges", display_mode),
  checkbox_menu_item("Display Distances", spectator_settings, "display_distances")
},
save_spectator_settings,
false)
-- !menu

function on_start()
  load_spectator_settings()
end

function on_load_state()
end

function before_frame()

  draw_read()
  gamestate_read()

  if developer_mode then
    local _write_game_vars_settings =
    {
      infinite_time = true,
    }
    write_game_vars(_write_game_vars_settings)
  end

  local _input = joypad.get()
  input_history_update(input_history[1], "P1", _input)
  input_history_update(input_history[2], "P2", _input)

end

function on_gui()

  if hotkey1_pressed then
    is_menu_open = not is_menu_open

    if is_menu_open then
      menu_stack_push(settings_menu)
    else
      menu_stack_clear()
    end
  end

  local _input =
  {
    down = hotkey3_pressed,
    up = hotkey2_pressed,
    left = false,
    right = hotkey4_pressed,
    validate = false,
    reset = false,
    cancel = false,
  }
  menu_stack_update(_input)
  menu_stack_draw()

  -- input history
  if spectator_settings.display_input_history == 2 or spectator_settings.display_input_history == 3 then
    input_history_draw(input_history[1], 4, 49, false)
  end

  if spectator_settings.display_input_history == 2 or spectator_settings.display_input_history == 4 then
    input_history_draw(input_history[2], screen_width - 4, 49, true)
  end

  -- controllers
  local _i = joypad.get()
  if spectator_settings.display_controllers == 2 or spectator_settings.display_controllers == 3 then
    local _p1 = make_input_history_entry("P1", _i)
    draw_controller_big(_p1, 44, 34)
  end

  if spectator_settings.display_controllers == 2 or spectator_settings.display_controllers == 4 then
    local _p2 = make_input_history_entry("P2", _i)
    draw_controller_big(_p2, 310, 34)
  end

  if is_in_match then

    -- hitboxes
    if spectator_settings.display_hitboxes == 2 or spectator_settings.display_hitboxes == 3 then
      draw_hitboxes(player_objects[1].pos_x, player_objects[1].pos_y, player_objects[1].flip_x, player_objects[1].boxes)

      -- projectiles
      for _id, _obj in pairs(projectiles) do
        if _obj.emitter_id == 1 then
          draw_hitboxes(_obj.pos_x, _obj.pos_y, _obj.flip_x, _obj.boxes)
        end
      end
    end

    if spectator_settings.display_hitboxes == 2 or spectator_settings.display_hitboxes == 4 then
      draw_hitboxes(player_objects[2].pos_x, player_objects[2].pos_y, player_objects[2].flip_x, player_objects[2].boxes)

      -- projectiles
      for _id, _obj in pairs(projectiles) do
        if _obj.emitter_id == 2 then
          draw_hitboxes(_obj.pos_x, _obj.pos_y, _obj.flip_x, _obj.boxes)
        end
      end
    end

    -- gauges
    if spectator_settings.display_gauges == 2 or spectator_settings.display_gauges == 3 then
      display_draw_life(player_objects[1])
      display_draw_meter(player_objects[1])
      display_draw_stun_gauge(player_objects[1])
      display_draw_bonuses(player_objects[1])
    end

    if spectator_settings.display_gauges == 2 or spectator_settings.display_gauges == 4 then
      display_draw_life(player_objects[2])
      display_draw_meter(player_objects[2])
      display_draw_stun_gauge(player_objects[2])
      display_draw_bonuses(player_objects[2])
    end

    if spectator_settings.display_distances then
      display_draw_distances(player_objects[1], player_objects[2])
    end

  end

  gui.box(0,0,0,0,0,0) -- if we don't draw something, what we drawed from last frame won't be cleared

  hotkey1_pressed = false
  hotkey2_pressed = false
  hotkey3_pressed = false
  hotkey4_pressed = false
end

emu.registerstart(on_start)
emu.registerbefore(before_frame)
gui.register(on_gui)
savestate.registerload(on_load_state)


function hotkey1()
  hotkey1_pressed = true
end
function hotkey2()
  hotkey2_pressed = true
end
function hotkey3()
  hotkey3_pressed = true
end
function hotkey4()
  hotkey4_pressed = true
end

input.registerhotkey(1, hotkey1)
input.registerhotkey(2, hotkey2)
input.registerhotkey(3, hotkey3)
input.registerhotkey(4, hotkey4)
