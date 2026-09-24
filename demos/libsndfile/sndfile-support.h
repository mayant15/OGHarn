// https://github.com/libsndfile/libsndfile/blob/4ab48d19f6d6ffb2876a0ab7fd319aca914dc404/ossfuzz/sndfile_fuzz_header.h
//
// sf_init_file made to close the handle when it rejects an opened file, and
// sf_fuzz_get_chunk_data made to skip zero-length chunks, with AI assistance
// (Claude Code); see the comments at each.

#ifndef SNDFILE_FUZZ_HEADER_H
#define SNDFILE_FUZZ_HEADER_H

#include <sndfile.h>
#include <errno.h>
#include <inttypes.h> // PRId64
#include <string.h>   // memcpy etc.

typedef SNDFILE* SndFileP;

typedef struct
{
  sf_count_t offset ;
  sf_count_t length ;
  const unsigned char *data ;
} VIO_DATA ;

static sf_count_t vfget_filelen (void *user_data)
{  VIO_DATA *vf = (VIO_DATA *)user_data ;
   return vf->length ;
}

static sf_count_t vfseek (sf_count_t offset, int whence, void *user_data)
{
  VIO_DATA *vf = (VIO_DATA *)user_data ;
  sf_count_t new_offset ;

  switch (whence)
  {   case SEEK_SET :
        new_offset = offset ;
        break ;

    case SEEK_CUR :
        new_offset = vf->offset + offset ;
        break ;

    case SEEK_END :
        new_offset = vf->length + offset ;
        break ;

    default :
        // SEEK_DATA and SEEK_HOLE are not supported by this function.
        errno = EINVAL ;
        return -1 ;
        break ;
  }

  /* Ensure you can't seek outside the data */
  if (new_offset > vf->length)
  {  /* Trying to seek past the end of the data */
     printf("vf overseek: new_offset(%" PRId64 ") > vf->length(%" PRId64 ");"
            "  whence(%d), vf->offset(%" PRId64 "), offset(%" PRId64 ")\n",
            new_offset, vf->length, whence, vf->offset, offset) ;
     new_offset = vf->length ;
  }
  else if (new_offset < 0)
  {  /* Trying to seek before the start of the data */
     printf("vf underseek: new_offset(%" PRId64 ") < 0;  whence(%d), vf->offset"
            "(%" PRId64 "), vf->length(%" PRId64 "), offset(%" PRId64 ")\n",
            new_offset, whence, vf->offset, vf->length, offset) ;
     new_offset = 0 ;
  }
  vf->offset = new_offset ;

  return vf->offset ;
}

static sf_count_t vfread (void *ptr, sf_count_t count, void *user_data)
{  VIO_DATA *vf = (VIO_DATA *)user_data ;

   if (vf->offset + count > vf->length)
     count = vf->length - vf->offset ;

   memcpy(ptr, vf->data + vf->offset, count) ;
   vf->offset += count ;

   return count ;
}

static sf_count_t vfwrite (const void *ptr, sf_count_t count, void *user_data)
{
  (void)ptr ;
  (void)count ;
  (void)user_data ;

  // Cannot write to this virtual file.
  return 0;
}

static sf_count_t vftell (void *user_data)
{ VIO_DATA *vf = (VIO_DATA *)user_data ;

  return vf->offset ;
}

int sf_init_file(const uint8_t *data, 
                size_t size, 
                SNDFILE **sndfile, 
                VIO_DATA *vio_data, 
                SF_VIRTUAL_IO *vio, SF_INFO *sndfile_info)
{
   // Initialize the virtual IO structure.
   vio->get_filelen = vfget_filelen ;
   vio->seek = vfseek ;
   vio->read = vfread ;
   vio->write = vfwrite ;
   vio->tell = vftell ;

   // Initialize the VIO user data.
   vio_data->data = data ;
   vio_data->length = size ;
   vio_data->offset = 0 ;

   memset(sndfile_info, 0, sizeof(SF_INFO)) ;

   // Try and open the virtual file.
   *sndfile = sf_open_virtual(vio, SFM_READ, sndfile_info, vio_data) ;

   // A file rejected here may still have been opened (e.g. more than 1M
   // channels). The spec can't close a handle from the error path, so close it
   // here instead of leaking it.
   if (sndfile_info->channels == 0 || sndfile_info->channels > 1024 * 1024)
   {  if (*sndfile != NULL)
        sf_close (*sndfile) ;
      *sndfile = NULL ;
      return -1 ;
   }

   return 0;
}

// sf_fuzz_readf_* / sf_fuzz_writef_* added with AI assistance (Claude Code).
// sf_readf_* and sf_writef_* read or write frames * channels samples through
// the caller's buffer, and Traffic's `fresh` only yields a single-element
// pointer, so these wrappers allocate a buffer of exactly that size. frames
// <= 0 is passed through with a NULL buffer, since libsndfile rejects it
// before touching the buffer.

#include <stdlib.h>

#define SF_FUZZ_MAX_SAMPLES (1 << 20)

// Returns the number of samples to allocate, 0 for frames <= 0, or -1 if the
// request is too large.
static sf_count_t sf_fuzz_samples(SNDFILE *file, int frames)
{  SF_INFO info ;

   if (frames <= 0)
     return 0 ;

   memset(&info, 0, sizeof(info)) ;
   if (sf_command(file, SFC_GET_CURRENT_SF_INFO, &info, sizeof(info)) != 0)
     return -1 ;
   if (info.channels <= 0 || (sf_count_t)frames * info.channels > SF_FUZZ_MAX_SAMPLES)
     return -1 ;

   return (sf_count_t)frames * info.channels ;
}

int sf_fuzz_readf_int(SNDFILE *file, int frames)
{  sf_count_t samples = sf_fuzz_samples(file, frames) ;
   int *buf = NULL ;
   sf_count_t count ;

   if (samples < 0)
     return -1 ;
   if (samples > 0 && (buf = calloc(samples, sizeof(int))) == NULL)
     return -1 ;
   count = sf_readf_int(file, buf, frames) ;
   free(buf) ;
   return (int)count ;
}

int sf_fuzz_writef_int(SNDFILE *file, int frames)
{  sf_count_t samples = sf_fuzz_samples(file, frames) ;
   int *buf = NULL ;
   sf_count_t count ;

   if (samples < 0)
     return -1 ;
   if (samples > 0 && (buf = calloc(samples, sizeof(int))) == NULL)
     return -1 ;
   count = sf_writef_int(file, buf, frames) ;
   free(buf) ;
   return (int)count ;
}

int sf_fuzz_readf_double(SNDFILE *file, int frames)
{  sf_count_t samples = sf_fuzz_samples(file, frames) ;
   double *buf = NULL ;
   sf_count_t count ;

   if (samples < 0)
     return -1 ;
   if (samples > 0 && (buf = calloc(samples, sizeof(double))) == NULL)
     return -1 ;
   count = sf_readf_double(file, buf, frames) ;
   free(buf) ;
   return (int)count ;
}

int sf_fuzz_writef_double(SNDFILE *file, int frames)
{  sf_count_t samples = sf_fuzz_samples(file, frames) ;
   double *buf = NULL ;
   sf_count_t count ;

   if (samples < 0)
     return -1 ;
   if (samples > 0 && (buf = calloc(samples, sizeof(double))) == NULL)
     return -1 ;
   count = sf_writef_double(file, buf, frames) ;
   free(buf) ;
   return (int)count ;
}

// sf_fuzz_get_chunk_iterator / sf_fuzz_get_chunk_data added with AI assistance
// (Claude Code). sf_get_chunk_iterator reads chunk_info->id as a C string and
// sf_get_chunk_data reads the chunk into chunk_info->data, so neither is safe
// with the uninitialized SF_CHUNK_INFO that `fresh` yields. These wrappers
// build a zeroed SF_CHUNK_INFO themselves.
//
// Zero-length chunks are skipped: with virtual I/O, libsndfile divides by the
// chunk length in psf_fread (bugs/libsndfile-zero-length-chunk-fpe.md), and
// the seed corpus hits that almost immediately, hiding other findings. Define
// SF_FUZZ_ALLOW_ZERO_CHUNK to reach the bug again.

#define SF_FUZZ_MAX_CHUNK (1 << 20)

SF_CHUNK_ITERATOR *sf_fuzz_get_chunk_iterator(SNDFILE *file, const char *id)
{  SF_CHUNK_INFO info ;

   if (id == NULL)
     return sf_get_chunk_iterator(file, NULL) ;

   memset(&info, 0, sizeof(info)) ;
   strncpy(info.id, id, sizeof(info.id) - 1) ;
   info.id_size = (unsigned)strlen(info.id) ;
   return sf_get_chunk_iterator(file, &info) ;
}

int sf_fuzz_get_chunk_data(const SF_CHUNK_ITERATOR *it)
{  SF_CHUNK_INFO info ;
   int err ;

   memset(&info, 0, sizeof(info)) ;
   if ((err = sf_get_chunk_size(it, &info)) != SF_ERR_NO_ERROR)
     return err ;
   if (info.datalen > SF_FUZZ_MAX_CHUNK)
     return -1 ;
#ifndef SF_FUZZ_ALLOW_ZERO_CHUNK
   if (info.datalen == 0)
     return SF_ERR_NO_ERROR ;
#endif
   // sf_get_chunk_data rejects a NULL data pointer, so allocate at least 1.
   if ((info.data = malloc(info.datalen > 0 ? info.datalen : 1)) == NULL)
     return -1 ;
   err = sf_get_chunk_data(it, &info) ;
   free(info.data) ;
   return err ;
}

#endif
