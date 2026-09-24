/* Generated with AI. */

#ifndef _TRAFFIC_LIBTIFF_SUPPORT_H
#define _TRAFFIC_LIBTIFF_SUPPORT_H

#include <tiffio.h>

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Caps how large a wrapper below will let a directory-driven allocation
   grow. Attacker-controlled width/height/rowsperstrip can otherwise blow
   the fuzzer's memory budget on their own; a huge-but-nonfailing malloc is
   a resource-exhaustion finding about this harness, not about libtiff. */
#define TIFF_FUZZ_MAX_BUF (64 * 1024 * 1024)

/* ---- Read: fixed-size in-memory source --------------------------------
 *
 * Backs tiff_open_r. TIFFClientOpen's read/write/seek/close/size arguments
 * are real callback function pointers over this fixed fuzzed buffer;
 * Traffic can only construct `fn () ()` stubs, not callbacks with real
 * logic, hence the wrapper.
 */

typedef struct {
  const uint8_t *data;
  size_t size;
  size_t offset;
} tiff_mem_src_t;

static tmsize_t tiff_src_read(thandle_t handle, void *buffer,
                               tmsize_t requested) {
  tiff_mem_src_t *in = (tiff_mem_src_t *)handle;
  size_t available, count;

  if (requested <= 0 || in->offset >= in->size)
    return 0;
  available = in->size - in->offset;
  count = (uint64_t)requested < (uint64_t)available ? (size_t)requested
                                                      : available;
  memcpy(buffer, in->data + in->offset, count);
  in->offset += count;
  return (tmsize_t)count;
}

static tmsize_t tiff_src_write(thandle_t handle, void *buffer,
                                tmsize_t size) {
  (void)handle;
  (void)buffer;
  (void)size;
  return -1; /* read-only handle */
}

static toff_t tiff_src_seek(thandle_t handle, toff_t offset, int whence) {
  tiff_mem_src_t *in = (tiff_mem_src_t *)handle;
  size_t base;

  switch (whence) {
    case SEEK_SET:
      base = 0;
      break;
    case SEEK_CUR:
      base = in->offset;
      break;
    case SEEK_END:
      base = in->size;
      break;
    default:
      return (toff_t)-1;
  }
  /* toff_t is unsigned (uint64_t); libtiff only ever seeks with
     non-negative offsets, so rejecting anything past the fixed buffer
     end is enough -- no underflow from a "negative" seek to worry about. */
  if (offset > (toff_t)(in->size - base))
    return (toff_t)-1;
  in->offset = base + (size_t)offset;
  return (toff_t)in->offset;
}

static int tiff_src_close(thandle_t handle) {
  free(handle);
  return 0;
}

static toff_t tiff_src_size(thandle_t handle) {
  return (toff_t)((tiff_mem_src_t *)handle)->size;
}

/* Opens the fuzzed buffer for reading. Mode "r" makes libtiff read the
   first directory before returning, so a non-NULL result also means the
   first directory parsed successfully. */
TIFF *tiff_open_r(const uint8_t *data, int size) {
  tiff_mem_src_t *in;
  TIFF *tif;

  if (size < 0)
    return NULL;
  in = (tiff_mem_src_t *)malloc(sizeof(*in));
  if (in == NULL)
    return NULL;
  in->data = data;
  in->size = (size_t)size;
  in->offset = 0;

  tif = TIFFClientOpen("traffic-mem-r", "r", (thandle_t)in, tiff_src_read,
                        tiff_src_write, tiff_src_seek, tiff_src_close,
                        tiff_src_size, NULL, NULL);
  if (tif == NULL)
    free(in);
  return tif;
}

/* ---- Write: growable in-memory destination -----------------------------
 *
 * Backs tiff_open_w. Unlike the read side's fixed buffer, the write
 * destination must grow as libtiff writes strips/directory data, so this
 * is not just a mode-flag variant of tiff_open_r.
 */

typedef struct {
  uint8_t *data;
  size_t size;
  size_t cap;
  size_t offset;
} tiff_mem_dst_t;

static tmsize_t tiff_dst_read(thandle_t handle, void *buffer,
                               tmsize_t requested) {
  (void)handle;
  (void)buffer;
  (void)requested;
  return 0; /* write-only handle */
}

static int tiff_dst_grow(tiff_mem_dst_t *out, size_t need) {
  size_t newcap;
  uint8_t *p;

  if (need <= out->cap)
    return 1;
  if (need > TIFF_FUZZ_MAX_BUF)
    return 0;
  newcap = out->cap != 0 ? out->cap : 4096;
  while (newcap < need)
    newcap *= 2;
  p = (uint8_t *)realloc(out->data, newcap);
  if (p == NULL)
    return 0;
  out->data = p;
  out->cap = newcap;
  return 1;
}

static tmsize_t tiff_dst_write(thandle_t handle, void *buffer,
                                tmsize_t requested) {
  tiff_mem_dst_t *out = (tiff_mem_dst_t *)handle;
  size_t need;

  if (requested < 0)
    return -1;
  need = out->offset + (size_t)requested;
  if (!tiff_dst_grow(out, need))
    return -1;
  memcpy(out->data + out->offset, buffer, (size_t)requested);
  out->offset += (size_t)requested;
  if (out->offset > out->size)
    out->size = out->offset;
  return requested;
}

static toff_t tiff_dst_seek(thandle_t handle, toff_t offset, int whence) {
  tiff_mem_dst_t *out = (tiff_mem_dst_t *)handle;
  size_t base;

  switch (whence) {
    case SEEK_SET:
      base = 0;
      break;
    case SEEK_CUR:
      base = out->offset;
      break;
    case SEEK_END:
      base = out->size;
      break;
    default:
      return (toff_t)-1;
  }
  /* Seeking alone doesn't grow the buffer -- only an actual write does,
     via tiff_dst_write -- so unlike tiff_src_seek there is no size cap
     to enforce here. */
  out->offset = base + (size_t)offset;
  return (toff_t)out->offset;
}

static int tiff_dst_close(thandle_t handle) {
  tiff_mem_dst_t *out = (tiff_mem_dst_t *)handle;
  free(out->data);
  free(out);
  return 0;
}

static toff_t tiff_dst_size(thandle_t handle) {
  return (toff_t)((tiff_mem_dst_t *)handle)->size;
}

/* Opens a fresh write-mode handle backed by a growable in-memory buffer.
   The buffer and its bookkeeping struct are freed by tiff_dst_close,
   which libtiff invokes internally when the caller calls the real
   TIFFClose on the returned handle. */
TIFF *tiff_open_w(void) {
  tiff_mem_dst_t *out;
  TIFF *tif;

  out = (tiff_mem_dst_t *)calloc(1, sizeof(*out));
  if (out == NULL)
    return NULL;

  tif = TIFFClientOpen("traffic-mem-w", "w", (thandle_t)out, tiff_dst_read,
                        tiff_dst_write, tiff_dst_seek, tiff_dst_close,
                        tiff_dst_size, NULL, NULL);
  if (tif == NULL) {
    free(out->data);
    free(out);
  }
  return tif;
}

/* ---- Sized-buffer decode/encode wrappers -------------------------------
 *
 * TIFFReadEncodedStrip/TIFFWriteEncodedStrip/TIFFReadRGBAImage all take a
 * caller-allocated buffer whose correct size depends on the parsed
 * directory. Traffic's only allocation intrinsic (`fresh`) yields a
 * single-element pointer, not a sized buffer, so exposing these directly
 * would make Traffic's own harness under-allocate -- a crash in the
 * scaffolding, not a real libtiff bug. These wrappers allocate the exact
 * size internally and expose only an int status.
 */

/* Always strip 0: every successfully opened TIFF has at least one strip,
   so this needs no extra "which strip" argument to stay reachable. */
static int tiff_fuzz_read_strip(TIFF *tif) {
  tmsize_t size = TIFFStripSize(tif);
  void *buf;
  tmsize_t n;

  if (size <= 0 || size > TIFF_FUZZ_MAX_BUF)
    return -1;
  buf = _TIFFmalloc(size);
  if (buf == NULL)
    return -1;
  n = TIFFReadEncodedStrip(tif, 0, buf, size);
  _TIFFfree(buf);
  return (int)n;
}

static int tiff_fuzz_read_rgba(TIFF *tif) {
  uint32_t w, h;
  uint32_t *raster;
  int status;

  if (TIFFGetField(tif, TIFFTAG_IMAGEWIDTH, &w) != 1)
    return -1;
  if (TIFFGetField(tif, TIFFTAG_IMAGELENGTH, &h) != 1)
    return -1;
  if (w == 0 || h == 0 || w > 0x1000 || h > 0x1000)
    return -1;
  raster = (uint32_t *)_TIFFmalloc(
      (tmsize_t)((size_t)w * (size_t)h * sizeof(uint32_t)));
  if (raster == NULL)
    return -1;
  status = TIFFReadRGBAImage(tif, w, h, raster, 0);
  _TIFFfree(raster);
  return status;
}

/* Encoder counterpart to tiff_fuzz_read_strip: writes strip 0 with pixel
   content drawn from the same fuzzed bytes the input TIFF was opened
   from (repeated/truncated to fit), rather than a constant buffer, so
   the compressor sees adversarial content instead of an all-zero strip. */
static int tiff_fuzz_write_strip(TIFF *tif, const uint8_t *data, int size) {
  tmsize_t strip_size = TIFFStripSize(tif);
  uint8_t *buf;
  tmsize_t i;
  tmsize_t n;

  if (strip_size <= 0 || strip_size > TIFF_FUZZ_MAX_BUF)
    return -1;
  buf = (uint8_t *)_TIFFmalloc(strip_size);
  if (buf == NULL)
    return -1;
  if (size > 0) {
    for (i = 0; i < strip_size; i++)
      buf[i] = data[i % (tmsize_t)size];
  } else {
    memset(buf, 0, (size_t)strip_size);
  }
  n = TIFFWriteEncodedStrip(tif, 0, buf, strip_size);
  _TIFFfree(buf);
  return (int)n;
}

#endif /* _TRAFFIC_LIBTIFF_SUPPORT_H */
