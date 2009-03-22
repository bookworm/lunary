#include <lua.h>
#include <lauxlib.h>

#define STATICSIZE 128
static char hexchars[] = {
	'0', '1', '2', '3', '4', '5', '6', '7',
	'8', '9', 'A', 'B', 'C', 'D', 'E', 'F',
};
static int bin2hex(lua_State* L)
{
	typedef unsigned char byte;
	const byte* bin;
	size_t size, i;
	char buffer[STATICSIZE*2];
	char* hex;
	bin = (const byte*)luaL_checklstring(L, 1, &size);
	if (size <= STATICSIZE)
		hex = buffer;
	else
		hex = (char*)lua_newuserdata(L, size * 2);
	for (i=0; i<size; ++i)
	{
		byte a;
		a = bin[i];
		hex[i*2] = hexchars[(a>>4)&0xf];
		hex[i*2+1] = hexchars[a&0xf];
	}
	lua_pushlstring(L, hex, size*2);
	return 1;
}

static luaL_Reg functions[] = {
	{"bin2hex", bin2hex},
	{0, 0},
};

LUALIB_API int luaopen_module(lua_State* L)
{
	luaL_register(L, lua_tostring(L, 1), functions);
	return 0;
}

