CC_FUZZ     	= afl-clang-fast
CXX_FUZZ    	= afl-clang-fast++
CFLAGS_ASAN 	= -fsanitize=address,undefined
CXXFLAGS_ASAN	= -fsanitize=address,undefined

LIB_NAME = lib
LIB_REPO = https://github.com/openssl/openssl.git
LIB_COMMIT = 3bd5319b5d0df9ecf05c8baba2c401ad8e3ba130

DEPS = -I $(PWD)/$(LIB_NAME)/include/ \
	   -L $(PWD)/$(LIB_NAME)/

DEPS_DYN = -lssl -lcrypto -lpthread -ldl
DEPS_STC = -l:libssl.a -l:libcrypto.a -lpthread -ldl
DEPS_LDD = $(PWD)/$(LIB_NAME)/

#------------------------------------------------------------------------
lib: # build for harness generation. Dynamic linking, asan, and afl instrumentation
	export AFL_USE_ASAN=1
	export AFL_USE_UBSAN=1

	rm -rf $(LIB_NAME)
	git clone $(LIB_REPO) $(LIB_NAME)
	cd $(LIB_NAME) && \
	git checkout $(LIB_COMMIT) && \
	CC=$(CC_FUZZ) CXX=$(CXX_FUZZ) ./config --debug disable-tests \
		-DPEDANTIC -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION \
		enable-tls1_3 enable-rc5 enable-md2 enable-ec_nistp_64_gcc_128 \
		enable-ssl3 enable-ssl3-method enable-nextprotoneg \
		enable-weak-ssl-ciphers -fno-sanitize=alignment && \
	make -j12

lib_plain: # Plain build for indexing with multiplier
	rm -rf $(LIB_NAME)_plain
	git clone $(LIB_REPO) $(LIB_NAME)_plain
	cd $(LIB_NAME)_plain && \
	git checkout $(LIB_COMMIT) && \
	CC=$(CC) CXX=$(CXX) ./config --debug disable-tests \
		-DPEDANTIC -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION \
		enable-tls1_3 enable-rc5 enable-md2 enable-ec_nistp_64_gcc_128 \
		enable-ssl3 enable-ssl3-method enable-nextprotoneg \
		enable-weak-ssl-ciphers -fno-sanitize=alignment && \
	bear -- make -j12

lib_fuzz: # build for fuzzing. Static linking with afl instrumentation
	rm -rf $(LIB_NAME)_fuzz
	git clone $(LIB_REPO) $(LIB_NAME)_fuzz
	cd $(LIB_NAME)_fuzz && \
	git checkout $(LIB_COMMIT) && \
	CC=$(CC_FUZZ) CXX=$(CXX_FUZZ) ./config --debug disable-tests \
		-DPEDANTIC -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION \
		no-shared no-module \
		enable-tls1_3 enable-rc5 enable-md2 enable-ec_nistp_64_gcc_128 \
		enable-ssl3 enable-ssl3-method enable-nextprotoneg \
		enable-weak-ssl-ciphers -fno-sanitize=alignment && \
	make -j12

run_mx: # Use Multiplier to index the library
	mx-index --db $(PWD)/$(LIB_NAME).db --target $(PWD)/$(LIB_NAME)_plain/compile_commands.json --workspace $(PWD)/mx

#------------------------------------------------------------------------
all: lib lib_plain lib_fuzz run_mx

#------------------------------------------------------------------------
harness: # make command used to make the harness during generation
	$(CC_FUZZ) -o $(OUT)/harness.out $(OUT)/harness.c $(DEPS) $(DEPS_DYN) $(CFLAGS_ASAN)

showmap: # command used to get coverage information about library under test
	LD_LIBRARY_PATH=$(DEPS_LDD) afl-showmap -o $(OUT)/tempfile -- $(OUT)/harness.out $(SEED)

harness_fuzz: # compile a harness specifically for fuzzing. Pass the harness number using make harness_fuzz HARNESS_NUMBER=x
	@ls bin || mkdir bin
	$(eval LIB_NAME=lib_fuzz) \
	$(CC_FUZZ) -o bin/ogharn$(HARNESS_NUMBER)\_fuzz $(OUT)/final-harnesses/src/harness$(HARNESS_NUMBER):*.c -static $(DEPS) $(DEPS_STC) ;

clean:
	rm -rf bin mx lib.db-*

clean_lib:
	rm -rf $(LIB_NAME)*
