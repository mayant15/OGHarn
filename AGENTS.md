# Working in an Amp Orb

OGHarn runs in the Ubuntu container built by `.agents/setup`; do not install or
source `extras/set_env.sh` on the Debian orb host.

## Container commands

- Run a command in the prepared image with `ogharn-container <command>`.
- Run OGHarn against the live checkout with `ogharn.py <arguments>`.
- Both wrappers preserve the current repository working directory and mount the
  live `src/` tree, so edits are used without rebuilding the image.
- After changing `Dockerfile`, run `.agents/setup` to rebuild the image and
  refresh the wrappers. Cached dependency layers make repeated setup runs fast.

## Demo smoke test

The cJSON demo is a small integration test:

```bash
cd demos/cjson
ogharn-container make lib
ogharn-container make run_mx
ogharn.py -i "$PWD" -o "$PWD/out" -n 3 \
  --m "$PWD/lib.db" -h cJSON.h -r b -d -f
```

The last command is a long-running harness campaign. For a smoke test, stop it
after it reports successful harnesses; generated files are written beneath the
demo directory and ignored by Git.

Use `ogharn-container make all` when both the generation and statically linked
fuzzing versions of a demo library are needed.

## Static analysis pitfall: -march=native

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
