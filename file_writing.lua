--function on_gui()
  local _write_file_path = "saved/test.txt"
  local _write, _write_error, _write_code = io.open(_write_file_path, "w")
  if _write == nil then
    print(string.format("Failed to open file \"%s\" in write mode: %s(%d)", _write_file_path, _write_error, _write_code))
  else
    _write:close()
  end

  local _read_file_path = "saved/test.txt"
  local _read, _read_error, _read_code = io.open(_read_file_path, "r")
  if _read == nil then
    print(string.format("Failed to open file \"%s\" in read mode: %s(%d)", _read_file_path, _read_error, _read_code))
  else
    _read:close()
  end
--end

gui.register(on_gui)
