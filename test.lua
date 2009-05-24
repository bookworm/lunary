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

assert(serial.serialize.uint8(0x00)==string.char(0x00))
assert(serial.serialize.uint8(0x55)==string.char(0x55))
assert(serial.serialize.uint8(0xaa)==string.char(0xaa))
assert(serial.serialize.uint8(0xff)==string.char(0xff))

assert(serial.serialize.uint16(0xbeef, 'le')==string.char(0xef, 0xbe))
assert(serial.serialize.uint16(0xbeef, 'be')==string.char(0xbe, 0xef))

assert(serial.serialize.uint32(0xdeadbeef, 'le')==string.char(0xef, 0xbe, 0xad, 0xde))
assert(serial.serialize.uint32(0xdeadbeef, 'be')==string.char(0xde, 0xad, 0xbe, 0xef))

assert(serial.serialize.uint64(0x0010feed * 2^32 + 0xdeadbeef, 'le')==string.char(0xef, 0xbe, 0xad, 0xde, 0xed, 0xfe, 0x10, 0x00))
assert(serial.serialize.uint64(0x0010feed * 2^32 + 0xdeadbeef, 'be')==string.char(0x00, 0x10, 0xfe, 0xed, 0xde, 0xad, 0xbe, 0xef))

assert(serial.serialize.enum('name1', enum_dict, {'uint8'})==string.char(0x01))
assert(serial.serialize.enum('name2', enum_dict, 'uint16', 'le')==string.char(0x02, 0x00))

if pcall(require, 'bit') then

assert(serial.serialize.flags({flag1=true}, flags_dict, {'uint8'})==string.char(0x01))
assert(serial.serialize.flags({flag1=true, flag3=true}, flags_dict, 'uint8')==string.char(0x05))
assert(serial.serialize.flags({flag2=true, flag12=true}, flags_dict, 'uint16', 'le')==string.char(0x03, 0x00))

end

