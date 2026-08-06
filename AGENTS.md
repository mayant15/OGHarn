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
