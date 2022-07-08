
---cSpell:ignore vararg

---[LuaFileSystem](https://keplerproject.github.io/luafilesystem/)
---@diagnostic disable-next-line: undefined-doc-name
---@type LFS
local lfs
do
  local success
  success, lfs = pcall(require, "lfs")
  if not success then
    lfs = (nil)--[[@as LFS]]
  end
end

---@class Path
---@field entries string[]
---@field force_directory boolean? @ trailing slashes define `force_directory` paths
---@field __is_absolute boolean? @ internal only. use `is_absolute()` instead
---@field drive_letter string? @ windows only
local Path = {}
Path.__index = Path

local main_separator = package.config:sub(1, 1)
local is_windows = main_separator == "\\"

local separator_pattern = is_windows
  and "()[\\/]()"
  or "()/()"

---The main separator defines what to use when converting Paths to strings.\
---By default this only sets the main separator if the current platform is windows.
---@param forward_or_backslash "/"|"\\" @ New main separator
---@param set_regardless_of_platform? boolean @ Set even if the current platform is not windows?
function Path.set_main_separator(forward_or_backslash, set_regardless_of_platform)
  if forward_or_backslash ~= "\\" and forward_or_backslash ~= "/" then
    error("Attempt to set main path separator to '"..forward_or_backslash.."' \z
      when the only valid separators are '/' and '\\'."
    )
  end
  if set_regardless_of_platform or is_windows then
    main_separator = forward_or_backslash
  end
end

---Get the main separator that is currently used when converting Paths to strings
function Path.get_main_separator()
  return main_separator
end

---@param path string
local function get_drive_letter(path)
  if not is_windows then
    error("Cannot get_drive_letter when not on windows")
  end
  if path:sub(2, 2) ~= ":" then
    return nil, "Unable to get drive letter from path '"..path.."'"
  end
  return path:sub(1, 1)
end

function Path.is_windows()
  return is_windows
end

---Try parsing a string as a path
---@param path string?
---@return Path|nil result @ nil if unable to parse
---@return nil|string err
function Path.try_parse(path)
  local entries = {}
  local result = {entries = entries}

  if path then
    local entries_start_position = 1

    if is_windows then
      local drive_letter = get_drive_letter(path)
      if drive_letter then
        result.drive_letter = drive_letter
        result.__is_absolute = true
        entries_start_position = 3
      end
    end

    if path:find("^"..separator_pattern, entries_start_position) then
      result.__is_absolute = true
      entries_start_position = entries_start_position + 1
    elseif is_windows and result.drive_letter and #path >= entries_start_position then
      return nil, "Expected path separator after drive letter in path '"..path.."'"
    end

    local entry_start_position = 1
    local entires_part = path:sub(entries_start_position)
    for sep_position, next_entry_position in entires_part:gmatch(separator_pattern) do
      if sep_position == entry_start_position then
        return nil, "Path separators must not be followed by another \z
          path separator in path '"..path.."' at "..sep_position
      end
      entries[#entries+1] = entires_part:sub(entry_start_position, sep_position - 1)
      entry_start_position = next_entry_position
    end

    if entries_start_position + entry_start_position - 1 > #path then -- trailing path separator?
      result.force_directory = true
    else
      entries[#entries+1] = entires_part:sub(entry_start_position)
    end
  end
  return (setmetatable(result, Path))
end

---Path constructor
---@param path (string|Path)?
---@return Path
function Path.new(path)
  if type(path) == "table" then
    return path:copy()
  end
  ---@cast path string
  local result, err = Path.try_parse(path)
  if not result then
    error(err)
  end
  return result
end

---copy this path
---@return Path
function Path:copy()
  local entries = {}
  local result = {
    entries = entries,
    __is_absolute = self.__is_absolute,
    force_directory = self.force_directory,
  }
  if is_windows then
    result.drive_letter = self.drive_letter
  end
  for _, entry_name in ipairs(self.entries) do
    entries[#entries+1] = entry_name
  end
  return setmetatable(result, Path)
end

function Path:is_absolute()
  return ((is_windows and self.drive_letter) or self.__is_absolute)
end

---By default this only overrides the main separator if the current platform is windows.
---@param overridden_separator ("/"|"\\")? @ Separator to use instead of the current main separator.
---@param override_regardless_of_platform boolean? @ Use even if the current platform is not windows?
---@return string
function Path:str(overridden_separator, override_regardless_of_platform)
  local separator = main_separator
  if overridden_separator then
    if overridden_separator ~= "\\" and overridden_separator ~= "/" then
      error("Attempt to set path separator to '"..overridden_separator.."' \z
        when the only valid separators are '/' and '\\'."
      )
    end
    if override_regardless_of_platform or is_windows then
      separator = overridden_separator
    end
  end
  return (is_windows and self.drive_letter and (self.drive_letter..":") or "")
    ..(self:is_absolute() and separator or "")
    ..(self.entries[1] and table.concat(self.entries, separator) or (not self:is_absolute() and "." or ""))
    ..(self.force_directory and (self.entries[1] or not self:is_absolute()) and separator or "")
end
Path.__tostring = Path.str

function Path:length()
  return #self.entries
end
Path.__len = Path.length

---@param other Path
---@return boolean
function Path:equals(other)
  local count = #self.entries
  if count ~= #other.entries
    or (is_windows and self.drive_letter ~= other.drive_letter)
    or self:is_absolute() ~= other:is_absolute()
    or self.force_directory ~= other.force_directory
  then
    return false
  end
  for i = 1, count do
    if self.entries[i] ~= other.entries[i] then
      return false
    end
  end
  return true
end
Path.__eq = Path.equals

---create a new path which is all given paths combined
---@vararg Path|string
---@return Path
function Path.combine(...)
  local result = Path.new()
  local entries = result.entries
  local paths = {...}
  result.force_directory = paths[1] and paths[#paths].force_directory
  for i, path in ipairs(paths) do
    if type(path) == "string" then
      local err
      path, err = Path.new(path)
      if not path then
        error(err.." when parsing path number "..i.." when combining paths")
      end
    end
    if i == 1 then
      if is_windows then
        result.drive_letter = path.drive_letter
      end
      result.__is_absolute = path.__is_absolute
    else
      if path:is_absolute() then
        error("Cannot combine paths that are absolute unless they are \z
          the first path in the list. Absolute path at number "..i.." '"..path:str().."."
        )
      end
    end
    for _, entry_name in ipairs(path.entries) do
      entries[#entries+1] = entry_name
    end
  end
  return result
end
Path.__div = Path.combine

---get the extension of the path
---@return string
function Path:extension()
  if self.force_directory then
    error("Unable to get the extension of a path that is a directory")
  end
  return string.match(self.entries[#self.entries], "(%.[^.]*)$") or ""
end

---get the filename of the path
---@return string
function Path:filename()
  if self.force_directory then
    error("Unable to get the filename of a path that is a directory")
  end
  return string.match(self.entries[#self.entries], "(.-)%.?[^.]*$")
end

---Extract a part of the path as a new path.
---Works just like string.sub where each entry_name is like a character
---@param i integer
---@param j integer?
---@return Path
function Path:sub(i, j)
  local count = #self.entries
  do
    if i < 0 then
      i = count + 1 + i
    end
    i = math.max(i, 1)
    if j then
      if j < 0 then
        j = count + 1 + j
      end
      j = math.min(j, count)
    else
      j = count
    end
  end
  local result = Path.new()
  if i == 1 then
    result.__is_absolute = self.__is_absolute
    if is_windows then
      result.drive_letter = self.drive_letter
    end
  end
  if j == count then
    result.force_directory = self.force_directory
  end
  for k = i, j do
    result.entries[#result.entries+1] = self.entries[k]
  end
  return result
end

---@param working_directory Path|string?
---@return Path
function Path:to_fully_qualified(working_directory)
  local result = self:copy()
  if self:is_absolute() then
    if is_windows and not self.drive_letter then
      if not working_directory and not lfs then
        error("Cannot convert an absolute path without a drive letter \z
          to a fully qualified path without a provided `working_directory` \z
          nor without LuaFileSystem."
        )
      end
      result.drive_letter = assert(get_drive_letter(
        type(working_directory) == "table"
          and working_directory:str()
          or working_directory--[[@as string?]]
          or assert(lfs.currentdir()))
      )
    end
  else
    if not working_directory and not lfs then
      error("Cannot convert a relative path to a fully qualified path \z
        without a provided `working_directory` \z
        nor without LuaFileSystem."
      )
    end
    result = Path.combine(working_directory or lfs.currentdir(), self)
  end
  return result
end

---@return Path
function Path:normalize()
  local result = self:copy()
  local entries = {}
  result.entries = entries
  for _, entry in ipairs(self.entries) do
    if entry == "." then
      goto continue
    elseif entry == ".." then
      if not entries[1] or entries[#entries] == ".." then
        if self:is_absolute() then
          error("Trying to move up an entry ('..') when there are no more \z
            entries left when normalizing the path '"..self:str().."'"
          )
        end
        entries[#entries+1] = ".."
      else
        entries[#entries] = nil
      end
    else
      entries[#entries+1] = entry
    end
    ::continue::
  end
  return result
end

---**on windows** clears the `drive_letter`. You may want `set_drive_letter()` instead
---@return Path
function Path:to_absolute()
  local result = self:copy()
  result.__is_absolute = true
  if is_windows then
    result.drive_letter = nil
  end
  return result
end

---@return Path
function Path:to_relative()
  local result = self:copy()
  result.__is_absolute = false
  if is_windows then
    result.drive_letter = nil
  end
  return result
end

---**windows only**
---@param drive_letter string?
---@return Path
function Path:set_drive_letter(drive_letter)
  if not is_windows then
    -- TODO: decide on if it should just silently return instead of erroring
    error("set_drive_letter is only for windows")
  end
  local result = self:copy()
  result.__is_absolute = true
  result.drive_letter = drive_letter
  return result
end

---@param force_directory boolean?
function Path:set_force_directory(force_directory)
  local result = self:copy()
  result.force_directory = force_directory
  return result
end

---requires [LuaFileSystem](https://keplerproject.github.io/luafilesystem/)
---@return boolean
function Path:exists()
  return lfs.attributes(self:str(), "dev") ~= nil
end

---requires [LuaFileSystem](https://keplerproject.github.io/luafilesystem/)
---@diagnostic disable-next-line: undefined-doc-name
---@return fun(dir_obj: LFSDirObject):string iter
---@diagnostic disable-next-line: undefined-doc-name
---@return LFSDirObject dir_obj
function Path:enumerate()
  return lfs.dir(self:str())
end

---requires [LuaFileSystem](https://keplerproject.github.io/luafilesystem/)\
---calls lfs.attributes(request_name) and returns the result
---@param request_name string
---@diagnostic disable-next-line: undefined-doc-name
---@return string|number|LFSAttributes|nil
function Path:attr(request_name)
  return lfs.attributes(self:str(), request_name)
end

---requires [LuaFileSystem](https://keplerproject.github.io/luafilesystem/)\
---calls lfs.symlinkattributes(request_name) and returns the result
---@param request_name string
---@diagnostic disable-next-line: undefined-doc-name
---@return string|number|LFSAttributes|nil
function Path:sym_attr(request_name)
  return lfs.symlinkattributes(self:str(), request_name)
end

Path.arg_parser_path_type_def = {
  id = "path",
  arg_count = 1,
  convert = function(arg, context)
    local result, err = Path.try_parse(arg)
    if not result then
      return nil, err.." "..context.."."
    end
    return result
  end,
  compare = function(left, right)
    return left:str() == right:str()
  end,
}

return Path
