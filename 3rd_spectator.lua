require("src/startup")

print("-----------------------------")
print("  3rd_spectator.lua - "..script_version.."")
print("  Spectator script for "..game_name.."")
print("  Last tested Fightcade version: "..fc_version.."")
print("  project url: https://github.com/Grouflon/3rd_training_lua")
print("-----------------------------")
print("")
print("Command List:")
print("- Lua Hotkey 1 (alt+1) to toggle controller display")
print("- Lua Hotkey 2 (alt+2) to toggle input history")
print("- Lua Hotkey 3 (alt+3) to toggle hitboxes")
print("- Lua Hotkey 4 (alt+4) to toggle gauges numbers")
print("")
print("* settings are saved between script sessions")
print("")

require("src/tools")
require("src/display")
require("src/framedata")
require("src/gamestate")
require("src/input_history")

developer_mode = false

-- settings
settings_version = 1
spectator_settings_file = "spectator_settings.json"
spectator_settings =
{
  version = settings_version,

  -- 0 is nothing, 1 is both players, 2 is P1 only, 3 is P2 only
  display_controllers = 0,
  display_input_history = 0,
  display_hitboxes = 0,
  display_gauges = 0,
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

  if _spectator_settings.version == spectator_settings.version then
    for _key, _value in pairs(_spectator_settings) do
      if type(_value) == "number" then
        spectator_settings[_key] = _value
      end
    end
  end
end
-- !settings

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

  if is_in_match then
    input_history_update(input_history[1], "P1", _input)
    input_history_update(input_history[2], "P2", _input)
  else
    clear_input_history()
  end

end

function on_gui()

  if is_in_match then

    -- input history
    if spectator_settings.display_input_history == 1 or spectator_settings.display_input_history == 2 then
      input_history_draw(input_history[1], 4, 49, false)
    end

    if spectator_settings.display_input_history == 1 or spectator_settings.display_input_history == 3 then
      input_history_draw(input_history[2], screen_width - 4, 49, true)
    end

    -- controllers
    local _i = joypad.get()
    if spectator_settings.display_controllers == 1 or spectator_settings.display_controllers == 2 then
      local _p1 = make_input_history_entry("P1", _i)
      draw_controller_big(_p1, 44, 34)
    end

    if spectator_settings.display_controllers == 1 or spectator_settings.display_controllers == 3 then
      local _p2 = make_input_history_entry("P2", _i)
      draw_controller_big(_p2, 310, 34)
    end

    -- hitboxes
    if spectator_settings.display_hitboxes == 1 or spectator_settings.display_hitboxes == 2 then
      draw_hitboxes(player_objects[1].pos_x, player_objects[1].pos_y, player_objects[1].flip_x, player_objects[1].boxes)

      -- projectiles
      for _id, _obj in pairs(projectiles) do
        if _obj.emitter_id == 1 then
          draw_hitboxes(_obj.pos_x, _obj.pos_y, _obj.flip_x, _obj.boxes)
        end
      end
    end

    if spectator_settings.display_hitboxes == 1 or spectator_settings.display_hitboxes == 3 then
      draw_hitboxes(player_objects[2].pos_x, player_objects[2].pos_y, player_objects[2].flip_x, player_objects[2].boxes)

      -- projectiles
      for _id, _obj in pairs(projectiles) do
        if _obj.emitter_id == 2 then
          draw_hitboxes(_obj.pos_x, _obj.pos_y, _obj.flip_x, _obj.boxes)
        end
      end
    end

    -- gauges
    if spectator_settings.display_gauges == 1 or spectator_settings.display_gauges == 2 then
      display_draw_life(player_objects[1])
      display_draw_meter(player_objects[1])
      display_draw_stun_gauge(player_objects[1])
      display_draw_bonuses(player_objects[1])
    end

    if spectator_settings.display_gauges == 1 or spectator_settings.display_gauges == 3 then
      display_draw_life(player_objects[2])
      display_draw_meter(player_objects[2])
      display_draw_stun_gauge(player_objects[2])
      display_draw_bonuses(player_objects[2])
    end

  end

  gui.box(0,0,0,0,0,0) -- if we don't draw something, what we drawed from last frame won't be cleared
end

emu.registerstart(on_start)
emu.registerbefore(before_frame)
gui.register(on_gui)
savestate.registerload(on_load_state)


function hotkey1()
  spectator_settings.display_controllers = (spectator_settings.display_controllers + 1) % 4
  save_spectator_settings()
end
function hotkey2()
  spectator_settings.display_input_history = (spectator_settings.display_input_history + 1) % 4
  save_spectator_settings()
end
function hotkey3()
  spectator_settings.display_hitboxes = (spectator_settings.display_hitboxes + 1) % 4
  save_spectator_settings()
end
function hotkey4()
  spectator_settings.display_gauges = (spectator_settings.display_gauges + 1) % 4
  save_spectator_settings()
end


input.registerhotkey(1, hotkey1) 
input.registerhotkey(2, hotkey2) 
input.registerhotkey(3, hotkey3) 
input.registerhotkey(4, hotkey4) 
