# Adapting OGHarn's demo benchmarks

Records support-header and Makefile fixes made to get OGHarn producing
meaningful harnesses for `demos/` benchmarks, the bugs (in OGHarn itself,
and in one demo's build configuration) that made each fix necessary, and a
survey of harness-generation results across all libraries in
`demos/run.sh`.

> **AI disclosure:** This document, the accompanying fixes
> (`demos/libpng/png-support.h`, `demos/libtiff/tiff-support.h`,
> `demos/libsndfile/sndfile-support.h`, `demos/sqlite/Makefile`), and the
> investigation behind all of them were produced by Claude (Anthropic),
> operating this repository's Docker-based OGHarn pipeline end-to-end
> (building each library, indexing with Multiplier, running and re-running
> `ogharn.py`) and reading OGHarn's own source (`src/engine.py`) to trace
> each root cause. The metrics and log excerpts below are taken directly
> from those runs; the analysis and conclusions have not been independently
> reviewed by a human at time of writing.

## `demos/libpng/png-support.h`: anonymous-struct dependency gap

### Problem

Running `run_ogharn.sh` against the stock `png-support.h` produced **zero**
final harnesses. OGHarn's search exhaustively tried every combination of the
whitelisted API (`png_image_begin_read_from_memory`, `png_image_finish_read`,
`png_image_free`, `png_fuzz_new_image`, `png_fuzz_free_image`) but never
called `png_fuzz_new_image()` to obtain a real `png_image` — every candidate
harness instead passed `NULL` or a locally zeroed struct as the first
argument. libpng's internal `version` check rejects that immediately, so
coverage plateaued at 7 edges and no harness ever reached real PNG parsing
code.

### Root cause

libpng declares `png_image` as an **anonymous struct aliased to two typedef
names at once** (`demos/libpng/lib_plain/png.h:2672-2708`):

```c
typedef struct
{
    ...
} png_image, *png_imagep;
```

The original `png-support.h` wrote `png_fuzz_new_image`'s return type as
`png_image *`, while libpng's own `png_image_begin_read_from_memory`,
`png_image_finish_read`, and `png_image_free` all take a `png_imagep`
argument (`demos/libpng/lib_plain/png.h:2991,2995,3030`). Structurally these are the same
type; textually they are two different typedef names.

OGHarn's dependency inference (`src/engine.py`, `BuildDependencies` /
`Compatibility.check_type_compatibility`) links function A's return type to
function B's argument type by resolving both down through Multiplier's type
AST (`init_mult_type`, `get_aliases`) and comparing the resulting base-type
name strings. For an ordinary named struct this works. For an **anonymous**
struct, Clang/Multiplier's `RecordDecl.name` is the empty string, so both
`png_image *` and `png_imagep` eventually resolve to a base type of `""`
once the alias chain is fully walked (confirmed directly in this run's
`log_multiplier.txt`, where the alias for `png_imagep` printed as bare `*`,
i.e. `base_type="" pointers=1`).

`check_type_compatibility` (`src/engine.py:725`) guards against exactly this
degenerate case:

```python
if dest_name == source_name and len(dest_name) > 1:
```

The `len(dest_name) > 1` check exists to stop unrelated anonymous types from
being treated as compatible by accident — but it also discards the one case
where two empty-string resolutions really do refer to the same anonymous
struct. Net effect: OGHarn never recorded "`png_fuzz_new_image`'s return
value satisfies `png_image_begin_read_from_memory`'s argument 0," because
the only path connecting `png_image *` and `png_imagep` runs through that
blocked anonymous-struct match.

Verified in `demos/libpng/out/debug-info/log_potential_dependencies.txt` from the
original (broken) run: `png_fuzz_new_image` only appears with a dependency
to `png_fuzz_free_image` (its own header — same typedef spelling on both
sides), never to any `png_image_*` function from `png.h`.

### Fix

Changed `png_fuzz_new_image`/`png_fuzz_free_image` in `png-support.h` to use
the same `png_imagep` spelling libpng's own declarations use, instead of the
structurally-equivalent but textually-different `png_image *`:

```c
png_imagep png_fuzz_new_image(void) { ... }
void png_fuzz_free_image(png_imagep image) { ... }
```

With matching spellings on both sides, `check_type_compatibility` finds
`dest_name == source_name == "png_imagep"` directly (a normal, non-anonymous
typedef name, length > 1) and never needs to fall through to the broken
anonymous-struct alias path.

This is a narrow, targeted fix, not a general patch to OGHarn: it works
around the anonymous-struct-name gap by avoiding it, rather than fixing
`check_type_compatibility` itself. A general fix would need some way to
distinguish "these two empty-string resolutions are the same anonymous
struct" from "these are two unrelated anonymous structs" — e.g. comparing
the underlying `RecordDecl`'s identity/location instead of its (possibly
empty) name.

### Verification

Rebuilt `lib_plain`'s `compile_commands.json` entry for the header, re-ran
`mx-index`, and reran `ogharn.py` with the same arguments as
`run_ogharn.sh` (`-n 3 -r b -d -f`).

| | Before | After |
|---|---|---|
| `png_fuzz_new_image` → `png_image_begin_read_from_memory` dependency recorded | No | Yes (`Dependency Code: 2`) |
| Functions successfully harnessed | 2 of 5 (`png_image_begin_read_from_memory`, `png_image_finish_read`) | 5 of 5 |
| Max coverage (unique edges) | 7 | 253 |
| Final harnesses produced | 0 | 5 |
| Combined coverage across final harnesses | 0 | 503 edges |

`log_potential_dependencies.txt` after the fix now shows the previously
missing entries:

```
Function: png_fuzz_new_image
Function Name: png_image_begin_read_from_memory,Current Function's Argument #: 0, Other Function's Argument #: -1, ..., Dependency Code: 2
Function Name: png_image_finish_read,Current Function's Argument #: 0, Other Function's Argument #: -1, ..., Dependency Code: 2
Function Name: png_image_free,Current Function's Argument #: 0, Other Function's Argument #: -1, ..., Dependency Code: 2
```

The best final harness (`demos/libpng/out_fixed/final-harnesses/src/harness1:486-new-tuples.c`)
correctly chains the initializer into the real API call:

```c
png_imagep png_fuzz_new_imageval1 = png_fuzz_new_image();
int png_image_begin_read_from_memoryval1 =
    png_image_begin_read_from_memory(png_fuzz_new_imageval1, (void*)fuzzData, size);
```

Running `harness1.out` directly against a valid seed confirms it reaches
real libpng code (not just the wrapper): LeakSanitizer reports the
`png_image_control` struct allocated inside `png_image_begin_read_from_memory`
as leaked, plus the `png_image` allocated by `png_fuzz_new_image` itself
(`demos/libpng/png-support.h:41`) — expected, since this minimal harness only calls
`png_image_begin_read_from_memory` and never reaches `png_fuzz_free_image`.

### Caveat: the observed "crashes" are likely harness artifacts, not libpng bugs

The fixed run also logged 30 discarded candidates that aborted with
`SIGABRT` (consistently on the `not_kitty_icc.png` seed). Inspecting one:

```c
int png_image_finish_readval1 = png_image_finish_read(
    png_fuzz_new_imageval1, NULL, (void*)&fuzzData, size, (void*)&fuzzData);
```

`png_image_finish_read`'s 3rd argument is the output pixel buffer and its
4th is that buffer's row stride; here OGHarn passed the address of a local
8-byte pointer variable as the buffer while using the *input file's byte
size* as the row stride, which is essentially guaranteed to overflow. This
looks like a harness-generation artifact (OGHarn has no way yet to compute
"buffer must be `image->height * row_stride` bytes, derived from fields of
the very struct `png_image_begin_read_from_memory` just populated") rather
than a genuine libpng memory-safety bug. Not investigated further here;
flagging it so it isn't mistaken for a confirmed finding.

### Generalization

Any Traffic/OGHarn support header for a library that exposes a type via
`typedef struct { ... } Name, *NameP;` (anonymous struct, multiple typedef
spellings) should spell wrapper return/parameter types **using the exact
typedef name the target library's own API uses**, not a structurally
equivalent alternative — otherwise OGHarn's dependency inference may not
connect them, silently degrading harness quality without any error message.

## `demos/libtiff` / `demos/libsndfile`: fixed-width integer typedefs break fuzz-argument detection

While checking the other libraries in `demos/run.sh` (`libtiff`, `libsndfile`,
`libxml2`, `lua`, `openssl`, `sqlite`) for whether OGHarn could produce
meaningful harnesses for them, `libtiff` and `libsndfile` both came back with
**zero** final harnesses and a much worse symptom than libpng's original
one: OGHarn never found `tiff_open_r`/`sf_init_file` — their support headers'
own primary "hand the fuzz buffer to the library" entry points — as a search
entry point *at all*. This is a second, independent gap in the same family
of problems (OGHarn's type-compatibility machinery not fully resolving
typedef chains), worth recording here since anyone adapting a support header
for a new library is likely to hit it.

**Root cause:** both wrappers declared their buffer parameter as
`const uint8_t *data`. On glibc, `uint8_t` resolves through **two** typedef
hops: `uint8_t -> __uint8_t -> unsigned char` (`/usr/include/x86_64-linux-gnu/bits/types.h:38`).
OGHarn's fuzz-argument detection (`CheckCompatibility.init_mult_type`,
`src/engine.py:498-523`) only recurses **one** typedef level when deciding
whether a pointer type "consumes" fuzz data: it checks whether the
one-level-down type's name is in `self.buffer_types`, or whether that
one-level-down type's *own* `consumes_fuzz` flag is already set. For
`uint8_t*`, one level down lands on `__uint8_t` — a name in nobody's list —
and `__uint8_t`'s own resolution never sets `consumes_fuzz` either, because
that check is additionally gated on `mult_type_obj.pointers`, which is `0`
at the `__uint8_t` level (the pointer was only ever counted once, on the
outermost `uint8_t*`). `uint8_t` also isn't in `extras/mult-to-c-types.txt`,
so it doesn't qualify for the auxiliary-function fallback either. Net
effect: the whole argument is invisible to OGHarn, and the function falls
through into "Processing Functions" — never tried as a way to get fuzz data
into the library — with no error or warning. Confirmed directly in
`demos/libtiff/out/debug-info/log_multiplier.txt` and
`demos/libsndfile/out/debug-info/log_multiplier.txt`: both entry points are
listed under "Processing Functions", not "Setup Functions".

**Why the libpng fix's pattern doesn't apply here:** this isn't a spelling
mismatch between two typedef names for the same type (the earlier bug) — no
respelling of `uint8_t` fixes it, since *every* spelling of that type
resolves through the same two-hop chain. The fix instead is to avoid
fixed-width `stdint.h` types in support-header signatures entirely and use
`char *` (a plain `BuiltinType`, no typedef indirection, so the one-level
check never comes into play): applied to `tiff_open_r`, `tiff_fuzz_write_strip`
(`demos/libtiff/tiff-support.h`) and `sf_init_file`
(`demos/libsndfile/sndfile-support.h`). This only works because none of the
*real* library API functions in either whitelist take a `uint8_t*`/similar
argument themselves — `TIFFClose`, `TIFFSetField`, `TIFFWriteDirectory`,
and all of libsndfile's whitelisted functions use `TIFF*`/`SNDFILE*`/plain
`int`/`char*` types instead. `tiffio.h` does use `uint8_t*`/`uint16_t*`/
`uint32_t*`/`uint64_t*` extensively elsewhere (unwhitelisted raster/strip
functions); if the whitelist ever grows to include one of those, this bug
resurfaces and can't be routed around by respelling, since we can't change
the library's own declaration.

This is a general OGHarn limitation, not a libpng-specific note — flagged
here because it's the same family of "type resolution silently gives up and
misclassifies a function" failure this document's main fix addresses, just
one typedef-hop deeper.

**Verification.** Re-ran `mx-index` after the header edits (function counts
unchanged: 9539 for libtiff, 3814 for libsndfile — confirming the fix didn't
perturb indexing), then reran `ogharn.py` with the same arguments
`demos/run.sh` uses for each:

| | libtiff (before → after) | libsndfile (before → after) |
|---|---|---|
| `tiff_open_r`/`sf_init_file` classified as | Processing → **Setup** | Processing → **Setup** |
| Final harnesses | 0 → **4** | 0 → **9** |
| Max coverage (edges) | 0 → **553** | 0 → **388** |
| Functions harnessed | 0/8 → **5/8** | 3/18 → **7/18** |

`log_multiplier.txt` now shows both entry points correctly resolved to
`CHARACTER_S*` (i.e. `char*`) and listed under "Setup Functions" rather than
"Processing Functions":

```
Setup Functions:
TIFF* tiff_open_r(['CHARACTER_S*', 'INT'])Status Check(operator: !, value: None)
INT tiff_fuzz_write_strip(['TIFF*', 'CHARACTER_S*', 'INT'])Status Check(operator: <, value: 0)
```
```
Setup Functions:
INT sf_init_file(['CHARACTER_S*', 'size_t', 'SNDFILE**', 'VIO_DATA*', 'SF_VIRTUAL_IO*', 'SF_INFO*'])Status Check(operator: <, value: 0)
SF_CHUNK_ITERATOR* sf_fuzz_get_chunk_iterator(['SNDFILE*', 'CHARACTER_S*'])Status Check(operator: !, value: None)
```

Neither library's remaining unsuccessfully-harnessed functions
(`TIFFSetField`/`TIFFWriteDirectory`; most of libsndfile's chunk-iterator and
error-reporting functions) are related to this bug — they look like
separate dependency-chaining gaps, not investigated further here.

## `demos/sqlite`: harness fuzzes the wrong library entirely

The initial survey run for sqlite (below) produced zero final harnesses and
a suspicious symptom: `Total Edges` in `log_stats` plateaued at **3** for
the entire ~10-minute campaign, across hundreds of candidate harnesses and
every seed file. That's far too low even for `sqlite3_prepare_v2` alone
parsing arbitrary bytes — real, varied SQL text (the seed corpus has
multi-statement `CREATE TABLE`/`INSERT`/`SELECT` scripts) should hit many
different tokenizer/parser branches. `sqlite3_step`/`sqlite3_finalize`/
`sqlite3_reset`/`sqlite3_close` were never harnessed.

**Root cause, confirmed empirically, not just by inspection:** extracted
one of OGHarn's own generated setup-routine harnesses
(`sqlite3_open(":memory:", &db); sqlite3_prepare_v2(db, fuzzData, size, ...)`),
compiled it against `demos/sqlite/lib/` exactly as `make harness`/`make
showmap` do, and ran `afl-showmap` against it directly:

```
$ LD_LIBRARY_PATH=demos/sqlite/lib/ ldd gen_harness.out | grep sqlite
    libsqlite3.so.0 => /lib/x86_64-linux-gnu/libsqlite3.so.0   <-- NOT our build!
```

Every seed — rich valid SQL, single-character garbage, hex-dump nonsense —
produced the *exact same* 2-tuple coverage hash. The harness was never
executing the fuzzing build's `libsqlite3.so` at all.

Why: sqlite's own (non-libtool) build embeds `SONAME libsqlite3.so.0` into
the shared object it produces, but the produced *file* is named plainly
`libsqlite3.so` — normally `make install` (or `ldconfig`) creates the
`libsqlite3.so.0` symlink the SONAME promises; the demo's `lib:` target
only runs `make all`, so that symlink never gets created. At runtime, the
dynamic loader resolves the harness's `NEEDED libsqlite3.so.0` entry by
filename, not by scanning `LD_LIBRARY_PATH` for something whose *SONAME*
happens to match — since no file named exactly `libsqlite3.so.0` exists in
`demos/sqlite/lib/`, it falls through to the system default paths, where
this container's base image happens to have `libsqlite3-0` installed (as
some other package's dependency) — completely uninstrumented, and not even
the same version. So every harness OGHarn generates for sqlite silently
fuzzes a random system library instead of the one it just spent an index
and a build understanding, and gets zero real coverage feedback back.

**Fix:** added `ln -sf libsqlite3.so libsqlite3.so.0` to the end of the
`lib:` target in `demos/sqlite/Makefile`, so `DEPS_LDD` contains a file
under the exact name the loader looks for.

**Verification.** Rebuilding `lib` isn't required for this fix (`lib_plain`
and the `.db` are untouched by it) — just created the symlink and reran
`ogharn.py` with the same arguments:

```
$ LD_LIBRARY_PATH=demos/sqlite/lib/ afl-showmap -- gen_harness.out seeds_valid/s5   # rich SQL
Captured 2058 tuples ...
$ LD_LIBRARY_PATH=demos/sqlite/lib/ afl-showmap -- gen_harness.out seeds_invalid/s4  # a single quote char
Captured 469 tuples ...
```

| | Before | After |
|---|---|---|
| Coverage hash across all seeds | Identical for every seed | Genuinely differs (2058 vs ~470-480 tuples) |
| Final harnesses | 0 | **6** |
| Max coverage (edges) | 3 | **3324** |
| Functions harnessed | 2/7 (`sqlite3_open`, `sqlite3_prepare_v2`) | **6/7** (adds `sqlite3_step`, `sqlite3_finalize`, `sqlite3_reset`, `sqlite3_close`) |

`sqlite3_limit` remains unharnessed — not investigated, but it doesn't
depend on the `sqlite3_stmt*` chain at all (it's a `sqlite3*`-level config
knob), so it's unrelated to this bug.

This is a Makefile/build-configuration bug specific to how this one demo
packages its library (the only demo whose target library isn't built via
GNU Autotools + libtool, which normally handles SONAME symlinks
automatically) — not an OGHarn source bug like the two above. Worth
flagging for anyone adding a new demo for a library with its own bespoke
(non-libtool) build system: **always verify with `ldd` that the compiled
harness actually links the freshly-built library, not a same-named system
package** — a mismatch here produces no error or crash, just silent,
totally flat coverage that looks like "the search isn't finding anything
interesting" rather than "the search is fuzzing the wrong binary."

## Survey: does every library in `demos/run.sh` produce meaningful harnesses?

Prompted by the fixes above, ran `ogharn.py` (same arguments each demo's
`run_ogharn.sh`/`demos/run.sh` uses) against all six other libraries listed
in `demos/run.sh`, to see how much of this class of bug is peculiar to
libpng versus widespread.

| Library | Final harnesses | Max coverage (edges) | Functions harnessed | Notes |
|---|---|---|---|---|
| **lua** | 23 | 4113 | 11/11 (all) | Richest result; no fix needed |
| **openssl** | 1 | 2928 | 5/11 | Real `d2i_X509` DER-parsing harness |
| **libxml2** | 15 | 1996 | 11/27 | Reaches real `xmlCtxtReadMemory`/`xmlNewTextReader` parsing |
| **libtiff** | 4 (was 0) | 553 (was 0) | 5/8 | Fixed by the `uint8_t` → `char*` change above |
| **libsndfile** | 9 (was 0) | 388 (was 0) | 7/18 | Fixed by the `uint8_t` → `char*` change above |
| **sqlite** | 6 (was 0) | 3324 (was 3) | 6/7 | Fixed by the `libsqlite3.so.0` symlink above — the real bug wasn't in the search at all, it was fuzzing an uninstrumented system library the whole time |

3 of the 6 (lua, openssl, libxml2) already worked without any changes. The
remaining 3 (libtiff, libsndfile, sqlite) each hit a different bug — two in
OGHarn's type resolution, one in this demo's build configuration — and all
three are now fixed and verified above.
