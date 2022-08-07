move_data_root_path = string.format("data/%s/moves", rom_name)

function load_move_data()
  local _moves = {}
  for _i, _char_str in ipairs(characters) do
    local _char_moves = {
      list = {},
      lookup = {},
    }

    -- load moves from file
    local _char_moves_path = string.format("%s/%s_moves.json", move_data_root_path, _char_str)
    local _char_moves_list = read_object_from_json_file(_char_moves_path)
    if _char_moves_list ~= nil then
      _char_moves.list = _char_moves_list

      -- generate animation to move lookup table
      _char_moves.lookup = {}
      for _i, _move in ipairs(_char_moves.list) do
        for __, _animation in ipairs(_move.hits) do
          _char_moves.lookup[_animation] = _i
        end
      end

      --print(string.format("Loaded moves from \"%s\"", _char_moves_path))
    end

    -- insert character
    _moves[_char_str] = _char_moves
  end
  return _moves
end

function find_move_from_animation(_char_moves, _animation)
  local _move_id = _char_moves.lookup[_animation]
  if _move_id == nil then
    return nil
  end
  return _char_moves.list[_move_id]
end
