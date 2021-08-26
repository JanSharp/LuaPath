
This is a pure Lua and very simple/basic path library.

Only supports paths in the format of `foo/bar.baz`.\
Basically, `/` is a separator and the last entry can have a `.extension`.

**Leading or railing `/` are not supported.** (for now?)

It also has very light, optional integration with [LuaFileSystem](https://keplerproject.github.io/luafilesystem/).

Inspired by `string.sub`. Think of each part/entry of a path like a character in a string.
That is how `Path.sub` works, other than that the lib is nothing special.

Lastly there is `arg_parser_path_type_def` which can be used with
`arg_parser.register_type()`to parse program args as paths.
See [LuaArgParser](https://github.com/JanSharp/LuaArgParser).
