---
name: generating-ogharn-harnesses
description: Generates fuzzing harnesses for C libraries using OGHarn. Use when asked to harness, fuzz-test, or generate fuzzers for a C/C++ library with OGHarn.
---

# Generating OGHarn Fuzzing Harnesses

OGHarn is an oracle-guided framework that auto-generates fuzzing harnesses for C
library APIs. It uses Multiplier for static analysis (code indexing) and AFL++
for coverage-guided harness validation. This skill covers the full workflow:
library build, indexing, harness generation, and final corpus extraction.

## Prerequisites

OGHarn runs inside an orb with a pre-built container image. The wrappers
`ogharn.py` and `ogharn-container` are on PATH. Inside the container:
AFL++ (`afl-clang-fast`, `afl-showmap`), Multiplier (`mx-index`), and
`clang-18` are installed.

## Workflow Overview

1. **Prepare demo directory** — Makefile, seeds, optional config.yaml
2. **Build library** — shared (AFL-instrumented) and static (for `-e` mode)
3. **Obtain Multiplier index** — run `mx-index` or use a pre-built `.db`
4. **Run OGHarn** — generate harnesses
5. **Stop & finalize** — SIGINT triggers minimized corpus
6. **Package results** — archive final harness source files

## Step 1: Prepare Demo Directory

Create or reuse a directory under `demos/<library>/` containing:

```
demos/<library>/
  Makefile
  config.yaml          # optional
  seeds_valid/         # files the library accepts (e.g. valid XML)
  seeds_invalid/       # random/perturbed files the library rejects
```

### Seeds

- `seeds_valid/`: Small valid inputs (e.g. well-formed XML, JSON). Use varied
  sizes. Example seeds: https://github.com/FuturesLab/fuzzing-seeds
- `seeds_invalid/`: Random bytes or perturbed valid inputs. 5–10 files each is
  sufficient.

### Makefile

Must define these variables:

| Variable | Purpose |
|----------|---------|
| `CC_FUZZ` | AFL compiler (`afl-clang-fast`) |
| `CXX_FUZZ` | AFL C++ compiler (`afl-clang-fast++`) |
| `CFLAGS_ASAN` | ASan+UBSan flags (`-fsanitize=address,undefined`) |
| `CXXFLAGS_ASAN` | Same for C++ |
| `DEPS` | Include/link dirs (`-I ... -L ...`) |
| `DEPS_DYN` | Dynamic link libs (e.g. `-lxml2 -lz`) |
| `DEPS_STC` | Static link libs (e.g. `-l:libxml2.a -lz -lm`) |
| `DEPS_LDD` | Path to shared lib directory (for `LD_LIBRARY_PATH`) |

Must define these targets:

| Target | Purpose |
|--------|---------|
| `lib` | Build shared library with AFL+ASan instrumentation |
| `lib_fuzz` | Build static library with AFL instrumentation (for `-e` mode) |
| `lib_plain` | Build with plain clang + `bear` for Multiplier indexing |
| `run_mx` | Run `mx-index` to produce `.db` file |
| `harness` | Compile a single harness: `$(CC_FUZZ) -o $(OUT)/harness.out $(OUT)/harness.c $(DEPS) $(DEPS_DYN) $(CFLAGS_ASAN)` |
| `harness_static` | Same but static: `$(CC_FUZZ) -o $(OUT)/harness.out $(OUT)/harness.c -static $(DEPS) $(DEPS_STC)` (no ASan flags) |
| `showmap` | Coverage: `LD_LIBRARY_PATH=$(DEPS_LDD) afl-showmap -o $(OUT)/tempfile -- $(OUT)/harness.out $(SEED)` |
| `showmap_static` | Same without `LD_LIBRARY_PATH` |
| `harness_fuzz` | Compile a final harness for fuzzing with static linking |

**Critical `DEPS_STC` note**: Include `-lm` if the library uses math functions
(`floor`, `ceil`, `pow`, etc.). Missing math linking causes static compilation
failures that silently block all harnesses when using `-e` (execute_both).

### config.yaml (optional)

```yaml
# Functions to skip (cleanup, init, side-effect-only, etc.)
blacklist:
  - xmlCleanupParser
  - xmlInitParser

# Functions to call before fuzz data injection
preamble_seq:
  - sqlite3_open

# Hardcoded argument values for specific functions
arg_keys:
  sqlite3_open:
    - {"index": 0, "value": "\":memory:\""}
  magic_open:
    - {"index": 0, "value": "MAGIC_NONE"}

# #define statements injected into every harness
add_define_to_harness: "#define CGLTF_IMPLEMENTATION"
```

## Step 2: Build the Library

```bash
cd demos/<library>
ogharn-container make lib       # shared, AFL-instrumented
ogharn-container make lib_fuzz  # static, AFL-instrumented (needed for -e)
```

If using `-e` (execute_both), also link the static `.a` into the shared lib's
`.libs/` directory so the `harness_static` target can find it:

```bash
ln -sf ../../lib_fuzz/.libs/libFoo.a lib/.libs/libFoo.a
```

Verify static linking works before running OGHarn:

```bash
# Write a minimal test harness and try static compilation
ogharn-container bash -c "cd $PWD && afl-clang-fast -o /tmp/test test.c -static -I lib/include -L lib/.libs -l:libFoo.a <DEPS_STC>"
```

If you see undefined reference errors for system symbols (e.g. `floor`,
`ucnv_close_74`), add the missing libs to `DEPS_STC` in the Makefile.

## Step 3: Obtain Multiplier Index

### Option A: Pre-built database (skip indexing)

If the user provides a `.db` file (or a `.tar.xz` archive), extract it:

```bash
# Download attachment
amp files get "<attachment-url>" -o /tmp/lib.db.tar.xz

# Extract — check contents first
tar tf /tmp/lib.db.tar.xz  # may contain <name>.db, not necessarily lib.db
tar xf /tmp/lib.db.tar.xz -C demos/<library>/

# Use the actual filename in the -m argument
```

### Option B: Generate index with Multiplier

```bash
cd demos/<library>
ogharn-container make lib_plain  # build with plain clang + bear
ogharn-container make run_mx      # run mx-index
```

This produces `lib.db` (or `<LIB_NAME>.db`) in the demo directory.

## Step 4: Run OGHarn

```bash
cd demos/<library>
PYTHONUNBUFFERED=1 ogharn.py \
  -i "$PWD" \
  -o "$PWD/out" \
  -n 3 \
  --m "$PWD/<database>.db" \
  -h <header1.h> [<header2.h> ...] \
  -r <b|p> \
  -d -f \
  [-e] \
  [-c "$PWD/config.yaml"] \
  > /tmp/ogharn.log 2>&1 &
```

### Required arguments

| Flag | Description |
|------|-------------|
| `-i` | Input directory (Makefile + seeds) |
| `-o` | Output directory for artifacts |
| `-n` | Max functions per harness call chain (3 is typical) |
| `-m` | Path to Multiplier `.db` file |
| `-h` | Library headers to target (space-separated) |
| `-r` | Read mode: `b` (buffer) or `p` (file path) |

### Key optional arguments

| Flag | Description |
|------|-------------|
| `-d` | Debug mode (logs failures, successes, dependencies) |
| `-f` | Fast mode (first-successful arg, skip exhaustive search) |
| `-e` | Execute both dynamic + static linking (needs `harness_static`/`showmap_static` targets) |
| `-c` | Path to config.yaml |
| `-as` | Allow stderr output in harnesses |
| `-al` | Allow linear coverage deltas |
| `-ac` | Allow const args as potential non-const args for other functions |
| `-t` | Target a specific function |

### Choosing flags

- **Buffer vs file** (`-r b` vs `-r p`): Use `b` if the API takes `char*` data
  buffers; use `p` if it takes file paths/filenames.
- **execute_both** (`-e`): Use for libraries where dynamic vs static behavior
  differs. Requires `harness_static` and `showmap_static` Makefile targets and
  a working static build. **Verify static linking works first** — static
  compilation failures cause OGHarn to discard every harness without trying
  dynamic linking.
- **config.yaml**: Use to blacklist cleanup/init functions, set preamble
  sequences for required setup, or hardcode specific arguments.

### Monitoring progress

```bash
# Check stats (updated each minute)
cat demos/<library>/out/debug-info/log_stats

# Check successful harnesses
cat demos/<library>/out/debug-info/log_successful.txt

# Check what's currently being tested
cat demos/<library>/out/gen/harness.c

# Check failure log size
wc -l demos/<library>/out/debug-info/log_failed.txt

# Monitor log
tail -f /tmp/ogharn.log
```

The stats file columns are:
`Minute, Total Harnesses, Successful, Failure on Compilation, Failure on Coverage, Failure on Crash, Total Edges, Total APIs`

### Termination

OGHarn terminates when it exhausts all reachable function call chains up to
depth `-n` from every viable setup routine. There is no timeout. For large
libraries this can take hours. To stop early, send SIGINT to the Python
process — this triggers `exit_routine()` which produces the final minimized
corpus.

## Step 5: Stop & Finalize

```bash
# Find the Python process
ps aux | grep 'python3.*ogharn' | grep -v grep

# Send SIGINT to trigger graceful shutdown + corpus minimization
kill -INT <pid>

# Wait for "DONE!" in the log
tail -5 /tmp/ogharn.log
```

Output after finalization:

```
demos/<library>/out/final-harnesses/
  src/          # minimized C harness source files
  bin/          # compiled harness binaries
```

The filename format is `harness<N>:<edges>-new-tuples.c` where `<edges>` is
the number of unique coverage edges that harness adds to the corpus.

## Step 6: Package Results

```bash
cd demos/<library>/out/final-harnesses
tar czf /tmp/<library>-harnesses.tar.gz src/*.c
```

To build a specific harness for fuzzing:

```bash
cd demos/<library>
make harness_fuzz HARNESS_NUMBER=<N> OUT=$PWD/out
# Binary: bin/ogharn<N>_fuzz
```

## Troubleshooting

### All harnesses fail with compilation errors

Check `out/debug-info/log_failed.txt`. Common causes:
- **Static linking failures with `-e`**: OGHarn tries static compilation first
  and returns early on failure without trying dynamic. Verify `DEPS_STC`
  includes all transitive dependencies (e.g. `-lm` for math, `-licuuc` for
  ICU). Test with a minimal harness before running OGHarn.
- **Missing headers**: Ensure `-I` paths in `DEPS` point to the right include
  directory.
- **Wrong library name in `.libs/`**: Verify `lib/.libs/` contains the
  expected `.so` and `.a` files.

### Zero successful harnesses after many minutes

- Check `out/debug-info/log_multiplier.txt` — if it's empty or tiny, the
  database may not match the library build.
- Verify the `.db` file corresponds to the library version you built.
- Try without `-e` to isolate dynamic-only harnessing.
- Try with `-r p` if the library primarily takes file path arguments.

### Harnesses compile but gain no coverage

- Use `-as` if the library legitimately writes to stderr.
- Use `-al` if the function has low input-dependent logic.
- Provide better seeds (more varied valid/invalid inputs).
