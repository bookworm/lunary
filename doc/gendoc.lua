require 'template'
require 'markdown'

local charset = ([[
vi: encoding=utf-8
]]):sub(14, -2):upper()

local file_index = "index.html"
local file_manual = "manual.html"
local file_examples = "examples.html"

------------------------------------------------------------------------------

print = template.print

function header()
	print([[
<?xml version="1.0" encoding="]]..charset..[["?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en"
lang="en">
<head>
<title>Lunary</title>
<meta http-equiv="Content-Type" content="text/html; charset=]]..charset..[["/>
<link rel="stylesheet" href="doc.css" type="text/css"/>
</head>
<body>
]])
	print([[
<div class="chapter" id="header">
<img width="128" height="128" alt="Lunary" src="lunary.png"/>
<p>A binary format I/O framework for Lua</p>
<p class="bar">
<a href="]]..file_index..[[">home</a> &middot;
<a href="]]..file_index..[[#download">download</a> &middot;
<a href="]]..file_index..[[#installation">installation</a> &middot;
<a href="]]..file_manual..[[">manual</a> &middot;
<a href="]]..file_examples..[[">examples</a>
</p>
</div>
]])
end

function footer()
	print([[
<div class="chapter" id="footer">
<small>Last update: ]]..os.date"%Y-%m-%d %T%z"..[[</small>
</div>
]])
	print[[
</body>
</html>
]]
end

local chapterid = 0

function chapter(title, text, sections, raw)
	chapterid = chapterid+1
	local text = text:gsub("%%chapterid%%", tostring(chapterid))
	if not raw then
		text = markdown(text)
	end
	if sections then
		for _,section in ipairs(sections) do
			section = section:gsub("%%chapterid%%", tostring(chapterid))
			text = text..[[
<div class="section">
]]..markdown(section)..[[
</div>]]
		end
	end
	print([[
<div class="chapter">
<h1>]]..tostring(chapterid).." - "..title..[[</h1>
]]..text..[[
</div>
]])
end

------------------------------------------------------------------------------

io.output(file_index)

header()

chapter("About Lunary", [[
Lunary is a framework to read and write structured binary data to files or network connections. The aim is to provide an easy to use interface to describe any complex binary format, and allow translation to Lua data structures. The focus is placed upon the binary side of the transformation, and further processing may be necessary to obtain the desired Lua structures. On the other hand Lunary should allow reading and writing of any binary format, and bring all the information available to the Lua side. User application or custom formats are required to remove themselves any unnecessary information (e.g. ordering of entries in a set or a map).

## Support

All support is done through the Lua mailing list. If the traffic becomes too important a specialized mailing list will be created.

Feel free to ask for further developments. I can't guarantee that I'll develop everything you ask, but I want my code to be as useful as possible, so I'll do my best to help you. You can also send me request or bug reports (for code and documentation) directly at [jerome.vuarand@gmail.com](mailto:jerome.vuarand@gmail.com).

## Credits

This module is written and maintained by Jérôme Vuarand.

Lunary is available under a [MIT-style license](LICENSE.txt).
]])

chapter('<a name="download">Download</a>', [[
Lunary sources are available in its [Mercurial repository](http://piratery.net/hg/lunary/):

    hg clone http://piratery.net/hg/lunary/

Tarballs of the latest code can be downloaded directly from there: as [gz](http://piratery.net/hg/lunary/archive/tip.tar.gz), [bz2](http://piratery.net/hg/lunary/archive/tip.tar.bz2) or [zip](http://piratery.net/hg/lunary/archive/tip.zip).
]])

chapter('<a name="installation">Installation</a>', [[
Lunary consists of two Lua modules named `serial` and `serial.util`. There is a also an optionnal `serial.optim` binary module which replace some functions of `serial.util` with optmized alternatives to improve Lunary performance.

A simple makefile is provided. The `build` target builds the `serial.optim` binary module. The `install` target installs all the Lunary modules to the `PREFIX` installation path, which is defined in the Makefile and can be overriden with an environment variable. The `installpure` target only install pure Lua modules, it can be used on platforms where compiling or using C modules is problematic.

Finally note that Lunary uses Roberto Ierusalimschy's struct library to read and write floats. The library is available at [http://www.inf.puc-rio.br/~roberto/struct/](http://www.inf.puc-rio.br/~roberto/struct/). If it is not available Lunary won't be able to use the `'float'` data type, but all other predefined types should work as expected.]])

footer()

------------------------------------------------------------------------------

io.output(file_manual)

header()

chapter('<a name="manual">Manual</a>', [[

## %chapterid%.1 - General library description

The Lunary framework is organized as a collection of data type descriptions. Basic data types include for example 8-bit integers, C strings, enums. Each data type has a unique name, and can have parameters. Datatypes can be described by different means. Ultimately, each data type will be manipulated with three functions, named according to the data type, and located in the following tables: `serial.read`, `serial.serialize` and `serial.write`.

`serial.read` contains functions that can be used to read a data object, of a given data type, from a data stream. For example the function `serial.read.uint8` can be used to read an unsigned 8 bit integer number. The general function prototype is:

    function serial.read.<type name>(<stream>, [type parameters])

For a description of the stream object, see the *Streams* section below. The type parameters are dependent on the data type, and may be used to reduce the overall number of data types and group similar types. A data type can have any number of type parameters. For example, Lunary provides a single `uint32` datatype, but support both big-endian and little-endian integers. The endianness is specified as the first type parameter.

`serial.serialize` functions that can be used to serialize a data object into a byte string. The general function prototype is:

    function serial.serialize.<type name>(<value>, [type parameters])

Finally `serial.write` contains functions that can be used to write a data object to a data stream. The general function prototype is:

    function serial.write.<type name>(<stream>, <value>, [type parameters])

The `serial.serialize` and `serial.write` tables are a little redundant. It is possible to create a `write` function from a `serialize` function, and vice versa. Actually, when implementing data types, it is not necessary to provide both of these functions. The other one will be automatically generated by Lunary if missing. However, when using complex data types, depending on the situation one function may be faster than the other. So when performance becomes important, it is a good idea to provide both a `write` and a `serialize` function for your new data types.

## %chapterid%.2 - Streams

The Lunary framework was originally created to write a proxy for a binary network protocol. This is why Lunary serialization functions expect a stream object implementing the LuaSocket socket interface. However Lunary provides a way to wrap standard Lua file objects and have them behave as LuaSocket streams.

Stream objects as used by Lunary should be Lua object (implemented with any indexable Lua type), which provide methods. The methods to implement depend on the serialization functions used, and on the data type that is serialized. For basic data types, the `serial.write` functions expect a `send` method, and the `serial.read` functions expect a `receive` methods, defined as:

    function stream:send(data)
    function stream:receive(pattern, [prefix])

where `data` is a Lua string containing the bytes to write to the stream, `pattern` is format specifier as defined in the [file:read](http://www.lua.org/manual/5.1/manual.html#pdf-file:read) standard Lua API, and `prefix` is a string which will be prefixed to the `receive` return value.

One other methods used by some data types described below is `length`:

    function stream:length()
    function stream:skip(nbytes)

The `length` method returns the number of bytes available in the stream. For network sockets, this makes no sense, but that information is available for file and buffer streams. That method is used by some data types which serialized length cannot be infered from the type description or content. For example array running to the end of the file or file section need that method when reading a stream.

As you can guess from the stream API we just described, the Lunary library is not capable of reading or writing data types that are not a multiple of a byte. This is a limitation that has not been problematic so far, but if necessary this could be changed.

## %chapterid%.3 - Compound data types

Lunary provides several basic data types, and some more complex compound data types. These types are generally more complicated to use, this section provides details about them.

### %chapterid%.3.1 - Type description as type parameters

Most of these compound data types contain sub-elements, but are described in the Lunary source code in a generic way. To use them with a given type for their sub-elements, a type description has to be given as one or more of their type parameters. Usually, type description as type parameters are passed as a Lua array, with the first array entry being the sub-element type name, and subsequent array entries being the sub-type type parameters. However when only a single sub-type description is necessary, the array may be expected as unpacked at the end of the parent type-parameter list. For example, to read an array or ten 8-bit numbers, one can call:

    serial.read.array(stream, 10, 'uint8')

When several sub-types are necessary, they are passed in Lua tables. So for example to read an array of C strings, prefixed by the number of string in a little-endian 16-bit integer, one can call:

    serial.read.sizedarray(stream, {'uint16', 'le'}, {'cstring'})

### %chapterid%.3.2 - Naming `struct`-based and `fstruct`-based data types, aliases

The `struct` and `fstruct` (as described below) are very handy to describe complex compound types. However, when such types are reused in several part of more complex data types, or in several root data types (like in several file formats), it may be handy to refer to them with names. The basic way to do it is to store the type parameters in Lua variables. For example one can write:

    local attribute = {
        {'name', 'cstring'},
        {'value', 'uint32', 'le'},
    }
    serial.read.struct(stream, attribute)

To share data types between libraries though, this may not be very handy. Lunary provides a way to define named data types. To do that three tables in the `serial` module are available: `serial.struct`, `serial.fstruct` and `serial.alias`. The first two are used to create named types based on structs and fstructs respectively, while the last one is used to give a name to any type. For example, the above `attribute` data type can be created like that:

    serial.struct.attribute = {
        {'name', 'cstring'},
        {'value', 'uint32', 'le'},
    }

This will automatically generate `read`, `serialize` and `write` functions for that type, which can be used as follow:

    serial.read.attribute(stream)

The `fstruct` works similarly for fstructs (see below). The `alias` table, will contain type description arrays as expected by the `array` or `sizedarray` data types, and described above. For example, if your datatype often contains 32-byte long character strings, you can define an alias as follows:

    serial.alias.string32 = {'bytes', 32}

You can then read such strings with the `serial.read.string32` function, or even include that new data type in compounds types, for example:

    serial.struct.disk = {
        {'artist', 'string32'},
        {'title', 'string32'},
        {'genre', 'string32'},
    }

## %chapterid%.4 - Data type reference

- uint8
- uint16
- uint32
- uint64
- enum
- flags
- sizedbuffer
- array
- sizedvalue
- sizedarray
- cstring
- float
- bytes
- bytes2hex
- bytes2base32
- boolean8
- struct
- fstruct

]])

footer()

------------------------------------------------------------------------------

io.output(file_examples)

header()

chapter('<a name="examples">Examples</a>', [[
No educative examples are yet available for Lunary, but it is already used to read and write .met files (the ones used by various ed2k P2P clients) by the ed2k-ltools software suite. Datatypes describing these file formats are available in the [`serial/met.lua` file](http://piratery.net/hg/ed2k-ltools/raw-file/tip/met-ltools/serial/met.lua).]])

footer()

------------------------------------------------------------------------------

-- vi: ts=4 sts=4 sw=4

