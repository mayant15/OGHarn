#!/usr/bin/env bash

set -euo pipefail

cd demos/

run_project() {
  DEMO="$1"
  shift

  echo "[*] running $DEMO"

  cd $DEMO
  ogharn.py -i $PWD -n 3 -m $PWD/lib.db -r b -d -f -c $PWD/config.yaml "$@"
  cd ..
}

run_project libpng     -o out -h png.h png-support.h
run_project libtiff    -o out -h tiffio.h tiff-support.h
run_project libsndfile -o out -h sndfile.h sndfile-support.h
run_project libxml2    -o out -h libxml/parser.h libxml/xmlreader.h libxml/tree.h libxml/globals.h libxml/xmlIO.h
run_project lua        -o out -h lua.h lauxlib.h
run_project openssl    -o out -h openssl/x509.h openssl/x509_vfy.h x509-support.h
run_project sqlite     -o out -h sqlite3.h
