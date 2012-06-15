package = 'lunary'
version = '0.32'
source = {
	url = 'git://github.com/bookworm/lunary.git',
}
description = {
	summary = "A binary format I/O framework for Lua.",
	detailed = [[Lunary is a framework to read and write structured binary data from and to files or network connections. The aim is to provide an easy to use interface to describe any complex binary format, and allow translation to Lua data structures. The focus is placed upon the binary side of the transformation, and further processing may be necessary to obtain the desired Lua structures. On the other hand Lunary should allow reading and writing of any binary format, and bring all the information available to the Lua side.]],
	homepage = 'http://piratery.net/lunary/',
	license = 'MIT',
}
dependencies = {
	'lua ~> 5.1',
	'luabitop',
	'struct',
	'lunary-core  0.32',
	'lunary-optim 0.32',
}
build = { type = 'none' }

-- vi: ft=lua
