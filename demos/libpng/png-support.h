/* Generated with AI. */

#ifndef _TRAFFIC_LIBPNG_SUPPORT_H
#define _TRAFFIC_LIBPNG_SUPPORT_H

#include <png.h>

#include <stdlib.h>
#include <string.h>

/* png_image is a public, caller-allocated struct: the real API contract
   requires the caller to zero it and set `version = PNG_IMAGE_VERSION`
   before calling png_image_begin_read_from_memory. Traffic has no struct
   literals and no way to write individual fields, so this is the "small
   C initializer" libpng.tf's header comment calls out -- it does the
   zeroing/version-stamping libpng.tf itself has no way to express, in
   place of the `fresh` intrinsic's uninitialized stack memory. */
png_image *png_fuzz_new_image(void) {
  /* png_access_version_number is a real, side-effect-free libpng export
     (it just returns the compiled PNG_LIBPNG_VER constant) -- calling it
     gives Traffic's coverage-guided search an actual libpng code path to
     attribute to this wrapper. Without it, png_fuzz_new_image is pure
     malloc/memset with no library call in it, so it looks, from a
     coverage standpoint, indistinguishable from doing nothing: the
     search's feedback loop only keeps a candidate around when it hits
     new coverage, so a version of this wrapper that touches no libpng
     code would never survive to become the stepping stone that lets the
     search build up to png_image_begin_read_from_memory. */
  (void)png_access_version_number();

  png_image *image = (png_image *)malloc(sizeof(png_image));
  if (image == NULL)
    return NULL;
  memset(image, 0, sizeof(*image));
  image->version = PNG_IMAGE_VERSION;
  return image;
}

/* Counterpart to png_fuzz_new_image. png_image_free (the real libpng API,
   also declared in libpng.tf) never frees the png_image struct itself --
   only image->opaque's internal allocation -- since the real API expects
   that struct to be caller-owned (normally stack-allocated). This wrapper
   calls the real png_image_free first (safe to call at any point in the
   image's lifecycle: it is a no-op when opaque is still NULL, e.g. an
   image that never got past png_image_begin_read_from_memory, and it
   nulls opaque out after freeing it, so it is also safe to call again on
   an image some other path already tore down) and then frees the struct
   png_fuzz_new_image malloc'd, so no fuzz iteration leaks it. */
void png_fuzz_free_image(png_image *image) {
  png_image_free(image);
  free(image);
}

#endif /* _TRAFFIC_LIBPNG_SUPPORT_H */
