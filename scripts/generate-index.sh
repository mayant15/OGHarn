#!/usr/bin/env bash

# Generate Multiplier indexes (demos/<lib>/lib.db) inside the OGHarn container.
#
# Usage: scripts/generate-index.sh [--no-build] [-o|--output DIR] [lib ...]
#
# The lib_plain/compile_commands.json files record absolute paths under
# /root/demos, so ./demos is mounted at exactly that path in the container.
# If a demo has no compile database yet, `make lib_plain` is run first.
# With --output, each successfully indexed lib.db is copied to DIR/<lib>.db.
#
# Generated with AI.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
image="${OGHARN_IMAGE:-ogharn:latest}"
mount_point=/root/demos

usage() {
  echo "usage: $0 [--no-build] [-o|--output DIR] [lib ...]" >&2
  exit 2
}

build=1
out_dir=
libs=()
while (($#)); do
  case "$1" in
    --no-build) build=0 ;;
    -o | --output)
      (($# >= 2)) || usage
      out_dir="$2"
      shift
      ;;
    -h | --help) usage ;;
    -*) usage ;;
    *) libs+=("$1") ;;
  esac
  shift
done

if ((${#libs[@]} == 0)); then
  libs=(libpng libtiff lua openssl sqlite libsndfile libxml2)
fi

for lib in "${libs[@]}"; do
  if [[ ! -f "$repo_root/demos/$lib/Makefile" ]]; then
    echo "error: no demo named '$lib' in $repo_root/demos" >&2
    exit 1
  fi
done

if ((build)); then
  echo "[index] Building $image"
  docker build -t "$image" "$repo_root"
fi

log="$(mktemp)"
trap 'rm -f "$log"' EXIT

# Seconds as m:ss; anything non-numeric (e.g. "-" for a skipped build) as-is.
fmt_time() {
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    printf '%d:%02d' $(($1 / 60)) $(($1 % 60))
  else
    printf '%s' "$1"
  fi
}

# Thousands separators without depending on the host locale.
fmt_count() {
  sed ':a;s/\B[0-9]\{3\}\>/,&/;ta' <<<"$1"
}

header=("Library" "Build \`lib_plain\`" "Index" "Functions")
rows=()
failed=()
for lib in "${libs[@]}"; do
  echo "[index] $lib"
  workdir="$mount_point/$lib"
  # The container reports "__STATS__ <build s> <index s> <functions>" last;
  # build is "-" when an existing compile database was reused.
  if docker run --rm \
      --volume "$repo_root/demos:$mount_point" \
      --workdir "$workdir" \
      --env "PWD=$workdir" \
      "$image" bash -euo pipefail -c '
        build_s=-
        if [[ ! -f lib_plain/compile_commands.json ]]; then
          start=$SECONDS
          make lib_plain
          build_s=$((SECONDS - start))
        fi
        rm -rf lib.db lib.db-* mx
        start=$SECONDS
        make run_mx
        index_s=$((SECONDS - start))
        # A clean mx-index exit does not guarantee a usable index (see
        # AGENTS.md, "-march=native"), so make sure declarations were found.
        count=$(mx-list-functions --db lib.db | wc -l)
        echo "indexed functions: $count"
        echo "__STATS__ $build_s $index_s $count"
        ((count > 0))
      ' 2>&1 | tee "$log"; then
    read -r _ build_s index_s count < <(grep '^__STATS__ ' "$log" | tail -n 1)
    rows+=("$lib|$(fmt_time "$build_s")|$(fmt_time "$index_s")|$(fmt_count "$count")")
  else
    failed+=("$lib")
    rows+=("$lib|FAILED|FAILED|FAILED")
  fi
done

# Print the summary as an aligned markdown table.
widths=()
for i in "${!header[@]}"; do
  widths[i]=${#header[i]}
done
for row in "${rows[@]}"; do
  IFS='|' read -ra cells <<<"$row"
  for i in "${!cells[@]}"; do
    if ((${#cells[i]} > widths[i])); then
      widths[i]=${#cells[i]}
    fi
  done
done
print_row() {
  local line="|" i
  for i in "${!widths[@]}"; do
    line+=" $(printf '%-*s' "${widths[i]}" "$1") |"
    shift
  done
  echo "$line"
}
echo
print_row "${header[@]}"
separators=()
for w in "${widths[@]}"; do
  separators+=("$(printf '%*s' "$w" '' | tr ' ' '-')")
done
print_row "${separators[@]}"
for row in "${rows[@]}"; do
  IFS='|' read -ra cells <<<"$row"
  print_row "${cells[@]}"
done
echo

if [[ -n "$out_dir" ]]; then
  mkdir -p "$out_dir"
  for lib in "${libs[@]}"; do
    if [[ " ${failed[*]} " == *" $lib "* ]]; then
      continue
    fi
    db="$repo_root/demos/$lib/lib.db"
    # Stale sidecars from an earlier copy would corrupt the new database.
    rm -f "$out_dir/$lib.db-wal" "$out_dir/$lib.db-shm"
    cp "$db" "$out_dir/$lib.db"
    # Keep any un-checkpointed SQLite writes with the copy.
    if [[ -s "$db-wal" ]]; then
      cp "$db-wal" "$out_dir/$lib.db-wal"
    fi
    echo "[index] Copied $lib -> $out_dir/$lib.db"
  done
fi

if ((${#failed[@]})); then
  echo "[index] FAILED: ${failed[*]}" >&2
  exit 1
fi
echo "[index] Done: ${libs[*]}"
