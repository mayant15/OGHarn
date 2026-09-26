# Adapting `png-support.h` for OGHarn

## Problem

Running `run_ogharn.sh` against the stock `png-support.h` produced **zero**
final harnesses. OGHarn's search exhaustively tried every combination of the
whitelisted API (`png_image_begin_read_from_memory`, `png_image_finish_read`,
`png_image_free`, `png_fuzz_new_image`, `png_fuzz_free_image`) but never
called `png_fuzz_new_image()` to obtain a real `png_image` — every candidate
harness instead passed `NULL` or a locally zeroed struct as the first
argument. libpng's internal `version` check rejects that immediately, so
coverage plateaued at 7 edges and no harness ever reached real PNG parsing
code.

## Root cause

libpng declares `png_image` as an **anonymous struct aliased to two typedef
names at once** (`lib_plain/png.h:2672-2708`):

```c
typedef struct
{
    ...
} png_image, *png_imagep;
```

The original `png-support.h` wrote `png_fuzz_new_image`'s return type as
`png_image *`, while libpng's own `png_image_begin_read_from_memory`,
`png_image_finish_read`, and `png_image_free` all take a `png_imagep`
argument (`lib_plain/png.h:2991,2995,3030`). Structurally these are the same
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

Verified in `out/debug-info/log_potential_dependencies.txt` from the
original (broken) run: `png_fuzz_new_image` only appears with a dependency
to `png_fuzz_free_image` (its own header — same typedef spelling on both
sides), never to any `png_image_*` function from `png.h`.

## Fix

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

## Verification

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

The best final harness (`out_fixed/final-harnesses/src/harness1:486-new-tuples.c`)
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
(`png-support.h:41`) — expected, since this minimal harness only calls
`png_image_begin_read_from_memory` and never reaches `png_fuzz_free_image`.

## Caveat: the observed "crashes" are likely harness artifacts, not libpng bugs

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

## Generalization

Any Traffic/OGHarn support header for a library that exposes a type via
`typedef struct { ... } Name, *NameP;` (anonymous struct, multiple typedef
spellings) should spell wrapper return/parameter types **using the exact
typedef name the target library's own API uses**, not a structurally
equivalent alternative — otherwise OGHarn's dependency inference may not
connect them, silently degrading harness quality without any error message.
