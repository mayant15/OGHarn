#!/usr/bin/env bash

# Generate random garbage files, for use as e.g. invalid fuzzing seeds.
#
# Usage: scripts/gen-garbage.sh [--size SIZE] <OUT> <COUNT>
#
# Writes COUNT files of SIZE random bytes each into OUT (created if missing),
# named garbage-0, garbage-1, ....
#
# Generated with AI.

set -euo pipefail

usage() {
  echo "usage: $0 [--size SIZE] <OUT> <COUNT>" >&2
  exit 2
}

size=1024
args=()
while (($#)); do
  case "$1" in
    --size)
      (($# >= 2)) || usage
      size="$2"
      shift
      ;;
    -h | --help) usage ;;
    -*) usage ;;
    *) args+=("$1") ;;
  esac
  shift
done

((${#args[@]} == 2)) || usage
out="${args[0]}"
count="${args[1]}"

[[ "$size" =~ ^[0-9]+$ ]] || usage
[[ "$count" =~ ^[0-9]+$ ]] || usage

mkdir -p "$out"

for ((i = 0; i < count; i++)); do
  dst="$out/garbage-$i"
  head -c "$size" /dev/urandom >"$dst"
  echo "[*] wrote $dst ($size bytes)"
done
