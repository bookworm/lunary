module((...), package.seeall)

local util = require(_NAME..".util")

serialize = {}
read = {}
write = {}
struct = {}
fstruct = {}
alias = {}

local function warning(message, level)
	if not level then
		level = 1
	end
	print(debug.traceback("warning: "..message, level+1))
end

-- function serialize.typename(value, typeparams...) return string end
-- function read.typename(stream, typeparams...) return value end

------------------------------------------------------------------------------

function serialize.uint8(value, scrambler)
	local a = value
	if value < 0 or value >= 2^8 or math.floor(value)~=value then
		error("invalid value")
	end
	local data = string.char(a)
	if scrambler then
		data = scrambler(data)
	end
	return data
end

function read.uint8(stream, scrambler)
	local data,err = stream:receive(1)
	if not data then
		return nil,err
	end
	if scrambler then
		data = scrambler(data)
	end
	return string.byte(data)
end

------------------------------------------------------------------------------

function serialize.uint16(value, endianness, scrambler)
	if value < 0 or value >= 2^16 or math.floor(value)~=value then
		error("invalid value")
	end
	local b = value % 256
	value = (value - b) / 256
	local a = value % 256
	local data
	if endianness=='le' then
		data = string.char(b, a)
	elseif endianness=='be' then
		data = string.char(a, b)
	else
		error("unknown endianness")
	end
	if scrambler then
		data = scrambler(data)
	end
	return data
end

function read.uint16(stream, endianness, scrambler)
	local data,err = stream:receive(2)
	if not data then
		return nil,err
	end
	if scrambler then
		data = scrambler(data)
	end
	local a,b
	if endianness=='le' then
		b,a = string.byte(data, 1, 2)
	elseif endianness=='be' then
		a,b = string.byte(data, 1, 2)
	else
		error("unknown endianness")
	end
	return a * 256 + b
end

------------------------------------------------------------------------------

function serialize.uint32(value, endianness, scrambler)
	if value < 0 or value >= 2^32 or math.floor(value)~=value then
		error("invalid value")
	end
	local d = value % 256
	value = (value - d) / 256
	local c = value % 256
	value = (value - c) / 256
	local b = value % 256
	value = (value - b) / 256
	local a = value % 256
	local data
	if endianness=='le' then
		data = string.char(d, c, b, a)
	elseif endianness=='be' then
		data = string.char(a, b, c, d)
	else
		error("unknown endianness")
	end
	if scrambler then
		data = scrambler(data)
	end
	return data
end

function read.uint32(stream, endianness, scrambler)
	local data,err = stream:receive(4)
	if not data then
		return nil,err
	end
	if scrambler then
		data = scrambler(data)
	end
	local a,b,c,d
	if endianness=='le' then
		d,c,b,a = string.byte(data, 1, 4)
	elseif endianness=='be' then
		a,b,c,d = string.byte(data, 1, 4)
	else
		error("unknown endianness")
	end
	return ((a * 256 + b) * 256 + c) * 256 + d
end

------------------------------------------------------------------------------

local maxbytes = {}
do
	function n(a,b,c,d,e,f,g,h) return (((((((a or 0) * 256 + (b or 0)) * 256 + (c or 0)) * 256 + (d or 0)) * 256 + (e or 0)) * 256 + (f or 0)) * 256 + (g or 0)) * 256 + (h or 0) end
	-- find maximum byte values
	local a,b,c,d,e,f,g,h
	local ma,mb,mc,md,me,mf,mg,mh
	for i=1,8 do
		a,b,c,d,e,f,g,h = 000,000,000,000,000,000,2^i-1,255; if n(a,b,c,d,e,f,g,0) ~= n(a,b,c,d,e,f,g,1) then ma,mb,mc,md,me,mf,mg,mh = a,b,c,d,e,f,g,h end
	end
	for i=1,8 do
		a,b,c,d,e,f,g,h = 000,000,000,000,000,2^i-1,255,255; if n(a,b,c,d,e,f,g,0) ~= n(a,b,c,d,e,f,g,1) then ma,mb,mc,md,me,mf,mg,mh = a,b,c,d,e,f,g,h end
	end
	for i=1,8 do
		a,b,c,d,e,f,g,h = 000,000,000,000,2^i-1,255,255,255; if n(a,b,c,d,e,f,g,0) ~= n(a,b,c,d,e,f,g,1) then ma,mb,mc,md,me,mf,mg,mh = a,b,c,d,e,f,g,h end
	end
	for i=1,8 do
		a,b,c,d,e,f,g,h = 000,000,000,2^i-1,255,255,255,255; if n(a,b,c,d,e,f,g,0) ~= n(a,b,c,d,e,f,g,1) then ma,mb,mc,md,me,mf,mg,mh = a,b,c,d,e,f,g,h end
	end
	for i=1,8 do
		a,b,c,d,e,f,g,h = 000,000,2^i-1,255,255,255,255,255; if n(a,b,c,d,e,f,g,0) ~= n(a,b,c,d,e,f,g,1) then ma,mb,mc,md,me,mf,mg,mh = a,b,c,d,e,f,g,h end
	end
	for i=1,8 do
		a,b,c,d,e,f,g,h = 000,2^i-1,255,255,255,255,255,255; if n(a,b,c,d,e,f,g,0) ~= n(a,b,c,d,e,f,g,1) then ma,mb,mc,md,me,mf,mg,mh = a,b,c,d,e,f,g,h end
	end
	for i=1,8 do
		a,b,c,d,e,f,g,h = 2^i-1,255,255,255,255,255,255,255; if n(a,b,c,d,e,f,g,0) ~= n(a,b,c,d,e,f,g,1) then ma,mb,mc,md,me,mf,mg,mh = a,b,c,d,e,f,g,h end
	end
	assert(ma)
	assert(mb)
	assert(mc)
	assert(md)
	assert(me)
	assert(mf)
	assert(mg)
	assert(mh)
	maxbytes.uint64 = {ma,mb,mc,md,me,mf,mg,mh}
end

function serialize.uint64(value, endianness, scrambler)
	local data
	local tvalue = type(value)
	if tvalue=='number' then
		if value < 0 or value >= 2^64 or math.floor(value)~=value then
			error("invalid value")
		end
		local h = value % 256
		value = (value - h) / 256
		local g = value % 256
		value = (value - g) / 256
		local f = value % 256
		value = (value - f) / 256
		local e = value % 256
		value = (value - e) / 256
		local d = value % 256
		value = (value - d) / 256
		local c = value % 256
		value = (value - c) / 256
		local b = value % 256
		value = (value - b) / 256
		local a = value % 256
		if endianness=='le' then
			data = string.char(h, g, f, e, d, c, b, a)
		elseif endianness=='be' then
			data = string.char(a, b, c, d, e, f, g, h)
		else
			error("unknown endianness")
		end
	elseif tvalue=='string' then
		assert(#value==8)
		-- uint64 as string is little-endian
		if endianness=='le' then
			data = value
		elseif endianness=='be' then
			data = value:reverse()
		else
			error("unknown endianness")
		end
	else
		error("uint64 value must be a number or a string")
	end
	if scrambler then
		data = scrambler(data)
	end
	return data
end

function read.uint64(stream, endianness, scrambler)
	local data,err = stream:receive(8)
	if not data then
		return nil,err
	end
	if scrambler then
		data = scrambler(data)
	end
	local a,b,c,d,e,f,g,h
	if endianness=='le' then
		h,g,f,e,d,c,b,a = string.byte(data, 1, 8)
	elseif endianness=='be' then
		a,b,c,d,e,f,g,h = string.byte(data, 1, 8)
	else
		error("unknown endianness")
	end
	local ma,mb,mc,md,me,mf,mg,mh = unpack(maxbytes.uint64)
	if a>ma or b>mb or c>mc or d>md or e>me or f>mf or g>mg or h>mh then
		-- uint64 as string is little-endian
		if endianness=='le' then
			return data
		else
			return data:reverse()
		end
	else
		return ((((((a * 256 + b) * 256 + c) * 256 + d) * 256 + e) * 256 + f) * 256 + g) * 256 + h
	end
end

------------------------------------------------------------------------------

function serialize.guid(value)
	local bytes = 0
	local data = ""
	for i=0,7 do
		local byte = value % 256
		value = (value - byte) / 256
		if byte ~= 0 then
			bytes = bytes + 2 ^ i
			data = data .. serialize.uint8(byte)
		end
	end
	data = serialize.uint8(bytes) .. data
	return data
end

function read.guid(stream)
	local byte,err = read.uint8(stream)
	if not byte then
		return nil,err
	end
	local bytes = byte
	local value = 0
	for i=0,7 do
		local bit = bytes % 2
		bytes = (bytes - bit) / 2
		if bit==1 then
			byte,err = read.uint8(stream)
			if not byte then
				return nil,err
			end
			value = value + byte * 256 ^ i
		end
	end
	return value
end

------------------------------------------------------------------------------

function serialize.enum(value, enum, int_t, ...)
	local ivalue
	if type(value)=='number' then
		ivalue = value
	else
		ivalue = enum[value]
	end
	assert(ivalue, "unknown enum string '"..tostring(value).."'")
	local serialize = assert(serialize[int_t], "unknown integer type "..tostring(int_t).."")
	return serialize(ivalue, ...)
end

function read.enum(stream, enum, int_t, ...)
	local read = assert(read[int_t], "unknown integer type "..tostring(int_t).."")
	local value,err = read(stream, ...)
	if not value then
		return nil,err
	end
	local svalue = enum[value]
	if not svalue then
		warning("unknown enum number "..tostring(value)..", keeping numerical value")
		svalue = value
	end
	return svalue
end

------------------------------------------------------------------------------

function serialize.flags(value, flagset, int_t, ...)
	local int = 0
	for flag,k in pairs(value) do
		assert(k==true, "flag has value other than true ("..tostring(k)..")")
		int = int + flagset[flag]
	end
	value = int
	local serialize = assert(serialize[int_t], "unknown integer type "..tostring(int_t).."")
	return serialize(value, ...)
end

function read.flags(stream, flagset, int_t, ...)
	local read = assert(read[int_t], "unknown integer type "..tostring(int_t).."")
	local int,err = read(stream, ...)
	if not int then
		return nil,err
	end
	local value = {}
	for k,v in pairs(flagset) do
		if bit.band(int, v) ~= 0 then
			value[k] = true
		end
	end
	return value
end

------------------------------------------------------------------------------

function serialize.fourcc(value)
	assert(#value==4, "fourcc value should be 4 bytes long")
	return value:reverse()
end

function read.fourcc(stream)
	local data,err = stream:receive(4)
	if not data then
		return nil,err
	end
	return data:reverse()
end

------------------------------------------------------------------------------

function serialize.sizedbuffer(value, size_t, ...)
	local serialize = assert(serialize[size_t], "unknown size type "..tostring(size_t).."")
	local size = #value
	local ssize,err = serialize(size, ...)
	if not ssize then return nil,err end
	return ssize .. value
end

function read.sizedbuffer(stream, size_t, ...)
	local read = assert(read[size_t], "unknown size type "..tostring(size_t).."")
	local size,err = read(stream, ...)
	if not size then return nil,err end
	if stream.length then
		assert(stream:length() >= size, "invalid sizedbuffer size, stream is too short")
	end
	local value,err = stream:receive(size)
	if not value then return nil,err end
	return value
end

------------------------------------------------------------------------------

function serialize.array(value, size, value_t, ...)
	local serialize = assert(serialize[value_t], "unknown value type "..tostring(value_t).."")
	if size=='*' then
		size = #value
	end
	assert(size == #value, "provided array size doesn't match")
	local data,temp,err = ""
	for i=1,size do
		temp,err = serialize(value[i], ...)
		if not temp then return nil,err end
		data = data .. temp
	end
	return data
end

function write.array(stream, value, size, value_t, ...)
	local write = assert(write[value_t], "unknown value type "..tostring(value_t).."")
	if size=='*' then
		size = #value
	end
	assert(size == #value, "provided array size doesn't match")
	for i=1,size do
		local success,err = write(stream, value[i], ...)
		if not success then return nil,err end
	end
	return true
end

function read.array(stream, size, value_t, ...)
	local read = assert(read[value_t], "unknown value type "..tostring(value_t).."")
	local value = {}
	if size=='*' then
		assert(stream.length, "infinite arrays can only be read from buffers, not infinite streams")
		while stream:length() > 0 do
			local elem,err = read(stream, ...)
			if not elem then return nil,err end
			value[#value+1] = elem
		end
	else
		for i=1,size do
			local elem,err = read(stream, ...)
			if not elem then return nil,err end
			value[i] = elem
		end
	end
	return value
end

------------------------------------------------------------------------------

function serialize.sizedvalue(value, size_t, value_t)
	assert(type(size_t)=='table', "size type definition should be an array")
	assert(size_t[1], "size type definition array is empty")
	assert(type(value_t)=='table', "value type definition should be an array")
	assert(value_t[1], "value type definition array is empty")
	-- get serialization functions
	local size_serialize = assert(serialize[size_t[1]], "unknown size type "..tostring(size_t[1]).."")
	local value_serialize = assert(serialize[value_t[1]], "unknown value type "..tostring(value_t[1]).."")
	-- serialize value
	local svalue,err = value_serialize(value, unpack(value_t, 2))
	if not svalue then return nil,err end
	-- if value has trailing bytes append them
	if type(value)=='table' and value.__trailing_bytes then
		svalue = svalue .. value.__trailing_bytes
	end
	local size = #svalue
	local ssize,err = size_serialize(size, unpack(size_t, 2))
	if not ssize then return nil,err end
	return ssize .. svalue
end

function read.sizedvalue(stream, size_t, value_t)
	assert(type(size_t)=='table', "size type definition should be an array")
	assert(size_t[1], "size type definition array is empty")
	assert(type(value_t)=='table', "value type definition should be an array")
	assert(value_t[1], "value type definition array is empty")
	-- get serialization functions
	local size_read = assert(read[size_t[1]], "unknown size type "..tostring(size_t[1]).."")
	local value_read = assert(read[value_t[1]], "unknown size type "..tostring(value_t[1]).."")
	-- read size
	local size,err = size_read(stream, unpack(size_t, 2))
	if not size then return nil,err end
	-- read serialized value
	local svalue,err = stream:receive(size)
	if not svalue then return nil,err end
	-- build a buffer stream
	local bvalue = _M.buffer(svalue)
	-- read the value from the buffer
	local value,err = value_read(bvalue, unpack(value_t, 2))
	if not value then return nil,err end
	-- if the buffer is not empty save trailing bytes or generate an error
	if bvalue:length() > 0 then
		local msg = "trailing bytes in sized value not read by value serializer "..tostring(value_t[1])..""
		if type(value)=='table' then
			warning(msg)
			value.__trailing_bytes = bvalue:receive("*a")
		else
			error(msg)
		end
	end
	return value
end

------------------------------------------------------------------------------

function serialize.sizedarray(value, size_t, value_t)
	assert(type(size_t)=='table', "size type definition should be an array")
	assert(size_t[1], "size type definition array is empty")
	assert(type(value_t)=='table', "value type definition should be an array")
	assert(value_t[1], "value type definition array is empty")
	local data,temp,err = ""
	-- get serialization functions
	local size_serialize = assert(serialize[size_t[1]], "unknown size type "..tostring(size_t[1]).."")
	-- serialize size
	local size = #value
	temp,err = size_serialize(size, unpack(size_t, 2))
	if not temp then return nil,err end
	data = data .. temp
	-- serialize array itself
	temp,err = serialize.array(value, size, unpack(value_t))
	if not temp then return nil,err end
	data = data .. temp
	-- return size..array
	return data
end

function write.sizedarray(stream, value, size_t, value_t)
	assert(type(size_t)=='table', "size type definition should be an array")
	assert(size_t[1], "size type definition array is empty")
	assert(type(value_t)=='table', "value type definition should be an array")
	assert(value_t[1], "value type definition array is empty")
	local success,err
	-- get serialization functions
	local size_write = assert(write[size_t[1]], "unknown size type "..tostring(size_t[1]).."")
	-- write size
	local size = #value
	success,err = size_write(stream, size, unpack(size_t, 2))
	if not success then return nil,err end
	-- write array itself
	success,err = write.array(stream, value, size, unpack(value_t))
	if not success then return nil,err end
	-- return success
	return true
end

function read.sizedarray(stream, size_t, value_t)
	assert(type(size_t)=='table', "size type definition should be an array")
	assert(size_t[1], "size type definition array is empty")
	assert(type(value_t)=='table', "value type definition should be an array")
	assert(value_t[1], "value type definition array is empty")
	-- get serialization functions
	local size_read = assert(read[size_t[1]], "unknown size type "..tostring(size_t[1]).."")
	-- read size
	local size,err = size_read(stream, unpack(size_t, 2))
	if not size then return nil,err end
	-- read array
	local value,err = read.array(stream, size, unpack(value_t))
	if not value then return nil,err end
	-- return array
	return value
end

------------------------------------------------------------------------------

function serialize.cstring(value)
	assert(not value:find('\0'), "cannot serialize a string containing embedded zeros as a C string")
	return value..'\0'
end

function read.cstring(stream)
	local bytes = {}
	repeat
		local byte = read.uint8(stream)
		bytes[#bytes+1] = byte
	until byte==0
	return string.char(unpack(bytes, 1, #bytes-1)) -- remove trailing 0
end

------------------------------------------------------------------------------

function serialize.float(value)
	local libstruct = require 'struct'
	return libstruct.pack("f", value)
end

function read.float(stream)
	local data,err = stream:receive(4)
	if not data then
		return nil,err
	end
	local libstruct = require 'struct'
	return libstruct.unpack("f", data)
end

------------------------------------------------------------------------------

function serialize.bytes(value, count)
	assert(type(value)=='string', "bytes value is not a string")
	assert(#value==count, "byte string has not the correct length")
	return value
end

function read.bytes(stream, count)
	return stream:receive(count)
end

------------------------------------------------------------------------------

function serialize.bytes2hex(value, count)
	assert(type(value)=='string', "bytes2hex value is not a string")
	value = util.hex2bin(value)
	assert(#value==count, "byte string has not the correct length")
	return value
end

function read.bytes2hex(stream, count)
	local value,err = stream:receive(count)
	if not value then return value,err end
	return util.bin2hex(value)
end

------------------------------------------------------------------------------

function serialize.bytes2base32(value, count)
	assert(type(value)=='string', "bytes2base32 value is not a string")
	value = util.base322bin(value)
	assert(#value==count, "byte string has not the correct length")
	return value
end

function read.bytes2base32(stream, count)
	local value,err = stream:receive(count)
	if not value then return value,err end
	return util.bin2base32(value)
end

------------------------------------------------------------------------------

function serialize.boolean8(value)
	if type(value)=='boolean' then
		return serialize.uint8(value and 1 or 0)
	else
		return serialize.uint8(value)
	end
end

function read.boolean8(stream)
	local value,err = read.uint8(stream)
	if not value then
		return nil,err
	end
	if value==0 then
		return false
	elseif value==1 then
		return true
	else
		warning("boolean value is not 0 or 1, it's "..tostring(value))
		return value
	end
end

------------------------------------------------------------------------------

function serialize.struct(value, fields)
	local data = ""
	for _,field in ipairs(fields) do
		local name,type = field[1],field[2]
		local serialize = assert(serialize[type], "no function to read field of type "..tostring(type))
		local temp,err = serialize(value[name], select(3, unpack(field)))
		if not temp then return nil,err end
		data = data .. temp
	end
	return data
end

function write.struct(stream, value, fields)
	local data = ""
	for _,field in ipairs(fields) do
		local name,type = field[1],field[2]
		local write = assert(write[type], "no function to read field of type "..tostring(type))
		local success,err = write(stream, value[name], select(3, unpack(field)))
		if not success then return nil,err end
	end
	return true
end

function read.struct(stream, fields)
	local object = {}
	for _,field in ipairs(fields) do
		local name,type = field[1],field[2]
		local read = assert(read[type], "no function to read field of type "..tostring(type))
		local value,err = read(stream, select(3, unpack(field)))
		if value==nil then return nil,err end
		object[name] = value
	end
	return object
end

------------------------------------------------------------------------------

function serialize.fstruct(object, f, ...)
	local params = {n=select('#', ...), ...}
	local str = ""
	local wrapper = setmetatable({}, {
		__index = object,
		__call = function(self, field)
			return function(type, ...)
				local serialize = assert(serialize[type], "no function to serialize field of type "..tostring(type))
				local temp,err = serialize(object[field], ...)
				if not temp then coroutine.yield(nil, err) end
				str = str .. temp
			end
		end,
	})
	local coro = coroutine.wrap(function()
		f(wrapper, unpack(params, 1, params.n))
		return true
	end)
	local success,err = coro()
	if not success then return nil,err end
	return str
end

function write.fstruct(stream, object, f, ...)
	local params = {n=select('#', ...), ...}
	local wrapper = setmetatable({}, {
		__index = object,
		__call = function(self, field)
			return function(type, ...)
				local write = assert(write[type], "no function to write field of type "..tostring(type))
				local success,err = write(stream, object[field], ...)
				if not success then coroutine.yield(nil, err) end
			end
		end,
	})
	local coro = coroutine.wrap(function()
		f(wrapper, unpack(params, 1, params.n))
		return true
	end)
	local success,err = coro()
	if not success then return nil,err end
	return true
end

function read.fstruct(stream, f, ...)
	local params = {n=select('#', ...), ...}
	local object = {}
	local wrapper = setmetatable({}, {
		__index = object,
		__newindex = object,
		__call = function(self, field)
			return function(type, ...)
				local read = assert(read[type], "no function to read field of type "..tostring(type))
				local value,err = read(stream, ...)
				if value==nil then coroutine.yield(nil, err) end
				object[field] = value
			end
		end,
	})
	local coro = coroutine.wrap(function()
		f(wrapper, unpack(params, 1, params.n))
		return true
	end)
	local success,err = coro()
	if not success then return nil,err end
	return object
end

------------------------------------------------------------------------------

serialize.fields = serialize.struct

function read.fields(stream, object, fields)
	local part,err = read.struct(stream, fields)
	if not part then return nil,err end
	for k,v in pairs(part) do
		object[k] = v
	end
	return true
end

------------------------------------------------------------------------------

setmetatable(serialize, {__index=function(self,k)
	local struct = struct[k]
	if struct then
		local serialize = function(object)
			return _M.serialize.struct(object, struct)
		end
		self[k] = serialize
		return serialize
	end
	local fstruct = fstruct[k]
	if fstruct then
		local serialize = function(object, ...)
			return _M.serialize.fstruct(object, fstruct, ...)
		end
		self[k] = serialize
		return serialize
	end
	local alias = alias[k]
	if alias then
		assert(type(alias)=='table', "alias type definition should be an array")
		assert(alias[1], "alias type definition array is empty")
		local serialize = function(value)
			local alias_serialize = assert(serialize[alias[1]], "unknown alias type "..tostring(alias[1]).."")
			return alias_serialize(value, unpack(alias, 2))
		end
		self[k] = serialize
		return serialize
	end
end})

setmetatable(read, {__index=function(self,k)
	local struct = struct[k]
	if struct then
		local read = function(stream)
			return _M.read.struct(stream, struct)
		end
		self[k] = read
		return read
	end
	local fstruct = fstruct[k]
	if fstruct then
		local read = function(stream, ...)
			return _M.read.fstruct(stream, fstruct, ...)
		end
		self[k] = read
		return read
	end
	local alias = alias[k]
	if alias then
		assert(type(alias)=='table', "alias type definition should be an array")
		assert(alias[1], "alias type definition array is empty")
		local read = function(stream)
			local alias_read = assert(read[alias[1]], "unknown alias type "..tostring(alias[1]).."")
			return alias_read(stream, unpack(alias, 2))
		end
		self[k] = read
		return read
	end
end})

setmetatable(write, {__index=function(self,k)
	local struct = struct[k]
	if struct then
		local write = function(stream, object)
			return _M.write.struct(stream, object, struct)
		end
		self[k] = write
		return write
	end
	local fstruct = fstruct[k]
	if fstruct then
		local write = function(stream, object, ...)
			return _M.write.fstruct(stream, object, fstruct, ...)
		end
		self[k] = write
		return write
	end
	local alias = alias[k]
	if alias then
		assert(type(alias)=='table', "alias type definition should be an array")
		assert(alias[1], "alias type definition array is empty")
		local write = function(stream, value)
			local write = assert(write[alias[1]], "unknown alias type "..tostring(alias[1]).."")
			return write(stream, value, unpack(alias, 2))
		end
		self[k] = write
		return write
	end
	local serialize = serialize[k]
	if serialize then
		local write = function(stream, ...)
			local data,err = serialize(...)
			if not data then
				return nil,err
			end
			return stream:send(data)
		end
		self[k] = write
		return write
	end
end})

-- force function instanciation for all known types
for type in pairs(serialize) do
	local _ = write[type]
end
for type in pairs(struct) do
	local _ = write[type] -- this forces write and serialize creation
	local _ = read[type]
end

------------------------------------------------------------------------------

local buffer_methods = {}
local buffer_mt = {__index=buffer_methods}

function buffer(data)
	return setmetatable({data=data}, buffer_mt)
end

local smatch = string.match
function buffer_methods:receive(pattern, prefix)
	local prefix = prefix or ""
	local data = self.data
	if not data then
		return nil,"end of buffer"
	end
	if smatch(pattern, "^%*a") then
		self.data = nil
		return prefix..data
	elseif smatch(pattern, "^%*l") then
		return nil,"unsupported pattern"
	elseif type(pattern)=='number' then
		if pattern~=math.floor(pattern) or pattern < 0 then
			return nil,"invalid numerical pattern"
		end
		if pattern > #data then
			self.data = nil
			return nil,"end of buffer",prefix..data
		elseif pattern == #data then
			self.data = nil
			return prefix..data
		else
			self.data = data:sub(pattern+1)
			return prefix..data:sub(1,pattern)
		end
	else
		return nil,"unknown pattern"
	end
end

function buffer_methods:length()
	local data = self.data
	return data and #data or 0
end

------------------------------------------------------------------------------

local filestream_methods = {}
local filestream_mt = {__index=filestream_methods}

function filestream(file)
	if io.type(file)~='file' then
		error("bad argument #1 to filestream (file expected, got "..(io.type(file) or type(file))..")", 2)
	end
	return setmetatable({file=file}, filestream_mt)
end

local smatch = string.match
function filestream_methods:receive(pattern, prefix)
	local prefix = prefix or ""
	local file = self.file
	if smatch(pattern, "^%*a") then
		local data,err = file:read(pattern)
		if not data then return data,err end
		return prefix..data
	elseif smatch(pattern, "^%*l") then
		local data,err = file:read(pattern)
		if not data then return data,err end
		return prefix..data
	elseif type(pattern)=='number' then
		local data,err = file:read(pattern)
		if not data then return data,err end
		return prefix..data
	else
		return nil,"unknown pattern"
	end
end

function filestream_methods:send(data)
	return self.file:write(data)
end

function filestream_methods:length()
	local cur = self.file:seek()
	local len = self.file:seek('end')
	self.file:seek('set', cur)
	return len - cur
end

