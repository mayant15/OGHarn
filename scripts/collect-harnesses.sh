#!/usr/bin/env bash

set -euo pipefail

DEST="$1"

collect() {
  PROJECT="$1"
  mkdir -p "$DEST/$PROJECT"
  cp -vr demos/$PROJECT/out-* "demos/$PROJECT/index.log" "demos/$PROJECT/lib.db" "$DEST/$PROJECT"
}

# collect libpng
# collect libxml2
# collect libtiff
# collect libsndfile
# collect lua
# collect sqlite
collect openssl
