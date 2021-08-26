
---cSpell:ignore vararg

---[LuaFileSystem](https://keplerproject.github.io/luafilesystem/)
---@diagnostic disable-next-line: undefined-doc-name
---@type LFS
local lfs = pcall(require, "lfs")

---@class Path
---@field entries string[]
local Path = {}
Path.__index = Path

local entry_name_pattern = "[^/]+"

---Path constructor
---@param path? string|Path
---@return Path
function Path.new(path)
  if type(path) == "table" then
    return path:copy()
  end
  local entries = {}
  if path then
    for entry_name in path:gmatch(entry_name_pattern) do
      entries[#entries+1] = entry_name
    end
  end
  return setmetatable({entries = entries}, Path)
end
Path.__call = Path.new

---copy this path
---@return Path
function Path:copy()
  local entries = {}
  for _, entry_name in ipairs(self.entries) do
    entries[#entries+1] = entry_name
  end
  return setmetatable({entries = entries}, Path)
end

---@return string
function Path:str()
  return table.concat(self.entries, "/")
end
Path.__tostring = Path.str

function Path:length()
  return #self.entries
end
Path.__len = Path.length

function Path:equals(other)
  local count = #self.entries
  if count ~= #other.entries then
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
  for _, path in ipairs{...} do
    if type(path) == "string" then
      for entry_name in path:gmatch(entry_name_pattern) do
        entries[#entries+1] = entry_name
      end
    else
      for _, entry_name in ipairs(path.entries) do
        entries[#entries+1] = entry_name
      end
    end
  end
  return result
end
Path.__div = Path.combine

---get the extension of the path
---@return string
function Path:extension()
  return string.match(self.entries[#self.entries], "(%.[^.]*)$") or ""
end

---get the filename of the path
---@return string
function Path:filename()
  return string.match(self.entries[#self.entries], "(.-)%.?[^.]*$")
end

---Extract a part of the path as a new path.
---Works just like string.sub where each entry_name is like a character
---@param i integer
---@param j? integer
---@return Path
function Path:sub(i, j)
  do
    local count = #self.entries
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
  for k = i, j do
    result.entries[#result.entries+1] = self.entries[k]
  end
  return result
end

---requires [LuaFileSystem](https://keplerproject.github.io/luafilesystem/)
function Path:exists()
  return lfs.attributes(self:str(), "dev") ~= nil
end

---requires [LuaFileSystem](https://keplerproject.github.io/luafilesystem/)\
---calls lfs.attributes(request_name) and returns the result
---@param request_name string
---@diagnostic disable-next-line: undefined-doc-name
---@return string|number|LFSAttributes|nil
function Path:attr(request_name)
  return lfs.attributes(self:str(), request_name)
end

return Path
