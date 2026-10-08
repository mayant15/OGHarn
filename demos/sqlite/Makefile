#------------------------------------------------------------------------
# Leave these as-is (unless you must change the compiler)!

CC_FUZZ       	= afl-clang-fast
CXX_FUZZ      	= afl-clang-fast++
CC 				= clang
CXX				= clang++
CFLAGS_ASAN 	= -fsanitize=address,undefined
CXXFLAGS_ASAN 	= -fsanitize=address,undefined

#------------------------------------------------------------------------
# Edit these below accordingly...

LIB_NAME = lib
LIB_REPO = https://github.com/sqlite/sqlite.git

DEPS = -I $(PWD)/$(LIB_NAME)/ \
	   -L $(PWD)/$(LIB_NAME)/
	   
DEPS_STAT = -I $(PWD)/$(LIB_NAME)_static/ \
	  		-L $(PWD)/$(LIB_NAME)_static/

DEPS_DYN = -lsqlite3
DEPS_STC = -l:libsqlite3.a -lm
DEPS_LDD = $(PWD)/$(LIB_NAME)/.libs

#------------------------------------------------------------------------
lib: # build for harness generation. Dynamic linking, asan, and afl instrumentation
	export AFL_USE_ASAN=1 && \
	export AFL_USE_UBSAN=1 && \
	rm -rf $(LIB_NAME) && \
	curl "https://www.sqlite.org/src/tarball/sqlite.tar.gz?r=8c432642572c8c4b" \
		-o "lib.tar.gz" && \
	mkdir -p "$(LIB_NAME)" && \
	tar -C "$(LIB_NAME)" --strip-components=1 -xzf "lib.tar.gz" && \
	cd "$(LIB_NAME)" && \
	./configure --enable-rtree \
	CC=$(CC_FUZZ) CXX=$(CXX_FUZZ) \
	CFLAGS="\
        -DSQLITE_MAX_LENGTH=128000000 -DSQLITE_MAX_SQL_LENGTH=128000000 \
        -DSQLITE_MAX_MEMORY=25000000 -DSQLITE_PRINTF_PRECISION_LIMIT=1048576 \
        -DSQLITE_DEBUG=1 -DSQLITE_MAX_PAGE_COUNT=16384" && \
	make all -j12 && \
	ln -s .libs/libsqlite3.so libsqlite3.so

lib_plain: # build for harness generation. Dynamic linking, asan, and afl instrumentation
	rm -rf $(LIB_NAME)_plain
	mkdir -p "$(LIB_NAME)_plain" && \
	tar -C "$(LIB_NAME)_plain" --strip-components=1 -xzf "lib.tar.gz" && \
	cd "$(LIB_NAME)_plain" && \
	./configure --enable-rtree \
	CC=$(CC) CXX=$(CXX) \
	CFLAGS="\
        -DSQLITE_MAX_LENGTH=128000000 -DSQLITE_MAX_SQL_LENGTH=128000000 \
        -DSQLITE_MAX_MEMORY=25000000 -DSQLITE_PRINTF_PRECISION_LIMIT=1048576 \
        -DSQLITE_DEBUG=1 -DSQLITE_MAX_PAGE_COUNT=16384" && \
	bear -- make all -j12

lib_static:
	rm -rf $(LIB_NAME)_static
	mkdir -p "$(LIB_NAME)_static" && \
	tar -C "$(LIB_NAME)_static" --strip-components=1 -xzf "lib.tar.gz" && \
	cd "$(LIB_NAME)_static" && \
	./configure --enable-rtree \
	CC=$(CC_FUZZ) CXX=$(CXX_FUZZ) \
	CFLAGS="\
        -DSQLITE_MAX_LENGTH=128000000 -DSQLITE_MAX_SQL_LENGTH=128000000 \
        -DSQLITE_MAX_MEMORY=25000000 -DSQLITE_PRINTF_PRECISION_LIMIT=1048576 \
        -DSQLITE_DEBUG=1 -DSQLITE_MAX_PAGE_COUNT=16384" && \
	make all -j12


lib_fuzz:  # build for fuzzing. Static linking with afl instrumentation
	rm -rf $(LIB_NAME)_fuzz
	mkdir -p "$(LIB_NAME)_fuzz" && \
	tar -C "$(LIB_NAME)_fuzz" --strip-components=1 -xzf "lib.tar.gz" && \
	cd "$(LIB_NAME)_fuzz" && \
	./configure --enable-rtree \
	CC=$(CC_FUZZ) CXX=$(CXX_FUZZ) \
	CFLAGS="\
        -DSQLITE_MAX_LENGTH=128000000 -DSQLITE_MAX_SQL_LENGTH=128000000 \
        -DSQLITE_MAX_MEMORY=25000000 -DSQLITE_PRINTF_PRECISION_LIMIT=1048576 \
        -DSQLITE_DEBUG=1 -DSQLITE_MAX_PAGE_COUNT=16384" && \
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
