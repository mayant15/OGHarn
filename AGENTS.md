# Setup

Pull the container from `ghcr.io/mayant15/ogharn:main`. This is the same as building
`docker build -t <tag> .` in this repository.

# Running

Run the container mounting demos with:
```
docker run -v $PWD/demos:/root/demos -it <tag>
```
Now from inside a demo, run `./run_ogharn.sh`.

# Static Analysis

Multiplier's release binary ships its own bundled Clang/LLVM front-end for
parsing `-cc1` invocations, pinned to whatever LLVM version that release was
built against. A demo's build patch that adds `-march=native` to `CFLAGS`
(previously `demos/lua/patch.diff`, now removed) makes the compiler emit an
explicit `-target-cpu`/`-target-feature` list for whatever host happens to
run `make lib_plain`. If that host's CPU reports features newer than
Multiplier's bundled front-end recognizes (e.g. `avx10.1-512`,
`amx-complex`), `mx-index` silently skips the affected compile jobs
(`Importer.cpp: ... unsupported language op`) instead of erroring loudly.
`lib_plain` still builds the library fine, but the resulting `.db` can end
up with zero indexed declarations, breaking harness generation without any
obvious failure.

Before trusting a freshly built `.db`, sanity-check it actually holds
declarations (e.g. `mx-list-functions --db lib.db | wc -l`, or check that
`file_path` rows exist for the library's own sources) rather than assuming
a clean `run_mx` exit means a usable index. Avoid `-march=native` in any
demo's `lib_plain` build path for this reason.
