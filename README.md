
This is a pure Lua and very simple/basic path library.

Supported formats
- `foo/bar` - 2 simple entries with nothing extra. usually referred to as a relative path
- `/` - rooted and 0 entries (**on windows:** rooted at the drive of the current working directory)
- `/foo/bar` - combination of the first 2
- `foo/` - 1 entry, plus a `force_directory` flag causing errors when trying to treat the entry as a filename
- `C:` - **windows only** 0 entries, but absolute with a drive letter already defined (unlike `/`)
- `C:/` - **windows only** same as `C:`
- **windows only** any `\` is treated like `/`

Speaking of windows, use `set_main_separator("/")` will cause `str()` to print paths using `/` instead of `\`. This can be reverted by setting it to `"\\"` and can be overridden for each `str()` call, like `str("/")` or `str("\\")`. A second arg for `set_main_separator()` and `str()` can be set to true to change the separator for all platforms, not just windows.

It also has very light, optional integration with [LuaFileSystem](https://keplerproject.github.io/luafilesystem/).\
`exists()` and `attr()` directly depend on it, `to_fully_qualified()` may depend on it if no `working_directory` is provided.

Inspired by `string.sub`. Think of each part/entry of a path like a character in a string.
That is how `Path.sub` works, other than that the lib is nothing special.

**Path objects are immutable.** While technically you can modify the tables, no library function does so. Every function that may modify a path returns a new instance.

There is `arg_parser_path_type_def` which can be used with
`arg_parser.register_type()` to parse program args as paths.
See [LuaArgParser](https://github.com/JanSharp/LuaArgParser).

<!-- cSpell:ignore metatable -->

For those without language servers, here's a list of all fields on `Path`\
This `Path` table is also the metatable of all path objects
```
__div(left, right)  -  uses combine()
__eq(left, right)  -  uses equals()
__index  -  this lib's `Path` table
__len(path)  -  uses length()
__tostring()  -  uses str()
is_windows()  -  is the current platform windows? based on Lua's package.config separator being a backslash
arg_parser_path_type_def  -  see notes about LuaArgParser above
attr(self, mode)  -  alias for `LFS.attributes(self:str(), mode)`
sym_attr(self, mode)  -  alias for `LFS.symlinkattributes(self:str(), mode)`
combine(...)
copy(self)
equals(self, other)
exists(self)  -  depends on LFS
extension(self)
filename(self)
is_absolute(self)
length(self)
new(path)  -  nil|string|path
normalize(self)  -  resolve all `.` and `..` entries
set_drive_letter(self, drive_letter)  -  windows only, errors otherwise (may change)
set_force_directory(self, force_directory)
str(self, overridden_separator, override_regardless_of_platform)
  - overridden_separator is only used if platform is windows or `override_regardless_of_platform == true`
sub(self, i, j)  -  similar to `string.sub`
to_absolute(self)  -  on windows clears drive_letter
to_fully_qualified(self, working_directory)
  -  may depend on LFS if no `working_directory` is provided
to_relative(self)
try_parse(path)  -  nil|string  returns `nil, err` on error
set_main_separator(forward_or_backslash, set_regardless_of_platform)
  -  only sets if platform is windows, unless `set_regardless_of_platform == true`
get_main_separator()  -  main separator is used by the `str` function
```

Extra fields on each path object
```
__is_absolute  -  use is_absolute() instead
drive_letter  -  windows only. `path:is_absolute() and not path.drive_letter`
                 means it's rooted at the current working dir's drive
entries  -  string array
force_directory  -  trailing `/` basically
```

(these are really bad docs, but it's better than nothing)
