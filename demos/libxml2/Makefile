CC_FUZZ       	= afl-clang-fast
CXX_FUZZ      	= afl-clang-fast++
CC            	= clang-18
CXX           	= clang++-18
CFLAGS_ASAN   	= -fsanitize=address,undefined
CXXFLAGS_ASAN 	= -fsanitize=address,undefined
#------------------------------------------------------------------------
# libxml2 - pinned to the commit used by Magma v1.2
# (https://github.com/HexHive/magma/tree/v1.2/targets/libxml2)

LIB_NAME = lib
LIB_REPO = https://gitlab.gnome.org/GNOME/libxml2.git
LIB_COMMIT = ec6e3efb06d7b15cf5a2328fabd3845acea4c815

# Configure flags shared by all builds (from Magma build.sh)
CONFIG_OPTS = --with-http=no --with-python=no --with-lzma=yes --with-threads=no

DEPS = -I $(PWD)/$(LIB_NAME)/include \
	   -L $(PWD)/$(LIB_NAME)/.libs

DEPS_DYN = -lxml2 -lz -llzma
DEPS_STC = -l:libxml2.a -lz -llzma
DEPS_LDD = $(PWD)/$(LIB_NAME)/.libs/

#------------------------------------------------------------------------
lib: # build for harness generation. Shared linking, asan, and afl instrumentation
	export AFL_USE_ASAN=1
	export AFL_USE_UBSAN=1

	rm -rf $(LIB_NAME)
	git clone $(LIB_REPO) $(LIB_NAME)
	cd $(LIB_NAME) && \
	git checkout $(LIB_COMMIT) && \
	./autogen.sh $(CONFIG_OPTS) --enable-shared --disable-static \
		CC=$(CC_FUZZ) CXX=$(CXX_FUZZ) && \
	make all -j12

lib_plain: # build with plain clang for Multiplier indexing (compile_commands.json)
	rm -rf $(LIB_NAME)_plain
	git clone $(LIB_REPO) $(LIB_NAME)_plain
	cd $(LIB_NAME)_plain && \
	git checkout $(LIB_COMMIT) && \
	./autogen.sh $(CONFIG_OPTS) --enable-shared --disable-static \
		CC=$(CC) CXX=$(CXX) && \
	bear -- make all -j12

lib_fuzz: # build for fuzzing. Static linking with afl instrumentation
	rm -rf $(LIB_NAME)_fuzz
	git clone $(LIB_REPO) $(LIB_NAME)_fuzz
	cd $(LIB_NAME)_fuzz && \
	git checkout $(LIB_COMMIT) && \
	./autogen.sh $(CONFIG_OPTS) --disable-shared --enable-static \
		CC=$(CC_FUZZ) CXX=$(CXX_FUZZ) && \
	make all -j12

run_mx: # Use Multiplier to index the library
	mx-index --db $(PWD)/$(LIB_NAME).db --target $(PWD)/$(LIB_NAME)_plain/compile_commands.json --workspace $(PWD)/mx

#------------------------------------------------------------------------
all: lib lib_plain lib_fuzz run_mx

#------------------------------------------------------------------------
harness: # make command used to make the harness during generation
	$(CC_FUZZ) -o $(OUT)/harness.out $(OUT)/harness.c $(DEPS) $(DEPS_DYN) $(CFLAGS_ASAN)

harness_static: # command used to statically compile harness during harness generation
	$(CC_FUZZ) -o $(OUT)/harness.out $(OUT)/harness.c -static $(DEPS) $(DEPS_STC)

showmap: # command used to get coverage information about library under test
	LD_LIBRARY_PATH=$(DEPS_LDD) afl-showmap -o $(OUT)/tempfile -- $(OUT)/harness.out $(SEED)

showmap_static: # command used to get coverage information about the statically linked harness
	afl-showmap -o $(OUT)/tempfile -- $(OUT)/harness.out $(SEED)

harness_fuzz: # compile a harness specifically for fuzzing. Pass the harness number using make harness_fuzz HARNESS_NUMBER=x
	@ls bin || mkdir bin
	$(eval LIB_NAME=lib_fuzz) \
	$(CC_FUZZ) -o bin/ogharn$(HARNESS_NUMBER)\_fuzz $(OUT)/final-harnesses/src/harness$(HARNESS_NUMBER):*.c -static $(DEPS) $(DEPS_STC) ;

clean:
	rm -rf bin mx lib.db-*

clean_lib:
	rm -rf $(LIB_NAME)*
