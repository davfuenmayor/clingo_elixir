ERL_INCLUDE ?= $(shell erl -noshell -eval 'io:format("~s/usr/include", [code:root_dir()]), halt().')
CLINGO_PREFIX ?= $(CURDIR)/_upstream
CC ?= cc
MAX_ALLOC ?= 67108864
CFLAGS ?= -O2 -g -Wall -Wextra -std=c11
CPPFLAGS += -DCLINGO_MAX_ALLOC=$(MAX_ALLOC) -D_POSIX_C_SOURCE=200809L -I$(ERL_INCLUDE) -Ic_src
LDLIBS += -L$(CLINGO_PREFIX)/lib -lclingo -lpthread
.PHONY: all clean generate
all: priv/clingo_elixir.so priv/libclingo.so.4 priv/clingo
priv/clingo_elixir.so priv/libclingo.so.4 priv/clingo: | priv
priv:
	mkdir -p $@
priv/clingo_elixir.so: c_src/clingo_elixir.c c_src/api.inc c_src/adapters.inc c_src/values.inc c_src/clingo.h $(CLINGO_PREFIX)/lib/libclingo.so.4
	cmp c_src/clingo.h $(CLINGO_PREFIX)/include/clingo.h
	$(CC) $(CPPFLAGS) $(CFLAGS) -fPIC -shared -o $@ c_src/clingo_elixir.c $(LDLIBS) -Wl,-rpath,'$$ORIGIN'
priv/libclingo.so.4: $(CLINGO_PREFIX)/lib/libclingo.so.4
	cp -L $< $@
priv/clingo: c_src/clingo_main.c c_src/clingo.h $(CLINGO_PREFIX)/lib/libclingo.so.4
	$(CC) -Ic_src $(CFLAGS) -o $@ c_src/clingo_main.c -L$(CLINGO_PREFIX)/lib -lclingo -Wl,-rpath,'$$ORIGIN'
generate:
	python3 tools/generate.py
clean:
	rm -f priv/clingo_elixir.so priv/libclingo.so.4 priv/clingo
