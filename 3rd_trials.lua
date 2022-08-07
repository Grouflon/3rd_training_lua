require("src/startup")

print("-----------------------------")
print("  3rd_trials.lua - "..script_version.."")
print("  Trials script for "..game_name.."")
print("  Last tested Fightcade version: "..fc_version.."")
print("  project url: https://github.com/Grouflon/3rd_training_lua")
print("-----------------------------")
print("WIP")
--print("This is a proof of concept which has only a handful of Hugo trials")
--print("Command List:")
print("- Lua Hotkey 1 (alt+1) Go up the trial list")
print("- Lua Hotkey 2 (alt+2) Go down the trial list")
print("- Lua Hotkey 3 (alt+3) Play the current trial demo")
print("- Lua Hotkey 4 (alt+4) Save the current trial to the saved/trials folder")
print("")
print("You can use the coin button to record your own trials. If you want to add your trial to the base list, you have to save it to the temp folder, and then copy it to data/{rom}/trials/base/{character}")

print("")

assert_enabled = true
developer_mode = false

require("src/tools")
require("src/memory_adresses")
require("src/framedata")
require("src/gamestate")
require("src/moves")
require("src/recording")
require("src/draw")
require("src/display")
require("src/menu_widgets")

-- TRIALS
function load_trials_list()
  local _trials = {}
  local _base_path = "data/sfiii3nr1/trials/base"
  for _i, _char_str in ipairs(characters) do
    local _char_path = string.format("%s/%s", _base_path, _char_str)

    --print (_char_path)
    local _trials_list = list_directory_content(_char_path)
    for __, _path in ipairs(_trials_list) do
      table.insert(_trials, string.format("%s/%s", _char_path, _path))
      if developer_mode then
        print(_path)
      end
    end
  end
  return _trials
end

function load_trial_definition(_path)
  local _savestate_path = string.format("%s/savestate.fs", _path)
  if not do_file_exists(_savestate_path) then
    print(string.format("Can't open trial: missing savestate \"%s\"", _savestate_path))
  end

  local _data_path = string.format("%s/data.json", _path)
  if not do_file_exists(_data_path) then
    print(string.format("Can't open trial: missing savestate \"%s\"", _data_path))
  end

  local _trial_definition = {}
  _trial_definition.data = read_object_from_json_file(_data_path)
  _trial_definition.savestate = savestate.create(_savestate_path)

  if developer_mode then
    print(string.format("Loaded trial \"%s\"", _path))
  end

  return _trial_definition
end

-- WATCH
function init_trial_watch(_trial_watch)
  local _object = _trial_watch or {}

  _object.is_started = false
  _object.hits = {}

  return _object
end

function update_trial_watch(_trial_watch, _attacker, _defender)
  t_assert(_trial_watch ~= nil)
  t_assert(_attacker ~= nil)
  t_assert(_defender ~= nil)
  if _trial_watch.is_started then
    local _trial_dropped = (_defender.has_just_been_hit and not _defender.is_being_thrown and _attacker.previous_combo >= _attacker.combo)
    _trial_dropped = _trial_dropped or _attacker.previous_combo > _attacker.combo

    if _trial_dropped or _defender.is_idle or _defender.is_wakingup or _defender.is_in_air_recovery then
      --print(string.format("%d, %d, %d, %d", to_bit(_trial_dropped), to_bit(_defender.is_idle), to_bit(_defender.is_wakingup), to_bit(_defender.is_in_air_recovery)))
      _trial_watch.is_started = false
      print(_trial_watch.hits)
    end
  end

  if _defender.has_just_been_hit then
    if not _trial_watch.is_started then
      init_trial_watch(_trial_watch)
      _trial_watch.is_started = true
    end
    table.insert(_trial_watch.hits, _attacker.animation)
  end
end


-- STEPS
function build_trial_steps(_char_moves, _hits)
  local _trial_steps = {
    steps = {},
    hit_to_step = {},
    char_moves = _char_moves
  }

  local _hit_id = 1
  while _hit_id <= #_hits do
    local _animation = _hits[_hit_id]
    table.insert(_trial_steps.steps, _animation)

    local _move = find_move_from_animation(_char_moves, _animation)
    if _move ~= nil then
      for _i = 1, #_move.hits do
        table.insert(_trial_steps.hit_to_step, #_trial_steps.steps)
        _hit_id = _hit_id + 1
      end
    else
      table.insert(_trial_steps.hit_to_step, #_trial_steps.steps)
      _hit_id = _hit_id + 1
    end
  end

  --print(_hits)
  --print(_trial_steps)

  return _trial_steps
end

function draw_trial_steps(_x, _y, _trial_steps, _progress)
  _progress = _progress or 0
  local _previous_step = 0
  for _i = 1, #_trial_steps.hit_to_step do
    local _step_id = _trial_steps.hit_to_step[_i]
    if _step_id ~= _previous_step then
      _previous_step = _step_id
      local _step = _trial_steps.steps[_step_id]
      local _s = _step
      local _move = find_move_from_animation(_trial_steps.char_moves, _step)
      if _move ~= nil then
        _s = string.format("%s - %s", _move.name, _move.command)
      end
      local _color = 0xFFFFFFFF
      if _i <= _progress then
        _color = 0xFF0000FF
      end

      gui.text(_x, _y, _s, _color)
      _y = _y + 9
    end
  end
end

-- RECORDING
function init_trial_recording(_trial_recording)
  local _object = _trial_recording or {}
  
  _object.on = false
  _object.char_str = ""
  _object.savestate = nil
  _object.sequence = {
    sequence = {},
    current_frame = 1
  }
  _object.steps = nil
  _object.watch = init_trial_watch()

  return _object
end

function start_trial_recording(_recording)
  init_trial_recording(_recording)

  _recording.on = true
  _recording.char_str = player_objects[1].char_str
  _recording.savestate = savestate.create(9)
  savestate.save(_recording.savestate)
end

function stop_trial_recording(_recording)
  _recording.on = false
  local _trial_definition = {
    data = {
      char = _recording.char_str,
      p1_sequence = _recording.sequence.sequence,
      hits = _recording.watch.hits,
    },
    savestate = _recording.savestate,
  }
  return _trial_definition
end

function save_trial_definition(_trial_definition, _path)
  if _trial_definition.savestate == nil then
    print(string.format("Can't save trial, no savestate found in the definition"))
    return
  end

  local _date = os.date("%Y-%m-%d_%Hh%Mm%Ss")
  local _trial_path = string.format("saved/trials/%s_%s", _trial_definition.data.char, _date);
  local _savestate_path = string.format("%s/savestate.fs", _trial_path)

  if not create_directory(_trial_path) then
    print(string.format("Failed to create directory \"%s\"", _trial_path))
    return
  end

  savestate.load(_trial_definition.savestate)
  local _savestate = savestate.create(_savestate_path)
  savestate.save(_savestate)
  if _savestate == nil or not do_file_exists(_savestate_path) then
    print(string.format("Failed to create savestate at \"%s\"", _savestate_path))
    return
  end

  local _trial_data = _trial_definition.data
  _trial_data.version = 1
  local _data_path = string.format("%s/data.json", _trial_path)
  if not write_object_to_json_file(_trial_data, _data_path) then
    print(string.format("Failed to write \"%s\"", _data_path))
    return
  end

  print(string.format("Saved trial to \"%s\"", _trial_path))
end

-- EMU
moves = load_move_data()

trials_list = load_trials_list()
current_trial = 1

trial_recording = init_trial_recording()
is_playing_demo = false

staged_trial = nil
function stage_trial(_trial_definition)
  staged_trial = {}
  staged_trial.definition = _trial_definition
  local _char_moves = moves[staged_trial.definition.data.char]
  staged_trial.steps = build_trial_steps(_char_moves, staged_trial.definition.data.hits)
  staged_trial.watch = init_trial_watch()
  savestate.load(staged_trial.definition.savestate)
  is_playing_demo = false
end

function on_start()
  local _trial_definition = load_trial_definition(trials_list[1])
  stage_trial(_trial_definition)
end

function before_frame()

  -- INPUT
  local _input = joypad.get()

  -- READ GAME STATE
  gamestate_read()

  -- WRITE GAME STATE
  local _write_game_vars_settings =
  {
    infinite_time = true,
    music_volume = 0,
  }
  write_game_vars(_write_game_vars_settings)

  for i = 1, #player_objects do
    local _player_obj = player_objects[i]

    -- LIFE
    if is_in_match and not is_menu_open then
      local _life = memory.readbyte(_player_obj.base + 0x9F)
      local _life_refill_delay = 1
      if _player_obj.is_idle and _player_obj.idle_time > _life_refill_delay then
        local _refill_rate = 6
        _life = math.min(_life + _refill_rate, 160)
      end
      memory.writebyte(_player_obj.base + 0x9F, _life)
      _player_obj.life = _life
    end

    -- METER
    if is_in_match and not is_menu_open and not _player_obj.is_in_timed_sa and _player_obj.is_idle then
      local _is_timed_sa = character_specific[_player_obj.char_str].timed_sa[_player_obj.selected_sa]
      local _previous_meter_count = memory.readbyte(_player_obj.meter_addr[2])
      local _previous_meter_count_slave = memory.readbyte(_player_obj.meter_addr[1])
      if _previous_meter_count ~= _player_obj.max_meter_count and _previous_meter_count_slave ~= _player_obj.max_meter_count then
        local _gauge_value = 0
        if _is_timed_sa then
          _gauge_value = _player_obj.max_meter_gauge
        end
        memory.writebyte(_player_obj.gauge_addr, _gauge_value)
        memory.writebyte(_player_obj.meter_addr[2], _player_obj.max_meter_count)
        memory.writebyte(_player_obj.meter_update_flag, 0x01)
      end
    end

    -- STUN
    if _player_obj.is_idle then
      memory.writebyte(_player_obj.stun_timer_addr, 0);
      memory.writedword(_player_obj.stun_bar_addr, 0);
    end
  end

  -- trial CHECK
  local function switch_trial(_index)
    local _list_size = #trials_list 
    while (_index < 1) do
      _index = _index + _list_size
    end      
    _index = ((_index - 1) % _list_size) + 1
    current_trial = _index
    local _trial_definition = load_trial_definition(trials_list[current_trial])
    stage_trial(_trial_definition)
  end
  if hotkey1_pressed then
    switch_trial(current_trial - 1)
  elseif hotkey2_pressed then
    switch_trial(current_trial + 1)
  end

  -- RECORDING
  if P1.input.pressed["coin"] then
    if not trial_recording.on then
      start_trial_recording(trial_recording)
    else
      --stop_trial_recording(trial_recording)
      --init_trial_watch(trial_watch)
      local _trial_definition = stop_trial_recording(trial_recording)
      stage_trial(_trial_definition)
    end
  end

  if hotkey3_pressed and staged_trial ~= nil then
    savestate.load(staged_trial.definition.savestate)
    staged_trial.sequence = {
      current_frame = 1,
      sequence = staged_trial.definition.data.p1_sequence
    }
    is_playing_demo = true
    init_trial_watch(staged_trial.watch)
  end

  -- WATCH
  if trial_recording.on then
    update_trial_watch(trial_recording.watch, player_objects[1], player_objects[2])
    record_frame_input(player_objects[1], _input, trial_recording.sequence.sequence)
    trial_recording.steps = build_trial_steps(moves[player_objects[1].char_str], trial_recording.watch.hits)
  else
    update_trial_watch(staged_trial.watch, player_objects[1], player_objects[2])
  end

  -- DEMO
  if is_playing_demo then
    process_input_sequence(player_objects[1], staged_trial.sequence, _input)
    joypad.set(_input)

    if staged_trial.sequence.current_frame > #staged_trial.sequence.sequence then
      savestate.load(staged_trial.definition.savestate)
      is_playing_demo = false
      init_trial_watch(staged_trial.watch)
    end
  end

  if hotkey4_pressed then
    save_trial_definition(staged_trial.definition)
  end
end

function on_gui()

  local _max_hit = 0
  if not trial_recording.on then
    for _i = 1, #staged_trial.watch.hits do
      if staged_trial.watch.hits[_i] == staged_trial.definition.data.hits[_i] then
        _max_hit = _max_hit + 1
      else
        break
      end
    end
  end

  local _x = 50
  local _y = 35
  local _steps = nil
  if trial_recording.on then
    _steps = trial_recording.steps
  elseif staged_trial ~= nil then 
    _steps = staged_trial.steps
  end

  if _steps ~= nil then
      draw_trial_steps(_x, _y, _steps, _max_hit)
  end

  -- RECORDING
  if trial_recording.on then
      gui.text(5, 5, "Recording trial...")
  end

  if is_playing_demo then
      gui.text(5, 5, "Demo...")
  end

  gui.box(0,0,0,0,0,0) -- if we don't draw something, what we drawed from last frame won't be cleared

  -- clear input state
  hotkey1_pressed = false
  hotkey2_pressed = false
  hotkey3_pressed = false
  hotkey4_pressed = false
end

emu.registerstart(on_start)
emu.registerbefore(before_frame)
gui.register(on_gui)


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