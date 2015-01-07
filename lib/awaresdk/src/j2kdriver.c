/**********************************************************************
 *
 * Copyright 2002 Aware, Inc.
 *
 * $Workfile: j2kdriver.c $    $Revision: 124 $
 * Last Modified: $Date: 2/28/05 3:06p $ by: $Author: Rgut $
 *
 **********************************************************************/
volatile const static char id_test_c[] = "@(#) $Header: /JPEG2000/platform/solaris/src/j2kdriver.c 124   2/28/05 3:06p Rgut $ Aware Inc.";

#define __EXTENSIONS__
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "j2k.h"
#include "aw_j2k_errors.h"
#include "get_precise_time.h"

#ifdef _WIN32
#  include <fcntl.h>
#  include <io.h>
#  include <windows.h>
#  define Free(x) HeapFree(GetProcessHeap(), 0, (x))
#  define Calloc(x,y) HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, ((x)*(y)))
#  define Malloc(x) HeapAlloc(GetProcessHeap(), 0, (x))
#  define Realloc(x,y) HeapReAlloc(GetProcessHeap(), 0,(x), (y))
#else /* !_WIN32 */
#  define Free free
#  define Calloc calloc
#  define Malloc malloc
#  define Realloc realloc

#endif /* _WIN32 */


#ifdef J2KTESTBED
#if defined(_WIN32) && !defined(J2K_STATIC_LIBRARY)
# define DLLEXPORT __declspec(dllexport)
# define DLLIMPORT DLLEXPORT
#else /* _WIN32 && !J2K_STATIC_LIBRARY */
# ifdef DLLEXPORT
#  undef DLLEXPORT
# endif /* DLLEXPORT */
# define DLLEXPORT
# ifdef DLLIMPORT
#  undef DLLIMPORT
# endif /* DLLIMPORT */
# define DLLIMPORT
#endif /* _WIN32 && !J2K_STATIC_LIBRARY */
#endif


/* Input from non-seekable sources (such as a pipe) is done in blocks.
 * READING_BLOCK_SIZE defines the size of this block.
 */
#define READING_BLOCK_SIZE 524288

/* forward declarations for I/O helper functions */
static BYTE *
load_raw_data_from_stdio(unsigned long *length);
static BYTE *
load_raw_data(char *filename, unsigned long *length);
static void
write_raw_data(char *filename, BYTE *data, unsigned long data_length);
static void
downcase(char *string);
static void
print_binary(FILE *fp, BYTE *data, int num_data);

#define ARG_MANDATORY 0         /* mandatory argument */
#define ARG_OPTIONAL  1         /* optional argument */

typedef struct {
  int argc;                     /* total count of arguments */
  int arg;                      /* current argument */
  char **argv;                  /* array of argument strings */
} args_t;

typedef struct {
  int help_flag;                /* display help on True else execute option */
  int verbosity_flag;           /* level of info printout  */
  int benchmark_flag;           /* number of benchmark iterations */
  FILE *diagnostic_stream;      /* where to send verbose output and help */

  /* the next two fields are used to keep track of run times */
  double file_read_time;         /* time to read image into memory */
  double memory_read_time;       /* time to load image into object */
} state_flags;

#define VERBOSITY_MAXIMUM_LEVEL 2
#define VERBOSITY_MINIMUM_LEVEL 0


/* this structure holds the list of options supported by this program */
typedef struct {
  void (*handler)(args_t *args, state_flags *flags, /* function to handle */
                  aw_j2k_object *j2k_object);       /* this option        */
  char *option;                 /* the name of the option */
  char *desc;                   /* option description     */
} aw_option_t;


static void
read_int_or_string(char **dest_string, int *dest_int, args_t *args,
                   state_flags *flags, int optional_flag, char *err_message);
static void
read_string(char **dest_string, args_t *args, state_flags *flags,
            int optional_flag, char *err_message);
static void
read_int(int *dest_int, args_t *args, state_flags *flags, int optional_flag,
         char *err_message);
static void
read_ulint(unsigned long int *dest, args_t *args, state_flags *flags,
           int optional_flag, char *err_message);
static void
read_lint(long int *dest, args_t *args, state_flags *flags,
          int optional_flag, char *err_message);
static void
read_float(float *dest, args_t *args, state_flags *flags, int optional_flag,
           char *err_message);
static void
read_boolean(BOOL *dest, args_t *args, state_flags *flags, int optional_flag,
             char *err_message);
static int
read_type(args_t *args, state_flags *flags, int optional_flag,
          char *err_message);
static unsigned long int
read_jp2_box_type(args_t *args, state_flags *flags, int optional_flag,
                  char *err_message);
static void
read_tile(int *tile_index, args_t *args, state_flags *flags);
static void
read_tile_and_channel(int *tile_index, int *channel_index, args_t *args,
                      state_flags *flags);

static void
call__get_library_version(args_t *args, state_flags *flags,
                          aw_j2k_object *j2k_object)
{
  int retval;
  unsigned long library_version;
  char *print_which;
  char library_version_string[AW_J2K_LIBRARY_VERSION_STRING_MINIMUM_LENGTH];

  read_string(&print_which, args, flags, ARG_OPTIONAL, NULL);

  retval = aw_j2k_get_library_version(&library_version, library_version_string,
                                      sizeof(library_version_string));
  if (retval == NO_ERROR) {
    if (print_which && (print_which[0] == 'n' || print_which[0] == 'N'))
      fprintf(flags->diagnostic_stream, "%ld.%ld.%ld.%ld\n",
              library_version / 1000000, (library_version / 10000) % 100,
              (library_version / 100) % 100, library_version % 100);
    else
      fprintf(flags->diagnostic_stream, "%s (%ld.%ld.%ld.%ld)\n",
              library_version_string,
              library_version / 1000000, (library_version / 10000) % 100,
              (library_version / 100) % 100, library_version % 100);
  }
  else {
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_library_version returned error code %d\n",
            retval);
  }

  return;
}

static void
call__reset_all_options(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  retval = aw_j2k_reset_all_options(j2k_object);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_reset_all_options returned error code %d\n",
            retval);
  return;
}
static void
call__set_internal_option(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  char *internal_option_string, *internal_option_value_string;
  int internal_option, internal_option_value;

  internal_option_string = internal_option_value_string = 0;
  internal_option = internal_option_value = 0;

  if (!strcmp(args->argv[args->arg], "--fixed-point")) {
    internal_option       = AW_J2K_INTERNAL_ARITHMETIC_OPTION;
    internal_option_value = AW_J2K_INTERNAL_USE_FIXED_POINT;
  }
  else if (!strcmp(args->argv[args->arg], "--floating-point")) {
    internal_option       = AW_J2K_INTERNAL_ARITHMETIC_OPTION;
    internal_option_value = AW_J2K_INTERNAL_USE_FLOATING_POINT;
  }
  else {
    read_int_or_string(&internal_option_string, &internal_option, args, flags,
                       ARG_MANDATORY, "Internal option not specified");
    read_int_or_string(&internal_option_value_string, &internal_option_value,
                       args, flags, ARG_MANDATORY,
                       "Internal option value not specified");
    if (internal_option_string &&
        (internal_option_string[0] == 'a' ||
         internal_option_string[0] == 'A')) {
      internal_option = AW_J2K_INTERNAL_ARITHMETIC_OPTION;
      if (internal_option_value_string &&
          (internal_option_value_string[0] == 'f' ||
           internal_option_value_string[0] == 'F')) {
        if (internal_option_value_string[1] == 'l' ||
            internal_option_value_string[1] == 'L')
          internal_option_value = AW_J2K_INTERNAL_USE_FLOATING_POINT;
        else if (internal_option_value_string[1] == 'i' ||
                 internal_option_value_string[1] == 'I')
          internal_option_value = AW_J2K_INTERNAL_USE_FIXED_POINT;
        else {
          fprintf(flags->diagnostic_stream,
                  "Unknown internal option value `%s', ignored.\n",
                  internal_option_value_string);
          return;
        }
      }
      else {
        if (internal_option_value_string) {
          fprintf(flags->diagnostic_stream,
                  "Unknown internal option value `%s', ignored.\n",
                  internal_option_value_string);
          return;
        }
      }
    }
    else {
      if (internal_option_string) {
        fprintf(flags->diagnostic_stream,
                "Unknown internal option `%s', ignored.\n",
                internal_option_string);
        return;
      }
    }
  }

  retval = aw_j2k_set_internal_option(j2k_object, internal_option,
                                      internal_option_value);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_internal_option returned error code %d\n",
            retval);
  return;
}
static void
call__set_input_image(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  char *image_name;
  unsigned char *buffer;
  unsigned long buffer_length;

  read_string(&image_name, args, flags, ARG_MANDATORY,
              "Image file name not specified");

  flags->file_read_time = get_precise_time();
  buffer = load_raw_data(image_name, &buffer_length);
  flags->file_read_time = get_precise_time() - flags->file_read_time;

  if (!buffer || buffer_length == 0) {
    if (image_name[0] == '-' && image_name[1] == '\0')
      fprintf(stderr, "Error: unable to read from stdin\n");
    else
      fprintf(stderr, "Error: unable to read `%s'\n", image_name);
    return;
  }

  flags->memory_read_time = get_precise_time();
  retval = aw_j2k_set_input_image(j2k_object, buffer, buffer_length);
  flags->memory_read_time = get_precise_time() - flags->memory_read_time;

  Free(buffer);

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_input_image returned error code %d\n",
            retval);
  return;
}
static void
call__set_input_image_type(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, type;
  char *image_name;
  unsigned char *buffer;
  unsigned long buffer_length;

  type = read_type(args, flags, ARG_MANDATORY, "Image type not specified");

  read_string(&image_name, args, flags, ARG_MANDATORY,
              "Image file name not specified");

  flags->file_read_time = get_precise_time();
  buffer = load_raw_data(image_name, &buffer_length);
  flags->file_read_time = get_precise_time() - flags->file_read_time;

  if (!buffer || buffer_length == 0) {
    if (image_name[0] == '-' && image_name[1] == '\0')
      fprintf(stderr, "Error: unable to read from stdin\n");
    else
      fprintf(stderr, "Error: unable to read `%s'\n", image_name);
    return;
  }

  flags->memory_read_time = get_precise_time();
  retval = aw_j2k_set_input_image_type(j2k_object, type, buffer,
                                       buffer_length);
  flags->memory_read_time = get_precise_time() - flags->memory_read_time;

  Free(buffer);

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_input_image_type returned error code %d\n",
            retval);
  return;
}
static void
call__set_input_image_raw(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  char *image_name;
  unsigned char *buffer;
  unsigned long buffer_length;
  unsigned long int rows, cols, channels;
  long int bit_depth;
  BOOL interleaved = FALSE;

  read_string(&image_name, args, flags, ARG_MANDATORY,
              "Image file name not specified");

  read_ulint(&rows, args, flags, ARG_MANDATORY, "Image rows not specified");
  read_ulint(&cols, args, flags, ARG_MANDATORY, "Image columns not specified");
  read_ulint(&channels, args, flags, ARG_MANDATORY,
             "The number of image channels not specified");
  read_lint(&bit_depth, args, flags, ARG_MANDATORY,
            "Total image bit depth not specified");

  read_boolean(&interleaved, args, flags, ARG_OPTIONAL, NULL);

  flags->file_read_time = get_precise_time();
  buffer = load_raw_data(image_name, &buffer_length);
  flags->file_read_time = get_precise_time() - flags->file_read_time;

  if (!buffer || buffer_length == 0) {
    if (image_name[0] == '-' && image_name[1] == '\0')
      fprintf(stderr, "Error: unable to read from stdin\n");
    else
      fprintf(stderr, "Error: unable to read `%s'\n", image_name);
    return;
  }

  flags->memory_read_time = get_precise_time();
  retval = aw_j2k_set_input_image_raw(j2k_object, buffer, rows, cols,
                                      channels, (unsigned long int)bit_depth,
                                      interleaved);
  flags->memory_read_time = get_precise_time() - flags->memory_read_time;

  Free(buffer);

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_input_image_raw returned error code %d\n",
            retval);
  return;
}
static void
call__set_input_image_raw_ex(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  char *image_name;
  unsigned char *buffer;
  unsigned long buffer_length;
  unsigned long int rows, cols, channels;
  long int bit_depth, bits_allocated;
  BOOL interleaved = FALSE;

  read_string(&image_name, args, flags, ARG_MANDATORY,
              "Image file name not specified");

  read_ulint(&rows, args, flags, ARG_MANDATORY, "Image rows not specified");
  read_ulint(&cols, args, flags, ARG_MANDATORY, "Image columns not specified");
  read_ulint(&channels, args, flags, ARG_MANDATORY,
             "The number of image channels not specified");
  read_lint(&bits_allocated, args, flags, ARG_MANDATORY,
            "Total image allocated bit depth not specified");
  read_lint(&bit_depth, args, flags, ARG_MANDATORY,
            "Total image stored bit depth not specified");

  read_boolean(&interleaved, args, flags, ARG_OPTIONAL, NULL);

  flags->file_read_time = get_precise_time();
  buffer = load_raw_data(image_name, &buffer_length);
  flags->file_read_time = get_precise_time() - flags->file_read_time;

  if (!buffer || buffer_length == 0) {
    if (image_name[0] == '-' && image_name[1] == '\0')
      fprintf(stderr, "Error: unable to read from stdin\n");
    else
      fprintf(stderr, "Error: unable to read `%s'\n", image_name);
    return;
  }

  flags->memory_read_time = get_precise_time();
  retval = aw_j2k_set_input_image_raw_ex(j2k_object, buffer, rows, cols,
                                         channels, bits_allocated, bit_depth,
                                         interleaved);
  flags->memory_read_time = get_precise_time() - flags->memory_read_time;

  Free(buffer);

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_input_image_raw_ex returned error code %d\n",
            retval);
  return;
}
static void
call__set_input_image_raw_channel(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  char *channel_file_name;
  unsigned char *buffer;
  unsigned long buffer_length, channel;

  read_ulint(&channel, args, flags, ARG_MANDATORY,
             "Channel index not specified");

  read_string(&channel_file_name, args, flags, ARG_MANDATORY,
              "Channel data file name not specified");

  flags->file_read_time = get_precise_time();
  buffer = load_raw_data(channel_file_name, &buffer_length);
  flags->file_read_time = get_precise_time() - flags->file_read_time;

  if (!buffer || buffer_length == 0) {
    if (channel_file_name[0] == '-' && channel_file_name[1] == '\0')
      fprintf(stderr, "Error: unable to read from stdin\n");
    else
      fprintf(stderr, "Error: unable to read `%s'\n", channel_file_name);
    return;
  }

  flags->memory_read_time = get_precise_time();
  retval = aw_j2k_set_input_image_raw_channel(j2k_object, channel, buffer,
                                              buffer_length);
  flags->memory_read_time = get_precise_time() - flags->memory_read_time;

  Free(buffer);

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_input_image_raw_channel returned error code %d\n",
            retval);
  return;
}

static void
call__set_input_image_raw_region(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  char *file_name;
  unsigned char *buffer;
  unsigned long buffer_length, channel, row, row_offset, col, col_offset;
  BOOL bInterleaved = FALSE;

  read_string(&file_name, args, flags, ARG_MANDATORY,
              "Region data file name not specified");

  read_ulint(&row_offset, args, flags, ARG_MANDATORY,
             "row offset not specified");
  read_ulint(&col_offset, args, flags, ARG_MANDATORY,
             "col offset not specified");
  read_ulint(&row, args, flags, ARG_MANDATORY,
             "row not specified");
  read_ulint(&col, args, flags, ARG_MANDATORY,
             "col not specified");
  read_ulint(&channel, args, flags, ARG_MANDATORY,
             "channel not specified");
  read_boolean(&bInterleaved, args, flags, ARG_OPTIONAL, NULL);

  flags->file_read_time = get_precise_time();
  buffer = load_raw_data(file_name, &buffer_length);
  flags->file_read_time = get_precise_time() - flags->file_read_time;

  if (!buffer || buffer_length == 0) {
    if (file_name[0] == '-' && file_name[1] == '\0')
      fprintf(stderr, "Error: unable to read from stdin\n");
    else
      fprintf(stderr, "Error: unable to read `%s'\n", file_name);
    return;
  }

  flags->memory_read_time = get_precise_time();

  retval = aw_j2k_set_input_image_raw_region(j2k_object, row_offset,
                                             col_offset, row, col, channel,
                                             buffer, bInterleaved);

  flags->memory_read_time = get_precise_time() - flags->memory_read_time;

  Free(buffer);

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_input_image_raw_region returned error code %d\n",
            retval);
  return;
}

static void
call__set_input_image_file(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  char *image_name;

  read_string(&image_name, args, flags, ARG_MANDATORY,
              "Image file name not specified");

  flags->memory_read_time = 0.0F;
  flags->file_read_time = get_precise_time();
  retval = aw_j2k_set_input_image_file(j2k_object, image_name);
  flags->file_read_time = get_precise_time() - flags->file_read_time;

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_input_image_file returned error code %d\n",
            retval);
  return;
}
static void
call__set_input_image_file_type(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, type;
  char *image_name;

  read_string(&image_name, args, flags, ARG_MANDATORY,
              "Image file name not specified");

  type = read_type(args, flags, ARG_MANDATORY, "Image type not specified");

  flags->memory_read_time = 0.0F;
  flags->file_read_time = get_precise_time();
  retval = aw_j2k_set_input_image_file_type(j2k_object, image_name, type);
  flags->file_read_time = get_precise_time() - flags->file_read_time;

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_input_image_file_type returned error code %d\n",
            retval);
  return;
}
static void
call__set_input_image_file_raw(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  char *image_name;
  unsigned long int rows, cols, channels;
  long int bit_depth;
  BOOL interleaved = FALSE;

  read_string(&image_name, args, flags, ARG_MANDATORY,
              "Image file name not specified");

  read_ulint(&rows, args, flags, ARG_MANDATORY, "Image rows not specified");
  read_ulint(&cols, args, flags, ARG_MANDATORY, "Image columns not specified");
  read_ulint(&channels, args, flags, ARG_MANDATORY,
             "The number of image channels not specified");
  read_lint(&bit_depth, args, flags, ARG_MANDATORY,
            "Total image bit depth not specified");

  read_boolean(&interleaved, args, flags, ARG_OPTIONAL, NULL);

  flags->memory_read_time = 0.0F;
  flags->file_read_time = get_precise_time();
  retval = aw_j2k_set_input_image_file_raw(j2k_object, image_name, rows, cols,
                                           channels,
                                           (unsigned long int)bit_depth,
                                           interleaved);
  flags->file_read_time = get_precise_time() - flags->file_read_time;

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_input_image_file_raw returned error code %d\n",
            retval);
  return;
}
static void
call__set_input_raw_information(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  unsigned long int rows, cols, channels;
  long int bit_depth;
  BOOL interleaved = FALSE;

  read_ulint(&rows, args, flags, ARG_MANDATORY, "Image rows not specified");
  read_ulint(&cols, args, flags, ARG_MANDATORY, "Image columns not specified");
  read_ulint(&channels, args, flags, ARG_MANDATORY,
             "The number of image channels not specified");
  read_lint(&bit_depth, args, flags, ARG_MANDATORY,
            "Total image bit depth not specified");

  read_boolean(&interleaved, args, flags, ARG_OPTIONAL, NULL);

  retval = aw_j2k_set_input_raw_information(j2k_object, rows, cols, channels,
                                            (unsigned long int)bit_depth,
                                            interleaved);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_input_raw_information returned error code %d\n",
            retval);
  return;
}
static void
call__set_input_raw_channel_bpp(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  unsigned long int channel;
  long int bit_depth;

  read_ulint(&channel, args, flags, ARG_MANDATORY,
             "Channel index not specified");
  read_lint(&bit_depth, args, flags, ARG_MANDATORY,
            "Channel bit depth not specified");

  retval = aw_j2k_set_input_raw_channel_bpp(j2k_object, channel, bit_depth);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_input_raw_channel_bpp returned error code %d\n",
            retval);
  return;
}
static void
call__set_input_raw_endianness(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, endianness;
  char *endianness_string;

  endianness_string = NULL;
  endianness = 0;

  read_int_or_string(&endianness_string, &endianness, args, flags,
                     ARG_MANDATORY, "Missing endianness specification");

  if (endianness_string) {
    switch (endianness_string[0]) {
    case 'b': case 'B':         /* "big" */
      endianness = AW_J2K_ENDIAN_BIG;
      break;
    case 'l': case 'L': case 's': case 'S':
      endianness = AW_J2K_ENDIAN_SMALL;
      break;
    default:
      endianness = AW_J2K_ENDIAN_LOCAL_MACHINE;
    }
  }

  retval = aw_j2k_set_input_raw_endianness(j2k_object,
                                           (unsigned long int)endianness);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_input_raw_endianness returned error code %d\n",
            retval);
  return;
}
static void
call__set_input_raw_channel_subsampling(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  unsigned long int channel, x_subsampling, y_subsampling;

  read_ulint(&channel, args, flags, ARG_MANDATORY,
             "Channel index not specified");
  read_ulint(&x_subsampling, args, flags, ARG_MANDATORY,
             "Horizontal subsampling not specified");
  read_ulint(&y_subsampling, args, flags, ARG_MANDATORY,
             "Vertical subsampling not specified");

  retval = aw_j2k_set_input_raw_channel_subsampling(j2k_object, channel,
                                                    x_subsampling,
                                                    y_subsampling);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_input_raw_channel_subsampling returned error code %d\n",
            retval);
  return;
}
static void
call__get_input_image_info(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  unsigned long int columns, rows, bit_depth, channels;

  retval = aw_j2k_get_input_image_info(j2k_object, &columns, &rows, &bit_depth,
                                       &channels);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_input_image_info returned error code %d\n",
            retval);
  else
    fprintf(flags->diagnostic_stream,
            "Uncompressed image information:\n"
            "   %ld columns by %ld rows, %ld channels, %ld bpp = %ld bytes\n",
            columns, rows, channels, bit_depth,
            columns * rows * ((bit_depth + 7) / 8));
  return;
}
static void
call__get_input_channel_bpp(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  unsigned long int channel;
  long int bit_depth;

  read_ulint(&channel, args, flags, ARG_MANDATORY,
             "Channel index not specified");

  retval = aw_j2k_get_input_channel_bpp(j2k_object, channel, &bit_depth);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_input_channel_bpp returned error code %d\n",
            retval);
  else {
    if (bit_depth < 0)
      fprintf(flags->diagnostic_stream,
              "Channel %ld bit depth: %ld (signed)\n", channel, -bit_depth);
    else
      fprintf(flags->diagnostic_stream,
              "Channel %ld bit depth: %ld (unsigned)\n", channel, bit_depth);
  }
  return;
}
static void
call__get_input_j2k_channel_subsampling(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  unsigned long int channel, x_subsampling, y_subsampling;

  read_ulint(&channel, args, flags, ARG_MANDATORY,
             "Channel index not specified");

  retval = aw_j2k_get_input_j2k_channel_subsampling(j2k_object, channel,
                                                    &x_subsampling,
                                                    &y_subsampling);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_input_j2k_channel_subsampling returned error code %d\n",
            retval);
  else
    fprintf(flags->diagnostic_stream,
            "Channel %ld Subsampling: X:%ld Y:%ld\n", channel, x_subsampling,
            y_subsampling);
  return;
}
static void
call__get_input_j2k_num_comments(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, num_comments;

  retval = aw_j2k_get_input_j2k_num_comments(j2k_object, &num_comments);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_input_j2k_num_comments returned error code %d\n",
            retval);
  else
    fprintf(flags->diagnostic_stream,
            "Found %d comments\n", num_comments);
  return;
}
static void
call__get_input_j2k_comments(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, comment_index;
  unsigned char *comment_data;
  unsigned long int length, type, location;

  comment_data = NULL; /* setting this to NULL will cause the library
                        * to allocate a buffer for the comment data */
  length = 0;

  read_int(&comment_index, args, flags, ARG_MANDATORY,
           "Comment index not specified");

  retval = aw_j2k_get_input_j2k_comments(j2k_object, comment_index,
                                         &comment_data, &length, &type,
                                         &location);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_input_j2k_comments returned error code %d\n",
            retval);
  else {
    fprintf(flags->diagnostic_stream, "Comment type %s, length %ld\n",
            type == AW_J2K_CO_BINARY ? "binary" : "ISO-8859-1 (Latin 1)",
            length);
    if (type == AW_J2K_CO_BINARY) {
      print_binary(flags->diagnostic_stream, comment_data, length);
    }
    else {
      unsigned char *comment_ptr = comment_data;
      fprintf(flags->diagnostic_stream, "Comment string: `");
      while (length--)
        printf("%c", *comment_ptr++);
      printf("'\n");
    }
    aw_j2k_free(j2k_object, comment_data);
  }

  return;
}
static void
call__get_input_j2k_progression_info(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  unsigned long int order, prog_levels, xform_levels, layers, channels,
    precincts, progression_available;

  retval = aw_j2k_get_input_j2k_progression_info(j2k_object, &order,
                                                 &prog_levels,
                                                 &xform_levels,
                                                 &layers, &channels,
                                                 &precincts,
                                                 &progression_available);

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_input_j2k_progression_info returned error code %d\n",
            retval);
  else {
    fprintf(flags->diagnostic_stream, "Progression information:\n  Progression order: ");

    switch (order) {
    case AW_J2K_PO_LAYER_RESOLUTION_COMPONENT_POSITION:
      fprintf(flags->diagnostic_stream, "Layer, resolution, component, position\n");
      break;
    case AW_J2K_PO_RESOLUTION_LAYER_COMPONENT_POSITION:
      fprintf(flags->diagnostic_stream, "Resolution, layer, component, position\n");
      break;
    case AW_J2K_PO_RESOLUTION_POSITION_COMPONENT_LAYER:
      fprintf(flags->diagnostic_stream, "Resolution, position, component, layer\n");
      break;
    case AW_J2K_PO_POSITION_COMPONENT_RESOLUTION_LAYER:
      fprintf(flags->diagnostic_stream, "Position, component, resolution, layer\n");
      break;
    case AW_J2K_PO_COMPONENT_POSITION_RESOLUTION_LAYER:
      fprintf(flags->diagnostic_stream, "Component, position, resolution, layer\n");
      break;
    }

    fprintf(flags->diagnostic_stream,
            "  Resolution levels: %ld\n"
            "  Quality layers: %ld\n"
            "  Color channels: %ld\n"
            "  Precincts: %ld\n"
            "  Progression level available: %ld (1 is max, %ld is min)\n",
            xform_levels, layers, channels, precincts, progression_available,
            prog_levels);
  }

  return;
}
static void
call__get_input_j2k_progression_byte_count(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, index;
  unsigned long int progression_offset;

  read_int(&index, args, flags, ARG_MANDATORY,
           "Progression index not specified");

  retval = aw_j2k_get_input_j2k_progression_byte_count(j2k_object, index,
                                                       &progression_offset);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_input_j2k_progression_byte_count returned error code %d\n",
            retval);
  else
    fprintf(flags->diagnostic_stream,
            "Progression level %d at offset %ld\n",
            index, progression_offset);
  return;
}
static void
call__get_input_j2k_tile_info(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  unsigned long int tile_offset_x, tile_offset_y, tile_cols, tile_rows,
    image_offset_x, image_offset_y;

  retval = aw_j2k_get_input_j2k_tile_info(j2k_object, &tile_offset_x,
                                          &tile_offset_y, &tile_cols,
                                          &tile_rows, &image_offset_x,
                                          &image_offset_y);

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_input_j2k_tile_info returned error code %d\n",
            retval);
  else {
    fprintf(flags->diagnostic_stream,
            "Tiling information:\n"
            "  tile offset: %ld,%ld\n"
            "  tile size: %ld,%ld\n"
            "  image offset: %ld,%ld\n",
            tile_offset_x, tile_offset_y,
            tile_cols, tile_rows,
            image_offset_x, image_offset_y);
  }
  return;
}
static void
call__get_input_j2k_selected_tile_geometry(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  unsigned long int tile_index, tile_columns, tile_rows, tile_offset_x,
    tile_offset_y;

  read_ulint(&tile_index, args, flags, ARG_MANDATORY,
             "Tile index not specified");

  retval = aw_j2k_get_input_j2k_selected_tile_geometry(j2k_object, tile_index,
                                                       &tile_columns,
                                                       &tile_rows,
                                                       &tile_offset_x,
                                                       &tile_offset_y);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_input_j2k_selected_tile_geometry returned error code %d\n",
            retval);
  else {
    fprintf(flags->diagnostic_stream,
            "Tile %ld information:\n"
            "  tile offset: %ld,%ld\n"
            "  tile size: %ld,%ld\n",
            tile_index,
            tile_offset_x, tile_offset_y,
            tile_columns, tile_rows);
  }
  return;
}
static void
call__get_input_j2k_component_registration(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, channel;
  WORD x_registration_offset, y_registration_offset;

  read_int(&channel, args, flags, ARG_MANDATORY,
           "channel not specified");

  retval = aw_j2k_get_input_j2k_component_registration(j2k_object, channel,
                                                       &x_registration_offset,
                                                       &y_registration_offset);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_input_j2k_component_registration returned error code %d\n",
            retval);
  else {
    fprintf(flags->diagnostic_stream,
            "Channel %d registration offset from origin: X:%d/65536 Y:%d/65536\n",
            channel, x_registration_offset, y_registration_offset);
  }
  return;
}
static void
call__get_input_j2k_bytes_read(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  DWORD bytes;
  retval = aw_j2k_get_input_j2k_bytes_read(j2k_object, &bytes);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_input_j2k_bytes_read returned error code %d\n",
            retval);
  else
    fprintf(flags->diagnostic_stream,
            "Decompression used up %ld bytes\n", bytes);
  return;
}
static void
call__set_input_j2k_progression_level(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, progression_level;

  read_int(&progression_level, args, flags, ARG_MANDATORY,
           "Progression level not specified");

  retval = aw_j2k_set_input_j2k_progression_level(j2k_object,
                                                  progression_level);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_input_j2k_progression_level returned error code %d\n",
            retval);
  return;
}
static void
call__set_input_j2k_resolution_level(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, resolution_level;
  BOOL full_transform;

  full_transform = FALSE;

  read_int(&resolution_level, args, flags, ARG_MANDATORY,
           "Resolution level not specified");

  read_boolean(&full_transform, args, flags, ARG_OPTIONAL, NULL);

  retval = aw_j2k_set_input_j2k_resolution_level(j2k_object, resolution_level,
                                                 full_transform);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_input_j2k_resolution_level returned error code %d\n",
            retval);
  return;
}
static void
call__set_input_j2k_quality_level(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, quality_level;

  read_int(&quality_level, args, flags, ARG_MANDATORY,
           "Quality level not specified");

  retval = aw_j2k_set_input_j2k_quality_level(j2k_object, quality_level);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_input_j2k_quality_level returned error code %d\n",
            retval);
  return;
}
static void
call__set_input_j2k_color_level(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, color_level, color_transform_flag;
  char *color_transform_flag_string;

  color_transform_flag = AW_J2K_CT_DEFAULT;
  color_transform_flag_string = NULL;

  read_int(&color_level, args, flags, ARG_MANDATORY,
           "Color level not specified");

  read_int_or_string(&color_transform_flag_string, &color_transform_flag, args,
                     flags, ARG_OPTIONAL, NULL);

  if (color_transform_flag_string) {
    switch (color_transform_flag_string[0]) {
    case 'y': case 'Y':
      color_transform_flag = AW_J2K_CT_PERFORM;
      break;
    case 'n': case 'N':
      color_transform_flag = AW_J2K_CT_SKIP;
      break;
    default:
      color_transform_flag = AW_J2K_CT_DEFAULT;
    }
  }

  retval = aw_j2k_set_input_j2k_color_level(j2k_object, color_level,
                                            color_transform_flag);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_input_j2k_color_level returned error code %d\n",
            retval);
  return;
}
static void
call__set_input_j2k_region_level(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  unsigned long int x0, x1, y0, y1;

  read_ulint(&x0, args, flags, ARG_MANDATORY,
             "Left coordinate of region not specified");
  read_ulint(&y0, args, flags, ARG_MANDATORY,
             "Top coordinate of region not specified");
  read_ulint(&x1, args, flags, ARG_MANDATORY,
             "Right coordinate of region not specified");
  read_ulint(&y1, args, flags, ARG_MANDATORY,
             "Bottom coordinate of region not specified");

  retval = aw_j2k_set_input_j2k_region_level(j2k_object, x0, y0, x1, y1);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_input_j2k_region_level returned error code %d\n",
            retval);
  return;
}
static void
call__set_input_j2k_selected_channel(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  unsigned long int channel;

  read_ulint(&channel, args, flags, ARG_MANDATORY,
             "Selected Channel not specified");

  retval = aw_j2k_set_input_j2k_selected_channel(j2k_object, channel);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_input_j2k_selected_channel returned error code %d\n",
            retval);
  return;
}
static void
call__set_input_j2k_selected_tile(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, tile;

  read_int(&tile, args, flags, ARG_MANDATORY, "Selected tile not specified");

  retval = aw_j2k_set_input_j2k_selected_tile(j2k_object, tile);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_input_j2k_selected_tile returned error code %d\n",
            retval);
  return;
}

static void
call__set_input_dcm_frame_index(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, frame_index = 0;
  
  read_int(&frame_index, args, flags, ARG_MANDATORY, "Selected frame index not specified"); 
  
  retval = aw_j2k_set_input_dcm_frame_index(j2k_object, frame_index);

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_input_dcm_frame_index returned error code %d\n",
            retval);

  return;
}

static void
call__input_reset_options(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  retval = aw_j2k_input_reset_options(j2k_object);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_input_reset_options returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_type(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, image_type;

  image_type = read_type(args, flags, ARG_MANDATORY,
                         "Output image type not specified");

  retval = aw_j2k_set_output_type(j2k_object, image_type);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_type returned error code %d\n",
            retval);
  return;
}
static void
call__get_output_image(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, iteration;
  char *image_name;
  unsigned char *image_buffer;
  unsigned long int image_buffer_length;
  double file_write_time, memory_write_time, memory_write_time_temp;

  read_string(&image_name, args, flags, ARG_MANDATORY,
              "Output image file name not specified");

  image_buffer = NULL;

  memory_write_time = get_precise_time();
  retval = aw_j2k_get_output_image(j2k_object, &image_buffer,
                                   &image_buffer_length);
  memory_write_time = get_precise_time() - memory_write_time;

  if (!retval && flags->benchmark_flag) {
    /* discard first memory benchmark, and time the call in a loop */
    memory_write_time = 0.0F;
    for (iteration = 0; iteration < flags->benchmark_flag; iteration++) {
      memory_write_time_temp = get_precise_time();
      retval = aw_j2k_get_output_image(j2k_object, &image_buffer,
                                       &image_buffer_length);
      memory_write_time += get_precise_time() - memory_write_time_temp;
      if (retval)
        break;
    }
    memory_write_time /= (double)flags->benchmark_flag;
  }

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_output_image returned error code %d\n",
            retval);
  else {
    file_write_time = get_precise_time();
    write_raw_data(image_name, image_buffer, image_buffer_length);
    file_write_time = get_precise_time() - file_write_time;
    if (flags->verbosity_flag)
      fprintf(flags->diagnostic_stream,
              "Memory-to-memory processing in %.2f seconds\n"
              "File-to-file in %.2f seconds\n",
              flags->memory_read_time + memory_write_time,
              flags->memory_read_time + memory_write_time +
              flags->file_read_time + file_write_time);
    aw_j2k_free(j2k_object, image_buffer);
  }
  return;
}
static void
call__get_output_image_type(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, image_type, iteration;
  char *image_name;
  unsigned char *image_buffer;
  unsigned long int image_buffer_length;
  double file_write_time, memory_write_time, memory_write_time_temp;

  image_type = read_type(args, flags, ARG_MANDATORY,
                         "Output image type not specified");
  read_string(&image_name, args, flags, ARG_MANDATORY,
              "Output image file name not specified");

  image_buffer = NULL;


  memory_write_time = get_precise_time();
  retval = aw_j2k_get_output_image_type(j2k_object, image_type, &image_buffer,
                                        &image_buffer_length);
  memory_write_time = get_precise_time() - memory_write_time;

  if (!retval && flags->benchmark_flag) {
    /* discard first memory benchmark, and time the call in a loop */
    memory_write_time = 0.0F;
    for (iteration = 0; iteration < flags->benchmark_flag; iteration++) {
      memory_write_time_temp = get_precise_time();
      retval = aw_j2k_get_output_image_type(j2k_object, image_type,
                                            &image_buffer,
                                            &image_buffer_length);
      memory_write_time += get_precise_time() - memory_write_time_temp;
      if (retval)
        break;
    }
    memory_write_time /= (double)flags->benchmark_flag;
  }

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_output_image_type returned error code %d\n",
            retval);
  else {
    file_write_time = get_precise_time();
    write_raw_data(image_name, image_buffer, image_buffer_length);
    file_write_time = get_precise_time() - file_write_time;
    if (flags->verbosity_flag)
      fprintf(flags->diagnostic_stream,
              "Memory-to-memory processing in %.2f seconds\n"
              "File-to-file in %.2f seconds\n",
              flags->memory_read_time + memory_write_time,
              flags->memory_read_time + memory_write_time +
              flags->file_read_time + file_write_time);
    aw_j2k_free(j2k_object, image_buffer);
  }
  return;
}
static void
call__get_output_image_raw(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, iteration;
  char *image_name;
  unsigned char *image_buffer;
  unsigned long int image_buffer_length, rows, columns, channels, bit_depth;
  double file_write_time, memory_write_time, memory_write_time_temp;
  BOOL interleaved = FALSE;

  read_string(&image_name, args, flags, ARG_MANDATORY,
              "Output image file name not specified");

  read_boolean(&interleaved, args, flags, ARG_OPTIONAL, NULL);

  image_buffer = NULL;

  memory_write_time = get_precise_time();
  retval = aw_j2k_get_output_image_raw(j2k_object, &image_buffer,
                                       &image_buffer_length, &rows, &columns,
                                       &channels, &bit_depth, interleaved);
  memory_write_time = get_precise_time() - memory_write_time;

  if (!retval && flags->benchmark_flag) {
    /* discard first memory benchmark, and time the call in a loop */
    memory_write_time = 0.0F;
    for (iteration = 0; iteration < flags->benchmark_flag; iteration++) {
      memory_write_time_temp = get_precise_time();
      retval = aw_j2k_get_output_image_raw(j2k_object, &image_buffer,
                                           &image_buffer_length, &rows,
                                           &columns, &channels, &bit_depth,
                                           interleaved);
      memory_write_time += get_precise_time() - memory_write_time_temp;
      if (retval)
        break;
    }
    memory_write_time /= (double)flags->benchmark_flag;
  }

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_output_image_raw returned error code %d\n",
            retval);
  else {
    file_write_time = get_precise_time();
    write_raw_data(image_name, image_buffer, image_buffer_length);
    file_write_time = get_precise_time() - file_write_time;
    if (flags->verbosity_flag) {
      fprintf(flags->diagnostic_stream,
              "Memory-to-memory processing in %.2f seconds\n"
              "File-to-file in %.2f seconds\n",
              flags->memory_read_time + memory_write_time,
              flags->memory_read_time + memory_write_time +
              flags->file_read_time + file_write_time);
      fprintf(flags->diagnostic_stream,
              "Output file information:\n"
              "   %lu bytes\n"
              "   %lu rows\n"
              "   %lu columns\n"
              "   %lu channels\n"
              "   %lu total bit depth\n",
              image_buffer_length, rows, columns, channels, bit_depth);
    }
    aw_j2k_free(j2k_object, image_buffer);
  }
  return;
}
static void
call__get_output_image_raw_ex(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, iteration;
  char *image_name;
  unsigned char *image_buffer;
  unsigned long int image_buffer_length, rows, columns, channels;
  long int bits_stored, bits_allocated;
  double file_write_time, memory_write_time, memory_write_time_temp;
  BOOL interleaved = FALSE;

  bits_allocated = 0;

  read_string(&image_name, args, flags, ARG_MANDATORY,
              "Output image file name not specified");

  read_lint(&bits_allocated, args, flags, ARG_OPTIONAL, NULL);

  read_boolean(&interleaved, args, flags, ARG_OPTIONAL, NULL);

  image_buffer = NULL;

  memory_write_time = get_precise_time();
  retval = aw_j2k_get_output_image_raw_ex(j2k_object, &image_buffer,
                                          &image_buffer_length, &rows,
                                          &columns, &channels, &bits_stored,
                                          bits_allocated, interleaved);
  memory_write_time = get_precise_time() - memory_write_time;

  if (!retval && flags->benchmark_flag) {
    /* discard first memory benchmark, and time the call in a loop */
    memory_write_time = 0.0F;
    for (iteration = 0; iteration < flags->benchmark_flag; iteration++) {
      memory_write_time_temp = get_precise_time();
      retval = aw_j2k_get_output_image_raw_ex(j2k_object, &image_buffer,
                                              &image_buffer_length, &rows,
                                              &columns, &channels, &bits_stored,
                                              bits_allocated, interleaved);
      memory_write_time += get_precise_time() - memory_write_time_temp;
      if (retval)
        break;
    }
    memory_write_time /= (double)flags->benchmark_flag;
  }

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_output_image_raw_ex returned error code %d\n",
            retval);
  else {
    file_write_time = get_precise_time();
    write_raw_data(image_name, image_buffer, image_buffer_length);
    file_write_time = get_precise_time() - file_write_time;
    if (flags->verbosity_flag) {
      fprintf(flags->diagnostic_stream,
              "Memory-to-memory processing in %.2f seconds\n"
              "File-to-file in %.2f seconds\n",
              flags->memory_read_time + memory_write_time,
              flags->memory_read_time + memory_write_time +
              flags->file_read_time + file_write_time);
      fprintf(flags->diagnostic_stream,
              "Output file information:\n"
              "   %lu bytes\n"
              "   %lu rows\n"
              "   %lu columns\n"
              "   %lu channels\n"
              "   %lu total bit depth\n",
              image_buffer_length, rows, columns, channels, bits_stored);
    }
    aw_j2k_free(j2k_object, image_buffer);
  }
  return;
}
static void
call__get_output_image_file(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, iteration;
  char *image_name;
  double file_write_time, file_write_time_temp;

  read_string(&image_name, args, flags, ARG_MANDATORY,
              "Output image file name not specified");

  file_write_time = get_precise_time();
  retval = aw_j2k_get_output_image_file(j2k_object, image_name);
  file_write_time = get_precise_time() - file_write_time;

  if (!retval && flags->benchmark_flag) {
    /* discard first memory benchmark, and time the call in a loop */
    file_write_time = 0.0F;
    for (iteration = 0; iteration < flags->benchmark_flag; iteration++) {
      file_write_time_temp = get_precise_time();
      retval = aw_j2k_get_output_image_file(j2k_object, image_name);
      file_write_time += get_precise_time() - file_write_time_temp;
      if (retval)
        break;
    }
    file_write_time /= (double)flags->benchmark_flag;
  }

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_output_image_file returned error code %d\n",
            retval);
  else {
    if (flags->verbosity_flag)
      fprintf(flags->diagnostic_stream,
              "Memory-to-memory processing in %.2f seconds\n"
              "File-to-file in %.2f seconds\n",
              flags->memory_read_time,
              flags->memory_read_time +
              flags->file_read_time + file_write_time);
  }
  return;
}
static void
call__get_output_image_file_type(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, image_type, iteration;
  char *image_name;
  double file_write_time, file_write_time_temp;

  read_string(&image_name, args, flags, ARG_MANDATORY,
              "Output image file name not specified");

  image_type = read_type(args, flags, ARG_MANDATORY,
                         "Output image type not specified");

  file_write_time = get_precise_time();
  retval = aw_j2k_get_output_image_file_type(j2k_object, image_name,
                                             image_type);
  file_write_time = get_precise_time() - file_write_time;

  if (!retval && flags->benchmark_flag) {
    /* discard first memory benchmark, and time the call in a loop */
    file_write_time = 0.0F;
    for (iteration = 0; iteration < flags->benchmark_flag; iteration++) {
      file_write_time_temp = get_precise_time();
      retval = aw_j2k_get_output_image_file_type(j2k_object, image_name,
                                                 image_type);
      file_write_time += get_precise_time() - file_write_time_temp;
      if (retval)
        break;
    }
    file_write_time /= (double)flags->benchmark_flag;
  }

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_output_image_file_type returned error code %d\n",
            retval);
  else {
    if (flags->verbosity_flag)
      fprintf(flags->diagnostic_stream,
              "Memory-to-memory processing in %.2f seconds\n"
              "File-to-file in %.2f seconds\n",
              flags->memory_read_time,
              flags->memory_read_time +
              flags->file_read_time + file_write_time);
  }
  return;
}
static void
call__get_output_image_file_raw(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, iteration;
  char *image_name;
  unsigned long int rows, columns, channels, bit_depth;
  double file_write_time, file_write_time_temp;
  BOOL interleaved = FALSE;

  read_string(&image_name, args, flags, ARG_MANDATORY,
              "Output image file name not specified");

  read_boolean(&interleaved, args, flags, ARG_OPTIONAL, NULL);

  file_write_time = get_precise_time();
  retval = aw_j2k_get_output_image_file_raw(j2k_object, image_name, &rows,
                                            &columns, &channels, &bit_depth,
                                            interleaved);
  file_write_time = get_precise_time() - file_write_time;

  if (!retval && flags->benchmark_flag) {
    /* discard first memory benchmark, and time the call in a loop */
    file_write_time = 0.0F;
    for (iteration = 0; iteration < flags->benchmark_flag; iteration++) {
      file_write_time_temp = get_precise_time();
      retval = aw_j2k_get_output_image_file_raw(j2k_object, image_name, &rows,
                                                &columns, &channels,
                                                &bit_depth, interleaved);
      file_write_time += get_precise_time() - file_write_time_temp;
      if (retval)
        break;
    }
    file_write_time /= (double)flags->benchmark_flag;
  }

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_output_image_file_raw returned error code %d\n",
            retval);
  else {
    if (flags->verbosity_flag) {
      fprintf(flags->diagnostic_stream,
              "Memory-to-memory processing in %.2f seconds\n"
              "File-to-file in %.2f seconds\n",
              flags->memory_read_time,
              flags->memory_read_time +
              flags->file_read_time + file_write_time);
      fprintf(flags->diagnostic_stream,
              "Output file information:\n"
              "   %lu rows\n"
              "   %lu columns\n"
              "   %lu channels\n"
              "   %lu total bit depth\n",
              rows, columns, channels, bit_depth);
    }
  }
  return;
}
static void
call__set_output_j2k_bitrate(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  float bitrate;

  read_float(&bitrate, args, flags, ARG_MANDATORY, "Bitrate not specified");

  retval = aw_j2k_set_output_j2k_bitrate(j2k_object, bitrate);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_bitrate returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_ratio(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  float ratio;

  read_float(&ratio, args, flags, ARG_MANDATORY,
             "Compression ratio not specified");

  retval = aw_j2k_set_output_j2k_ratio(j2k_object, ratio);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_ratio returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_filesize(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  unsigned long int bytes;

  read_ulint(&bytes, args, flags, ARG_MANDATORY,
             "File size not specified");

  retval = aw_j2k_set_output_j2k_filesize(j2k_object, bytes);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_filesize returned error code %d\n",
            retval);
  return;
}


static void
call__set_output_j2k_psnr(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  float psnr;

  read_float(&psnr, args, flags, ARG_MANDATORY,
             "pSNR value not specified");

  retval = aw_j2k_set_output_j2k_psnr(j2k_object, psnr);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_psnr returned error code %d\n",
            retval);
  return;
}

static void
call__set_output_j2k_color_xform(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  int color_xform;
  char *color_xform_string;

  color_xform = AW_J2K_CT_DEFAULT;
  color_xform_string = NULL;

  read_int_or_string(&color_xform_string, &color_xform, args, flags,
                     ARG_MANDATORY, "Color transform not specified");

  if (color_xform_string) {
    switch (color_xform_string[0]) {
    case 'y': case 'Y':
      color_xform = AW_J2K_CT_PERFORM;
      break;
    case 'n': case 'N':
      color_xform = AW_J2K_CT_SKIP;
      break;
    default:
      color_xform = AW_J2K_CT_DEFAULT;
    }
  }

  retval = aw_j2k_set_output_j2k_color_xform(j2k_object, color_xform);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_color_xform returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_color_xform_ex(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, tile_index, color_xform;
  char *color_xform_string;

  color_xform = AW_J2K_CT_DEFAULT;
  color_xform_string = NULL;

  read_tile(&tile_index, args, flags);

  read_int_or_string(&color_xform_string, &color_xform, args, flags,
                     ARG_MANDATORY, "Color transform not specified");

  if (color_xform_string) {
    switch (color_xform_string[0]) {
    case 'y': case 'Y':
      color_xform = AW_J2K_CT_PERFORM;
      break;
    case 'n': case 'N':
      color_xform = AW_J2K_CT_SKIP;
      break;
    default:
      color_xform = AW_J2K_CT_DEFAULT;
    }
  }

  retval = aw_j2k_set_output_j2k_color_xform_ex(j2k_object, tile_index,
                                                color_xform);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_color_xform_ex returned error code %d\n",
            retval);
  return;
}

static void
call__set_output_j2k_progression_order(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  int progression_order;
  char *progression_order_string;

  progression_order = AW_J2K_PO_DEFAULT;
  progression_order_string = NULL;

  read_int_or_string(&progression_order_string, &progression_order, args, flags,
                     ARG_MANDATORY, "Color transform not specified");

  if (progression_order_string) {
    downcase(progression_order_string);

    if (!strcmp(progression_order_string, "lrcp"))
      progression_order = AW_J2K_PO_LAYER_RESOLUTION_COMPONENT_POSITION;
    else if (!strcmp(progression_order_string, "rlcp"))
      progression_order = AW_J2K_PO_RESOLUTION_LAYER_COMPONENT_POSITION;
    else if (!strcmp(progression_order_string, "rpcl"))
      progression_order = AW_J2K_PO_RESOLUTION_POSITION_COMPONENT_LAYER;
    else if (!strcmp(progression_order_string, "pcrl"))
      progression_order = AW_J2K_PO_POSITION_COMPONENT_RESOLUTION_LAYER;
    else if (!strcmp(progression_order_string, "cprl"))
      progression_order = AW_J2K_PO_COMPONENT_POSITION_RESOLUTION_LAYER;
    else {
      fprintf(flags->diagnostic_stream,
              "Warning: unrecognized progression order `%s'; using default\n",
              progression_order_string);
      progression_order = AW_J2K_PO_DEFAULT;
    }
  }


  retval = aw_j2k_set_output_j2k_progression_order(j2k_object,
                                                   progression_order);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_progression_order returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_tile_size(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  unsigned long int width, height;

  read_ulint(&width, args, flags, ARG_MANDATORY,
             "Tile width not specified");
  read_ulint(&height, args, flags, ARG_MANDATORY,
             "Tile height not specified");

  retval = aw_j2k_set_output_j2k_tile_size(j2k_object, width, height);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_tile_size returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_add_comment(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  char *data, *file_name, *type_string, *location_string;
  int type, location, need_to_free_data;
  unsigned long int length;

  if (!strcmp(args->argv[args->arg], "--add-comment-from-file")) {
    read_string(&file_name, args, flags, ARG_MANDATORY,
                "Comment file name not specified");
    data = (char *)load_raw_data(file_name, &length);

    if (!data || length == 0) {
      if (file_name[0] == '-' && file_name[1] == '\0')
        fprintf(stderr, "Error: unable to read comment from stdin\n");
      else
        fprintf(stderr, "Error: unable to read comment from `%s'\n",
                file_name);
      return;
    }

    need_to_free_data = 1;
    type = AW_J2K_CO_BINARY;
  }
  else {
    read_string(&data, args, flags, ARG_MANDATORY, "Comment not specified");
    length = strlen(data);
    need_to_free_data = 0;
    type = AW_J2K_CO_ISO_8859;
  }

  read_string(&type_string, args, flags, ARG_OPTIONAL, NULL);
  if (type_string) {
    switch (type_string[0]) {
    case 'b': case 'B':
      type = AW_J2K_CO_BINARY;
      break;
    default:
      type = AW_J2K_CO_ISO_8859;
    }
  }

  location = AW_J2K_CO_LOCATION_MAIN_HEADER;
  read_string(&location_string, args, flags, ARG_OPTIONAL, NULL);
  if (location_string) {
    if (isdigit((int)location_string[0])) {
      location = atoi(location_string);
    }
    else {
      location = AW_J2K_CO_LOCATION_MAIN_HEADER;
    }
  }

  retval = aw_j2k_set_output_j2k_add_comment(j2k_object, data, type, length,
                                             location);

  if (need_to_free_data)
    Free(data);

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_add_comment returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_image_offset(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  unsigned long x_offset, y_offset;

  read_ulint(&x_offset, args, flags, ARG_MANDATORY,
             "Image horizontal offset not specified");
  read_ulint(&y_offset, args, flags, ARG_MANDATORY,
             "Image Vertical offset not specified");

  retval = aw_j2k_set_output_j2k_image_offset(j2k_object, x_offset, y_offset);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_image_offset returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_tile_offset(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  unsigned long x_offset, y_offset;

  read_ulint(&x_offset, args, flags, ARG_MANDATORY,
             "Tile horizontal offset not specified");
  read_ulint(&y_offset, args, flags, ARG_MANDATORY,
             "Tile Vertical offset not specified");

  retval = aw_j2k_set_output_j2k_tile_offset(j2k_object, x_offset, y_offset);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_tile_offset returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_error_resilience(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  int use_SOP, use_EPH, use_SEG;
  char *error_resilience_ptr, *p;

  use_SOP = use_EPH = use_SEG = 0;

  read_string(&error_resilience_ptr, args, flags, ARG_MANDATORY,
              "Error resilience options not specified");

  downcase(error_resilience_ptr);
  p = strtok(error_resilience_ptr, ",");
  while (p && *p) {
    if (!strcmp(p, "sop"))
      use_SOP = 1;
    else if (!strcmp(p, "eph"))
      use_EPH = 1;
    else if (!strcmp(p, "seg")) {
      use_SEG = 1;
    }
    else if (!strcmp(p, "all")) {
      use_SOP = 1;
      use_EPH = 1;
      use_SEG = 1;
    }
    else if (!strcmp(p, "none")) {
      use_SOP = 0;
      use_EPH = 0;
      use_SEG = 0;
    }
    else {
      fprintf(stderr,"Warning: Unrecognized Error resilience option `%s', ignored\n",
              p);
    }
    p = strtok(NULL, ",");
  }

  retval = aw_j2k_set_output_j2k_error_resilience(j2k_object, use_SOP, use_EPH,
                                                  use_SEG);

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_error_resilience returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_error_resilience_ex(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, tile_index, channel_index;
  int use_SOP, use_EPH, use_SEG;
  char *error_resilience_ptr, *p;

  read_tile_and_channel(&tile_index, &channel_index, args, flags);

  use_SOP = use_EPH = use_SEG = 0;

  read_string(&error_resilience_ptr, args, flags, ARG_MANDATORY,
              "Error resilience options not specified");

  downcase(error_resilience_ptr);
  p = strtok(error_resilience_ptr, ",");
  while (p && *p) {
    if (!strcmp(p, "sop"))
      use_SOP = 1;
    else if (!strcmp(p, "eph"))
      use_EPH = 1;
    else if (!strcmp(p, "seg")) {
      use_SEG = 1;
    }
    else if (!strcmp(p, "all")) {
      use_SOP = 1;
      use_EPH = 1;
      use_SEG = 1;
    }
    else if (!strcmp(p, "none")) {
      use_SOP = 0;
      use_EPH = 0;
      use_SEG = 0;
    }
    else {
      fprintf(stderr,"Warning: Unrecognized Error resilience option `%s', ignored\n",
              p);
    }
    p = strtok(NULL, ",");
  }

  retval = aw_j2k_set_output_j2k_error_resilience_ex(j2k_object, tile_index,
                                                     channel_index, use_SOP,
                                                     use_EPH, use_SEG);

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_error_resilience_ex returned error code %d\n",
            retval);
  return;
}

static void
call__set_output_j2k_xform(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, type, levels;
  char *type_string;

  read_string(&type_string, args, flags, ARG_MANDATORY,
              "Wavelet transform type not specified");

  type = AW_J2K_WV_TYPE_DEFAULT;
  if (type_string) {
    switch (type_string[0]) {
    case 'i': case 'I':
      type = AW_J2K_WV_TYPE_I97;
      break;
    case 'r': case 'R':
      type = AW_J2K_WV_TYPE_R53;
      break;
    default:
      type = AW_J2K_WV_TYPE_DEFAULT;
    }
  }

  levels = AW_J2K_WV_DEPTH_DEFAULT;
  read_int(&levels, args, flags, ARG_OPTIONAL, NULL);

  retval = aw_j2k_set_output_j2k_xform(j2k_object, type, levels);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_xform returned error code %d\n",
            retval);
  return;
}



static void
call__set_output_j2k_wavelet_mct(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, type, levels, Nmcc;
  char *type_string;

  read_string(&type_string, args, flags, ARG_MANDATORY,
              "MCT Wavelet type not specified");

  type = AW_J2K_WV_TYPE_DEFAULT;
  if (type_string) {
    switch (type_string[0]) {
    case 'i': case 'I':
      type = AW_J2K_WV_TYPE_I97;
      break;
    case 'r': case 'R':
      type = AW_J2K_WV_TYPE_R53;
      break;
    default:
      type = AW_J2K_WV_TYPE_DEFAULT;
    }
  }

  levels = AW_J2K_WV_DEPTH_DEFAULT;
  read_int(&levels, args, flags, ARG_OPTIONAL, NULL);
  
  Nmcc = AW_J2K_SELECT_ALL_CHANNELS; 
  
  read_int(&Nmcc, args, flags, ARG_OPTIONAL, NULL);

  retval = aw_j2k_set_output_j2k_wavelet_mct(j2k_object, type, levels, Nmcc);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_wavelet_mct returned error code %d\n",
            retval);
  return;
}



static void
call__set_output_j2k_xform_ex(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, type, levels, tile_index, channel_index;
  char *type_string;

  read_tile_and_channel(&tile_index, &channel_index, args, flags);

  read_string(&type_string, args, flags, ARG_MANDATORY,
              "Wavelet transform type not specified");

  type = AW_J2K_WV_TYPE_DEFAULT;
  if (type_string) {
    switch (type_string[0]) {
    case 'i': case 'I':
      type = AW_J2K_WV_TYPE_I97;
      break;
    case 'r': case 'R':
      type = AW_J2K_WV_TYPE_R53;
      break;
    default:
      type = AW_J2K_WV_TYPE_DEFAULT;
    }
  }

  levels = AW_J2K_WV_DEPTH_DEFAULT;
  read_int(&levels, args, flags, ARG_OPTIONAL, NULL);

  retval = aw_j2k_set_output_j2k_xform_ex(j2k_object, tile_index,
                                          channel_index, type, levels);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_xform_ex returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_layers(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, layers;

  read_int(&layers, args, flags, ARG_MANDATORY,
           "Number of quality layers not specified");

  retval = aw_j2k_set_output_j2k_layers(j2k_object, layers);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_layers returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_layer_bitrate(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, layer_index;
  float bitrate;

  read_int(&layer_index, args, flags, ARG_MANDATORY,
           "Layer index not specified");

  read_float(&bitrate, args, flags, ARG_MANDATORY,
             "Layer bitrate not specified");

  retval = aw_j2k_set_output_j2k_layer_bitrate(j2k_object, layer_index,
                                               bitrate);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_layer_bitrate returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_layer_bitrate_ex(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, tile_index, layer_index;
  float bitrate;

  read_tile(&tile_index, args, flags);

  read_int(&layer_index, args, flags, ARG_MANDATORY,
           "Layer index not specified");

  read_float(&bitrate, args, flags, ARG_MANDATORY,
             "Layer bitrate not specified");

  retval = aw_j2k_set_output_j2k_layer_bitrate_ex(j2k_object, tile_index,
                                                  layer_index, bitrate);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_layer_bitrate_ex returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_layer_ratio(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, layer_index;
  float ratio;

  read_int(&layer_index, args, flags, ARG_MANDATORY,
           "Layer index not specified");

  read_float(&ratio, args, flags, ARG_MANDATORY,
             "Layer ratio not specified");

  retval = aw_j2k_set_output_j2k_layer_ratio(j2k_object, layer_index, ratio);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_layer_ratio returned error code %d\n",
            retval);
  return;
}

static void
call__set_output_j2k_layer_ratio_ex(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, tile_index, layer_index;
  float ratio;

  read_tile(&tile_index, args, flags);

  read_int(&layer_index, args, flags, ARG_MANDATORY,
           "Layer index not specified");

  read_float(&ratio, args, flags, ARG_MANDATORY,
             "Layer ratio not specified");

  retval = aw_j2k_set_output_j2k_layer_ratio_ex(j2k_object, tile_index,
                                                layer_index, ratio);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_layer_ratio_ex returned error code %d\n",
            retval);
  return;
}


static void
call__set_output_j2k_layer_size(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, layer_index;
  unsigned long int bytes;

  read_int(&layer_index, args, flags, ARG_MANDATORY,
           "Layer index not specified");

  read_ulint(&bytes, args, flags, ARG_MANDATORY,
             "Layer size not specified");

  retval = aw_j2k_set_output_j2k_layer_size(j2k_object, layer_index, bytes);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_layer_size returned error code %d\n",
            retval);
  return;
}

static void
call__set_output_j2k_layer_size_ex(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, tile_index, layer_index;
  unsigned long int bytes;

  read_tile(&tile_index, args, flags);

  read_int(&layer_index, args, flags, ARG_MANDATORY,
           "Layer index not specified");

  read_ulint(&bytes, args, flags, ARG_MANDATORY,
             "Layer size not specified");

  retval = aw_j2k_set_output_j2k_layer_size_ex(j2k_object, tile_index,
                                               layer_index, bytes);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_layer_size_ex returned error code %d\n",
            retval);
  return;
}


static void
call__set_output_j2k_layer_psnr(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, layer_index;
  float psnr;

  read_int(&layer_index, args, flags, ARG_MANDATORY,
           "Layer index not specified");

  read_float(&psnr, args, flags, ARG_MANDATORY,
             "Layer pSNR not specified");

  retval = aw_j2k_set_output_j2k_layer_psnr(j2k_object, layer_index, psnr);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_layer_psnr returned error code %d\n",
            retval);
  return;
}

static void
call__set_output_j2k_layer_psnr_ex(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, tile_index, layer_index;
  float psnr;

  read_tile(&tile_index, args, flags);

  read_int(&layer_index, args, flags, ARG_MANDATORY,
           "Layer index not specified");

  read_float(&psnr, args, flags, ARG_MANDATORY,
             "Layer pSNR not specified");

  retval = aw_j2k_set_output_j2k_layer_psnr_ex(j2k_object, tile_index,
                                               layer_index, psnr);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_layer_psnr_ex returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_channel_quantization(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, channel_index, quantization_option;
  char *channel_string, *quantization_string;
  channel_index = AW_J2K_SELECT_ALL_CHANNELS;
  quantization_option = AW_J2K_QUANTIZATION_EXPOUNDED;

  read_int_or_string(&channel_string, &channel_index, args, flags,
                     ARG_MANDATORY, "Channel index not specified");
  if (channel_string) {
    if (channel_string[0] == 'a' || channel_string[0] == 'A')
      channel_index = AW_J2K_SELECT_ALL_CHANNELS;
    else
      fprintf(flags->diagnostic_stream,
              "Warning: channel index `%s' not recognized\n", channel_string);
  }

  read_string(&quantization_string, args, flags, ARG_MANDATORY,
              "Quantization option not specified");
  if (quantization_string) {
    switch (quantization_string[0]) {
    case 'r': case 'R':
      quantization_option = AW_J2K_QUANTIZATION_REVERSIBLE;
      break;
    case 'd': case 'D':
      quantization_option = AW_J2K_QUANTIZATION_DERIVED;
      break;
    case 'e': case 'E':
      quantization_option = AW_J2K_QUANTIZATION_EXPOUNDED ;
      break;
    default:
      fprintf(flags->diagnostic_stream,
              "Warning: Quantization option `%s' not recognized\n",
              quantization_string);
    }
  }

  retval = aw_j2k_set_output_j2k_channel_quantization(j2k_object,
                                                      channel_index,
                                                      quantization_option);

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_channel_quantization returned error code %d\n",
            retval);
  return;
}

static void
call__set_output_j2k_quantization_ex(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, tile_index, channel_index, quantization_option;
  char *quantization_string;

  read_tile_and_channel(&tile_index, &channel_index, args, flags);

  read_string(&quantization_string, args, flags, ARG_MANDATORY,
              "Quantization option not specified");
  if (quantization_string) {
    switch (quantization_string[0]) {
    case 'r': case 'R':
      quantization_option = AW_J2K_QUANTIZATION_REVERSIBLE;
      break;
    case 'd': case 'D':
      quantization_option = AW_J2K_QUANTIZATION_DERIVED;
      break;
    case 'e': case 'E':
      quantization_option = AW_J2K_QUANTIZATION_EXPOUNDED ;
      break;
    default:
      fprintf(flags->diagnostic_stream,
              "Warning: Quantization option `%s' not recognized\n",
              quantization_string);
    }
  }

  retval = aw_j2k_set_output_j2k_quantization_ex(j2k_object,
                                                 tile_index, channel_index,
                                                 quantization_option);

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_quantization_ex returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_quantization_binwidth_scale(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  float binwidth_scale;

  read_float(&binwidth_scale, args, flags, ARG_MANDATORY,
             "Binwidth scale factor not specified");

  retval = aw_j2k_set_output_j2k_quantization_binwidth_scale(j2k_object,
                                                             binwidth_scale);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_quantization_binwidth_scale returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_quantization_binwidth_scale_ex(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, tile_index, channel_index;
  float binwidth_scale;

  read_tile_and_channel(&tile_index, &channel_index, args, flags);

  read_float(&binwidth_scale, args, flags, ARG_MANDATORY,
             "Binwidth scale factor not specified");

  retval =
    aw_j2k_set_output_j2k_quantization_binwidth_scale_ex(j2k_object,
                                                         tile_index,
                                                         channel_index,
                                                         binwidth_scale);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_quantization_binwidth_scale_ex returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_guard_bits(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, guard_bits;

  read_int(&guard_bits, args, flags, ARG_MANDATORY,
           "Guard bits not specified");

  retval = aw_j2k_set_output_j2k_guard_bits(j2k_object, guard_bits);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_guard_bits returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_guard_bits_ex(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, guard_bits, tile_index, channel_index;

  read_tile_and_channel(&tile_index, &channel_index, args, flags);

  read_int(&guard_bits, args, flags, ARG_MANDATORY,
           "Guard bits not specified");

  retval = aw_j2k_set_output_j2k_guard_bits_ex(j2k_object, tile_index,
                                               channel_index, guard_bits);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_guard_bits_ex returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_codeblock_size(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, codeblock_height, codeblock_width;
  read_int(&codeblock_height, args, flags, ARG_MANDATORY,
           "Codeblock height not specified");
  read_int(&codeblock_width, args, flags, ARG_MANDATORY,
           "Codeblock width not specified");
  retval = aw_j2k_set_output_j2k_codeblock_size(j2k_object, codeblock_height,
                                                codeblock_width);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_codeblock_size returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_codeblock_size_ex(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, tile_index, channel_index, codeblock_height, codeblock_width;
  read_tile_and_channel(&tile_index, &channel_index, args, flags);

  read_int(&codeblock_height, args, flags, ARG_MANDATORY,
           "Codeblock height not specified");
  read_int(&codeblock_width, args, flags, ARG_MANDATORY,
           "Codeblock width not specified");
  retval = aw_j2k_set_output_j2k_codeblock_size_ex(j2k_object, tile_index,
                                                   channel_index,
                                                   codeblock_height,
                                                   codeblock_width);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_codeblock_size_ex returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_arithmetic_coding_option(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, option, value;
  char *option_string;

  if (!strcmp(args->argv[args->arg], "--context-reset"))
    option = AW_J2K_ARITH_OPT_CONTEXT_RESET;
  else if (!strcmp(args->argv[args->arg], "--ac-term"))
    option = AW_J2K_ARITH_OPT_ARITHMETIC_TERMINATION;
  else if (!strcmp(args->argv[args->arg], "--pred-term"))
    option = AW_J2K_ARITH_OPT_PREDICTABLE_TERMINATION;
  else if (!strcmp(args->argv[args->arg], "--vert-causal"))
    option = AW_J2K_ARITH_OPT_VERTICALLY_CAUSAL_CONTEXT;
  else {
    read_string(&option_string, args, flags, ARG_MANDATORY,
                "Arithmetic coding option not specified");
    switch (option_string[0]) {
    case 'c': case 'C':
      option = AW_J2K_ARITH_OPT_CONTEXT_RESET;
      break;
    case 'a': case 'A':
      option = AW_J2K_ARITH_OPT_ARITHMETIC_TERMINATION;
      break;
    case 'p': case 'P':
      option = AW_J2K_ARITH_OPT_PREDICTABLE_TERMINATION;
      break;
    case 'v': case 'V':
      option = AW_J2K_ARITH_OPT_VERTICALLY_CAUSAL_CONTEXT;
      break;
    default:
      fprintf(flags->diagnostic_stream,
              "Unrecognized arithmetic coding option `%s'.",
              option_string);
      return;
    }
  }

  switch (option) {
  case AW_J2K_ARITH_OPT_CONTEXT_RESET:
    read_string(&option_string, args, flags, ARG_MANDATORY,
                "Arithmetic coding context reset frequency not specified");
    switch (option_string[0]) {
    case 'p': case 'P':
      value = AW_J2K_ACR_AT_EACH_CODEPASS_END;
      break;
    default:
      value = AW_J2K_ACR_ONLY_AT_CODEBLOCK_END;
    }
    break;
  case AW_J2K_ARITH_OPT_ARITHMETIC_TERMINATION:
    read_string(&option_string, args, flags, ARG_MANDATORY,
                "Arithmetic coding termination frquency not specified");
    switch (option_string[0]) {
    case 'p': case 'P':
      value = AW_J2K_AT_AT_EACH_CODEPASS_END;
      break;
    default:
      value = AW_J2K_AT_ONLY_AT_CODEBLOCK_END;
    }
    break;
  case AW_J2K_ARITH_OPT_PREDICTABLE_TERMINATION:
    read_string(&option_string, args, flags, ARG_MANDATORY,
                "Arithmetic coding predictable termination choice not specified");
    switch (option_string[0]) {
    case 'y': case 'Y':
      value = AW_J2K_PT_USE_PREDICTABLE_TERMINATION;
      break;
    default:
      value = AW_J2K_PT_NO_PREDICTABLE_TERMINATION;
    }
    break;
  case AW_J2K_ARITH_OPT_VERTICALLY_CAUSAL_CONTEXT:
    read_string(&option_string, args, flags, ARG_MANDATORY,
                "Vertically causal context formation choice not specified");
    switch (option_string[0]) {
    case 'y': case 'Y':
      value = AW_J2K_VC_USE_VERTICALLY_CAUSAL_CONTEXT;
      break;
    default:
      value = AW_J2K_VC_NO_VERTICALLY_CAUSAL_CONTEXT;
    }
  }
  retval = aw_j2k_set_output_j2k_arithmetic_coding_option(j2k_object, option,
                                                          value);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_arithmetic_coding_option returned error code %d\n",
            retval);
  return;
}

static void
call__set_output_j2k_header_option(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  BOOL header, end_marker;

  read_boolean(&header, args, flags, ARG_MANDATORY,
               "header option not specified");
  read_boolean(&end_marker, args, flags, ARG_MANDATORY,
             "end_marker option not specified");
  retval = aw_j2k_set_output_j2k_header_option(j2k_object, header, end_marker);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_header_option returned error code %d\n",
            retval);
  return;
}

static void
call__set_output_j2k_arithmetic_coding_option_ex(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, tile_index, channel_index, option, value;
  char *option_string;

  read_tile_and_channel(&tile_index, &channel_index, args, flags);

  if (!strcmp(args->argv[args->arg], "--context-reset"))
    option = AW_J2K_ARITH_OPT_CONTEXT_RESET;
  else if (!strcmp(args->argv[args->arg], "--ac-term"))
    option = AW_J2K_ARITH_OPT_ARITHMETIC_TERMINATION;
  else if (!strcmp(args->argv[args->arg], "--pred-term"))
    option = AW_J2K_ARITH_OPT_PREDICTABLE_TERMINATION;
  else if (!strcmp(args->argv[args->arg], "--vert-causal"))
    option = AW_J2K_ARITH_OPT_VERTICALLY_CAUSAL_CONTEXT;
  else {
    read_string(&option_string, args, flags, ARG_MANDATORY,
                "Arithmetic coding option not specified");
    switch (option_string[0]) {
    case 'c': case 'C':
      option = AW_J2K_ARITH_OPT_CONTEXT_RESET;
      break;
    case 'a': case 'A':
      option = AW_J2K_ARITH_OPT_ARITHMETIC_TERMINATION;
      break;
    case 'p': case 'P':
      option = AW_J2K_ARITH_OPT_PREDICTABLE_TERMINATION;
      break;
    case 'v': case 'V':
      option = AW_J2K_ARITH_OPT_VERTICALLY_CAUSAL_CONTEXT;
      break;
    default:
      fprintf(flags->diagnostic_stream,
              "Unrecognized arithmetic coding option `%s'.",
              option_string);
      return;
    }
  }

  switch (option) {
  case AW_J2K_ARITH_OPT_CONTEXT_RESET:
    read_string(&option_string, args, flags, ARG_MANDATORY,
                "Arithmetic coding context reset frequency not specified");
    switch (option_string[0]) {
    case 'p': case 'P':
      value = AW_J2K_ACR_AT_EACH_CODEPASS_END;
      break;
    default:
      value = AW_J2K_ACR_ONLY_AT_CODEBLOCK_END;
    }
    break;
  case AW_J2K_ARITH_OPT_ARITHMETIC_TERMINATION:
    read_string(&option_string, args, flags, ARG_MANDATORY,
                "Arithmetic coding termination frquency not specified");
    switch (option_string[0]) {
    case 'p': case 'P':
      value = AW_J2K_AT_AT_EACH_CODEPASS_END;
      break;
    default:
      value = AW_J2K_AT_ONLY_AT_CODEBLOCK_END;
    }
    break;
  case AW_J2K_ARITH_OPT_PREDICTABLE_TERMINATION:
    read_string(&option_string, args, flags, ARG_MANDATORY,
                "Arithmetic coding predictable termination choice not specified");
    switch (option_string[0]) {
    case 'y': case 'Y':
      value = AW_J2K_PT_USE_PREDICTABLE_TERMINATION;
      break;
    default:
      value = AW_J2K_PT_NO_PREDICTABLE_TERMINATION;
    }
    break;
  case AW_J2K_ARITH_OPT_VERTICALLY_CAUSAL_CONTEXT:
    read_string(&option_string, args, flags, ARG_MANDATORY,
                "Vertically causal context formation choice not specified");
    switch (option_string[0]) {
    case 'y': case 'Y':
      value = AW_J2K_VC_USE_VERTICALLY_CAUSAL_CONTEXT;
      break;
    default:
      value = AW_J2K_VC_NO_VERTICALLY_CAUSAL_CONTEXT;
    }
  }
  retval = aw_j2k_set_output_j2k_arithmetic_coding_option_ex(j2k_object,
                                                             tile_index,
                                                             channel_index,
                                                             option, value);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_arithmetic_coding_option_ex returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_coding_predictor_offset(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, predictor_offset;

  read_int(&predictor_offset, args, flags, ARG_MANDATORY,
           "Coding predictor offset not specified");

  retval = aw_j2k_set_output_j2k_coding_predictor_offset(j2k_object,
                                                         predictor_offset);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_coding_predictor_offset returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_coding_predictor_offset_ex(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, tile_index, predictor_offset;

  read_tile(&tile_index, args, flags);

  read_int(&predictor_offset, args, flags, ARG_MANDATORY,
           "Coding predictor offset not specified");

  retval =
    aw_j2k_set_output_j2k_coding_predictor_offset_ex(j2k_object, tile_index,
                                                     predictor_offset);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_coding_predictor_offset_ex returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_component_registration(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, channel, x_registration_offset, y_registration_offset;

  read_int(&channel, args, flags, ARG_MANDATORY,
           "Channel index not specified");

  read_int(&x_registration_offset, args, flags, ARG_MANDATORY,
           "Horizontal registration offset not specified");
  read_int(&y_registration_offset, args, flags, ARG_MANDATORY,
           "Vertical registration offset not specified");

  retval = aw_j2k_set_output_j2k_component_registration(j2k_object,
                                                        (WORD)channel,
                                                        (WORD)x_registration_offset,
                                                        (WORD)y_registration_offset);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_component_registration returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_tile_toc(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  retval = aw_j2k_set_output_j2k_tile_toc(j2k_object);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_tile_toc returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_tile_data_toc(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  retval = aw_j2k_set_output_j2k_tile_data_toc(j2k_object);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_tile_data_toc returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_tile_data_toc_ex(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, tile_index;
  BOOL include_plt;
  
  read_tile(&tile_index, args, flags);
  read_boolean(&include_plt, args, flags, ARG_MANDATORY,
               "PLT inclusion is not specified");

  retval = aw_j2k_set_output_j2k_tile_data_toc_ex(j2k_object, tile_index,
                                                  include_plt);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_tile_data_toc_ex returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_clear_comments(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  retval = aw_j2k_set_output_j2k_clear_comments(j2k_object);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_clear_comments returned error code %d\n",
            retval);
  return;
}
static void
call__output_reset_options(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  retval = aw_j2k_output_reset_options(j2k_object);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_output_reset_options returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_roi_from_image(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  char *image_name;
  unsigned char *buffer;
  unsigned long buffer_length;

  read_string(&image_name, args, flags, ARG_MANDATORY,
              "ROI image file name not specified");
  buffer = load_raw_data(image_name, &buffer_length);

  if (!buffer || buffer_length == 0) {
    if (image_name[0] == '-' && image_name[1] == '\0')
      fprintf(stderr, "Error: unable to read from stdin\n");
    else
      fprintf(stderr, "Error: unable to read `%s'\n", image_name);
    return;
  }

  retval = aw_j2k_set_output_j2k_roi_from_image(j2k_object, (char *)buffer,
                                                buffer_length);

  Free(buffer);

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_roi_from_image returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_roi_from_image_type(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, image_type;
  char *image_name;
  unsigned char *buffer;
  unsigned long buffer_length;

  read_string(&image_name, args, flags, ARG_MANDATORY,
              "ROI image file name not specified");
  buffer = load_raw_data(image_name, &buffer_length);

  if (!buffer || buffer_length == 0) {
    if (image_name[0] == '-' && image_name[1] == '\0')
      fprintf(stderr, "Error: unable to read from stdin\n");
    else
      fprintf(stderr, "Error: unable to read `%s'\n", image_name);
    return;
  }

  image_type = read_type(args, flags, ARG_MANDATORY,
                         "ROI image type not specified");

  retval = aw_j2k_set_output_j2k_roi_from_image_type(j2k_object,
                                                     (char *)buffer,
                                                     buffer_length,
                                                     image_type);
  Free(buffer);

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_roi_from_image_type returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_roi_from_image_raw(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  char *image_name;
  unsigned char *buffer;
  unsigned long buffer_length;
  unsigned long int rows, cols, bit_depth;
  BOOL interleaved = FALSE;

  read_string(&image_name, args, flags, ARG_MANDATORY,
              "ROI image file name not specified");

  read_ulint(&rows, args, flags, ARG_MANDATORY,
             "ROI image rows not specified");
  read_ulint(&cols, args, flags, ARG_MANDATORY,
             "ROI image columns not specified");
  read_ulint(&bit_depth, args, flags, ARG_MANDATORY,
             "Total ROI image bit depth not specified");

  read_boolean(&interleaved, args, flags, ARG_OPTIONAL, NULL);

  buffer = load_raw_data(image_name, &buffer_length);

  if (!buffer || buffer_length == 0) {
    if (image_name[0] == '-' && image_name[1] == '\0')
      fprintf(stderr, "Error: unable to read from stdin\n");
    else
      fprintf(stderr, "Error: unable to read `%s'\n", image_name);
    return;
  }

  retval = aw_j2k_set_output_j2k_roi_from_image_raw(j2k_object, (char *)buffer,
                                                    rows, cols, bit_depth,
                                                    interleaved);
  Free(buffer);

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_roi_from_image_raw returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_roi_from_file(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  char *image_name;

  read_string(&image_name, args, flags, ARG_MANDATORY,
              "ROI image file name not specified");

  retval = aw_j2k_set_output_j2k_roi_from_file(j2k_object, image_name);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_roi_from_file returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_roi_from_file_raw(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  char *image_name;
  unsigned long int rows, cols, bit_depth;
  BOOL interleaved = FALSE;

  read_string(&image_name, args, flags, ARG_MANDATORY,
              "ROI image file name not specified");

  read_ulint(&rows, args, flags, ARG_MANDATORY,
             "ROI image rows not specified");
  read_ulint(&cols, args, flags, ARG_MANDATORY,
             "ROI image columns not specified");
  read_ulint(&bit_depth, args, flags, ARG_MANDATORY,
             "Total ROI image bit depth not specified");

  read_boolean(&interleaved, args, flags, ARG_OPTIONAL, NULL);

  retval = aw_j2k_set_output_j2k_roi_from_file_raw(j2k_object, image_name,
                                                   rows, cols, bit_depth,
                                                   interleaved);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_roi_from_file_raw returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_roi_add_shape(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  char *shape_string;
  int shape;
  unsigned long int x, y, width, height;

  if (!strcmp(args->argv[args->arg], "--roi-rect"))
    shape = AW_ROISHAPE_RECTANGLE;
  else if (!strcmp(args->argv[args->arg], "--roi-ellipse"))
    shape = AW_ROISHAPE_ELLIPSE;
  else {
    read_string(&shape_string, args, flags, ARG_MANDATORY,
                "ROI shape not specified");
    switch (shape_string[0]) {
    case 'r': case 'R':
      shape = AW_ROISHAPE_RECTANGLE;
      break;
    case 'e': case 'E':
      shape = AW_ROISHAPE_ELLIPSE;
    default:
      fprintf(flags->diagnostic_stream,
              "Warning: Unknown ROI shape `%s' ignored\n",
              shape_string);
      return;
    }
  }

  read_ulint(&x, args, flags, ARG_MANDATORY,
             "ROI shape left coordinate not specified");
  read_ulint(&y, args, flags, ARG_MANDATORY,
             "ROI shape top coordinate not specified");
  read_ulint(&width, args, flags, ARG_MANDATORY,
             "ROI shape width not specified");
  read_ulint(&height, args, flags, ARG_MANDATORY,
             "ROI shape height not specified");

  retval = aw_j2k_set_output_j2k_roi_add_shape(j2k_object, shape, x, y, width,
                                               height);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_roi_add_shape returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_clear_roi(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  retval = aw_j2k_set_output_j2k_clear_roi(j2k_object);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_clear_roi returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_jpg_options(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  long int quality;

  read_int(&quality, args, flags, ARG_MANDATORY, "JPEG quality not specified");
  if ((quality < 0 && quality != -1) || quality > 100) {
      fprintf(flags->diagnostic_stream, "JPEG quality not specified\n");
      exit(1);
  }

  retval = aw_j2k_set_output_jpg_options(j2k_object, quality);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_jpg_options returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_com_geometry_rotation(args_t *args, state_flags *flags,
                                       aw_j2k_object *j2k_object)
{
  int retval, angle;

  read_int(&angle, args, flags, ARG_MANDATORY,
             "Rotation angle not specified");

  retval = aw_j2k_set_output_com_geometry_rotation(j2k_object, angle);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_com_geometry_rotation returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_raw_endianness(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval;
  char *endianness_string;
  unsigned long int endianness;

  read_string(&endianness_string, args, flags, ARG_MANDATORY,
              "Output Raw endianness not specified");

  switch (endianness_string[0]) {
  case 'b': case 'B':
    endianness = AW_J2K_ENDIAN_BIG;
    break;
  case 's': case 'S': case 'l': case 'L':
    endianness = AW_J2K_ENDIAN_SMALL;
    break;
  default:
    endianness = AW_J2K_ENDIAN_LOCAL_MACHINE;
  }

  retval = aw_j2k_set_output_raw_endianness(j2k_object, endianness);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_raw_endianness returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_channel_precinct_size(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  int retval, channel_index, resolution_index, precinct_height, precinct_width;
  char *channel_string;

  channel_index = AW_J2K_SELECT_ALL_CHANNELS;
  read_int_or_string(&channel_string, &channel_index, args, flags,
                     ARG_MANDATORY, "Channel index not specified");
  if (channel_string) {
    if (channel_string[0] == 'a' || channel_string[0] == 'A')
      channel_index = AW_J2K_SELECT_ALL_CHANNELS;
    else
      fprintf(flags->diagnostic_stream,
              "Warning: channel index `%s' not recognized\n", channel_string);
  }

  read_int(&resolution_index, args, flags, ARG_MANDATORY,
           "resolution index not specified");
  read_int(&precinct_height, args, flags, ARG_MANDATORY,
           "precinct height not specified");
  read_int(&precinct_width, args, flags, ARG_MANDATORY,
           "precinct width not specified");
  retval = aw_j2k_set_output_j2k_channel_precinct_size(j2k_object,
                                                       channel_index,
                                                       resolution_index,
                                                       precinct_height,
                                                       precinct_width);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_channel_precinct_size returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_j2k_precinct_size_ex(args_t *args, state_flags *flags,
                                      aw_j2k_object *j2k_object)
{
  int retval, tile_index, channel_index, resolution_index, precinct_height, precinct_width;

  read_tile_and_channel(&tile_index, &channel_index, args, flags);

  read_int(&resolution_index, args, flags, ARG_MANDATORY,
           "resolution index not specified");
  read_int(&precinct_height, args, flags, ARG_MANDATORY,
           "precinct height not specified");
  read_int(&precinct_width, args, flags, ARG_MANDATORY,
           "precinct width not specified");
  retval = aw_j2k_set_output_j2k_precinct_size_ex(j2k_object, tile_index,
                                                  channel_index,
                                                  resolution_index,
                                                  precinct_height,
                                                  precinct_width);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_j2k_precinct_size_ex returned error code %d\n",
            retval);
  return;
}
static void
call__set_input_j2k_error_handling(args_t *args, state_flags *flags,
                                   aw_j2k_object *j2k_object)
{
  int retval;
  char *mode_string;
  int mode;

  mode = AW_J2K_ERROR_RESILIENT_MODE;

  read_string(&mode_string, args, flags, ARG_MANDATORY,
              "Error handling mode not specified");

  switch (mode_string[0]) {
  case 's': case 'S':           /* strict */
    mode = AW_J2K_ERROR_STRICT_MODE;
    break;
  case 'r': case 'R':           /* resilient */
    mode = AW_J2K_ERROR_RESILIENT_MODE;
    break;
  default:
    fprintf(flags->diagnostic_stream,
            "Warning: Error handling mode `%s' not recognized.\n",
            mode_string);
  }

  retval = aw_j2k_set_input_j2k_error_handling(j2k_object, mode);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_input_j2k_error_handling returned error code %d\n",
            retval);
  return;
}
static void
call__get_input_j2k_decoder_status(args_t *args, state_flags *flags,
                                   aw_j2k_object *j2k_object)
{
  int retval;
  unsigned long int status = AW_J2K_DECODER_FULL_DECODE;

  retval = aw_j2k_get_input_j2k_decoder_status(j2k_object, &status);

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_input_j2k_decoder_status returned error code %d\n",
            retval);
  else {
    switch (status) {
    case AW_J2K_DECODER_FULL_DECODE:
      fprintf(flags->diagnostic_stream,
              "JPEG 2000 Decoder Status: codestream successfully decoded\n");
      break;
    case AW_J2K_DECODER_PARTIAL_DECODE_TRUNCATION:
      fprintf(flags->diagnostic_stream,
              "JPEG 2000 Decoder Status: codestream truncation detected\n");
      break;
    case AW_J2K_DECODER_PARTIAL_DECODE_CORRUPTION:
      fprintf(flags->diagnostic_stream,
              "JPEG 2000 Decoder Status: codestream corruption detected\n");
      break;
    }
  }
  return;
}
static void
call__set_output_jp2_add_metadata_box(args_t *args, state_flags *flags,
                                      aw_j2k_object *j2k_object)
{
  int retval;
  unsigned long int type, data_length, uuid_length;
  char *data_file_name, *uuid_file_name, *data;
  unsigned char *uuid;
  type = data_length = uuid_length = 0;
  data_file_name = uuid_file_name = data = 0;
  uuid = 0;

  type = read_jp2_box_type(args, flags, ARG_MANDATORY,
                           "JP2 Metadata box type not specified");

  read_string(&data_file_name, args, flags, ARG_MANDATORY,
              "JP2 metadata file name not specified");
  data = (char *)load_raw_data(data_file_name, &data_length);

  if (!data || data_length == 0) {
    if (data_file_name[0] == '-' && data_file_name[1] == '\0')
      fprintf(stderr, "Error: unable to read metadata from stdin\n");
    else
      fprintf(stderr, "Error: unable to read metadata from `%s'\n",
              data_file_name);
    return;
  }

  if (type == AW_JP2_MDTYPE_UUID) {
    read_string(&uuid_file_name, args, flags, ARG_MANDATORY,
                "JP2 UUID file name not specified");
    uuid = load_raw_data(uuid_file_name, &uuid_length);

    if (!uuid || uuid_length == 0) {
      if (uuid_file_name[0] == '-' && uuid_file_name[1] == '\0')
        fprintf(stderr, "Error: unable to read UUID from stdin\n");
      else
        fprintf(stderr, "Error: unable to read UUID from `%s'\n",
                uuid_file_name);
      return;
    }
  }

  retval =
    aw_j2k_set_output_jp2_add_metadata_box(j2k_object, type, data, data_length,
                                           uuid, uuid_length);

  Free(data);
  if (uuid) Free(uuid);

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_jp2_add_metadata_box returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_jp2_add_UUIDInfo_box(args_t *args, state_flags *flags,
                                      aw_j2k_object *j2k_object)
{
  int retval, num_uuid;
  unsigned long int url_length, uuid_length;
  char *uuid_list_file_name, *url;
  unsigned char *uuid;

  num_uuid = url_length = 0;
  uuid_list_file_name = url = 0;
  uuid = 0;

  read_string(&uuid_list_file_name, args, flags, ARG_MANDATORY,
              "UUID list file name not specified");
  uuid = load_raw_data(uuid_list_file_name, &uuid_length);

  if (!uuid || uuid_length == 0) {
    if (uuid_list_file_name[0] == '-' && uuid_list_file_name[1] == '\0')
      fprintf(stderr, "Error: unable to read UUID list from stdin\n");
    else
      fprintf(stderr, "Error: unable to read UUID list from `%s'\n",
              uuid_list_file_name);
    return;
  }

  if (uuid_length % 16 != 0)
    fprintf(flags->diagnostic_stream,
            "Warning: found an incomplete UUID at the end of `%s', discarding.\n",
            uuid_list_file_name);
  num_uuid = uuid_length / 16;

  read_string(&url, args, flags, ARG_MANDATORY, "URL not specified");

  retval =
    aw_j2k_set_output_jp2_add_UUIDInfo_box(j2k_object, uuid, num_uuid,
                                           url, strlen(url));

  Free(uuid);

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_jp2_add_UUIDInfo_box returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_enum_colorspace(args_t *args, state_flags *flags,
                                 aw_j2k_object *j2k_object)
{
  int retval;
  long int color_space;
  char *color_space_string;

  color_space = AW_JP2_CS_DEFAULT;
  color_space_string = 0;

  read_string(&color_space_string, args, flags, ARG_MANDATORY,
              "Color space not specified");

  if (color_space_string) {
    downcase(color_space_string);
    if (!strcmp(color_space_string, "greyscale") ||
        !strcmp(color_space_string, "grayscale"))
      color_space = AW_JP2_CS_GREYSCALE;
    else if (!strcmp(color_space_string, "srgb"))
      color_space = AW_JP2_CS_sRGB;
    else if (!strcmp(color_space_string, "sycc"))
      color_space = AW_JP2_CS_sYCC;
    else if (!strcmp(color_space_string, "default"))
      color_space = AW_JP2_CS_DEFAULT;
    else 
      fprintf(flags->diagnostic_stream,
              "Warning: unrecognized color space `%s' ignored.\n",
              color_space_string);
  }

  retval =
    aw_j2k_set_output_enum_colorspace(j2k_object, color_space);

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_enum_colorspace returned error code %d\n",
            retval);
  return;
}
static void
call__set_output_jp2_restricted_ICCProfile(args_t *args, state_flags *flags,
                                           aw_j2k_object *j2k_object)
{
  int retval;
  char *icc_profile_file;
  unsigned char *icc_buffer;
  unsigned long int icc_buffer_length;

  icc_profile_file = 0;
  icc_buffer_length = 0;
  icc_buffer = 0;

  read_string(&icc_profile_file, args, flags, ARG_MANDATORY,
              "ICC Profile file name not specified");

  icc_buffer = load_raw_data(icc_profile_file, &icc_buffer_length);
  if (!icc_buffer || icc_buffer_length == 0) {
    if (icc_profile_file[0] == '-' && icc_profile_file[1] == '\0')
      fprintf(stderr, "Error: unable to read ICC profile from stdin\n");
    else
      fprintf(stderr, "Error: unable to read ICC profile from `%s'\n",
              icc_profile_file);
    return;
  }

  retval =
    aw_j2k_set_output_jp2_restricted_ICCProfile(j2k_object, icc_buffer,
                                                icc_buffer_length);

  Free(icc_buffer);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_set_output_jp2_restricted_ICCProfile returned error code %d\n",
            retval);
  return;
}


static void
call__get_input_jp2_num_metadata_boxes(args_t *args, state_flags *flags,
                                       aw_j2k_object *j2k_object)
{
  int retval;
  unsigned long int type, metadata_box_count;
  char *type_string;

  type = metadata_box_count = 0;

  type = read_jp2_box_type(args, flags, ARG_MANDATORY,
                           "JP2 Metadata box type not specified");
  type_string = args->argv[args->arg];

  retval = aw_j2k_get_input_jp2_num_metadata_boxes(j2k_object, type,
                                                   &metadata_box_count);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_input_jp2_num_metadata_boxes returned error code %d\n",
            retval);
  else
    fprintf(flags->diagnostic_stream,
            "Found %ld %s metadata boxes.\n", metadata_box_count,
            type_string);

  return;
}


static void
call__get_output_j2k_layer_psnr_estimate(args_t *args, state_flags *flags,
                                         aw_j2k_object *j2k_object)
{
   int retval, layer_index;
   char *layer_index_string;
   float psnr;
   
   read_int_or_string(&layer_index_string, &layer_index, args, flags,
      ARG_MANDATORY, "Layer index not specified");
   if (layer_index_string) {
      if (layer_index_string[0] == 'a' || layer_index_string[0] == 'A')
         layer_index = AW_J2K_GLOBAL_LAYER_INDEX;
      else
         fprintf(flags->diagnostic_stream,
         "Warning: Layer index `%s' not recognized\n", layer_index_string);
   };
   
   retval = aw_j2k_get_output_j2k_layer_psnr_estimate(j2k_object, layer_index, &psnr);
   
   if (retval)
      fprintf(flags->diagnostic_stream,
      "Warning: aw_j2k_get_output_j2k_layer_psnr_estimate returned error code %d\n",
      retval);
   else {
      if (layer_index == -1)
         fprintf(flags->diagnostic_stream, "pSNR estimate for entire image = %f\n", psnr);
      else
         fprintf(flags->diagnostic_stream, "pSNR estimate for layer %d = %f\n",layer_index, psnr);
   }
   return;
}

static void
call__get_input_jp2_metadata_box(args_t *args, state_flags *flags,
                                 aw_j2k_object *j2k_object)
{
  int retval;
  unsigned long int type, metadata_box_index, metadata_length, uuid_length;
  unsigned char *metadata, *uuid;
  char *metadata_file_name, *uuid_file_name;

  type = metadata_box_index = metadata_length = uuid_length = 0;
  metadata = uuid = 0;
  metadata_file_name = uuid_file_name = 0;

  type = read_jp2_box_type(args, flags, ARG_MANDATORY,
                           "JP2 metadata box type not specified");

  read_ulint(&metadata_box_index,args, flags, ARG_MANDATORY,
             "JP2 metadata box index not specified");

  read_string(&metadata_file_name, args, flags, ARG_MANDATORY,
             "JP2 metadata file name not specified");

  if (type == AW_JP2_MDTYPE_UUID)
    read_string(&uuid_file_name, args, flags, ARG_MANDATORY,
                "JP2 UUID file name not specified");

  retval = aw_j2k_get_input_jp2_metadata_box(j2k_object, type,
                                             metadata_box_index,
                                             &metadata, &metadata_length,
                                             &uuid, &uuid_length);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_input_jp2_metadata_box returned error code %d\n",
            retval);
  else {
    write_raw_data(metadata_file_name, metadata, metadata_length);
    if (uuid_file_name)
      write_raw_data(uuid_file_name, uuid, uuid_length);
  }

  return;
}

static void
call__get_input_jp2_UUIDInfo_box(args_t *args, state_flags *flags,
                                 aw_j2k_object *j2k_object)
{
  int retval;
  unsigned long int uuid_box_index, url_length, uuid_count, uuid_length;
  unsigned char *uuid;
  char *url_file_name, *url, *uuid_file_name;

  uuid_box_index = url_length = uuid_count = uuid_length = 0;
  uuid = 0;
  url = url_file_name = uuid_file_name = 0;

  read_ulint(&uuid_box_index,args, flags, ARG_MANDATORY,
             "JP2 UUID box index not specified");

  read_string(&uuid_file_name, args, flags, ARG_OPTIONAL, NULL);
  read_string(&url_file_name, args, flags, ARG_OPTIONAL, NULL);

  retval = aw_j2k_get_input_jp2_UUIDInfo_box(j2k_object, 
                                             uuid_box_index,
                                             &uuid, &uuid_count,
                                             &url, &url_length);

  uuid_length = uuid_count * AW_JP2_UUID_LENGTH;

  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_input_jp2_UUIDInfo_box returned error code %d\n",
            retval);
  else {
    if (uuid_file_name)
      write_raw_data(uuid_file_name, uuid, uuid_length);
    else {
      fprintf(flags->diagnostic_stream,
              "Contents of the UUID:\n");
      print_binary(flags->diagnostic_stream, uuid, uuid_length);
    }
    if (url_file_name)
      write_raw_data(url_file_name, (unsigned char *)url, url_length);
    else
      fprintf(flags->diagnostic_stream, "%s", url);
  }

  return;
}
static void
call__get_input_jp2_enum_colorspace(args_t *args, state_flags *flags,
                                    aw_j2k_object *j2k_object)
{
  int retval;
  long int color_space;

  color_space = AW_JP2_CS_DEFAULT;

  retval = aw_j2k_get_input_jp2_enum_colorspace(j2k_object, &color_space);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_input_jp2_enum_colorspace returned error code %d\n",
            retval);
  else {
    switch (color_space) {
    case AW_JP2_CS_GREYSCALE:
      fprintf(flags->diagnostic_stream, "JP2 greyscale image image.\n");
      break;
    case AW_JP2_CS_sRGB:
      fprintf(flags->diagnostic_stream, "JP2 sRGB image image.\n");
      break;
    case AW_JP2_CS_sYCC:
      fprintf(flags->diagnostic_stream, "JP2 sYCC image image.\n");
      break;
    default:
      fprintf(flags->diagnostic_stream,
              "JP2 image image in an unknown color space.\n");
      break;
    }
  }
  return;
}
static void
call__get_input_jp2_restricted_ICCProfile(args_t *args, state_flags *flags,
                                          aw_j2k_object *j2k_object)
{
  int retval;
  unsigned char *icc_data = 0;
  unsigned long int icc_data_length = 0;
  char *icc_file_name = 0;

  read_string(&icc_file_name, args, flags, ARG_OPTIONAL, NULL);

  retval = aw_j2k_get_input_jp2_restricted_ICCProfile(j2k_object,
                                                      &icc_data,
                                                      &icc_data_length);
  if (retval)
    fprintf(flags->diagnostic_stream,
            "Warning: aw_j2k_get_input_jp2_restricted_ICCProfile returned error code %d\n",
            retval);
  else {
    if (icc_file_name)
      write_raw_data(icc_file_name, icc_data, icc_data_length);
    else {
      fprintf(flags->diagnostic_stream,
              "Contents of the Restricted ICC Color Profile:\n");
      print_binary(flags->diagnostic_stream, icc_data, icc_data_length);
    }
  }
  return;
}
static void
call__help(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  flags->help_flag++;
  return;
}
static void
call__verbose(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  flags->verbosity_flag++;
  if (flags->verbosity_flag > VERBOSITY_MAXIMUM_LEVEL)
    flags->verbosity_flag = VERBOSITY_MAXIMUM_LEVEL;
  return;
}
static void
call__quiet(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  flags->verbosity_flag--;
  if (flags->verbosity_flag < VERBOSITY_MINIMUM_LEVEL)
    flags->verbosity_flag = VERBOSITY_MINIMUM_LEVEL;
  return;
}
static void
call__benchmark(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  flags->benchmark_flag = 1;    /* default */
  read_int(&flags->benchmark_flag, args, flags, ARG_OPTIONAL, NULL);
  return;
}
static void
call__verbose_to_stdout(args_t *args, state_flags *flags, aw_j2k_object *j2k_object)
{
  flags->diagnostic_stream = stdout;
  return;
}


/* The structure of options.  Note that the order the options appear
 * in this structure is critical in that the hashing logic implemented
 * by perfecthash() (see below) depends on this order not changing to
 * correctly hash the option to its location in this list.  If you
 * wish to add, remove, or generally change the order of entries in
 * this array, you'll need to regenerate the hash table (G).
 */
aw_option_t options_list[] =
{
  {
    call__help,
    "--help",
    "\n"                        /* no args */
    "Turns on the help system.  Descriptions of every option listed on the\n"
    "command line will be printed after this option is encountered.\n",
  },
  {
    call__help,
    "-h",
    NULL
  },
  {
    call__get_library_version,
    "--get-library-version",
    "[<type>]\n"
    "Prints the current library version.  The optional argument <type> can be:\n"
    "  Numeric - print the only the numeric version\n"
    "  String  - print the full version string\n"
    "The full version string is printed by default\n"
  },
  {
    call__reset_all_options,
    "--reset-all-options",
    "\n"                        /* no args */
    "Resets the J2K library object to its initial state.\n"
  },
  {
    call__set_internal_option,
    "--fixed-point",
    "\n"                        /* no args */
    "Selects the usage of fixed-point arithmetic for irreversible processing\n"
    "(i.e. when using the I97 wavelet).  Using the --fixed-point flag is\n"
    "equivalent to using `--set-internal-option arithmetic fixed'.\n"
  },
  {
    call__set_internal_option,
    "--floating-point",
    "\n"                        /* no args */
    "Selects the usage of fixed-point arithmetic for irreversible processing\n"
    "(i.e. when using the I97 wavelet).  Using the --floating-point flag is\n"
    "equivalent to using `--set-internal-option arithmetic float'.\n"
  },
  {
    call__set_internal_option,
    "--set-internal-option",
    "<option> <value>\n"
    "Sets the internal option <option> to <value>.  The options are:\n"
    "  arithmetic - sets the type of arithmetic operations that will be used for\n"
    "               irreversible processing (i.e. when using the I97 wavelet)\n"
    "For the arithmetic option, the values are:\n"
    "  fixed      - for fixed-point operation\n"
    "  float      - for floating-point operation\n"
    "Using the --fixed-point flag is equivalent to using\n"
    "`--set-internal-option arithmetic fixed', and using the --floating-point\n"
    "flag is equivalent to `--set-internal-option arithmetic float'.\n"
  },
  {
    call__set_input_image,
    "--set-input-image",
    "<image file name>\n"
    "Reads an input image from the file <image file name>, and inputs it into\n"
    "the library using the memory-buffer interface.  The image type is deduced\n"
    "From the image itself.\n"
  },
  {
    call__set_input_image,
    "-i",
    NULL
  },
  {
    call__set_input_image,
    "--input-file-name",
    NULL
  },
  {
    call__set_input_image_type,
    "--set-input-image-type",
    "<image type> <image file name>\n"
    "Reads an input image from the file <image file name>, and inputs it into\n"
    "the library using the memory-buffer interface.  The image type is specified\n"
    "by <image type>, which must be one of:\n"
    "  j2k                - JPEG2000 codestreams\n"
    "  jp2                - JPEG2000 file format\n"
    "  tif, tiff          - TIFF\n"
    "  pnm, pbm, pgm, ppm - Any of the portable bit/gray/pix-map formats\n"
    "  dcm, dcm_raw       - DICOM (with embedded raw pixels)\n"
    "  dcm_j2k            - DICOM (with embedded J2K codestreams)\n"
    "  bmp                - Windows bitmap\n"
    "  tga, targa         - TARGA image format\n"
    "  jpg, jpeg          - Original JPEG format\n"
    "  pgx                - Extended portable graymap format\n"
  },
  {
    call__set_input_image_raw,
    "--set-input-image-raw",
    "<image file name> <rows> <columns> <channels> <total bit depth> [<interleaved>]\n"
    "Reads a raw input image from the file <image file name>, and inputs it into\n"
    "the library using the memory-buffer interface.  The size of the image must\n"
    "be specified using <rows>, <columns>, <channels>, and <total bit depth>.  The\n"
    "optional <interleaved> flag indicates whether the channel data is interleaved\n"
    "or not (the default if not specified).  <interleaved> may be `yes' or `no'.\n"
  },
  {
    call__set_input_image_raw,
    "--input-file-raw",
    NULL
  },
  {
    call__set_input_image_raw_ex,
    "--set-input-image-raw-ex",
    "<image file name> <rows> <columns> <channels> <bits allocated> <bits stored> [<interleaved>]\n"
    "Reads a raw input image from the file <image file name>, and inputs it into\n"
    "the library using the memory-buffer interface.  The size of the image must\n"
    "be specified using <rows>, <columns>, <channels>, <bits allocated> and <bits\n"
    "stored>.  The optional <interleaved> flag indicates whether the channel data\n"
    "is interleaved or not (the default if not specified).  <interleaved> may be\n"
    "`yes' or `no'.\n"
  },
  {
    call__set_input_image_raw_channel,
    "--set-input-image-raw-channel",
    "<channel index> <channel data file name>\n"
    "Loads the data for channel number <channel index> from <channel data file\n"
    "name>.  The data is input into the library using the memory-buffer interface\n"
    "The dimensions of the image can be provided via a call to\n"
    "--set-input-raw-information.\n"
  },
  {
    call__set_input_image_raw_region,
    "--set-input-image-raw-region",
    "<region file name> <row offset> <cols offset> <rows> <cols> <interleaved>\n"
    "Loads the data for give region from <channel data file name>.  The data is\n"
    "input into the library using the memory-buffer interface.  The dimensions of\n"
    "the image should be provided via a call to --set-input-raw-information.\n"
  },
  {
    call__set_input_image_file,
    "--set-input-image-file",
    "<image file name>\n"
    "Reads an input image from the file <image file name>, and inputs it into\n"
    "the library using the file interface.  The image type is deduced\n"
    "From the image itself.\n"
  },
  {
    call__set_input_image_file,
    "--input-file",
    NULL
  },
  {
    call__set_input_image_file_type,
    "--set-input-image-file-type",
    "<image file name> <image type>\n"
    "Reads an input image from the file <image file name>, and inputs it into\n"
    "the library using the file interface.  The image type is specified\n"
    "by <image type>, which must be one of:\n"
    "  j2k                - JPEG2000 codestreams\n"
    "  jp2                - JPEG2000 file format\n"
    "  tif, tiff          - TIFF\n"
    "  pnm, pbm, pgm, ppm - Any of the portable bit/gray/pix-map formats\n"
    "  dcm, dcm_raw       - DICOM (with embedded raw pixels)\n"
    "  dcm_j2k            - DICOM (with embedded J2K codestreams)\n"
    "  bmp                - Windows bitmap\n"
    "  tga, targa         - TARGA image format\n"
    "  jpg, jpeg          - Original JPEG format\n"
    "  pgx                - Extended portable graymap format\n"
  },
  {
    call__set_input_image_file_raw,
    "--set-input-image-file-raw",
    "<image file name> <rows> <columns> <channels> <total bit depth> [<interleaved>]\n"
    "Reads a raw input image from the file <image file name>, and inputs it into\n"
    "the library using the file interface.  The size of the image must\n"
    "be specified using <rows>, <columns>, <channels>, and <total bit depth>.  The\n"
    "optional <interleaved> flag indicates whether the channel data is interleaved\n"
    "or not (the default if not specified).  <interleaved> may be `yes' or `no'.\n"
  },
  {
    call__set_input_image_file_raw,
    "--input-image-file-raw",
    NULL
  },
  {
    call__set_input_raw_information,
    "--set-input-raw-information",
    "<rows> <columns> <channels> <total bit depth> [<interleaved>]\n"
    "Sets the dimensions of an image, without providing the image itself.  The\n"
    "image data can be provided later using --set-input-image-raw-channel.\n"
    "If the data is signed, the bit depth should be negative; it should be positive\n"
    "for unsigned data.  <interleaved> may be `yes' or `no'.\n"
  },
  {
    call__set_input_raw_channel_bpp,
    "--set-input-raw-channel-bpp",
    "<channel index> <channel bit depth>\n"
    "Sets the bit depth of the data in the specified channel.  If the data is\n"
    "signed, the bit depth should be negative; it should be positive for unsigned\n"
    "data.\n"
  },
  {
    call__set_input_raw_endianness,
    "--set-input-raw-endianness",
    "<endianness>\n"
    "Sets the endianness of multi-byte-per-channel raw images.  The value of\n"
    "<endianness> should be `big' or `little'.\n"
  },
  {
    call__set_input_raw_channel_subsampling,
    "--set-input-raw-channel-subsampling",
    "<channel index> <horizontal subsampling> <vertical subsampling>\n"
    "Specifies the subsampling of a specific channel relative to the\n"
    "full image dimensions.\n"
  },
  {
    call__get_input_image_info,
    "--get-input-image-info",
    "\n"                        /* no args */
    "Prints the dimensions, total bit depth, and number of channels in\n"
    "the image.  The bit depth returned here is the sum of the bit depths\n"
    "of all the channels, and does not indicate whether the data is\n"
    "signed or not.  Use --get-input-channel-bpp to determine the\n"
    "bit depth of each channel, as well as whether the data in the\n"
    "channel is signed.\n"
  },
  {
    call__get_input_channel_bpp,
    "--get-input-channel-bpp",
    "<channel index>\n"
    "Returns the bit depth of the specified channel in the image, as well as\n"
    "whether the data in the channel is signed or not.\n"
  },
  {
    call__get_input_j2k_channel_subsampling,
    "--get-input-j2k-channel-subsampling",
    "<channel index>\n"
    "Returns the subsampling of a channel in a JPEG 2000 image relative\n"
    "to the full image dimensions.\n"
  },
  {
    call__get_input_j2k_num_comments,
    "--get-input-j2k-num-comments",
    "\n"                        /* no args */
    "Returns the number of comments that are embedded in a JPEG 2000\n"
    "image.\n"
  },
  {
    call__get_input_j2k_comments,
    "--get-input-j2k-comments",
    "<comment index>\n"
    "Returns a comment from a JPEG 2000 image.  The number of comments can be\n"
    "had using --get-input-j2k-num-comments.\n"
  },
  {
    call__get_input_j2k_comments,
    "--get-comments",
    NULL
  },
  {
    call__get_input_j2k_progression_info,
    "--get-input-j2k-progression-info",
    "\n"                        /* no args */
    "Prints the progression order, number of wavelet transform levels,\n"
    "number of quality layers, and number of color channels in a JPEG\n"
    "2000 image.\n"
  },
  {
    call__get_input_j2k_progression_info,
    "--progression-info",
    NULL
  },
  {
    call__get_input_j2k_progression_info,
    "--image-progression-info",
    NULL
  },
  {
    call__get_input_j2k_progression_byte_count,
    "--get-input-j2k-progression-byte-count",
    "<progression level index>\n"
    "Prints the number of bytes needed to decode a given progression\n"
    "level.  The type of progression level is determined by the\n"
    "progression order of the JPEG 2000 image.\n"
  },
  {
    call__get_input_j2k_tile_info,
    "--get-input-j2k-tile-info",
    "\n"                        /* no args */
    "Prints the tile size and image and tile offsets in a JPEG 2000\n"
    "image.\n"
  },
  {
    call__get_input_j2k_tile_info,
    "--image-tiling-info",
    NULL
  },
  {
    call__get_input_j2k_selected_tile_geometry,
    "--get-input-j2k-selected-tile-geometry",
    "<tile index>\n"
    "Returns the size of a tile and its offset from the image origin.\n"
  },
  {
    call__get_input_j2k_component_registration,
    "--get-input-j2k-component-registration",
    "<channel index>\n"
    "Returns a specified channel's registration offset.  The registration offsets\n"
    "indicate how much to offset each color channel relative to the image grid for\n"
    "display.  The offsets are given in units of 1/65536 of a pixel.\n"
  },
  {
    call__get_input_j2k_component_registration,
    "--get-component-registration",
    NULL
  },
  {
    call__get_input_j2k_bytes_read,
    "--get-input-j2k-bytes-read",
    "\n"                        /* no args */
    "Prints the number of bytes actually used from a JPEG 2000 image.\n"
    "If the full image was decompressed, this will return the size of\n"
    "the original image.  If a partial decompression was performed\n"
    "(e.g. only a single tile or a reduced resolution was decoded) then\n"
    "this number may be smaller than the full image.\n"
  },
  {
    call__get_input_j2k_bytes_read,
    "--get-bytecount",
    NULL
  },
  {
    call__set_input_j2k_progression_level,
    "--set-input-j2k-progression-level",
    "<progression level>\n"
    "Sets the number of progression levels that will be decoded form the\n"
    "JPEG 2000 image.  The progression type is determined by the\n"
    "progression order of the image.\n"
  },
  {
    call__set_input_j2k_progression_level,
    "-pl",
    NULL
  },
  {
    call__set_input_j2k_progression_level,
    "--progression-level",
    NULL
  },
  {
    call__set_input_j2k_resolution_level,
    "--set-input-j2k-resolution-level",
    "<resolution level> [<full transform flag>]\n"
    "Sets the number of resolution levels to decode from the JPEG 2000\n"
    "image.  The full number of resolution levels is always one more\n"
    "than the number of wavelet transform levels in the JPEG 2000 image.\n"
    "To fully decode the image, set the resolution level to 1.  For quarter\n"
    "resolution, use 2.  The optional full transform flag, which should be 'Yes'\n"
    "or 'No', indicates whether the full wavelet transform should be performed\n"
    "(resulting in a full size image of lower quality) or not (resulting in a\n"
    "reduced size image).\n"
  },
  {
    call__set_input_j2k_resolution_level,
    "-rl",
    NULL
  },
  {
    call__set_input_j2k_resolution_level,
    "--resolution-level",
    NULL
  },
  {
    call__set_input_j2k_quality_level,
    "--set-input-j2k-quality-level",
    "<quality level>\n"
    "Sets the number of quality layers to decode from a JPEG 2000 image.\n"
    "Setting this value to 1 decodes all the quality layers; setting it to 2\n"
    "drops one layer.\n"
  },
  {
    call__set_input_j2k_quality_level,
    "-ql",
    NULL
  },
  {
    call__set_input_j2k_quality_level,
    "--quality-level",
    NULL
  },
  {
    call__set_input_j2k_color_level,
    "--set-input-j2k-color-level",
    "<color level> [<color transform flag>]\n"
    "Sets the number of color channels to decode from a JPEG 2000 image.\n"
    "Setting <color level> to 1 decodes all the color channels.  Setting it to 2\n"
    "drops the last color channel.  The optional <color transform flag> indicates\n"
    "whether the color transform will be performed or not.  Use 'yes' to force the\n"
    "transform to be performed if possible; 'no' to disallow the color transform;\n"
    "and 'default' to let the transform be performed if so specified by the image.\n"
  },
  {
    call__set_input_j2k_color_level,
    "-cl",
    NULL
  },
  {
    call__set_input_j2k_color_level,
    "--color-level",
    NULL
  },
  {
    call__set_input_j2k_region_level,
    "--set-input-j2k-region-level",
    "<left> <top> <right> <bottom>\n"
    "Defines a rectangular subregion to be decoded from a JPEG 2000\n"
    "image.  Only those precincts that intersect with the defined region will be\n"
    "decoded.  Precincts are set by calling  --set-output-j2k-channel-precinct-size\n"
  },
  {
    call__set_input_j2k_region_level,
    "-wl",
    NULL
  },
  {
    call__set_input_j2k_region_level,
    "--decode-region",
    NULL
  },
  {
    call__set_input_j2k_selected_channel,
    "--set-input-j2k-selected-channel",
    "<channel index>\n"
    "Selects a specific single color channel to decode from a JPEG 2000\n"
    "image.  The color channels are indexed starting at 0.  Any color\n"
    "rotations specified in the JPEG 2000 image will not be performed on\n"
    "this channel.\n"
  },
  {
    call__set_input_j2k_selected_channel,
    "-sc",
    NULL
  },
  {
    call__set_input_j2k_selected_channel,
    "--selected-channel",
    NULL
  },
  {
    call__set_input_j2k_selected_tile,
    "--set-input-j2k-selected-tile",
    "<tile index>\n"
    "Selects a specific single tile to decode from a JPEG 2000 image.\n"
  },
  {
    call__set_input_j2k_selected_tile,
    "-sl",
    NULL
  },
  {
    call__set_input_j2k_selected_tile,
    "--selected-tile",
    NULL
  },
  {
    call__set_input_dcm_frame_index, 
    "--set-input-dcm-frame-index",
    "<frame index>\n"
    "Selects a specific single frame to decode from a DICOM image.\n"
  },

  {
    call__input_reset_options,
    "--input-reset-options",
    "\n"                        /* no args */
    "Resets all the input options to their default values.\n"
  },
  {
    call__set_output_type,
    "--set-output-type",
    "<output type>\n"
    "Selects the type for the output image.  The output type is one of:\n"
    "  j2k                - JPEG2000 codestreams\n"
    "  jp2                - JPEG2000 file format\n"
    "  tif, tiff          - TIFF\n"
    "  pnm, pbm, pgm, ppm - Any of the portable bit/gray/pix-map formats\n"
    "  dcm, dcm_raw       - DICOM (with embedded raw pixels)\n"
    "  dcm_j2k            - DICOM (with embedded J2K codestreams)\n"
    "  bmp                - Windows bitmap\n"
    "  tga, targa         - TARGA image format\n"
    "  jpg, jpeg          - Original JPEG format\n"
    "  pgx                - Extended portable graymap format\n"
    "  raw                - Unformatted raw data\n"
  },
  {
    call__set_output_type,
    "-t",
    NULL
  },
  {
    call__set_output_type,
    "--output-file-type",
    NULL
  },
  {
    call__get_output_image,
    "--get-output-image",
    "<output image name>\n"
    "Writes a new image to <output image name> using the memory-buffer interface.\n"
    "The output image type must have been specified using --set-output-type\n"
  },
  {
    call__get_output_image,
    "-o",
    NULL
  },
  {
    call__get_output_image,
    "--output-file-name",
    NULL
  },
  {
    call__get_output_image_type,
    "--get-output-image-type",
    "<output type> <output image name>\n"
    "Writes a new image to <output image name> using the memory-buffer interface.\n"
    "The output type is one of:\n"
    "  j2k                - JPEG2000 codestreams\n"
    "  jp2                - JPEG2000 file format\n"
    "  tif, tiff          - TIFF\n"
    "  pnm, pbm, pgm, ppm - Any of the portable bit/gray/pix-map formats\n"
    "  dcm, dcm_raw       - DICOM (with embedded raw pixels)\n"
    "  dcm_j2k            - DICOM (with embedded J2K codestreams)\n"
    "  bmp                - Windows bitmap\n"
    "  tga, targa         - TARGA image format\n"
    "  jpg, jpeg          - Original JPEG format\n"
    "  pgx                - Extended portable graymap format\n"
    "  raw                - Unformatted raw data\n"
  },
  {
    call__get_output_image_raw,
    "--get-output-image-raw",
    "<output image name> [<interleaved>]\n"
    "Writes a new raw image to <output image name> using the memory-buffer\n"
    "interface.  The size of the image will be printed if verbose operation was\n"
    "selected.  The optional <interleaved> flag, which may be `yes' or `no',\n"
    "indicates whether the color channels should be interleaved or not.\n"
  },
  {
    call__get_output_image_raw_ex,
    "--get-output-image-raw-ex",
    "<output image name> [<bits allocated>] [<interleaved>]\n"
    "Writes a new raw image to <output image name> using the memory-buffer\n"
    "interface.  The size of the image will be printed if verbose operation was\n"
    "selected.  The optional <bits allocated> flag controls the padding of the\n"
    "pixel data.  The optional <interleaved> flag, which may be `yes' or `no',\n"
    "indicates whether the color channels should be interleaved or not.\n"
  },
  {
    call__get_output_image_file,
    "--get-output-image-file",
    "<output image name>\n"
    "Writes a new image to <output image name> using the file interface.\n"
    "The output image type must have been specified using --set-output-type\n"
  },
  {
    call__get_output_image_file_type,
    "--get-output-image-file-type",
    "<output type> <output image name>\n"
    "Writes a new image to <output image name> using the file interface.\n"
    "The output type is one of:\n"
    "  j2k                - JPEG2000 codestreams\n"
    "  jp2                - JPEG2000 file format\n"
    "  tif, tiff          - TIFF\n"
    "  pnm, pbm, pgm, ppm - Any of the portable bit/gray/pix-map formats\n"
    "  dcm, dcm_raw       - DICOM (with embedded raw pixels)\n"
    "  dcm_j2k            - DICOM (with embedded J2K codestreams)\n"
    "  bmp                - Windows bitmap\n"
    "  tga, targa         - TARGA image format\n"
    "  jpg, jpeg          - Original JPEG format\n"
    "  pgx                - Extended portable graymap format\n"
    "  raw                - Unformatted raw data\n"
  },
  {
    call__get_output_image_file_raw,
    "--get-output-image-file-raw",
    "<output image name> [<interleaved>]\n"
    "Writes a new raw image to <output image name> using the file\n"
    "interface.  The size of the image will be printed if verbose operation was\n"
    "selected.  The optional <interleaved> flag, which may be `yes' or `no',\n"
    "indicates whether the color channels should be interleaved or not.\n"
  },
  {
    call__set_output_j2k_bitrate,
    "--set-output-j2k-bitrate",
    "<bitrate>\n"
    "Sets the output image bitrate, in bits per pixel.  A bitrate of 0\n"
    "indicates that all the quantized data should be included in the\n"
    "image.  This creates lossless images if the R53 wavelet is chosen\n"
    "using --set-output-j2k-xform.\n"
  },
  {
    call__set_output_j2k_bitrate,
    "-B",
    NULL
  },
  {
    call__set_output_j2k_bitrate,
    "--bitrate",
    NULL
  },
  {
    call__set_output_j2k_ratio,
    "--set-output-j2k-ratio",
    "<ratio>\n"
    "Sets the compression ratio for the output image.  A ratio of 0\n"
    "indicates that all the quantized data should be included in the\n"
    "image.  This creates lossless images if the R53 wavelet is chosen\n"
    "using --set-output-j2k-xform.\n"
  },
  {
    call__set_output_j2k_ratio,
    "-R",
    NULL
  },
  {
    call__set_output_j2k_ratio,
    "--ratio",
    NULL
  },
  {
    call__set_output_j2k_filesize,
    "--set-output-j2k-filesize",
    "<file size>\n"
    "Sets the output image size, in bytes.\n"
  },
  {
    call__set_output_j2k_filesize,
    "-F",
    NULL
  },
  {
    call__set_output_j2k_filesize,
    "--file-size",
    NULL
  },
  {
    call__set_output_j2k_psnr,
    "--set-output-j2k-psnr",
    "<psnr>\n"
    "Sets the output image pSNR, in dB.\n"
  },
  {
    call__set_output_j2k_color_xform,
    "--set-output-j2k-color-xform",
    "<color transform flag>\n"
    "Sets whether the color transform will be performed.  The value of <color\n"
    "transform flag> should be `yes' to perform and `no' to skip the transform.\n"
    "The color transform can only be performed only if there are 3 or more\n"
    "channels and the first three channels have the same bit depth, data\n"
    "type (signed or unsigned), and subsampling.\n"
  },
  {
    call__set_output_j2k_color_xform,
    "--color-transform",
    NULL
  },
  {
    call__set_output_j2k_color_xform_ex,
    "--set-output-j2k-color-xform-ex",
    "<tile index> <color transform flag>\n"
    "Sets whether the color transform will be performed in tile <tile index>.  The\n"
    "value of <color transform flag> should be `yes' to perform and `no' to skip\n"
    "the transform.  The color transform can only be performed only if there are 3\n"
    "or more channels and the first three channels have the same bit depth, data\n"
    "type (signed or unsigned), and subsampling.\n"
  },
  {
    call__set_output_j2k_progression_order,
    "--set-output-j2k-progression-order",
    "<progression order>\n"
    "Sets the progression order of the compressed image file.  The value of\n"
    "<progression order> is one of the following:\n"
    "\n"
    "lrcp - Layer, Resolution, Component, Position\n"
    "rlcp - Resolution, Layer, Component, Position\n"
    "rpcl - Resolution, Position, Component, Layer\n"
    "pcrl - Position, Component, Resolution, Layer\n"
    "cprl - Component, Position, Resolution, Layer\n"
  },
  {
    call__set_output_j2k_progression_order,
    "-p",
    NULL
  },
  {
    call__set_output_j2k_progression_order,
    "--progression-order",
    NULL
  },
  {
    call__set_output_j2k_tile_size,
    "--set-output-j2k-tile-size",
    "<tile width> <tile height>\n"
    "Sets the tile size for JPEG 2000 output.  All tiles, except those\n"
    "at the edges of the image, will be of this size.\n"
  },
  {
    call__set_output_j2k_tile_size,
    "--tile-size",
    NULL
  },
  {
    call__set_output_j2k_add_comment,
    "--set-output-j2k-add-comment",
    "<comment string> [<comment type> [<comment location>]]\n"
    "Adds a comment to the JPEG 2000 image.  The value of <comment string> is used\n"
    "verbatim for the comment.  The optional <comment type> flag, whose values may\n"
    "be `binary' or `text', denotes whether the comment is binary data or Latin-1\n"
    "(ISO-8859-15) text.  Text is the default type.  The optional <comment\n"
    "location> field may be `main' to denote that the comment will be stored in the\n"
    "main header, or an index to denote that the comment will be stored in the\n"
    "header of the indexed tile.  The default location is the main header.\n"
  },
  {
    call__set_output_j2k_add_comment,
    "--add-comment",
    NULL
  },
  {
    call__set_output_j2k_add_comment,
    "--add-comment-from-file",
    "<comment file> [<comment type> [<comment location>]]\n"
    "Adds a comment to the JPEG 2000 image.  The comment is taken from the file\n"
    "named <comment file>.  The optional <comment type> flag, whose values may\n"
    "be `binary' or `text', denotes whether the comment is binary data or Latin-1\n"
    "(ISO-8859-15) text.  Binary is the default type.  The optional <comment\n"
    "location> field may be `main' to denote that the comment will be stored in the\n"
    "main header, or an index to denote that the comment will be stored in the\n"
    "header of the indexed tile.  The default location is the main header.\n"
  },
  {
    call__set_output_j2k_image_offset,
    "--set-output-j2k-image-offset",
    "<x offset> <y offset>\n"
    "Offsets the image boundary from the top-left corner of the image\n"
    "grid, thereby cropping the image.\n"
  },
  {
    call__set_output_j2k_image_offset,
    "--image-offset",
    NULL
  },
  {
    call__set_output_j2k_tile_offset,
    "--set-output-j2k-tile-offset",
    "<x offset> <y offset>\n"
    "Offsets the tile boundary from the top-left corner of the image\n"
    "grid.  The tile offset must be within the rectangle defined by the\n"
    "origin and the image offset.\n"
  },
  {
    call__set_output_j2k_tile_offset,
    "--tile-offset",
    NULL
  },
  {
    call__set_output_j2k_error_resilience,
    "--set-output-j2k-error-resilience",
    "<error resilience options list>\n"
    "Enables and disables the use of the error resilience features of JPEG 2000.\n"
    "Allows Start of Packet and End of Packet Header markers to be added to the\n"
    "codestream, as well as Segmentation Symbols to be embedded in it.\n"
    "The error resilience options are:\n"
    "  SOP  - to enable Start of Packet markers\n"
    "  EPH  - to enable End of Packet Header markers\n"
    "  SEG  - to enable segmentation symbols\n"
    "  ALL  - to enable all of the above\n"
    "  NONE - to disable all of the options\n"
    "Multiple options may be listed, separated by commas.\n"
  },
  {
    call__set_output_j2k_error_resilience,
    "-E",
    NULL
  },
  {
    call__set_output_j2k_error_resilience,
    "--error-resilience",
    NULL
  },
  {
    call__set_output_j2k_error_resilience_ex,
    "--set-output-j2k-error-resilience-ex",
    "<tile index> <channel index> <error resilience options list>\n"
    "Enables and disables the use of the error resilience features of JPEG 2000\n"
    "for the given channel of a tile.  Allows Start of Packet and End of Packet\n"
    "Header markers to be added to the codestream, as well as Segmentation Symbols\n"
    "to be embedded in it.  SOP and EPH markers cannot be set individually by\n"
    "channel; they must be enabled or disabled for all channels of a tile.\n"
    "The error resilience options are:\n"
    "  SOP  - to enable Start of Packet markers\n"
    "  EPH  - to enable End of Packet Header markers\n"
    "  SEG  - to enable segmentation symbols\n"
    "  ALL  - to enable all of the above\n"
    "  NONE - to disable all of the options\n"
    "Multiple options may be listed, separated by commas.\n"
  },
  {
    call__set_output_j2k_error_resilience_ex,
    "--error-resilience-ex",
    NULL
  },
  {
    call__set_output_j2k_xform,
    "--set-output-j2k-xform",
    "<transform type> [<transform depth>]\n"
    "Selects the type of wavelet and (optionally) the transform depth to use for\n"
    "compression.  The wavelet choices are:\n"
    "  I97 - irreversible 9-7 wavelet\n"
    "  R53 - reversible 5-3 wavelet\n"
  },
  {
    call__set_output_j2k_xform,
    "-w",
    NULL
  },
  {
    call__set_output_j2k_xform,
    "--wavelet-transform",
    NULL
  },
  {
    call__set_output_j2k_xform_ex,
    "--set-output-j2k-xform-ex",
    "<tile index> <channel index> <transform type> [<transform depth>]\n"
    "Selects the type of wavelet and (optionally) the transform depth to use for\n"
    "compression.  The wavelet choices are:\n"
    "  I97 - irreversible 9-7 wavelet\n"
    "  R53 - reversible 5-3 wavelet\n"
  },
{
    call__set_output_j2k_wavelet_mct,
    "--set-output-j2k-wavelet-mct",
    "<transform type> [<transform depth>] [<number of components>]\n"
    "Selects the type of multi-component wavelet transform, (optionally) the transform depth to use for\n"
    "compression and (optionally) the number of components for each component collection.  The wavelet choices are:\n"
    "  I97 - irreversible 9-7 wavelet\n"
    "  R53 - reversible 5-3 wavelet\n"
  },
  {
    call__set_output_j2k_wavelet_mct,
    "-mct",
    NULL
  },
  {
    call__set_output_j2k_layers,
    "--set-output-j2k-layers",
    "<quality layers>\n"
    "Sets the number of quality layers to be embedded in a JPEG 2000 image.\n"
  },
  {
    call__set_output_j2k_layers,
    "-y",
    NULL
  },
  {
    call__set_output_j2k_layers,
    "--layers",
    NULL
  },
  {
    call__set_output_j2k_layer_bitrate,
    "--set-output-j2k-layer-bitrate",
    "<layer index> <bitrate>\n"
    "Sets the target bitrate, in bits per pixel, for the selected quality layer.\n"
  },
  {
    call__set_output_j2k_layer_bitrate,
    "-yB",
    NULL
  },
  {
    call__set_output_j2k_layer_bitrate,
    "--layer-bitrate",
    NULL
  },
  {
    call__set_output_j2k_layer_bitrate_ex,
    "--set-output-j2k-layer-bitrate-ex",
    "<tile index> <layer index> <bitrate>\n"
    "Sets the target bitrate, in bits per pixel, for the selected quality layer\n"
    "of the selected tile.\n"
  },
  {
    call__set_output_j2k_layer_ratio,
    "--set-output-j2k-layer-ratio",
    "<layer index> <ratio>\n"
    "Sets the target compression ratio for the selected quality layer.\n"
  },
  {
    call__set_output_j2k_layer_ratio,
    "-yR",
    NULL
  },
  {
    call__set_output_j2k_layer_ratio,
    "--layer-ratio",
    NULL
  },
  {
    call__set_output_j2k_layer_ratio_ex,
    "--set-output-j2k-layer-ratio-ex",
    "<tile index> <layer index> <ratio>\n"
    "Sets the target compression ratio for the selected quality layer of the\n"
    "selected tile.\n"
  },
  {
    call__set_output_j2k_layer_size,
    "--set-output-j2k-layer-size",
    "<layer index> <byte count>\n"
    "Sets the target size, in bytes, of the selected quality layer.\n"
  },
  {
    call__set_output_j2k_layer_size,
    "-yF",
    NULL
  },
  {
    call__set_output_j2k_layer_size,
    "--layer-size",
    NULL
  },
  {
    call__set_output_j2k_layer_size_ex,
    "--set-output-j2k-layer-size-ex",
    "<tile index> <layer index> <byte count>\n"
    "Sets the target size, in bytes, of the selected quality layer of the selected\n"
    "tile.\n"
  },
  {
    call__set_output_j2k_layer_psnr,
    "--set-output-j2k-layer-psnr",
    "<layer index> <psnr>\n"
    "Sets the output image pSNR for a specific layer, in dB.\n"
  },
  {
    call__set_output_j2k_layer_psnr_ex,
    "--set-output-j2k-layer-psnr-ex",
    "<tile index> <layer index> <psnr>\n"
    "Sets the output image pSNR for a specific layer of the selected tile, in dB.\n"
  },
  {
    call__set_output_j2k_channel_quantization,
    "--set-output-j2k-channel-quantization",
    "<channel index> <quantization type>\n"
    "Sets the quantization type for a channel of a JPEG 2000 image.  The channel\n"
    "index may be `all' to set the quantization for all channels.  The supported\n"
    "quantization types are:\n"
    "  reversible - Reversible quantization (used only with the 5-3 wavelet)\n"
    "  derived    - Derived irreversible quantization (used with the 9-7 wavelet)\n"
    "  expounded  - Expounded irreversible quantization (used with the 9-7 wavelet)\n"
  },
  {
    call__set_output_j2k_channel_quantization,
    "-q",
    NULL
  },
  {
    call__set_output_j2k_channel_quantization,
    "--quantization-type",
    NULL
  },
  {
    call__set_output_j2k_quantization_ex,
    "--set-output-j2k-quantization-ex",
    "<tile index> <channel index> <quantization type>\n"
    "Sets the quantization type for a channel of a tile of a JPEG 2000 image.  The\n"
    "tile index may be `all' to set the quantization for all the tiles; similarly,\n"
    "the channel index may be `all' to set the quantization for all channels.  The\n"
    "supported quantization types are:\n"
    "  reversible - Reversible quantization (used only with the 5-3 wavelet)\n"
    "  derived    - Derived irreversible quantization (used with the 9-7 wavelet)\n"
    "  expounded  - Expounded irreversible quantization (used with the 9-7 wavelet)\n"
  },
  {
    call__set_output_j2k_quantization_binwidth_scale,
    "--set-output-j2k-quantization-binwidth-scale",
    "<binwidth scale>\n"
    "Scales the default binwidths by the factor <binwidth scale>.  This\n"
    "scale is only applied to the derived and expounded quantization options.\n"
  },
  {
    call__set_output_j2k_quantization_binwidth_scale,
    "--binwidth-scale",
    NULL
  },
  {
    call__set_output_j2k_quantization_binwidth_scale_ex,
    "--set-output-j2k-quantization-binwidth-scale-ex",
    "<tile index> <channel index> <binwidth scale>\n"
    "Scales the default binwidths for a channel of a tile by the factor <binwidth\n"
    "scale>.  This scale is only applied to the derived and expounded quantization\n"
    "options.\n"
  },
  {
    call__set_output_j2k_guard_bits,
    "--set-output-j2k-guard-bits",
    "<guard bits>\n"
    "Sets the number of guard bits, which are used to ensure the the\n"
    "block encoder does not overflow.  The legal values for this parameter\n"
    "range from 0 to 7.  The default is 2.\n"
  },
  {
    call__set_output_j2k_guard_bits,
    "-g",
    NULL
  },
  {
    call__set_output_j2k_guard_bits,
    "--guard-bits",
    NULL
  },
  {
    call__set_output_j2k_guard_bits_ex,
    "--set-output-j2k-guard-bits-ex",
    "<tile index> <channel index> <guard bits>\n"
    "Sets the number of guard bits, which are used to ensure the the\n"
    "block encoder does not overflow, for a specified channel of a tile.  The legal\n"
    "values for this parameter range from 0 to 7.  The default is 2.\n"
  },
  {
    call__set_output_j2k_channel_precinct_size,
    "--set-output-j2k-channel-precinct-size",
    "<channel index> <resolution index> <precinct height> <precinct width>\n"
    "Sets the dimensions of the precincts in a JPEG 2000 image.  <Channel index>\n"
    "can either be `all' for all channels or the index of a channel for which the\n"
    "precinct sizes are set.  <Resolution index> runs from 0 for the lowest\n"
    "resolution to one more than the number of transform levels.  <Precinct height>\n"
    "and <precinct width> are the base-2 logarithm of the desired precinct sizes.\n"
    "They can range from 0 to 15.  Precinct size of 0 is only allowed for\n"
    "resolution level 0.\n"
  },
  {
    call__set_output_j2k_channel_precinct_size,
    "-P",
    NULL
  },
  {
    call__set_output_j2k_channel_precinct_size,
    "--precinct",
    NULL
  },
  {
    call__set_output_j2k_precinct_size_ex,
    "--set-output-j2k-precinct-size-ex",
    "<tile index> <channel index> <resolution index> <precinct height> <precinct width>\n"
    "Sets the dimensions of the precincts for a channel in a tile.  <Resolution\n"
    "index> runs from 0 for the lowest resolution, to N, where N is the number of\n"
    "transform levels.  <Precinct height> and <precinct width> are the base-2\n"
    "logarithm of the desired precinct sizes.  They can range from 0 to 15.\n"
    "Precinct size of 0 is only allowed for resolution level 0.\n"
  },
  {
    call__set_output_j2k_codeblock_size,
    "--set-output-j2k-codeblock-size",
    "<codeblock height> <codeblock width>\n"
    "Sets the dimensions of the codeblocks.  The values for <codeblock height> and\n"
    "<codeblock width> are the base-2 logarithm of the actual codeblock sizes.\n"
    "Each of height and width may range from 2 to 10, and their sum must be less\n"
    "than or equal to 12.\n"
  },
  {
    call__set_output_j2k_codeblock_size,
    "-cb",
    NULL
  },
  {
    call__set_output_j2k_codeblock_size,
    "--codeblock-size",
    NULL
  },
  {
    call__set_output_j2k_codeblock_size_ex,
    "--set-output-j2k-codeblock-size-ex",
    "<tile index> <channel index> <codeblock height> <codeblock width>\n"
    "Sets the dimensions of the codeblocks in a channel of a tile.  The values for\n"
    "<codeblock height> and <codeblock width> are the base-2 logarithm of the\n"
    "actual codeblock sizes.  Each of height and width may range from 2 to 10, and\n"
    "their sum must be less than or equal to 12.\n"
  },
  {
    call__set_output_j2k_arithmetic_coding_option,
    "--context-reset",
    "<context reset frequency>\n"
    "Sets how frequently the arithmetic coder is reset.  The allowed values are:\n"
    "  block - only at the end of codeblock\n"
    "  pass  - at the end of each coding pass\n"
    "Reset at end of codeblock is the default\n"
  },
  {
    call__set_output_j2k_arithmetic_coding_option,
    "--ac-term",
    "<arithmetic termination frequency>\n"
    "Sets how frequently the arithmetic coder is terminated.  The allowed values\n"
    "are:\n"
    "  block - only at the end of codeblock\n"
    "  pass  - at the end of each coding pass\n"
    "Termination at end of codeblock is the default\n"
  },
  {
    call__set_output_j2k_arithmetic_coding_option,
    "--pred-term",
    "<predictable termination flag>\n"
    "Determines whether predictable termination will be used.  The allowed values\n"
    "are:\n"
    "  yes - use predictable termination\n"
    "  no  - do not use predictable termination (use normal termination)\n"
    "Normal termination is the default.\n"
  },
  {
    call__set_output_j2k_arithmetic_coding_option,
    "--vert-causal",
    "<vertically causal context flag>\n"
    "Sets whether the aritmetic coder's context formation will be vertically\n"
    "causal.  The allowed values are:\n"
    "  yes - use vertically causal context formation\n"
    "  no  - do not use vertically causal context formation (use normal context\n"
    "        formation)\n"
    "Normal context formation is the default.\n"
  },
  {
    call__set_output_j2k_arithmetic_coding_option,
    "--set-output-j2k-arithmetic-coding-option",
    "<option> <value>\n"
    "Sets any of the arithmetic coding options.  The following options, and their\n"
    "corresponding values, are supported:\n"
    "\n"
    "  context - sets how frequently the arithmetic coder is reset.  The allowed\n"
    "            values are:\n"
    "              block - only at the end of codeblock\n"
    "              pass  - at the end of each coding pass\n"
    "            Reset at end of codeblock is the default\n"

    "\n"
    "  arith   - sets how frequently the arithmetic coder is terminated.  The\n"
    "            allowed values are:\n"
    "              block - only at the end of codeblock\n"
    "              pass  - at the end of each coding pass\n"
    "            Termination at end of codeblock is the default\n"
    "\n"
    "  pred    - determines whether predictable termination will be used.  The\n"
    "            allowed values are:\n"
    "              yes   - use predictable termination\n"
    "              no    - do not use predictable termination (use normal\n"
    "                      termination)\n"
    "            Normal termination is the default.\n"
    "\n"
    "  vert    - sets whether the aritmetic coder's context formation will be\n"
    "            vertically causal.  The allowed values are:\n"
    "              yes - use vertically causal context formation\n"
    "              no  - do not use vertically causal context formation (use\n"
    "                    normal context formation)\n"
    "            Normal context formation is the default.\n"
  },
  {
    call__set_output_j2k_arithmetic_coding_option_ex,
    "--set-output-j2k-arithmetic-coding-option-ex",
    "<tile index> <channel index> <option> <value>\n"
    "Sets any of the arithmetic coding options for a channel of a tile.  The\n"
    "following options, and their corresponding values, are supported:\n"
    "\n"
    "  context - sets how frequently the arithmetic coder is reset.  The allowed\n"
    "            values are:\n"
    "              block - only at the end of codeblock\n"
    "              pass  - at the end of each coding pass\n"
    "            Reset at end of codeblock is the default\n"

    "\n"
    "  arith   - sets how frequently the arithmetic coder is terminated.  The\n"
    "            allowed values are:\n"
    "              block - only at the end of codeblock\n"
    "              pass  - at the end of each coding pass\n"
    "            Termination at end of codeblock is the default\n"
    "\n"
    "  pred    - determines whether predictable termination will be used.  The\n"
    "            allowed values are:\n"
    "              yes   - use predictable termination\n"
    "              no    - do not use predictable termination (use normal\n"
    "                      termination)\n"
    "            Normal termination is the default.\n"
    "\n"
    "  vert    - sets whether the aritmetic coder's context formation will be\n"
    "            vertically causal.  The allowed values are:\n"
    "              yes - use vertically causal context formation\n"
    "              no  - do not use vertically causal context formation (use\n"
    "                    normal context formation)\n"
    "            Normal context formation is the default.\n"
  },
  {
    call__set_output_j2k_coding_predictor_offset,
    "--set-output-j2k-coding-predictor-offset",
    "<predictor offset>\n"
    "Sets the offset from the predicted point at which coding will stop.  A\n"
    "smaller number will result in faster compression, though with a possible\n"
    "reduction in quality.  The default value is 2; a value of 1 will speed\n"
    "up compression and reduce quality; 3 will reduce speed and increase quality;\n"
    "0 will cause the library to code everything, resulting in the lowest speed\n"
    "but best quality.\n"
  },
  {
    call__set_output_j2k_coding_predictor_offset,
    "--predictor-offset",
    NULL
  },
  {
    call__set_output_j2k_coding_predictor_offset_ex,
    "--set-output-j2k-coding-predictor-offset-ex",
    "<tile index> <predictor offset>\n"
    "Sets the offset from the predicted point at which coding will stop for the\n"
    "given tile.  A smaller number will result in faster compression, though with a\n"
    "possible reduction in quality.  The default value is 2; a value of 1 will speed\n"
    "up compression and reduce quality; 3 will reduce speed and increase quality;\n"
    "0 will cause the library to code everything, resulting in the lowest speed\n"
    "but best quality.\n"
  },
  {
    call__set_output_j2k_component_registration,
    "--set-output-j2k-component-registration",
    "<channel> <x registration offset> <y registration offset>\n"
    "Sets a color channel's registration offset in a JPEG 2000 image.\n"
    "The registration offsets indicate how much to offset each color\n"
    "channel relative to the image grid for display.  The offsets are\n"
    "given in units of 1/65536 of a pixel.\n"
  },
  {
    call__set_output_j2k_component_registration,
    "--set-component-registration",
    NULL
  },
  {
    call__set_output_j2k_tile_toc,
    "--set-output-j2k-tile-toc",
    "\n"                        /* no args */
    "Adds to the JPEG 2000 image a Tile Length Marker (TLM) segment.\n"
  },
  {
    call__set_output_j2k_tile_toc,
    "--add-tile-toc",
    NULL
  },
  {
    call__set_output_j2k_tile_data_toc,
    "--set-output-j2k-tile-data-toc",
    "\n"                        /* no args */
    "Adds to the JPEG 2000 image a Packet Length, Tilepart Header Marker (PLT)\n"
    "segment.\n"
  },
  {
    call__set_output_j2k_tile_data_toc,
    "--add-tile-data-toc",
    NULL
  },
  {
    call__set_output_j2k_tile_data_toc_ex,
    "--set-output-j2k-tile-data-toc-ex",
    "<tile index> <inclusion>\n"
    "Specifies whether to add to the given tile a Packet Length, Tilepart Header\n"
    "Marker (PLT) segment.  The <inclusion> parameter is boolean -- i.e. `Yes' or\n"
    "`No' are its expected values.\n"
  },
  {
    call__set_output_j2k_header_option,
    "--set-output-j2k-header-option",
    "<header> <end_marker>\n"
    "Determines whether the output j2k code stream will have a header and an end of\n"
    "stream marker.  By default both of the parameters are true.\n"
  },
  {
    call__set_output_j2k_clear_comments,
    "--set-output-j2k-clear-comments",
    "\n"                        /* no args */
    "Clears all comments from a JPEG 2000 image.\n"
  },
  {
    call__output_reset_options,
    "--output-reset-options",
    "\n"                        /* no args */
    "Resets all of the options set by the output image functions.\n"
  },
  {
    call__set_output_j2k_roi_from_image,
    "--set-output-j2k-roi-from-image",
    "<ROI image file name>\n"
    "Defines a region of interest from an image.  The image is input to the library\n"
    "through the memory-buffer interface, and its type is automatically determined.\n"
  },
  {
    call__set_output_j2k_roi_from_image,
    "--roi-image",
    NULL
  },
  {
    call__set_output_j2k_roi_from_image_type,
    "--set-output-j2k-roi-from-image-type",
    "<ROI image file name> <ROI image type>\n"
    "Defines a region of interest from an image.  The image is input to the library\n"
    "through the memory-buffer interface, and its type is as given.\n"
  },
  {
    call__set_output_j2k_roi_from_image_raw,
    "--set-output-j2k-roi-from-image-raw",
    "<ROI image file name> <rows> <columns> <bit_depth> [<interleaved>]\n"
    "Defines a region of interest from an image.  The raw image is input to the\n"
    "library throught the memory-buffer interface.  The size of the image is\n"
    "specified using <rows>, <columns>, and <bit_depth>.  Only one channel of the\n"
    "image is read.\n"
  },
  {
    call__set_output_j2k_roi_from_file,
    "--set-output-j2k-roi-from-file",
    "<ROI image file name>\n"
    "Defines a region of interest from an image.  The image is input to the library\n"
    "through the file interface, and its type is automatically determined.\n"
  },
  {
    call__set_output_j2k_roi_from_file_raw,
    "--set-output-j2k-roi-from-file-raw",
    "<ROI image file name> <rows> <columns> <bit_depth> [<interleaved>]\n"
    "Defines a region of interest from an image.  The raw image is input to the\n"
    "library throught the file interface.  The size of the image is specified using\n"
    "<rows>, <columns>, and <bit_depth>.  Only one channel of the image is read.\n"
  },
  {
    call__set_output_j2k_roi_add_shape,
    "--roi-rect",
    "<left> <top> <width> <height>\n"
    "A filled rectangle is added to the region of interest.\n"
  },
  {
    call__set_output_j2k_roi_add_shape,
    "--roi-ellipse",
    "<left> <top> <width> <height>\n"
    "A filled ellipse is added to the region of interest.\n"
  },
  {
    call__set_output_j2k_roi_add_shape,
    "--set-output-j2k-roi-add-shape",
    "<shape> <left> <top> <width> <height>\n"
    "A filled shape is added to the region of interest.  The shapes are:\n"
    "  rectangle\n"
    "  ellipse\n"
  },
  {
    call__set_output_j2k_clear_roi,
    "--set-output-j2k-clear-roi",
    "\n"                        /* no args */
    "Clears all region of interest information.\n"
  },
  {
    call__set_output_jpg_options,
    "--set-output-jpg-options",
    "<quality>\n"
    "Sets the quality parameter for JPEG compression (not JPEG 2000).  The quality\n"
    "parameter ranges from 0 to 100. Set quality to -1 for lossless compression.\n"
  },
  {
    call__set_output_jpg_options,
    "--quality",
    NULL
  },
  {
    call__set_output_com_geometry_rotation,
    "--set-output-com-geometry-rotation",
    "<angle>\n"
    "Rotates the input image by <angle> degrees.  <Angle> must be an whole multiple\n"
    "of 90.\n"
  },
  {
    call__set_output_com_geometry_rotation,
    "--rotate",
    NULL
  },
  {
    call__set_output_raw_endianness,
    "--set-output-raw-endianness",
    "<endianness>\n"
    "Sets the endianness of an output raw image.  The endianness values are:\n"
    "  big\n"
    "  little\n"
  },
  {
    call__set_input_j2k_error_handling,
    "--set-input-j2k-error-handling",
    "<mode>\n"
    "Sets the error handling mode of the JPEG 2000 decoder.  The modes are:\n"
    "  resilient - attempts to recover from errors\n"
    "  strict    - stops decoding on the first error detection\n"
  },
  {
    call__get_input_j2k_decoder_status,
    "--get-input-j2k-decoder-status",
    "\n"                        /* no args */
    "Returns the status of the JPEG 2000 decoder, which will signal whether a JPEG\n"
    "2000 image was successfully decoded, or whether errors were found\n"
  },
  {
    call__set_output_jp2_add_metadata_box,
    "--set-output-jp2-add-metadata-box",
    "<type> <data file name> [<uuid file name>]\n"
    "Add the data found in <data file name> to a metadata box of a JP2 image.\n"
    "<type> is one of:\n"
    "  jp2i - to add intellectual property metadata\n"
    "  xml  - to add XML\n"
    "  uuid - to add an UUID box\n"
    "The <uuid file name> argument should be used only if adding a UUID box.  The\n"
    "UUID contained in that file must be 16 bytes long.\n"
  },
  {
    call__set_output_jp2_add_UUIDInfo_box,
    "--set-output-jp2-add-UUIDInfo-box",
    "<UUID list file name> <url>\n"
    "Adds a UUID Information box to a JP2 image.  <UUID list file> is a file\n"
    "containing a list of the UUIDs to add to the box.  Each <uuid> is 16 bytes\n"
    "long.\n"
  },
  {
    call__set_output_enum_colorspace,
    "--set-output-enum-colorspace",
    "<color space>\n"
    "Sets the color space of the output image, which can be one of:\n"
    "  greyscale\n"
    "  sRGB\n"
    "  sYCC\n"
    "  default\n"
    "The default action is to set the color space to greyscale for single channel\n"
    "images, and sRGB for multi-channel images.\n"
  },
  {
    call__set_output_jp2_restricted_ICCProfile,
    "--set-output-jp2-restricted-ICCProfile",
    "<ICC Profile file>\n"
    "Reads a restricted ICC color space profile from the given file and uses it\n"
    "to set the output color space of a JP2 image, without performing any color\n"
    "conversions.\n"
  },
  {
    call__get_output_j2k_layer_psnr_estimate,
    "--get-output-j2k-layer-psnr-estimate",
    "<layer index>\n"
    "Returns the estimated pSNR for the specified layer. \n"
    "<Layer Index> can either be `all' for all layers or the index of the specific \n"
    "layer. For an image with N layers, layer index runs from 0 for the first \n"
    "layer to N-1 for all layers.  For images with more than one channel \n"
    "the value returned is the average estimate for all channels. \n"
    "This option should be used after the -o option, on the command line.\n"
  },
    
    {
    call__get_input_jp2_num_metadata_boxes,
    "--get-input-jp2-num-metadata-boxes",
    "<box type>\n"
    "Prints the count of metadata box of the given type in an input JP2 image.\n"
    "The <box type> can be one of:\n"
    "  jp2i     - for Intellectual Property boxes;\n"
    "  xml      - for XML boxes;\n"
    "  uuid     - for UUID boxes; or\n"
    "  uuidinfo - for UUID Information boxes.\n"
  },
  {
    call__get_input_jp2_metadata_box,
    "--get-input-jp2-metadata-box",
    "<box type> <box index> [<data file name> [<UUID file name>]]\n"
    "Prints, or optionally stores to the named files, the contents of the box of\n"
    "the given type and index.  The <box type> can be one of:\n"
    "  jp2i     - for Intellectual Property boxes;\n"
    "  xml      - for XML boxes;\n"
    "  uuid     - for UUID boxes; or\n"
    "The <UUID file name> may only be supplied if the <box type> is ``uuid''.\n"
  },
  {
    call__get_input_jp2_UUIDInfo_box,
    "--get-input-jp2-UUIDInfo-box",
    "<box index> [<UUID file name> [<URL file name>]]\n"
    "Prints, or optionally stores to the named files, the contets of the UUID\n"
    "Information box denoted by the given index.  If a single file name is given,\n"
    "The UUID list is stored to that file and the URL is printed to screen.\n"
  },
  {
    call__get_input_jp2_enum_colorspace,
    "--get-input-jp2-enum-colorspace",
    "\n"                        /* no args */
    "Prints the color space of a JP2 input image, if the color space is stored as\n"
    "an enumerated color space.\n"
  },
  {
    call__get_input_jp2_restricted_ICCProfile,
    "--get-input-jp2-restricted-ICCProfile",
    "[<file name>]\n"
    "Prints, or optionally stores to the named file, the color space of a JP2 input\n"
    "image, if the color space is stored as a Restricted ICC Profile.\n"
  },
  {
    call__verbose,
    "--verbose",
    "\n"                        /* no args */
    "Increases the verbosity level of the program.\n"
  },
  {
    call__verbose,
    "-v",
    NULL
  },
  {
    call__quiet,
    "--quiet",
    "\n"                        /* no args */
    "Decreases the verbosity level of the program.\n"
  },
  {
    call__benchmark,
    "--benchmark",
    "[<repetitions>]\n"
    "Enables benchmarking mode.\n"
  },
  {
    call__verbose_to_stdout,
    "--verbose-to-stdout",
    "\n"                        /* no args */
    "Redirects all verbose and diagnostic output from stderr to stdout.  Note that\n"
    "this disables the use of stdout for retrieving images.\n"
  },
};


/* read_string: read a string argument from the args list */
static void
read_string(char **dest, args_t *args, state_flags *flags, int optional_flag,
            char *err_message)
{
  args->arg++;
  if (args->argc > args->arg && (args->argv[args->arg][0] != '-' ||
                                 args->argv[args->arg][1] == '\0'))
    *dest = args->argv[args->arg];
  else {
    *dest = NULL;
    args->arg--;
    if (err_message)
      fprintf(flags->diagnostic_stream, "%s\n", err_message);
    if (ARG_MANDATORY == optional_flag)
      exit(1);
  }
  return;
}

/* read_int: read an integer argument from the args list */
static void
read_int(int *dest, args_t *args, state_flags *flags, int optional_flag,
         char *err_message)
{
  args->arg++;
  if (args->argc > args->arg && (args->argv[args->arg][0] != '-' ||
                                 isdigit((int)args->argv[args->arg][1])))
    *dest = atoi(args->argv[args->arg]);
  else {
    args->arg--;
    if (err_message)
      fprintf(flags->diagnostic_stream, "%s\n", err_message);
    if (ARG_MANDATORY == optional_flag)
      exit(1);
  }
  return;
}
/* read_ulint: read an unsigned long integer argument from the args list */
static void
read_ulint(unsigned long int *dest, args_t *args, state_flags *flags,
           int optional_flag, char *err_message)
{
  args->arg++;
  if (args->argc > args->arg && args->argv[args->arg][0] != '-')
    *dest = (unsigned long int)atoi(args->argv[args->arg]);
  else {
    args->arg--;
    if (err_message)
      fprintf(flags->diagnostic_stream, "%s\n", err_message);
    if (ARG_MANDATORY == optional_flag)
      exit(1);
  }
  return;
}
/* read_lint: read a long integer argument from the args list */
static void
read_lint(long int *dest, args_t *args, state_flags *flags,
          int optional_flag, char *err_message)
{
  args->arg++;
  if (args->argc > args->arg && (args->argv[args->arg][0] != '-' ||
                                 isdigit((int)args->argv[args->arg][1])))
    *dest = (long int)atoi(args->argv[args->arg]);
  else {
    args->arg--;
    if (err_message)
      fprintf(flags->diagnostic_stream, "%s\n", err_message);
    if (ARG_MANDATORY == optional_flag)
      exit(1);
  }
  return;
}

/* read_int_or_string: read an argument from the args list, and return it
 * as either an int (if parseable as an int) or a string
 */
static void
read_int_or_string(char **dest_string, int *dest_int, args_t *args,
                   state_flags *flags, int optional_flag, char *err_message)
{
  int c, l, number;
  *dest_string = NULL;
  args->arg++;
  if (args->argc > args->arg && (args->argv[args->arg][0] != '-' ||
                                 isdigit((int)args->argv[args->arg][1]))) {
    l = strlen(args->argv[args->arg]);
    number = isdigit((int)args->argv[args->arg][0]) ||
      (args->argv[args->arg][0] == '-');
    for (c = 1; c < l && number; c++)
      number = number && isdigit((int)args->argv[args->arg][c]);
    if (number)
      *dest_int = atoi(args->argv[args->arg]);
    else
      *dest_string = args->argv[args->arg];
  }
  else {
    args->arg--;
    if (err_message)
      fprintf(flags->diagnostic_stream, "%s\n", err_message);
    if (ARG_MANDATORY == optional_flag)
      exit(1);
  }
  return;
}

/* read_float: read a float argument from the args list */
static void
read_float(float *dest, args_t *args, state_flags *flags, int optional_flag,
           char *err_message)
{
  args->arg++;
  if (args->argc > args->arg && (args->argv[args->arg][0] != '-' ||
                                 isdigit((int)args->argv[args->arg][1])))
    *dest = (float)atof(args->argv[args->arg]);
  else {
    args->arg--;
    if (err_message)
      fprintf(flags->diagnostic_stream, "%s\n", err_message);
    if (ARG_MANDATORY == optional_flag)
      exit(1);
  }
  return;
}

/* read_boolean: read a boolean argument from the args list.  Anything
 * starting with 'T', 't', 'Y', 'y' is considered true; everything
 * else is false.
 */
static void
read_boolean(BOOL *dest, args_t *args, state_flags *flags, int optional_flag,
             char *err_message)
{
  args->arg++;
  if (args->argc > args->arg && args->argv[args->arg][0] != '-') {
    switch (args->argv[args->arg][0]) {
    case 'T': case 't': case 'Y': case 'y':
      *dest = TRUE;
      break;
    default:
      *dest = FALSE;
    }
  }
  else {
    *dest = NULL;
    args->arg--;
    if (err_message)
      fprintf(flags->diagnostic_stream, "%s\n", err_message);
    if (ARG_MANDATORY == optional_flag)
      exit(1);
  }
  return;
}

static int
read_type(args_t *args, state_flags *flags, int optional_flag,
          char *err_message)
{
  char *type_string;
  read_string(&type_string, args, flags, optional_flag, err_message);
  downcase(type_string);
  if (!strcmp(type_string, "j2k"))
    return AW_J2K_FORMAT_J2K;
  else if (!strcmp(type_string, "jp2"))
    return AW_J2K_FORMAT_JP2;
  else if (!strcmp(type_string, "raw"))
    return AW_J2K_FORMAT_RAW;
  else if (!strcmp(type_string, "tif") || !strcmp(type_string, "tiff"))
    return AW_J2K_FORMAT_TIF;
  else if (!strcmp(type_string, "pnm") || !strcmp(type_string, "pbm") ||
           !strcmp(type_string, "pgm") || !strcmp(type_string, "ppm"))
    return AW_J2K_FORMAT_PPM;
  else if (!strcmp(type_string, "dcm") || !strcmp(type_string, "dcm_raw"))
    return AW_J2K_FORMAT_DCM;
  else if (!strcmp(type_string, "dcm_j2k"))
    return AW_J2K_FORMAT_DCMJ2K;
  else if (!strcmp(type_string, "dcm_jpg"))
    return AW_J2K_FORMAT_DCMJPG;
  else if (!strcmp(type_string, "bmp"))
    return AW_J2K_FORMAT_BMP;
  else if (!strcmp(type_string, "tga") || !strcmp(type_string, "targa"))
    return AW_J2K_FORMAT_TGA;
  else if (!strcmp(type_string, "jpg") || !strcmp(type_string, "jpeg"))
    return AW_J2K_FORMAT_JPG;
  else if (!strcmp(type_string, "raw_i"))
    return AW_J2K_FORMAT_RAW_INTERLEAVED;
  else if (!strcmp(type_string, "pgx"))
    return AW_J2K_FORMAT_PGX;
  else
    fprintf(stderr,
            "Warning: Unrecognized type `%s' ignored. Defaulting to J2K\n",
            type_string);
  return AW_J2K_FORMAT_J2K;
}

static unsigned long int
read_jp2_box_type(args_t *args, state_flags *flags, int optional_flag,
                  char *err_message)
{
  char *type_string;
  read_string(&type_string, args, flags, optional_flag, err_message);
  downcase(type_string);
  if (!strcmp(type_string, "jp2i"))
    return AW_JP2_MDTYPE_JP2I;
  else if (!strcmp(type_string, "uuid"))
    return AW_JP2_MDTYPE_UUID;
  else if (!strcmp(type_string, "uuidinfo"))
    return AW_JP2_MDTYPE_UUIDINFO;
  else if (!strcmp(type_string, "url"))
    return AW_JP2_MDTYPE_URL;
  else if (!strcmp(type_string, "xml"))
    return AW_JP2_MDTYPE_XML;
  else
    fprintf(stderr,
            "Warning: Unrecognized type `%s' ignored. Defaulting to xml\n",
            type_string);
  return AW_JP2_MDTYPE_XML;
}

static void
read_tile(int *tile_index, args_t *args, state_flags *flags)
{
  char *tile_string;
  *tile_index = AW_J2K_SELECT_ALL_TILES;

  read_int_or_string(&tile_string, tile_index, args, flags,
                     ARG_MANDATORY, "Tile index not specified");
  if (tile_string) {
    if (tile_string[0] == 'a' || tile_string[0] == 'A')
      *tile_index = AW_J2K_SELECT_ALL_TILES;
    else
      fprintf(flags->diagnostic_stream,
              "Warning: tile index `%s' not recognized\n", tile_string);
  }
}
static void
read_tile_and_channel(int *tile_index, int *channel_index, args_t *args,
                      state_flags *flags)
{
  char *tile_string, *channel_string;
  *tile_index = AW_J2K_SELECT_ALL_TILES;
  *channel_index = AW_J2K_SELECT_ALL_CHANNELS;

  read_int_or_string(&tile_string, tile_index, args, flags,
                     ARG_MANDATORY, "Tile index not specified");
  if (tile_string) {
    if (tile_string[0] == 'a' || tile_string[0] == 'A')
      *tile_index = AW_J2K_SELECT_ALL_TILES;
    else
      fprintf(flags->diagnostic_stream,
              "Warning: tile index `%s' not recognized\n", tile_string);
  }

  read_int_or_string(&channel_string, channel_index, args, flags,
                     ARG_MANDATORY, "Channel index not specified");
  if (channel_string) {
    if (channel_string[0] == 'a' || channel_string[0] == 'A')
      *channel_index = AW_J2K_SELECT_ALL_CHANNELS;
    else
      fprintf(flags->diagnostic_stream,
              "Warning: channel index `%s' not recognized\n", channel_string);
  }
}


/* START_HASH_PARAM */
static const int G[] = {
  0, 0, 0, 0, 0, 0, 0, 0, 0, 144, 23, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 
  0, 0, 0, 0, 0, 0, 53, 78, 259, 296, 0, 0, 312, 0, 0, 0, 0, 0, 0, 60, 0, 
  19, 0, 212, 0, 264, 0, 0, 0, 0, 0, 0, 268, 0, 370, 0, 230, 0, 52, 0, 281, 
  0, 0, 0, 174, 240, 68, 148, 180, 0, 292, 0, 0, 0, 0, 0, 10, 0, 0, 184, 
  115, 0, 247, 38, 37, 0, 140, 379, 0, 0, 344, 101, 0, 0, 152, 64, 0, 0, 
  139, 188, 0, 0, 277, 0, 316, 0, 67, 267, 280, 0, 359, 0, 76, 377, 0, 0, 
  0, 0, 0, 0, 378, 0, 0, 0, 0, 0, 144, 0, 0, 0, 93, 175, 0, 0, 0, 210, 111, 
  0, 55, 0, 0, 0, 170, 175, 213, 88, 260, 0, 293, 0, 0, 0, 25, 0, 0, 252, 
  0, 0, 112, 0, 0, 56, 0, 0, 0, 0, 253, 355, 0, 0, 0, 0, 72, 364, 61, 129, 
  56, 70, 5, 261, 0, 0, 2, 89, 0, 0, 0, 170, 355, 0, 276, 0, 28, 226, 0, 
  0, 0, 371, 0, 0, 160, 0, 186, 64, 0, 99, 175, 228, 0, 292, 178, 90, 20, 
  0, 326, 0, 0, 36, 0, 5, 0, 0, 203, 185, 0, 0, 0, 0, 0, 13, 92, 0, 28, 258, 
  6, 0, 152, 19, 0, 0, 0, 378, 0, 195, 48, 337, 60, 315, 189, 348, 100, 81, 
  0, 99, 0, 134, 0, 42, 0, 373, 173, 0, 0, 22, 65, 27, 55, 78, 0, 174, 271, 
  84, 0, 0, 134, 0, 0, 0, 0, 349, 261, 159, 131, 44, 32, 187, 209, 143, 108, 
  38, 114, 0, 76, 5, 17, 0, 0, 117, 0, 191, 22, 0, 155, 260, 138, 378, 365, 
  126, 0, 70, 66, 4, 69, 187, 0, 138, 129, 31, 169, 251, 152, 0, 309, 377, 
  0, 111, 87, 367, 192, 22, 0, 0, 0, 35, 376, 338, 0, 162, 0, 110, 157, 101, 
  0, 73, 105, 176, 164, 136, 251, 371, 64, 285, 59, 0, 153, 0, 193, 371, 
  0, 12, 0, 145, 0, 367, 353, 0, 0, 144, 116, 0, 0, 45, 0, 29, 0, 49, 34, 
  

};
#define SALT_F1      1190278451
#define SALT_F2       113707396
#define SALT_LENGTH          10
#define HASH_LIMIT          380
/* END_HASH_PARAM */

 

/* salt_hash: compute a hash value for a string, using a salt value to
 * initialize the hash.  Adapted from the Python 1.5.2 distribution.
 * The original code of the function is copyrighted thusly:
 *
 * Copyright 1991-1995 by Stichting Mathematisch Centrum, Amsterdam,
 * The Netherlands.
 */
static long
salt_hash(const char *text, long salt, int salt_length)
{
  register unsigned char *p;
  register int hash;

  p = (unsigned char *) text;

  hash = salt;
  while (*p)
    hash = (1000003 * hash) ^ *p++;
  hash ^= salt_length + (p - (unsigned char *) text);
  if (hash == -1)
    hash = -2;

  hash = hash % HASH_LIMIT;
  if (hash < 0)
    hash += HASH_LIMIT;

  return hash;
}

/* Minimal perfect hashing function for the set of arguments this program
 * takes.  To add new arguments to this program, the HASH_LIMIT, the two salt
 * values (SALT_F1 and SALT_F2), and the lookup table G need to be modified
 * to create a minimal perfect hashing function for the new set.
 */
static int
perfecthash(const char *keyword)
{
  return (G[salt_hash(keyword, SALT_F1, SALT_LENGTH)] +
          G[salt_hash(keyword, SALT_F2, SALT_LENGTH)]) % HASH_LIMIT;
}


static BYTE *
load_raw_data_from_stdio(unsigned long *length)
{
  FILE *fp;
  unsigned long new_len, old_len, read_len;
  BYTE *new_data, *old_data;

  fp = stdin;
#ifdef _WIN32
  (void)_setmode(_fileno(fp), _O_BINARY);
#endif

  new_len = old_len = 0;
  new_data = old_data = NULL;
  do {
    old_len = new_len;
    new_len += READING_BLOCK_SIZE;
    old_data = new_data;
    new_data = (BYTE *)Malloc(sizeof(BYTE) * new_len);
    if (old_data && old_len > 0) {
      memcpy(new_data, old_data, old_len);
      Free(old_data);
      old_data = NULL;
    }

    read_len = fread(new_data + old_len, 1, new_len - old_len, fp);
  } while (read_len == READING_BLOCK_SIZE);
  new_len = new_len - READING_BLOCK_SIZE + read_len;

  *length = new_len;
  return new_data;
}


static BYTE *
load_raw_data(char *filename, unsigned long *length)
{
  FILE *fp;
  BYTE *data;

  if (filename[0] == '-' && filename[1] == '\0')
    return load_raw_data_from_stdio(length);

  fp = fopen(filename, "rb");
  if (!fp) {
    fprintf(stderr, "Warning: unable to open file `%s' for reading\n",
            filename);
    *length = 0;
    return NULL;
  }

  fseek(fp, 0, SEEK_END);
  *length = ftell(fp);
  rewind(fp);

  data = (BYTE *)Malloc(sizeof(BYTE) * (*length));
  fread(data, 1, *length, fp);
  fclose(fp);
  return data;
}

static void
write_raw_data(char *filename, BYTE *data, unsigned long data_length)
{
  FILE *fp;
  if (!strcmp(filename, "-")) {
    fp = stdout;
#ifdef _WIN32
    (void)_setmode(_fileno(fp), _O_BINARY);
#endif
  }
  else {
    fp = fopen(filename, "wb");
    if (!fp) {
      fprintf(stderr, "Error: unable to open %s for writing\n", filename);
      return;
    }
  }
  fwrite(data, 1, data_length, fp);
  if (fp != stdout)
    fclose(fp);
  return;
}
static void
downcase(char *string)
{
  while (string && *string) {
    if (*string >= 'A' && *string <= 'Z')
      *string = *string - 'A' + 'a';
    string++;
  }
}

static void
print_binary(FILE *fp, BYTE *data, int num_data)
{
  int c, d, e, f;
  e = (num_data/16)*16;
  f = 16;
  for (c = 0; c < num_data; c+=16) {
    fprintf(fp,"%08x: ", c);
    if (c == e)
      f = num_data % 16;
    for (d = 0; d < f; d++) {
      fprintf(fp,"%02x", data[c+d]);
      if ((d%2)==1)
        fprintf(fp," ");
    }
    for (; d < 16; d++) {
      fprintf(fp,"  ");
      if ((d%2)==1)
        fprintf(fp," ");
    }
    fprintf(fp,"  ");
    for (d = 0; d < f; d++) {
      if (isprint(data[c+d]))
        fprintf(fp,"%c", data[c+d]);
      else
        fprintf(fp,".");
    }
    fprintf(fp,"\n");
  }
}

static char *
program_basename(char *program_full_path)
{
  char *prog;
  prog = strrchr(program_full_path, '/');
  if (!prog)
    prog = program_full_path;
  else
    prog++;
  return prog;
}

static void
usage(char *program_full_path)
{
  int i, h;
  char ch;
  fprintf(stderr,
          "Usage: %s [ options ]\n"
          "The following options are recognized (aliases of the same option are separated\n"
          "by a comma):",
          program_basename(program_full_path));
  h = -1;
  for (i = 0 ; i < sizeof(options_list)/sizeof(options_list[0]); i++) {
    ch = options_list[i].desc ? '\n' : ',';
    fprintf(stderr, "%c %s", ch, options_list[i].option);
  }
  fprintf(stderr,
          "\n"
          "\n"
          "\n"
          "The program will produce a full description for any option specified\n"
          "after the help option (`--help' or `-h').  For example, running\n"
          "  j2kdriver --help --get-library-version\n"
          "will produce a description of the --get-library-version option\n");
  exit(0);
}

static void
short_help_and_exit(char *program_full_path)
{
  fprintf(stderr, "Try `%s -h' for help.\n",
          program_basename(program_full_path));
  exit(0);
}

#ifdef J2KTESTBED
   DLLEXPORT int CALLING_CONVENTION 
   j2k_main(int argc, char **argv)
#else
   int main(int argc, char **argv)
#endif
{
  aw_j2k_object *j2k_object;
  args_t args;
  state_flags flags;
  int hashval;
  int retval;
  int i;

  if (argc == 1) {
    short_help_and_exit(argv[0]);
  }

  args.argc = argc;
  args.argv = argv;

  flags.help_flag         = 0;          /* do not offer help */
  flags.verbosity_flag    = 1;          /* print out some information */
  flags.benchmark_flag    = 0;          /* no benchmarking */
  flags.diagnostic_stream = stderr;     /* output goes to stderr by default */
  flags.file_read_time    = 0.0F;

  j2k_object = NULL;
  retval = aw_j2k_create(&j2k_object);
  if (retval) {
    fprintf(stderr, "Error: failed to create j2k_object with error %d\n",
            retval);
    exit(1);
  }

  for (args.arg = 1; args.arg < args.argc; args.arg++) {
    hashval = perfecthash(args.argv[args.arg]);
    if (hashval < (sizeof(options_list) / sizeof(aw_option_t)) &&
        !strcmp(options_list[hashval].option, args.argv[args.arg])) {
      if (flags.help_flag == 0)
        options_list[hashval].handler(&args, &flags, j2k_object);
      else {
        for (i = hashval; !options_list[i].desc; i--)
          ;
        fprintf(flags.diagnostic_stream, "%s %s\n",
                options_list[hashval].option,
                options_list[i].desc);
      }
    }
    else
      fprintf(flags.diagnostic_stream,
              "Warning: Unrecognized option `%s' ignored.\n",
              args.argv[args.arg]);
  }

  if (flags.help_flag && args.argc == 2)
    usage(args.argv[0]);

  retval = aw_j2k_destroy(j2k_object);
  j2k_object = NULL;

  if (retval) {
    fprintf(stderr, "Error: failed to destroy j2k_object with error %d\n",
            retval);
    exit(1);
  }

  return 0;
}
