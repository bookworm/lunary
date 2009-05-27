local serial = require 'serial'
local bit = require 'bit'

local read = serial.read
local write = serial.write
local serialize = serial.serialize
local struct = serial.struct
local fstruct = serial.fstruct
local alias = serial.alias

-- based on http://www.libpng.org/pub/png/spec/1.2/png-1.2-pdg.html

------------------------------------------------------------------------------

-- Table of CRCs of all 8-bit messages.
local crc_table = {}
do
	for n=0,255 do
		local c = n
		for k=0,7 do
			if bit.band(c, 1)~=0 then
				c = bit.bxor(0xedb88320, bit.rshift(c, 1))
			else
				c = bit.rshift(c, 1)
			end
		end
		crc_table[n] = c
	end
end

--[[ Update a running CRC with the bytes buf[0..len-1]--the CRC
	 should be initialized to all 1's, and the transmitted value
	 is the 1's complement of the final running CRC (see the
	 crc() routine below)). ]]

local function update_crc(crc, buf) -- return unsigned long
	local c = crc -- unsigned long

	for n=1,#buf do
		c = bit.bxor(crc_table[bit.band(bit.bxor(c, string.byte(buf, n)), 0xff)], bit.rshift(c, 8))
	end
	return c
end

-- Return the CRC of the bytes buf[0..len-1].
local function crc(buf)
	local value = bit.bxor(update_crc(0xffffffff, buf), 0xffffffff)
	return serial.serialize.sint32(value, 'be') -- sint32 because bit lib defaults to that
end

------------------------------------------------------------------------------

local png_color_type = {
	palette = 1,
	color = 2,
	alpha = 4,
}

local png_compression_method = serial.util.enum{
	deflate = 0,
}

local png_filter_method = serial.util.enum{
	default = 0,
}

local png_interlace_method = serial.util.enum{
	none = 0,
	adam7 = 1,
}

------------------------------------------------------------------------------

function fstruct.png_file(self)
	self 'signature' ('bytes', 8)
	assert(self.signature==string.char(137, 80, 78, 71, 13, 10, 26, 10), "invalid PNG signature")
	self 'chunks' ('array', '*', 'png_chunk')
	assert(self.chunks[1].type=='IHDR', "first chunk shoud be an IHDR")
	assert(self.chunks[#self.chunks].type=='IEND', "last chunk shoud be an IEND")
end

function read.png_chunk(stream)
	local length = read.uint32(stream, 'be')
	local type = read.bytes(stream, 4)
	local data = read.bytes(stream, length)
	local chunk_crc = read.bytes(stream, 4)
	assert(crc(type..data)==chunk_crc, "invalid chunk CRC")
	local read = read["png_"..type.."_chunk"]
	if read then
		data = read(serial.buffer(data))
	end
	return {
		type = type,
		data = data,
	}
end

struct.png_IHDR_chunk = {
	{'width',				'uint32', 'be'},
	{'height',				'uint32', 'be'},
	{'bit_depth',			'uint8'}, -- various restrictions depending on color_type
	{'color_type',			'flags', png_color_type, 'uint8'}, -- can only be 0, 2, 3, 4 or 6
	{'compression_method',	'enum', png_compression_method, 'uint8'},
	{'filter_method',		'enum', png_filter_method, 'uint8'},
	{'interlace_method',	'enum', png_interlace_method, 'uint8'},
}

struct.png_IEND_chunk = {}

