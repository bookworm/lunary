ifeq ($(OS),Windows_NT)
DLLEXT=dll
else
DLLEXT=so
endif

PREFIX?=/usr/local
INSTALL_LUA=$(PREFIX)/share/lua/5.1
INSTALL_BIN=$(PREFIX)/lib/lua/5.1
CPPFLAGS=-Wall -O2

.PHONY:build
build:serial/optim.$(DLLEXT)

.PHONY:clean
clean:
	rm -f serial/optim.$(DLLEXT)

.PHONY:pureinstall
pureinstall:
	install -d $(INSTALL_LUA)
	install -d $(INSTALL_LUA)/serial
	install -d $(INSTALL_BIN)/serial
	install *.lua $(INSTALL_LUA)
	install serial/*.lua $(INSTALL_LUA)/serial

.PHONY:install
install:build pureinstall
	install serial/*.$(DLLEXT) $(INSTALL_BIN)/serial

serial/optim.so: CPPFLAGS+=-Dluaopen_module=luaopen_serial_optim

%.$(DLLEXT): %.c
	$(LINK.c) -shared $^ $(LOADLIBES) $(LDLIBS) -o $@

