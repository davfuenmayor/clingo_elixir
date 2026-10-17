ERL_INCLUDE ?= $(shell erl +S 1:1 -noshell -eval 'io:format("~s/usr/include", [code:root_dir()]), halt().')
CLINGO_PREFIX ?= $(CURDIR)/_upstream
DESTDIR ?= priv
MAX_ALLOC ?= 67108864
CFLAGS ?= -O2 -g -Wall -Wextra -std=c11
NIF_EXT ?= $(if $(filter MINGW%,$(shell uname -s)),dll,so)
CPPFLAGS += -DCLINGO_MAX_ALLOC=$(MAX_ALLOC) -D_POSIX_C_SOURCE=200809L -I"$(ERL_INCLUDE)" -Ic_src

ifeq ($(NIF_EXT),dll)
CLINGO_LIBRARY = $(firstword $(wildcard $(CLINGO_PREFIX)/bin/*clingo*.dll))
EXE_EXT = .exe
LINK_FLAGS = -shared -static -static-libgcc
CLINGO_LINK = -L"$(CLINGO_PREFIX)/lib" -l:libclingo.dll.a
THREAD_FLAGS = -pthread
else ifeq ($(shell uname -s),Darwin)
CLINGO_LIBRARY = $(CLINGO_PREFIX)/lib/libclingo.4.dylib
LINK_FLAGS = -bundle -undefined dynamic_lookup -Wl,-headerpad_max_install_names -Wl,-rpath,@loader_path
CLINGO_LINK = -L"$(CLINGO_PREFIX)/lib" -lclingo
CLI_LINK_FLAGS = -Wl,-headerpad_max_install_names -Wl,-rpath,@loader_path
THREAD_FLAGS = -pthread
else
CLINGO_LIBRARY = $(CLINGO_PREFIX)/lib/libclingo.so.4
LINK_FLAGS = -shared -Wl,-rpath,'$$ORIGIN'
CLINGO_LINK = -L"$(CLINGO_PREFIX)/lib" -lclingo
CLI_LINK_FLAGS = -Wl,-rpath,'$$ORIGIN'
THREAD_FLAGS = -pthread
endif

.PHONY: all clean generate
all: $(DESTDIR)/clingo_elixir.$(NIF_EXT) $(DESTDIR)/$(notdir $(CLINGO_LIBRARY)) $(DESTDIR)/clingo$(EXE_EXT)
$(DESTDIR):
	mkdir -p "$@"
$(DESTDIR)/clingo_elixir.$(NIF_EXT): c_src/clingo_elixir.c c_src/api.inc c_src/adapters.inc c_src/values.inc c_src/clingo.h $(CLINGO_LIBRARY) | $(DESTDIR)
	cmp c_src/clingo.h "$(CLINGO_PREFIX)/include/clingo.h"
	$(CC) $(CPPFLAGS) $(CFLAGS) -fPIC $(LINK_FLAGS) -o "$@" c_src/clingo_elixir.c $(CLINGO_LINK) $(THREAD_FLAGS)
$(DESTDIR)/$(notdir $(CLINGO_LIBRARY)): $(CLINGO_LIBRARY) | $(DESTDIR)
	cp -L "$<" "$@"
$(DESTDIR)/clingo$(EXE_EXT): c_src/clingo_main.c c_src/clingo.h $(CLINGO_LIBRARY) | $(DESTDIR)
	$(CC) -Ic_src $(CFLAGS) -o "$@" c_src/clingo_main.c $(CLINGO_LINK) $(CLI_LINK_FLAGS) $(THREAD_FLAGS) $(if $(filter dll,$(NIF_EXT)),-static -static-libgcc)
generate:
	python3 tools/generate.py
clean:
	rm -f "$(DESTDIR)/clingo_elixir.so" "$(DESTDIR)/clingo_elixir.dll" "$(DESTDIR)/libclingo.so.4" "$(DESTDIR)/libclingo.4.dylib" "$(DESTDIR)/libclingo.dll" "$(DESTDIR)/clingo" "$(DESTDIR)/clingo.exe" "$(DESTDIR)/.bundle"
