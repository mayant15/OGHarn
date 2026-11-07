#!/usr/bin/env bash

# Regenerate invalid-seed garbage files for a demo, matching the number of
# valid seeds it has.
#
# Usage: .bin/gen-invalid.sh <DEMO>
#
# Deletes existing files in demos/<DEMO>/seeds_invalid, then calls
# scripts/gen-garbage.sh to write as many garbage files as there are files
# in demos/<DEMO>/seeds_valid.

set -euo pipefail

usage() {
  echo "usage: $0 <DEMO>" >&2
  exit 2
}

(($# == 1)) || usage
demo="$1"

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
valid_dir="$root/demos/$demo/seeds_valid"
invalid_dir="$root/demos/$demo/seeds_invalid"

[[ -d "$valid_dir" ]] || {
  echo "error: $valid_dir does not exist" >&2
  exit 1
}

count="$(find "$valid_dir" -maxdepth 1 -type f | wc -l)"

rm -rf "$invalid_dir"

"$root/scripts/gen-garbage.sh" "$invalid_dir" "$count"
