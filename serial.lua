module(... or 'test', package.seeall)

local util
if _NAME=='test' then
	util = require("serial.util")
else
	util = require(_NAME..".util")
end

serialize = {}
read = {}
write = {}
struct = {}
fstruct = {}
alias = {}

_M.verbose = false

local function warning(message, level)
	if not level then
		level = 1
	end
	if _M.verbose then
		print(debug.traceback("warning: "..message, level+1))
	end
end

-- function serialize.typename(value, typeparams...) return string end
-- function write.typename(stream, value, typeparams...) return true end
-- function read.typename(stream, typeparams...) return value end

local err_stack = {}
local function push(x)
	err_stack[#err_stack+1] = x
end
local function pop()
	err_stack[#err_stack] = nil
end
local function ioerror(msg)
	local t = {}
	for i=#err_stack,1,-1 do
		t[#t+1] = err_stack[i]
	end
	local str = "io error:\n\tin "..table.concat(t, "\n\tin ").."\nwith message: "..msg
	err_stack = {}
	return str
end

local pack = function(...) return {n=select('#', ...), ...} end

------------------------------------------------------------------------------

function serialize.uint8(value)
	push 'uint8'
	local a = value
	if value < 0 or value >= 2^8 or math.floor(value)~=value then
		error("invalid value")
	end
	local data = string.char(a)
	pop()
	return data
end

function read.uint8(stream)
	push 'uint8'
	local data,err = stream:getbytes(1)
	if not data then return nil,ioerror(err) end
	if #data < 1 then return nil,"end of stream" end
	pop()
	return string.byte(data)
end

------------------------------------------------------------------------------

function serialize.sint8(value)
	push 'sint8'
	if value < -2^7 or value >= 2^7 or math.floor(value)~=value then
		error("invalid value")
	end
	if value < 0 then
		value = value + 2^8
	end
	local value,err = serialize.uint8(value)
	if not value then return nil,err end
	pop()
	return value
end

function read.sint8(stream)
	push 'sint8'
	local value,err = read.uint8(stream)
	if not value then return nil,err end
	if value >= 2^7 then
		value = value - 2^8
	end
	pop()
	return value
end

------------------------------------------------------------------------------

function serialize.uint16(value, endianness)
	push 'uint16'
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
	pop()
	return data
end

function read.uint16(stream, endianness)
	push 'uint16'
	local data,err = stream:getbytes(2)
	if not data then return nil,ioerror(err) end
	if #data < 2 then return nil,"end of stream" end
	local a,b
	if endianness=='le' then
		b,a = string.byte(data, 1, 2)
	elseif endianness=='be' then
		a,b = string.byte(data, 1, 2)
	else
		error("unknown endianness")
	end
	pop()
	return a * 256 + b
end

------------------------------------------------------------------------------

function serialize.sint16(value, endianness)
	push 'sint16'
	if value < -2^15 or value >= 2^15 or math.floor(value)~=value then
		error("invalid value")
	end
	if value < 0 then
		value = value + 2 ^ 16
	end
	local value,err = serialize.uint16(value, endianness)
	if not value then return nil,err end
	pop()
	return value
end

function read.sint16(stream, endianness)
	push 'sint16'
	local value,err = read.uint16(stream, endianness)
	if not value then return nil,err end
	if value >= 2^15 then
		value = value - 2^16
	end
	pop()
	return value
end

------------------------------------------------------------------------------

function serialize.uint32(value, endianness)
	push 'uint32'
	if type(value)~='number' then
		error("bad argument #1 to serialize.uint32 (number expected, got "..type(value)..")", 2)
	end
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
	pop()
	return data
end

function read.uint32(stream, endianness)
	push 'uint32'
	local data,err = stream:getbytes(4)
	if not data then return nil,ioerror(err) end
	if #data < 4 then return nil,"end of stream" end
	local a,b,c,d
	if endianness=='le' then
		d,c,b,a = string.byte(data, 1, 4)
	elseif endianness=='be' then
		a,b,c,d = string.byte(data, 1, 4)
	else
		error("unknown endianness")
	end
	pop()
	return ((a * 256 + b) * 256 + c) * 256 + d
end

------------------------------------------------------------------------------

function serialize.sint32(value, endianness)
	push 'sint32'
	if value < -2^31 or value >= 2^31 or math.floor(value)~=value then
		error("invalid value")
	end
	if value < 0 then
		value = value + 2^32
	end
	local value,err = serialize.uint32(value, endianness)
	if not value then return nil,err end
	pop()
	return value
end

function read.sint32(stream, endianness)
	push 'sint32'
	local value,err = read.uint32(stream, endianness)
	if not value then return nil,err end
	if value >= 2^31 then
		value = value - 2^32
	end
	pop()
	return value
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

function serialize.uint64(value, endianness)
	push 'uint64'
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
	pop()
	return data
end

function read.uint64(stream, endianness)
	push 'uint64'
	local data,err = stream:getbytes(8)
	if not data then return nil,ioerror(err) end
	if #data < 8 then return nil,"end of stream" end
	local a,b,c,d,e,f,g,h
	if endianness=='le' then
		h,g,f,e,d,c,b,a = string.byte(data, 1, 8)
	elseif endianness=='be' then
		a,b,c,d,e,f,g,h = string.byte(data, 1, 8)
	else
		error("unknown endianness")
	end
	local ma,mb,mc,md,me,mf,mg,mh = unpack(maxbytes.uint64)
	local value
	if a>ma or b>mb or c>mc or d>md or e>me or f>mf or g>mg or h>mh then
		-- uint64 as string is little-endian
		if endianness=='le' then
			value = data
		else
			value = data:reverse()
		end
	else
		value = ((((((a * 256 + b) * 256 + c) * 256 + d) * 256 + e) * 256 + f) * 256 + g) * 256 + h
	end
	pop()
	return value
end

------------------------------------------------------------------------------

function serialize.enum(value, enum, int_t, ...)
	push 'enum'
	if type(int_t)~='table' or select('#', ...)>=1 then
		int_t = {int_t, ...}
	end
	local ivalue
	if type(value)=='number' then
		ivalue = value
	else
		ivalue = enum[value]
	end
	assert(ivalue, "unknown enum string '"..tostring(value).."'")
	local serialize = assert(serialize[int_t[1]], "unknown integer type "..tostring(int_t[1]).."")
	local sdata,err = serialize(ivalue, unpack(int_t, 2))
	if not sdata then return nil,err end
	pop()
	return sdata
end

function read.enum(stream, enum, int_t, ...)
	push 'enum'
	if type(int_t)~='table' or select('#', ...)>=1 then
		int_t = {int_t, ...}
	end
	local read = assert(read[int_t[1]], "unknown integer type "..tostring(int_t[1]).."")
	local value,err = read(stream, unpack(int_t, 2))
	if not value then
		return nil,assert(err, "type '"..int_t[1].."' returned nil but no error")
	end
	local svalue = enum[value]
	if not svalue then
		warning("unknown enum number "..tostring(value)..(util.enum_names[enum] and (" for enum "..tostring(enum)) or "")..", keeping numerical value")
		svalue = value
	end
	pop()
	return svalue
end

------------------------------------------------------------------------------

local success,libbit = pcall(require, 'bit')
if success then

function serialize.flags(value, flagset, int_t, ...)
	push 'flags'
	if type(int_t)~='table' or select('#', ...)>=1 then
		int_t = {int_t, ...}
	end
	local ints = {}
	for flag,k in pairs(value) do
		assert(k==true, "flag has value other than true ("..tostring(k)..")")
		ints[#ints+1] = flagset[flag]
	end
	if #ints==0 then
		value = 0
	else
		value = libbit.bor(unpack(ints))
	end
	local serialize = assert(serialize[int_t[1]], "unknown integer type "..tostring(int_t[1]).."")
	local sdata,err = serialize(value, unpack(int_t, 2))
	if not sdata then return nil,err end
	pop()
	return sdata
end

function read.flags(stream, flagset, int_t, ...)
	push 'flags'
	if type(int_t)~='table' or select('#', ...)>=1 then
		int_t = {int_t, ...}
	end
	local read = assert(read[int_t[1]], "unknown integer type "..tostring(int_t[1]).."")
	local int,err = read(stream, unpack(int_t, 2))
	if not int then
		return nil,err
	end
	local value = {}
	for k,v in pairs(flagset) do
		-- ignore reverse or invalid mappings (allows use of same dict in enums)
		if type(v)=='number' and libbit.band(int, v) ~= 0 then
			value[k] = true
		end
	end
	pop()
	return value
end

end

------------------------------------------------------------------------------

function serialize.sizedbuffer(value, size_t, ...)
	push 'sizedbuffer'
	if type(size_t)~='table' or select('#', ...)>=1 then
		size_t = {size_t, ...}
	end
	local serialize = assert(serialize[size_t[1]], "unknown size type "..tostring(size_t[1]).."")
	local size = #value
	local ssize,err = serialize(size, unpack(size_t, 2))
	if not ssize then return nil,err end
	pop()
	return ssize .. value
end

function read.sizedbuffer(stream, size_t, ...)
	push 'sizedbuffer'
	if type(size_t)~='table' or select('#', ...)>=1 then
		size_t = {size_t, ...}
	end
	local read = assert(read[size_t[1]], "unknown size type "..tostring(size_t[1]).."")
	local size,err = read(stream, unpack(size_t, 2))
	if not size then return nil,err end
	if stream.length then
		assert(stream:length() >= size, "invalid sizedbuffer size, stream is too short")
	end
	local value,err = stream:getbytes(size)
	if not value then return nil,ioerror(err) end
	if #value < size then return nil,"end of stream" end
	pop()
	return value
end

------------------------------------------------------------------------------

function serialize.array(value, size, value_t, ...)
	push 'array'
	if type(value_t)~='table' or select('#', ...)>=1 then
		value_t = {value_t, ...}
	end
	local serialize = assert(serialize[value_t[1]], "unknown value type "..tostring(value_t[1]).."")
	if size=='*' then
		size = #value
	end
	assert(size == #value, "provided array size doesn't match")
	local data,temp,err = ""
	for i=1,size do
		temp,err = serialize(value[i], unpack(value_t, 2))
		if not temp then return nil,err end
		data = data .. temp
	end
	pop()
	return data
end

function write.array(stream, value, size, value_t, ...)
	push 'array'
	if type(value_t)~='table' or select('#', ...)>=1 then
		value_t = {value_t, ...}
	end
	local write = assert(write[value_t[1]], "unknown value type "..tostring(value_t[1]).."")
	if size=='*' then
		size = #value
	end
	assert(size == #value, "provided array size doesn't match")
	for i=1,size do
		local success,err = write(stream, value[i], unpack(value_t, 2))
		if not success then return nil,err end
	end
	pop()
	return true
end

function read.array(stream, size, value_t, ...)
	push 'array'
	if type(value_t)~='table' or select('#', ...)>=1 then
		value_t = {value_t, ...}
	end
	local read = assert(read[value_t[1]], "unknown value type "..tostring(value_t[1]).."")
	local value = {}
	if size=='*' then
		assert(stream.length, "infinite arrays can only be read from buffers, not infinite streams")
		while stream:length() > 0 do
			local elem,err = read(stream, unpack(value_t, 2))
			if not elem then return nil,err end
			value[#value+1] = elem
		end
	elseif type(size)=='number' then
		for i=1,size do
			local elem,err = read(stream, unpack(value_t, 2))
			if not elem then return nil,err end
			value[i] = elem
		end
	else
		error("size is neither '*' nor a number ("..tostring(size)..")")
	end
	pop()
	return value
end

------------------------------------------------------------------------------

function serialize.paddedvalue(value, size_t, padding, value_t, ...)
	push 'sizedvalue'
	if type(value_t)~='table' or select('#', ...)>=1 then
		value_t = {value_t, ...}
	end
	-- get serialization functions
	local size_serialize
	if type(size_t)=='table' then
		assert(size_t[1], "size type definition array is empty")
		size_serialize = assert(serialize[size_t[1]], "unknown size type "..tostring(size_t[1]).."")
	elseif type(size_t)=='number' then
		size_serialize = size_t
	else
		error("size_t should be a type definition array or a number")
	end
	assert(padding==nil or type(padding)=='string' and #padding==1, "padding should be nil or a single character")
	assert(type(value_t)=='table', "value type definition should be an array")
	assert(value_t[1], "value type definition array is empty")
	local value_serialize = assert(serialize[value_t[1]], "unknown value type "..tostring(value_t[1]).."")
	-- serialize value
	local svalue,err = value_serialize(value, unpack(value_t, 2))
	if not svalue then return nil,err end
	-- if value has trailing bytes append them
	if type(value)=='table' and value.__trailing_bytes then
		svalue = svalue .. value.__trailing_bytes
	end
	local size = #svalue
	if type(size_serialize)=='number' then
		if padding then
			-- check we don't exceed the padded size
			assert(size<=size_serialize, "value size exceeds padded size")
			svalue = svalue .. string.rep(padding, size_serialize-size)
		else
			assert(size==size_serialize, "value size doesn't match sizedvalue size")
		end
		return svalue
	else
		local ssize,err = size_serialize(size, unpack(size_t, 2))
		if not ssize then return nil,err end
		pop()
		return ssize .. svalue
	end
end

function read.paddedvalue(stream, size_t, padding, value_t, ...)
	push 'paddedvalue'
	if type(value_t)~='table' or select('#', ...)>=1 then
		value_t = {value_t, ...}
	end
	-- get serialization functions
	local size_read
	if type(size_t)=='table' then
		assert(size_t[1], "size type definition array is empty")
		size_read = assert(read[size_t[1]], "unknown size type "..tostring(size_t[1]).."")
	elseif type(size_t)=='number' then
		size_read = size_t
	else
		error("size type definition should be an array")
	end
	assert(type(value_t)=='table', "value type definition should be an array")
	assert(value_t[1], "value type definition array is empty")
	local value_read = assert(read[value_t[1]], "unknown value type "..tostring(value_t[1]).."")
	-- read size
	local size,err
	if type(size_read)=='number' then
		size = size_read
	else
		size,err = size_read(stream, unpack(size_t, 2))
	end
	if not size then return nil,err end
	-- read serialized value
	local svalue,err
	if size > 0 then
		svalue,err = stream:getbytes(size)
		if not svalue then return nil,ioerror(err) end
		if #svalue < size then return nil,"end of stream" end
	else
		svalue = ""
	end
	-- build a buffer stream
	local bvalue = _M.buffer(svalue)
	-- read the value from the buffer
	local value,err = value_read(bvalue, unpack(value_t, 2))
	if not value then return nil,err end
	-- if the buffer is not empty save trailing bytes or generate an error
	if bvalue:length() > 0 then
		local __trailing_bytes = bvalue:getbytes(bvalue:length())
		if padding then
			-- remove padding
			if padding=='\0' then
				__trailing_bytes = __trailing_bytes:match("^(.-)%z*$")
			else
				__trailing_bytes = __trailing_bytes:match("^(.-)%"..padding.."*$")
			end
		end
		if #__trailing_bytes > 0 then
			local msg = "trailing bytes in sized value not read by value serializer "..tostring(value_t[1])..""
			if type(value)=='table' then
				warning(msg)
				value.__trailing_bytes = __trailing_bytes
			else
				error(msg)
			end
		end
	end
	pop()
	return value
end

------------------------------------------------------------------------------

function serialize.sizedvalue(value, size_t, value_t, ...)
    push 'sizedvalue'
	local results = pack(serialize.paddedvalue(value, size_t, nil, value_t, ...))
    pop()
    return unpack(results, 1, results.n)
end

function read.sizedvalue(stream, size_t, value_t, ...)
    push 'sizedvalue'
	local results = pack(read.paddedvalue(stream, size_t, nil, value_t, ...))
    pop()
    return unpack(results, 1, results.n)
end

------------------------------------------------------------------------------

function serialize.sizedarray(value, size_t, value_t, ...)
	push 'sizedarray'
	if type(value_t)~='table' or select('#', ...)>=1 then
		value_t = {value_t, ...}
	end
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
	pop()
	return data
end

function write.sizedarray(stream, value, size_t, value_t, ...)
	push 'sizedarray'
	if type(value_t)~='table' or select('#', ...)>=1 then
		value_t = {value_t, ...}
	end
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
	pop()
	return true
end

function read.sizedarray(stream, size_t, value_t, ...)
	push 'sizedarray'
	if type(value_t)~='table' or select('#', ...)>=1 then
		value_t = {value_t, ...}
	end
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
	pop()
	return value
end

------------------------------------------------------------------------------

function serialize.cstring(value)
	push 'cstring'
	assert(not value:find('\0'), "cannot serialize a string containing embedded zeros as a C string")
	pop()
	return value..'\0'
end

function read.cstring(stream)
	push 'cstring'
	local bytes = {}
	repeat
		local byte = read.uint8(stream)
		bytes[#bytes+1] = byte
	until byte==0
	pop()
	return string.char(unpack(bytes, 1, #bytes-1)) -- remove trailing 0
end

------------------------------------------------------------------------------

local success,libstruct = pcall(require, 'struct')
if success then

function serialize.float(value, endianness)
	push 'float'
	local format
	if endianness=='le' then
		format = "<f"
	elseif endianness=='be' then
		format = ">f"
	else
		error("unknown endianness")
	end
	local data = libstruct.pack(format, value)
	if #data ~= 4 then
		error("struct library \"f\" format doesn't correspond to a 32 bits float")
	end
	pop()
	return data
end

function read.float(stream, endianness)
	push 'float'
	local format
	if endianness=='le' then
		format = "<f"
	elseif endianness=='be' then
		format = ">f"
	else
		error("unknown endianness")
	end
	local data,err = stream:getbytes(4)
	if not data then return nil,ioerror(err) end
	if #data < 4 then return nil,"end of stream" end
	pop()
	return libstruct.unpack(format, data)
end

else

local function grab_byte(v)
	return math.floor(v / 256), string.char(math.floor(v) % 256)
end

local function s2f_le(x)
	local sign = 1
	local mantissa = string.byte(x, 3) % 128
	for i = 2, 1, -1 do mantissa = mantissa * 256 + string.byte(x, i) end
	if string.byte(x, 4) > 127 then sign = -1 end
	local exponent = (string.byte(x, 4) % 128) * 2 + math.floor(string.byte(x, 3) / 128)
	if exponent == 0 then return 0 end
	mantissa = (math.ldexp(mantissa, -23) + 1) * sign
	return math.ldexp(mantissa, exponent - 127)
end

local function s2f_be(x)
	return s2f_le(x:reverse())
end

local function f2s_le(x)
	local sign = 0
	if x < 0 then sign = 1; x = -x end
	local mantissa, exponent = math.frexp(x)
	if x == 0 then -- zero
		mantissa = 0; exponent = 0
	else
		mantissa = (mantissa * 2 - 1) * math.ldexp(0.5, 24)
		exponent = exponent + 126
	end
	local v, byte = "" -- convert to bytes
	x, byte = grab_byte(mantissa); v = v..byte -- 7:0
	x, byte = grab_byte(x); v = v..byte -- 15:8
	x, byte = grab_byte(exponent * 128 + x); v = v..byte -- 23:16
	x, byte = grab_byte(sign * 128 + x); v = v..byte -- 31:24
	return v
end

local function f2s_be(x)
	return f2s_le(x):reverse()
end

function serialize.float(value, endianness)
	push 'float'
	local format
	if endianness=='le' then
		format = f2s_le
	elseif endianness=='be' then
		format = f2s_be
	else
		error("unknown endianness")
	end
	local data = format(value)
	if #data ~= 4 then
		error("struct library \"f\" format doesn't correspond to a 32 bits float")
	end
	pop()
	return data
end

function read.float(stream, endianness)
	push 'float'
	local format
	if endianness=='le' then
		format = s2f_le
	elseif endianness=='be' then
		format = s2f_be
	else
		error("unknown endianness")
	end
	local data,err = stream:getbytes(4)
	if not data then return nil,ioerror(err) end
	if #data < 4 then return nil,"end of stream" end
	pop()
	return format(data)
end

end

------------------------------------------------------------------------------

local success,libstruct = pcall(require, 'struct')
if success then

function serialize.double(value, endianness)
	push 'double'
	local format
	if endianness=='le' then
		format = "<d"
	elseif endianness=='be' then
		format = ">d"
	else
		error("unknown endianness")
	end
	local data = libstruct.pack(format, value)
	if #data ~= 8 then
		error("struct library \"f\" format doesn't correspond to a 64 bits float")
	end
	pop()
	return data
end

function read.double(stream, endianness)
	push 'double'
	local format
	if endianness=='le' then
		format = "<d"
	elseif endianness=='be' then
		format = ">d"
	else
		error("unknown endianness")
	end
	local data,err = stream:getbytes(8)
	if not data then return nil,ioerror(err) end
	if #data < 8 then return nil,"end of stream" end
	local value,err = libstruct.unpack(format, data)
	if not value then return nil,err end
	pop()
	return value
end

end

------------------------------------------------------------------------------

function serialize.bytes(value, count)
	push 'bytes'
	assert(type(value)=='string', "bytes value is not a string")
	assert(#value==count or count=='*', "byte string has not the correct length")
	pop()
	return value
end

function read.bytes(stream, count)
	push 'bytes'
	if count=='*' then
		assert(stream.length, "infinite arrays can only be read from buffers, not infinite streams")
		count = stream:length()
	end
	local data,err = stream:getbytes(count)
	if not data then return nil,ioerror(err) end
	if #data < count then return nil,"end of stream" end
	pop()
	return data
end

------------------------------------------------------------------------------

function serialize.bytes2hex(value, count)
	push 'bytes2hex'
	assert(type(value)=='string', "bytes2hex value is not a string")
	value = util.hex2bin(value)
	local err
	value,err = serialize.bytes(value, count)
	if not value then return nil,err end
	pop()
	return value
end

function read.bytes2hex(stream, count)
	push 'bytes2hex'
	local value,err = read.bytes(stream, count)
	if not value then return nil,err end
	pop()
	return util.bin2hex(value)
end

------------------------------------------------------------------------------

function serialize.bytes2base32(value, count)
	push 'bytes2base32'
	assert(type(value)=='string', "bytes2base32 value is not a string")
	value = util.base322bin(value)
	local err
	value,err = serialize.bytes(value, count)
	if not value then return nil,err end
	pop()
	return value
end

function read.bytes2base32(stream, count)
	push 'bytes2base32'
	local value,err = read.bytes(stream, count)
	if not value then return nil,err end
	pop()
	return util.bin2base32(value)
end

------------------------------------------------------------------------------

function serialize.boolean(value, int_t, ...)
	push 'boolean'
	if type(int_t)~='table' or select('#', ...)>=1 then
		int_t = {int_t, ...}
	end
	if type(value)=='boolean' then
		value = value and 1 or 0
	end
	local serialize = assert(serialize[int_t[1]], "unknown integer type "..tostring(int_t[1]).."")
	local sdata,err = serialize(value, unpack(int_t, 2))
	if not sdata then return nil,err end
	pop()
	return sdata
end

function read.boolean(stream, int_t, ...)
	push 'boolean'
	if type(int_t)~='table' or select('#', ...)>=1 then
		int_t = {int_t, ...}
	end
	local read = assert(read[int_t[1]], "unknown integer type "..tostring(int_t[1]).."")
	local value,err = read(stream, unpack(int_t, 2))
	if not value then return nil,err end
	local result
	if value==0 then
		result = false
	elseif value==1 then
		result = true
	else
		warning("boolean value is not 0 or 1, it's "..tostring(value))
		result = value
	end
	pop()
	return result
end

alias.boolean8 = {'boolean', 'uint8'}

------------------------------------------------------------------------------

function serialize._struct(value, fields)
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

function serialize.struct(value, fields)
	push 'struct'
	local data,err = serialize._struct(value, fields)
	if data==nil then return nil,err end
	pop()
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

function write.struct(stream, value, fields)
	push 'struct'
	local success,err = write._struct(stream, value, fields)
	if not success then return nil,err end
	pop()
	return true
end

function read._struct(stream, fields)
	local object = {}
	for _,field in ipairs(fields) do
		local name,type = field[1],field[2]
		push(name)
		local read = assert(read[type], "no function to read field of type "..tostring(type))
		local results = pack(read(stream, select(3, unpack(field))))
		if results[1]==nil then
			-- replace partial result (at position 3) with our own
			object[name] = results[3]
			return nil,results[2],object,unpack(results, 4, results.n)
		end
		object[name] = results[1]
		pop()
	end
	return object
end

function read.struct(stream, fields)
	push 'struct'
	local results = pack(read._struct(stream, fields))
	if not results[1] then return nil,unpack(results, 2, results.n) end
	pop()
	return results[1]
end

------------------------------------------------------------------------------

local cyield = coroutine.yield
local cwrap,unpack = coroutine.wrap,unpack
local token = {}

function serialize.fstruct(object, f, ...)
	push 'fstruct'
	local params = {n=select('#', ...), ...}
	local str = ""
	local wrapper = setmetatable({}, {
		__index = object,
		__newindex = object,
		__call = function(self, field, ...)
			if select('#', ...)>0 then
				local type = ...
				local serialize = serialize[type]
				if not serialize then error("no function to serialize field of type "..tostring(type)) end
				local temp,err = serialize(object[field], select(2, ...))
				if not temp then cyield(token, nil, err) end
				str = str .. temp
			else
				return function(type, ...)
					local serialize = serialize[type]
					if not serialize then error("no function to serialize field of type "..tostring(type)) end
					local temp,err = serialize(object[field], ...)
					if not temp then cyield(token, nil, err) end
					str = str .. temp
				end
			end
		end,
	})
	local coro = cwrap(function()
		f(wrapper, wrapper, unpack(params, 1, params.n))
		return token, true
	end)
	local results = pack(coro())
	while results[1]~=token do
		results = pack(coro(cyield(unpack(results, 1, results.n))))
	end
	if not results[2] then return nil,unpack(results, 3, results.n) end
	pop()
	return str
end

function write.fstruct(stream, object, f, ...)
	push 'fstruct'
	local params = {n=select('#', ...), ...}
	local wrapper = setmetatable({}, {
		__index = object,
		__newindex = object,
		__call = function(self, field, ...)
			if select('#', ...)>0 then
				local type = ...
				local write = write[type]
				if not write then error("no function to write field of type "..tostring(type)) end
				local success,err = write(stream, object[field], select(2, ...))
				if not success then cyield(token, nil, err) end
			else
				return function(type, ...)
					local write = write[type]
					if not write then error("no function to write field of type "..tostring(type)) end
					local success,err = write(stream, object[field], ...)
					if not success then cyield(token, nil, err) end
				end
			end
		end,
	})
	local coro = cwrap(function()
		f(wrapper, wrapper, unpack(params, 1, params.n))
		return token, true
	end)
	local results = pack(coro())
	while results[1]~=token do
		results = pack(coro(cyield(unpack(results, 1, results.n))))
	end
	if not results[2] then return nil,unpack(results, 3, results.n) end
	pop()
	return true
end

function read.fstruct(stream, f, ...)
	push 'fstruct'
	local params = {n=select('#', ...), ...}
	local object = {}
	local wrapper = setmetatable({}, {
		__index = object,
		__newindex = object,
		__call = function(self, field, ...)
			if select('#', ...)>0 then
				local type = ...
				local read = read[type]
				if not read then error("no function to read field of type "..tostring(type)) end
				local results = pack(read(stream, select(2, ...)))
				if results[1]==nil then
					-- replace field partial result (at position 3) with our own
					object[field] = results[3]
					cyield(token, nil, assert(results[2], "type '"..type.."' returned nil, but no error"), object, unpack(results, 4, results.n))
				end
				object[field] = results[1]
			else
				return --[[util.wrap("field "..field, ]]function(type, ...)
					local read = read[type]
					if not read then error("no function to read field of type "..tostring(type)) end
					local results = pack(read(stream, ...))
					if results[1]==nil then
						-- replace field partial result (at position 3) with our own
						object[field] = results[3]
						cyield(token, nil, assert(results[2], "type '"..type.."' returned nil, but no error"), object, unpack(results, 4, results.n))
					end
					object[field] = results[1]
				end--[[)]]
			end
		end,
	})
	local coro = cwrap(function()
		f(wrapper, wrapper, unpack(params, 1, params.n))
		return token, true
	end)
	local results = pack(coro())
	while results[1]~=token do
		results = pack(coro(cyield(unpack(results, 1, results.n))))
	end
	if not results[2] then return nil,unpack(results, 3, results.n) end
	pop()
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
			push("struct<"..tostring(k)..">")
			local value,err = _M.read._struct(stream, struct)
			if value==nil then return nil,err end
			pop()
			return value
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
			push("struct<"..tostring(k)..">")
			local result,err = _M.write.struct(stream, object, struct)
			if not result then return nil,err end
			pop()
			return result
		end
		local wrapper = util.wrap("write."..k, write)
		self[k] = wrapper
		return wrapper
	end
	local fstruct = fstruct[k]
	if fstruct then
		local write = function(stream, object, ...)
			return select(1, _M.write.fstruct(stream, object, fstruct, ...))
		end
		local wrapper = util.wrap("write."..k, write)
		self[k] = wrapper
		return wrapper
	end
	local alias = alias[k]
	if alias then
		assert(type(alias)=='table', "alias type definition should be an array")
		assert(alias[1], "alias type definition array is empty")
		local write = function(stream, value)
			local write = assert(write[alias[1]], "unknown alias type "..tostring(alias[1]).."")
			local wrapper = util.wrap("write."..alias[1], write)
			return select(1, wrapper(stream, value, unpack(alias, 2)))
		end
		local wrapper = util.wrap("write."..k, write)
		self[k] = wrapper
		return wrapper
	end
	local serialize = serialize[k]
	if serialize then
		local write = function(stream, ...)
			local data,err = serialize(...)
			if not data then
				return nil,err
			end
			local written,err = stream:putbytes(data)
			if not written then return nil,ioerror(err) end
			return true
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
	return setmetatable({data=data or ""}, buffer_mt)
end

function buffer_methods:getbytes(nbytes)
	local result
	if nbytes >= #self.data then
		result,self.data = self.data,""
	else
		result,self.data = self.data:sub(1, nbytes),self.data:sub(nbytes+1)
	end
	return result
end

function buffer_methods:putbytes(data)
	self.data = self.data..data
	return #data
end

function buffer_methods:length()
	return #self.data
end

------------------------------------------------------------------------------

local filestream_methods = {}
local filestream_mt = {__index=filestream_methods}

function filestream(file)
	-- assume the passed object behaves like a file
--	if io.type(file)~='file' then
--		error("bad argument #1 to filestream (file expected, got "..(io.type(file) or type(file))..")", 2)
--	end
	return setmetatable({file=file}, filestream_mt)
end

function filestream_methods:getbytes(nbytes)
	assert(type(nbytes)=='number')
	local data = ""
	while #data < nbytes do
		local bytes,err = self.file:read(nbytes - #data)
		-- eof
		if bytes==nil and err==nil then break end
		-- error
		if not bytes then return nil,err end
		-- accumulate bytes
		data = data..bytes
	end
	return data
end

function filestream_methods:putbytes(data)
	return self.file:write(data)
end

function filestream_methods:length()
	local cur = self.file:seek()
	local len = self.file:seek('end')
	self.file:seek('set', cur)
	return len - cur
end

------------------------------------------------------------------------------

local tcpstream_methods = {}
local tcpstream_mt = {__index=tcpstream_methods}

function tcpstream(socket)
	-- assumes the passed object behaves like a luasocket TCP socket
--	if io.type(file)~='file' then
--		error("bad argument #1 to filestream (file expected, got "..(io.type(file) or type(file))..")", 2)
--	end
	return setmetatable({socket=socket}, tcpstream_mt)
end

function tcpstream_methods:getbytes(nbytes)
	assert(type(nbytes)=='number')
	local data = ""
	while #data < nbytes do
		local bytes,err = self.socket:receive(nbytes - #data)
		-- error
		if not bytes then return nil,err end
		-- eof
		if #bytes==0 then break end
		-- accumulate bytes
		data = data..bytes
	end
	return data
end

function tcpstream_methods:putbytes(data)
	assert(type(data)=='string')
	local total = 0
	local written,err = self.socket:send(data)
	while written and written < #data do
		total = total + written
		data = data:sub(#written + 1)
		written,err = self.socket:send(data)
	end
	if not written then return nil,err end
	total = total + written
	return total
end

------------------------------------------------------------------------------

if _NAME=='test' then

-- use random numbers to improve coverage without trying all values, but make
-- sure tests are repeatable
math.randomseed(0)

local function randombuffer(size)
	local t = {}
	for i=1,size do
		t[i] = math.random(0, 255)
	end
	return string.char(unpack(t))
end

-- uint8

assert(_M.read.uint8(_M.buffer("\042"))==42)
assert(_M.read.uint8(_M.buffer("\242"))==242)

-- sint8

assert(_M.read.sint8(_M.buffer("\042"))==42)
assert(_M.read.sint8(_M.buffer("\242"))==-14)

-- uint16

assert(_M.read.uint16(_M.buffer("\037\042"), 'le')==10789)
assert(_M.read.uint16(_M.buffer("\237\042"), 'le')==10989)
assert(_M.read.uint16(_M.buffer("\037\242"), 'le')==61989)
assert(_M.read.uint16(_M.buffer("\237\242"), 'le')==62189)

assert(_M.read.uint16(_M.buffer("\037\042"), 'be')==9514)
assert(_M.read.uint16(_M.buffer("\237\042"), 'be')==60714)
assert(_M.read.uint16(_M.buffer("\037\242"), 'be')==9714)
assert(_M.read.uint16(_M.buffer("\237\242"), 'be')==60914)

-- sint16

assert(_M.read.sint16(_M.buffer("\037\042"), 'le')==10789)
assert(_M.read.sint16(_M.buffer("\237\042"), 'le')==10989)
assert(_M.read.sint16(_M.buffer("\037\242"), 'le')==-3547)
assert(_M.read.sint16(_M.buffer("\237\242"), 'le')==-3347)

assert(_M.read.sint16(_M.buffer("\037\042"), 'be')==9514)
assert(_M.read.sint16(_M.buffer("\237\042"), 'be')==-4822)
assert(_M.read.sint16(_M.buffer("\037\242"), 'be')==9714)
assert(_M.read.sint16(_M.buffer("\237\242"), 'be')==-4622)

-- uint32

assert(_M.read.uint32(_M.buffer("\037\000\000\042"), 'le')==704643109)
assert(_M.read.uint32(_M.buffer("\037\000\000\242"), 'le')==4060086309)
assert(_M.read.uint32(_M.buffer("\237\000\000\042"), 'le')==704643309)
assert(_M.read.uint32(_M.buffer("\237\000\000\242"), 'le')==4060086509)

assert(_M.read.uint32(_M.buffer("\037\000\000\042"), 'be')==620757034)
assert(_M.read.uint32(_M.buffer("\037\000\000\242"), 'be')==620757234)
assert(_M.read.uint32(_M.buffer("\237\000\000\042"), 'be')==3976200234)
assert(_M.read.uint32(_M.buffer("\237\000\000\242"), 'be')==3976200434)

-- sint32

assert(_M.read.sint32(_M.buffer("\037\000\000\042"), 'le')==704643109)
assert(_M.read.sint32(_M.buffer("\037\000\000\242"), 'le')==-234880987)
assert(_M.read.sint32(_M.buffer("\237\000\000\042"), 'le')==704643309)
assert(_M.read.sint32(_M.buffer("\237\000\000\242"), 'le')==-234880787)

assert(_M.read.sint32(_M.buffer("\037\000\000\042"), 'be')==620757034)
assert(_M.read.sint32(_M.buffer("\037\000\000\242"), 'be')==620757234)
assert(_M.read.sint32(_M.buffer("\237\000\000\042"), 'be')==-318767062)
assert(_M.read.sint32(_M.buffer("\237\000\000\242"), 'be')==-318766862)

-- uint64

assert(_M.read.uint64(_M.buffer("\000\000\000\000\037\000\000\042"), 'le')=="\000\000\000\000\037\000\000\042")
assert(_M.read.uint64(_M.buffer("\000\000\000\000\037\000\000\242"), 'le')=="\000\000\000\000\037\000\000\242")
assert(_M.read.uint64(_M.buffer("\000\000\000\000\237\000\000\042"), 'le')=="\000\000\000\000\237\000\000\042")
assert(_M.read.uint64(_M.buffer("\000\000\000\000\237\000\000\242"), 'le')=="\000\000\000\000\237\000\000\242")

assert(_M.read.uint64(_M.buffer("\000\000\000\000\037\000\000\042"), 'be')==620757034)
assert(_M.read.uint64(_M.buffer("\000\000\000\000\037\000\000\242"), 'be')==620757234)
assert(_M.read.uint64(_M.buffer("\000\000\000\000\237\000\000\042"), 'be')==3976200234)
assert(_M.read.uint64(_M.buffer("\000\000\000\000\237\000\000\242"), 'be')==3976200434)

assert(_M.read.uint64(_M.buffer("\000\000\000\000\037\000\000\042"), 'le')=="\000\000\000\000\037\000\000\042")
assert(_M.read.uint64(_M.buffer("\000\000\000\000\037\000\000\242"), 'le')=="\000\000\000\000\037\000\000\242")
assert(_M.read.uint64(_M.buffer("\000\000\000\000\237\000\000\042"), 'le')=="\000\000\000\000\237\000\000\042")
assert(_M.read.uint64(_M.buffer("\000\000\000\000\237\000\000\242"), 'le')=="\000\000\000\000\237\000\000\242")

assert(_M.read.uint64(_M.buffer("\000\000\000\000\037\000\000\042"), 'be')==620757034)
assert(_M.read.uint64(_M.buffer("\000\000\000\000\037\000\000\242"), 'be')==620757234)
assert(_M.read.uint64(_M.buffer("\000\000\000\000\237\000\000\042"), 'be')==3976200234)
assert(_M.read.uint64(_M.buffer("\000\000\000\000\237\000\000\242"), 'be')==3976200434)

assert(_M.read.uint64(_M.buffer("\037\000\000\042\000\000\000\000"), 'le')==704643109)
assert(_M.read.uint64(_M.buffer("\037\000\000\242\000\000\000\000"), 'le')==4060086309)
assert(_M.read.uint64(_M.buffer("\237\000\000\042\000\000\000\000"), 'le')==704643309)
assert(_M.read.uint64(_M.buffer("\237\000\000\242\000\000\000\000"), 'le')==4060086509)

assert(_M.read.uint64(_M.buffer("\037\000\000\042\000\000\000\000"), 'be')=="\000\000\000\000\042\000\000\037")
assert(_M.read.uint64(_M.buffer("\037\000\000\242\000\000\000\000"), 'be')=="\000\000\000\000\242\000\000\037")
assert(_M.read.uint64(_M.buffer("\237\000\000\042\000\000\000\000"), 'be')=="\000\000\000\000\042\000\000\237")
assert(_M.read.uint64(_M.buffer("\237\000\000\242\000\000\000\000"), 'be')=="\000\000\000\000\242\000\000\237")

assert(_M.read.uint64(_M.buffer("\037\000\000\042\000\000\000\000"), 'le')==704643109)
assert(_M.read.uint64(_M.buffer("\037\000\000\242\000\000\000\000"), 'le')==4060086309)
assert(_M.read.uint64(_M.buffer("\237\000\000\042\000\000\000\000"), 'le')==704643309)
assert(_M.read.uint64(_M.buffer("\237\000\000\242\000\000\000\000"), 'le')==4060086509)

assert(_M.read.uint64(_M.buffer("\037\000\000\042\000\000\000\000"), 'be')=="\000\000\000\000\042\000\000\037")
assert(_M.read.uint64(_M.buffer("\037\000\000\242\000\000\000\000"), 'be')=="\000\000\000\000\242\000\000\037")
assert(_M.read.uint64(_M.buffer("\237\000\000\042\000\000\000\000"), 'be')=="\000\000\000\000\042\000\000\237")
assert(_M.read.uint64(_M.buffer("\237\000\000\242\000\000\000\000"), 'be')=="\000\000\000\000\242\000\000\237")

assert(_M.read.uint64(_M.buffer("\000\000\000\037\042\000\000\000"), 'le')==181009383424)
assert(_M.read.uint64(_M.buffer("\000\000\000\037\242\000\000\000"), 'le')==1040002842624)
assert(_M.read.uint64(_M.buffer("\000\000\000\237\042\000\000\000"), 'le')==184364826624)
assert(_M.read.uint64(_M.buffer("\000\000\000\237\242\000\000\000"), 'le')==1043358285824)

assert(_M.read.uint64(_M.buffer("\000\000\000\037\042\000\000\000"), 'be')==159618433024)
assert(_M.read.uint64(_M.buffer("\000\000\000\037\242\000\000\000"), 'be')==162973876224)
assert(_M.read.uint64(_M.buffer("\000\000\000\237\042\000\000\000"), 'be')==1018611892224)
assert(_M.read.uint64(_M.buffer("\000\000\000\237\242\000\000\000"), 'be')==1021967335424)

assert(_M.read.uint64(_M.buffer("\000\000\000\037\042\000\000\000"), 'le')==181009383424)
assert(_M.read.uint64(_M.buffer("\000\000\000\037\242\000\000\000"), 'le')==1040002842624)
assert(_M.read.uint64(_M.buffer("\000\000\000\237\042\000\000\000"), 'le')==184364826624)
assert(_M.read.uint64(_M.buffer("\000\000\000\237\242\000\000\000"), 'le')==1043358285824)

assert(_M.read.uint64(_M.buffer("\000\000\000\037\042\000\000\000"), 'be')==159618433024)
assert(_M.read.uint64(_M.buffer("\000\000\000\037\242\000\000\000"), 'be')==162973876224)
assert(_M.read.uint64(_M.buffer("\000\000\000\237\042\000\000\000"), 'be')==1018611892224)
assert(_M.read.uint64(_M.buffer("\000\000\000\237\242\000\000\000"), 'be')==1021967335424)

assert(_M.read.uint64(_M.buffer("\037\000\000\000\000\000\000\042"), 'le')=="\037\000\000\000\000\000\000\042")
assert(_M.read.uint64(_M.buffer("\037\000\000\000\000\000\000\242"), 'le')=="\037\000\000\000\000\000\000\242")
assert(_M.read.uint64(_M.buffer("\237\000\000\000\000\000\000\042"), 'le')=="\237\000\000\000\000\000\000\042")
assert(_M.read.uint64(_M.buffer("\237\000\000\000\000\000\000\242"), 'le')=="\237\000\000\000\000\000\000\242")

assert(_M.read.uint64(_M.buffer("\037\000\000\000\000\000\000\042"), 'be')=="\042\000\000\000\000\000\000\037")
assert(_M.read.uint64(_M.buffer("\037\000\000\000\000\000\000\242"), 'be')=="\242\000\000\000\000\000\000\037")
assert(_M.read.uint64(_M.buffer("\237\000\000\000\000\000\000\042"), 'be')=="\042\000\000\000\000\000\000\237")
assert(_M.read.uint64(_M.buffer("\237\000\000\000\000\000\000\242"), 'be')=="\242\000\000\000\000\000\000\237")

assert(_M.read.uint64(_M.buffer("\037\000\000\000\000\000\000\042"), 'le')=="\037\000\000\000\000\000\000\042")
assert(_M.read.uint64(_M.buffer("\037\000\000\000\000\000\000\242"), 'le')=="\037\000\000\000\000\000\000\242")
assert(_M.read.uint64(_M.buffer("\237\000\000\000\000\000\000\042"), 'le')=="\237\000\000\000\000\000\000\042")
assert(_M.read.uint64(_M.buffer("\237\000\000\000\000\000\000\242"), 'le')=="\237\000\000\000\000\000\000\242")

assert(_M.read.uint64(_M.buffer("\037\000\000\000\000\000\000\042"), 'be')=="\042\000\000\000\000\000\000\037")
assert(_M.read.uint64(_M.buffer("\037\000\000\000\000\000\000\242"), 'be')=="\242\000\000\000\000\000\000\037")
assert(_M.read.uint64(_M.buffer("\237\000\000\000\000\000\000\042"), 'be')=="\042\000\000\000\000\000\000\237")
assert(_M.read.uint64(_M.buffer("\237\000\000\000\000\000\000\242"), 'be')=="\242\000\000\000\000\000\000\237")

-- enum

local foo_e = util.enum{
	bar = 1,
	baz = 2,
}

assert(_M.read.enum(_M.buffer("\001"), foo_e, 'uint8')=='bar')
assert(_M.read.enum(_M.buffer("\002\000"), foo_e, 'uint16', 'le')=='baz')

-- flags

local foo_f = {
	bar = 1,
	baz = 2,
}

local value = _M.read.flags(_M.buffer("\001"), foo_e, 'uint8')
assert(value.bar==true and next(value, next(value))==nil)
local value = _M.read.flags(_M.buffer("\003\000"), foo_e, 'uint16', 'le')
assert(value.bar==true and value.baz==true and next(value, next(value, next(value)))==nil)

-- bytes

assert(_M.read.bytes(_M.buffer("fo"), 2)=='fo')
assert(_M.read.bytes(_M.buffer("foo"), 2)=='fo')

-- sizedbuffer

assert(_M.read.sizedbuffer(_M.buffer("\002fo"), 'uint8')=='fo')
assert(_M.read.sizedbuffer(_M.buffer("\002\000foo"), 'uint16', 'le')=='fo')

-- array

local value = _M.read.array(_M.buffer("\037\042"), 2, 'uint8')
assert(value[1]==37 and value[2]==42 and next(value, next(value, next(value)))==nil)
local value = _M.read.array(_M.buffer("\000\042\000\037"), '*', 'uint16', 'be')
assert(value[1]==42 and value[2]==37 and next(value, next(value, next(value)))==nil)

-- paddedvalue

assert(_M.read.paddedvalue(_M.buffer("\037\000\000"), 3, '\000', 'uint8')==37)
assert(_M.read.paddedvalue(_M.buffer("\004\042\000\000\000"), {'uint8'}, '\000', 'uint8')==42)

-- sizedvalue

local value = _M.read.sizedvalue(_M.buffer("\037\000\000"), 2, 'array', '*', 'uint8')
assert(value[1]==37 and value[2]==0 and next(value, next(value, next(value)))==nil)
assert(_M.read.sizedvalue(_M.buffer("\000\004foobar"), {'uint16', 'be'}, 'bytes', '*')=="foob")

-- sizedarray

local value = _M.read.sizedarray(_M.buffer("\002\037\042\000"), {'uint8'}, 'uint8')
assert(value[1]==37 and value[2]==42 and next(value, next(value, next(value)))==nil)
local value = _M.read.sizedarray(_M.buffer("\002\000\000\037\000\042\038"), {'uint16', 'le'}, 'uint16', 'be')
assert(value[1]==37 and value[2]==42 and next(value, next(value, next(value)))==nil)
local value = _M.read.sizedarray(_M.buffer("\002\000\000\037\000\042\038"), {'uint16', 'le'}, {'uint16', 'be'})
assert(value[1]==37 and value[2]==42 and next(value, next(value, next(value)))==nil)

-- cstring

assert(_M.read.cstring(_M.buffer("foo\000bar"))=="foo")

-- float

--print(string.byte(_M.serialize.float(-37e-12, 'le'), 1, 4))

assert(_M.serialize.float(37e12, 'le')=='\239\154\006\086')
assert(_M.serialize.float(-3.1953823392725e-34, 'le')=='\157\094\212\135')
assert(_M.read.float(_M.buffer("\000\000\000\000"), 'le')==0)
assert(_M.read.float(_M.buffer("\000\000\128\063"), 'le')==1)
assert(_M.read.float(_M.buffer("\000\000\000\064"), 'le')==2)
assert(_M.read.float(_M.buffer("\000\000\040\066"), 'le')==42)
assert(_M.read.float(_M.buffer("\239\154\006\086"), 'le')==36999998210048) -- best approx for 37e12
assert(_M.read.float(_M.buffer("\000\000\000\063"), 'le')==0.5)
assert(math.abs(_M.read.float(_M.buffer("\010\215\163\060"), 'le') / 0.02 - 1) < 1e-7)
assert(math.abs(_M.read.float(_M.buffer("\076\186\034\046"), 'le') / 37e-12 - 1) < 1e-8)
assert(_M.read.float(_M.buffer("\000\000\128\191"), 'le')==-1)
assert(_M.read.float(_M.buffer("\000\000\000\192"), 'le')==-2)
assert(_M.read.float(_M.buffer("\000\000\040\194"), 'le')==-42)
assert(math.abs(_M.read.float(_M.buffer("\239\154\006\214"), 'le') / -37e12 - 1) < 1e-7)
assert(math.abs(_M.read.float(_M.buffer("\076\186\034\174"), 'le') / -37e-12 - 1) < 1e-8)

-- double
-- :TODO:

-- bytes2hex

assert(_M.read.bytes2hex(_M.buffer("fo"), 2)=='666F')
assert(_M.read.bytes2hex(_M.buffer("foo"), 2)=='666F')

-- bytes2base32

assert(_M.read.bytes2base32(_M.buffer("fooba"), 5)=='MZXW6YTB')
assert(_M.read.bytes2base32(_M.buffer("foobar"), 5)=='MZXW6YTB')

-- boolean

assert(_M.read.boolean(_M.buffer("\000"), 'uint8')==false)
assert(_M.read.boolean(_M.buffer("\000\001"), 'uint16', 'be')==true)
assert(_M.read.boolean(_M.buffer("\002\000"), 'sint16', 'le')==2)

-- boolean8

assert(_M.read.boolean8(_M.buffer("\000"))==false)
assert(_M.read.boolean8(_M.buffer("\001"))==true)
assert(_M.read.boolean8(_M.buffer("\002\000"))==2)

-- struct

local foo_s = {
	{'foo', 'uint8'},
	{'bar', 'uint16', 'be'},
}
_M.struct.foo_s = foo_s

local value = _M.read.foo_s(_M.buffer("\001\002\003\004"))
assert(value.foo==1 and value.bar==515 and next(value, next(value, next(value)))==nil)

-- fstruct

function _M.fstruct.foo_s(self)
	self 'foo' ('uint8')
	self 'bar' ('uint16', 'be')
end

local value = _M.read.foo_s(_M.buffer("\001\002\003\004"))
assert(value.foo==1 and value.bar==515 and next(value, next(value, next(value)))==nil)

-- fields

local value = {baz=0}
assert(_M.read.fields(_M.buffer("\001\002\003\004"), value, foo_s))
assert(value.baz==0 and value.foo==1 and value.bar==515 and next(value, next(value, next(value, next(value))))==nil)

-- filestream

do
	require 'io'
	local file = io.tmpfile()
	local out = _M.filestream(file)
	_M.write.bytes(out, "foo", 3)
	_M.write.cstring(out, "bar")
	file:seek('set', 0)
	local in_ = _M.filestream(file)
	assert(_M.read.cstring(in_)=="foobar")
	file:close()
end

-- tcp stream

do
	require 'socket'
	local server,port
	for i=1,10 do
		port = 50000+i
		server = socket.bind('*', port)
		if server then break end
	end
	if server then
		local a = socket.connect('127.0.0.1', port)
		local b = server:accept()
		local out = _M.tcpstream(a)
		_M.write.bytes(out, "foo", 3)
		_M.write.cstring(out, "bar")
		local in_ = _M.tcpstream(b)
		a:send("foo")
		assert(_M.read.cstring(in_)=="foobar")
	else
		print("could not test tcp streams")
	end
end

print("all tests passed successfully")

end

--[[
Copyright (c) 2009-2010 Jérôme Vuarand

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]

-- vi: ts=4 sts=4 sw=4 noet enc=utf-8
