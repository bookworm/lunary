CPPFLAGS=-Wall -O2
INSTALL_LUA=/usr/local/share/lua/5.1
INSTALL_BIN=/usr/local/lib/lua/5.1

.PHONY:build
build:serial/optim.so

.PHONY:clean
clean:
	rm -f serial/optim.so

.PHONY:install
install:
	install -d $(INSTALL_LUA)
	install -d $(INSTALL_LUA)/serial
	install -d $(INSTALL_BIN)/serial
	install *.lua $(INSTALL_LUA)
	install serial/*.lua $(INSTALL_LUA)/serial
	install serial/*.so $(INSTALL_BIN)/serial

serial/optim.so: CPPFLAGS+=-Dluaopen_module=luaopen_serial_optim

%.so: %.c
	$(LINK.c) -shared $^ $(LOADLIBES) $(LDLIBS) -o $@

