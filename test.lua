require 'serial'

local enum_dict = {
	name1 = 1, [1] = 'name1',
	name2 = 2, [2] = 'name2',
}

local flags_dict = {
	flag1 = 1,
	flag2 = 2,
	flag3 = 4,
	flag12 = 1 + 2,
}

local buffer_string = "Hello World!"

local struct_desc = {
	{'name', 'cstring'},
	{'value', 'uint32', 'le'},
}

local fstruct_closure1 = function(value, declare_field)
	declare_field('name', 'cstring')
	declare_field('value', 'uint32', 'le')
end

local fstruct_closure2 = function(self)
	self 'name' ('cstring')
	self 'value' ('uint32', 'le')
end

local fstruct_object = {
	name = "foo",
	value = 42,
}

assert(serial.serialize.uint8(0x00)==string.char(0x00))
assert(serial.serialize.uint8(0x55)==string.char(0x55))
assert(serial.serialize.uint8(0xaa)==string.char(0xaa))
assert(serial.serialize.uint8(0xff)==string.char(0xff))

assert(serial.serialize.sint8(-128)==string.char(0x80))
assert(serial.serialize.sint8(-1)==string.char(0xff))
assert(serial.serialize.sint8(0)==string.char(0x00))
assert(serial.serialize.sint8(1)==string.char(0x01))
assert(serial.serialize.sint8(127)==string.char(0x7f))

assert(serial.serialize.uint16(0xbeef, 'le')==string.char(0xef, 0xbe))
assert(serial.serialize.uint16(0xbeef, 'be')==string.char(0xbe, 0xef))

assert(serial.serialize.sint16(-32768, 'be')==string.char(0x80, 0x00))
assert(serial.serialize.sint16(-1, 'be')==string.char(0xff, 0xff))
assert(serial.serialize.sint16(0, 'be')==string.char(0x00, 0x00))
assert(serial.serialize.sint16(1, 'be')==string.char(0x00, 0x01))
assert(serial.serialize.sint16(32767, 'be')==string.char(0x7f, 0xff))

assert(serial.serialize.uint32(0xdeadbeef, 'le')==string.char(0xef, 0xbe, 0xad, 0xde))
assert(serial.serialize.uint32(0xdeadbeef, 'be')==string.char(0xde, 0xad, 0xbe, 0xef))

assert(serial.serialize.sint32(-2147483648, 'be')==string.char(0x80, 0x00, 0x00, 0x00))
assert(serial.serialize.sint32(-1, 'be')==string.char(0xff, 0xff, 0xff, 0xff))
assert(serial.serialize.sint32(0, 'be')==string.char(0x00, 0x00, 0x00, 0x00))
assert(serial.serialize.sint32(1, 'be')==string.char(0x00, 0x00, 0x00, 0x01))
assert(serial.serialize.sint32(2147483647, 'be')==string.char(0x7f, 0xff, 0xff, 0xff))

assert(serial.serialize.uint64(0x0010feed * 2^32 + 0xdeadbeef, 'le')==string.char(0xef, 0xbe, 0xad, 0xde, 0xed, 0xfe, 0x10, 0x00))
assert(serial.serialize.uint64(0x0010feed * 2^32 + 0xdeadbeef, 'be')==string.char(0x00, 0x10, 0xfe, 0xed, 0xde, 0xad, 0xbe, 0xef))

assert(serial.serialize.enum('name1', enum_dict, {'uint8'})==string.char(0x01))
assert(serial.serialize.enum('name2', enum_dict, 'uint16', 'le')==string.char(0x02, 0x00))

if pcall(require, 'bit') then

assert(serial.serialize.flags({flag1=true}, flags_dict, {'uint8'})==string.char(0x01))
assert(serial.serialize.flags({flag1=true, flag3=true}, flags_dict, 'uint8')==string.char(0x05))
assert(serial.serialize.flags({flag2=true, flag12=true}, flags_dict, 'uint16', 'le')==string.char(0x03, 0x00))

end

assert(serial.serialize.sizedbuffer(buffer_string, 'uint8')==string.char(#buffer_string)..buffer_string)

assert(serial.serialize.array({42, 37}, 2, 'uint8')==string.char(42, 37))
assert(serial.serialize.array({0xdead, 0xbeef, 0xd00d, 0xface}, 4, 'uint16', 'be')==string.char(0xde, 0xad, 0xbe, 0xef, 0xd0, 0x0d, 0xfa, 0xce))

assert(serial.serialize.sizedvalue(42, {'uint8'}, 'uint64', 'le')==string.char(8, 42, 0, 0, 0, 0, 0, 0, 0))
assert(serial.serialize.sizedvalue(buffer_string, {'uint16', 'le'}, 'cstring')==string.char(#buffer_string+1, 0)..buffer_string..'\0')
assert(serial.serialize.sizedvalue({
	name = "foo",
	value = 42,
}, {'uint8'}, 'struct', struct_desc)==string.char(8).."foo"..'\0'..string.char(42, 0, 0, 0))

assert(serial.serialize.sizedarray({42, 37}, {'uint16', 'le'}, 'uint8')==string.char(2, 0, 42, 37))

assert(serial.serialize.cstring(buffer_string)==buffer_string..'\0')

if pcall(require, 'struct') then

assert(serial.serialize.float(42.37, 'le')==string.char(0xe1, 0x7a, 0x29, 0x42))
assert(serial.serialize.float(42.37, 'be')==string.char(0x42, 0x29, 0x7a, 0xe1))
assert(serial.serialize.double(42.37, 'le')==string.char(0x8F, 0xC2, 0xF5, 0x28, 0x5C, 0x2F, 0x45, 0x40))
assert(serial.serialize.double(42.37, 'be')==string.char(0x40, 0x45, 0x2F, 0x5C, 0x28, 0xF5, 0xC2, 0x8F))

end

assert(serial.serialize.bytes(buffer_string, #buffer_string)==buffer_string)

assert(serial.serialize.bytes2hex("deadbeef", 4)==string.char(0xde, 0xad, 0xbe, 0xef))

assert(serial.serialize.bytes2base32("deadbeef", 5)==string.char(0x19, 0x00, 0x30, 0x90, 0x85))

assert(serial.serialize.boolean8(false)==string.char(0x00))
assert(serial.serialize.boolean8(true)==string.char(0x01))

assert(serial.serialize.struct({
	name = "foo",
	value = 42,
}, struct_desc)=="foo"..'\0'..string.char(42, 0, 0, 0))

assert(serial.serialize.fstruct(fstruct_object, fstruct_closure1)=="foo"..'\0'..string.char(42, 0, 0, 0))

assert(serial.serialize.fstruct(fstruct_object, fstruct_closure2)=="foo"..'\0'..string.char(42, 0, 0, 0))


