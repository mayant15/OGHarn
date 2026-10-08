#!/usr/bin/env bash

set -euo pipefail

ITER="$1"

cd demos/

run_project() {
  DEMO="$1"
  shift

  OUT="$1"
  shift

  echo "[*] running $DEMO"

  cd $DEMO
  { time ogharn.py -o $OUT -i $PWD -n 3 -m $PWD/lib.db -r b -d -f -c $PWD/config.yaml "$@"; } 2>&1 | tee "$OUT.log"
  cd ..
}

run_project libpng     "out-$ITER" -h png.h png-support.h
run_project libtiff    "out-$ITER" -h tiffio.h tiff-support.h
run_project libsndfile "out-$ITER" -h sndfile.h sndfile-support.h
run_project libxml2    "out-$ITER" -h libxml/parser.h libxml/xmlreader.h libxml/tree.h libxml/globals.h libxml/xmlIO.h
run_project lua        "out-$ITER" -h lua.h lauxlib.h
run_project sqlite     "out-$ITER" -h sqlite3.h
# run_project openssl    "out-$ITER" -h openssl/x509.h openssl/x509_vfy.h x509-support.h
