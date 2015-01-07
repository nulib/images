/**********************************************************************
 *
 * Copyright 2000 Aware, Inc.
 *
 * $Workfile: j2k.h $    $Revision: 125 $
 * Last Modified: $Date: 12/16/04 4:31p $ by: $Author: Lev $
 *
 **********************************************************************/
#ifndef _J2K_H_
#define _J2K_H_

volatile const static char id_j2k_h[] = "@(#) $Header: /JPEG2000/platform/win32/aw_j2k_dll/j2k.h 125   12/16/04 4:31p Lev $ Aware Inc.";

/*
 * Aware's JPEG 2000 implementation -- library header
 */
/*
 * For many functions, this can be used to get the default behavior
 */
#define AW_J2K_DEFAULT_ACTION -1


/* endian types */

#define AW_J2K_ENDIAN_LOCAL_MACHINE 0 /* default value */
#define AW_J2K_ENDIAN_SMALL 1
#define AW_J2K_ENDIAN_BIG 2

/* support image types */
#define AW_J2K_FORMAT_UNKNOWN 0x0000
#define AW_J2K_FORMAT_RAW     0x0040
#define AW_J2K_FORMAT_RAW2    0x0041
#define AW_J2K_FORMAT_TIF     0x0042
#define AW_J2K_FORMAT_PPM     0x0043
#define AW_J2K_FORMAT_DCM     0x0044
#define AW_J2K_FORMAT_BMP     0x0045
#define AW_J2K_FORMAT_TGA     0x0046
#define AW_J2K_FORMAT_JPG     0x0047
#define AW_J2K_FORMAT_J2K     0x0048
#define AW_J2K_FORMAT_WSQ     0x0049
#define AW_J2K_FORMAT_JP2     0x004A
#define AW_J2K_FORMAT_RAW_INTERLEAVED 0x004b
#define AW_J2K_FORMAT_RAW_CHANNELS 0x004c
#define AW_J2K_FORMAT_DCMJ2K  0x004d
#define AW_J2K_FORMAT_YUY2    0x004e
#define AW_J2K_FORMAT_PGX     0x004f
#define AW_J2K_FORMAT_VIDEO_RGB24  0x0050
#define AW_J2K_FORMAT_RAW_REGIONS  0x0051
#define AW_J2K_FORMAT_TIFFJ2K      0x0052
#define AW_J2K_FORMAT_VIDEO_RGB24_SINGLEFIELD               0x0053
#define AW_J2K_FORMAT_VIDEO_RGB24_SINGLEFIELD_SECOND_FIELD  0x0054
#define AW_J2K_FORMAT_VIDEO_RGB24_SINGLEFIELD_INTERPOLATED  0x0055
#define AW_J2K_FORMAT_VIDEO_YUY2_SINGLEFIELD                0x0056
#define AW_J2K_FORMAT_VIDEO_YUY2_SINGLEFIELD_INTERPOLATED   0x0057
#define AW_J2K_FORMAT_VIDEO_YUY2_SINGLEFIELD_SECOND_FIELD   0x0058
#define AW_J2K_FORMAT_DCMJPG  0x0059


#define AW_J2K_FORMAT_DIB       0x80


/* Color transformations */
#define AW_J2K_CT_DEFAULT   -1  /* default action                         */
#define AW_J2K_CT_SKIP       0  /* do not perform the color rotation      */
#define AW_J2K_CT_PERFORM    1  /* perform the color rotation             */

#define AW_J2K_MCT_ARRAY      2  /* perform the array based MultiComponent Xform  */
#define AW_J2K_MCT_WAVELET    4  /* perform the Wavelet based MultiComponent Xform */
 
/* color space choices */
#define AW_JP2_CS_DEFAULT   -1
#define AW_JP2_CS_GREYSCALE  17
#define AW_JP2_CS_sRGB       16
#define AW_JP2_CS_sYCC       18

/* any function that takes a channel index as an argument will accept
 * AW_J2K_SELECT_ALL_CHANNELS to indicate that the option applies to all
 * color channels.
 */
#define AW_J2K_SELECT_ALL_CHANNELS -1

/* any function that takes a tile index as an argument will accept
 * AW_J2K_SELECT_ALL_TILES to indicate that the option applies to all
 * tiles.
 */
#define AW_J2K_SELECT_ALL_TILES -1

/* Wavelet Transform types*/
#define AW_J2K_WV_TYPE_DEFAULT -1
#define AW_J2K_WV_TYPE_I97      0 /* Irreversible option */
#define AW_J2K_WV_TYPE_R53      1 /* Reversible option */

/* wavelet transform depth */
#define AW_J2K_WV_DEPTH_DEFAULT -1

/* quantization types */
#define AW_J2K_QUANTIZATION_REVERSIBLE 0 /* used with R53 wavelet */
#define AW_J2K_QUANTIZATION_DERIVED    1 /* used with I97 wavelet */
#define AW_J2K_QUANTIZATION_EXPOUNDED  2 /* used with I97 wavelet */

/* progression order */
#define AW_J2K_PO_DEFAULT                            -1
#define AW_J2K_PO_LAYER_RESOLUTION_COMPONENT_POSITION 0
#define AW_J2K_PO_RESOLUTION_LAYER_COMPONENT_POSITION 1
#define AW_J2K_PO_RESOLUTION_POSITION_COMPONENT_LAYER 2
#define AW_J2K_PO_POSITION_COMPONENT_RESOLUTION_LAYER 3
#define AW_J2K_PO_COMPONENT_POSITION_RESOLUTION_LAYER 4

/****
 *
 * The flags for the various arithmetic coding options are all used
 * with aw_j2k_set_output_j2k_arithmetic_coding_option().
 */
/* Flags to indicate the arithmetic coding options */
#define AW_J2K_ARITH_OPT_CONTEXT_RESET             1
#define AW_J2K_ARITH_OPT_ARITHMETIC_TERMINATION    2
#define AW_J2K_ARITH_OPT_PREDICTABLE_TERMINATION   3
#define AW_J2K_ARITH_OPT_VERTICALLY_CAUSAL_CONTEXT 4

/* arithmetic coding options: values for the context reset option */
#define AW_J2K_ACR_ONLY_AT_CODEBLOCK_END 0
#define AW_J2K_ACR_AT_EACH_CODEPASS_END  1

/* arithmetic coding options: values for the arithmetic termination option */
#define AW_J2K_AT_ONLY_AT_CODEBLOCK_END 0
#define AW_J2K_AT_AT_EACH_CODEPASS_END  1

/* arithmetic coding options: values for the predictable termination option */
#define AW_J2K_PT_NO_PREDICTABLE_TERMINATION  0
#define AW_J2K_PT_USE_PREDICTABLE_TERMINATION 1

/* arithmetic coding options: values for the vertically causal context formation */
#define AW_J2K_VC_NO_VERTICALLY_CAUSAL_CONTEXT  0
#define AW_J2K_VC_USE_VERTICALLY_CAUSAL_CONTEXT 1


/* comment data type (values are per spec) */
#define AW_J2K_CO_BINARY   0 /* binary data  */
#define AW_J2K_CO_ISO_8859 1 /* Latin 1 text */

/* Comment locations */
/* comment location is either -1 for the main header, or the index of a
 * tile
 */
#define AW_J2K_CO_LOCATION_MAIN_HEADER     -1
#define AW_J2K_CO_LOCATION_TILEPART_HEADER  0

/* for backwards compatibility: */
#define A2_COMMENT_LOCATION_MAIN_HEADER     AW_J2K_CO_LOCATION_MAIN_HEADER
#define A2_COMMENT_LOCATION_TILEPART_HEADER AW_J2K_CO_LOCATION_TILEPART_HEADER

/* maximum length of a comment (text or binary) */
#define AW_J2K_CO_MAXLEN 65531

/* shape definition to be added to the ROI */
#define AW_ROISHAPE_RECTANGLE 0
#define AW_ROISHAPE_ELLIPSE   1

/* Rate control options:
 * the "global" layer is the final layer, the one that includes the most
 * information.  Using the -1 index is a convenient way of specifying a
 * target bitrate for the final layer.
 */
#define AW_J2K_GLOBAL_LAYER_INDEX -1
/* The default overall compression ratio is 10:1.  If more than one
 * layer is included in the file, the default compression ratio for the
 * first layer is 50:1.  The layers between the first and last layers will
 * have target bitrates that are linearly spaced.
 */
#define AW_J2K_DEFAULT_FIRST_LAYER_RATIO 50.0F
#define AW_J2K_DEFAULT_LAST_LAYER_RATIO  10.0F

/* values for the error handling mode option, set by
 * aw_j2k_set_input_j2k_error_handling()
 */
#define AW_J2K_ERROR_RESILIENT_MODE 0
#define AW_J2K_ERROR_STRICT_MODE    1

/* decoder status values, as returned by
 * aw_j2k_get_input_j2k_decoder_status()
 */
#define AW_J2K_DECODER_FULL_DECODE                 0
#define AW_J2K_DECODER_PARTIAL_DECODE_TRUNCATION   1
#define AW_J2K_DECODER_PARTIAL_DECODE_CORRUPTION   2

/* aw_j2k_set_output_j2k_coding_predictor_offset() takes an offset or this
 * special value which indicates to ignore the predictor and encode all data.
 * Once coded, the data may still be lossily truncated to achieve the desired
 * compression ratio.
 */
#define AW_J2K_PREDICTOR_CODE_ALL_DATA -1

/* aw_j2k_get_library_version() takes a pointer to a pre-allocated
 * character array.  This array must be at least this many bytes long:
 */
#define AW_J2K_LIBRARY_VERSION_STRING_MINIMUM_LENGTH 80

/* internal options:
 * these options change the low-level internal implementation details of
 * the library.  These flags are used with aw_j2k_set_internal_option().
 */
/* internal option names */
#define AW_J2K_INTERNAL_ARITHMETIC_OPTION   1

/* internal options: values for the arithmetic option */
#define AW_J2K_INTERNAL_USE_FLOATING_POINT 0
#define AW_J2K_INTERNAL_USE_FIXED_POINT    1
#define AW_J2K_INTERNAL_USE_DEFAULT_ARITHEMETIC -1

/* JP2 metadata box types.  These are used to select the type of boxes for
 * metadata that are allowed in the JP2 format.
 */
#define AW_JP2_MDTYPE_JP2I      1
#define AW_JP2_MDTYPE_UUID      2
#define AW_JP2_MDTYPE_UUIDINFO  3
#define AW_JP2_MDTYPE_URL       4
#define AW_JP2_MDTYPE_XML       5

/* The length of the UUID is 16 bytes.  The format of the UUID is
 * specificed by ISO/IEC 11578:1996.
 */
#define AW_JP2_UUID_LENGTH 16

/* the object that all the functions accept is opaque */
typedef void aw_j2k_object;

#if defined(_WIN32)
# include <windows.h>
# if !defined(J2K_STATIC_LIBRARY)
#  ifndef DLLIMPORT
#   define DLLIMPORT __declspec(dllimport)
#  endif /* DLLIMPORT */
#  define CALLING_CONVENTION WINAPI
# else /* J2K_STATIC_LIBRARY */
#  ifdef DLLIMPORT
#   undef DLLIMPORT
#  endif /* DLLIMPORT */
#  define DLLIMPORT
#  define CALLING_CONVENTION
# endif /* !J2K_STATIC_LIBRARY */
#else /* !_WIN32 */
# ifdef DLLIMPORT
#  undef DLLIMPORT
# endif /* DLLIMPORT */
# define DLLIMPORT
# define CALLING_CONVENTION
#endif /* !_WIN32 */

#include "aw_j2k_dtypes.h"


#ifdef __cplusplus
extern "C" {
#endif


/* The API functions
 *
 * The functions are listed here in the same order as in the SDK
 * manual.  Section numbers from the manual are given for each
 * function to facilitate cross-referencing.
 */

/*
 * Chapter 4. Global Functions
 *
 */

/* aw_j2k_create()
 * aw_j2k_create_with_memory_manager()
 * See Section 4.1.1 in the manual
 *
 * These functions create the library object, of type aw_j2k_object,
 * which is used by most of the other functions.  Aw_j2k_create()
 * simply creates the object.  Aw_j2k_create_with_memory_manager()
 * creates an object that uses the given callback functions for memory
 * allocation and deallocation.  The user_data argument is passed
 * unchanged to the alloc_function and free_function callbacks as
 * their first argument.  The second argument to the alloc_function
 * callback is the size of the memory requested.  The second argument
 * to the free_function callback is the pointer that will be freed.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_create(aw_j2k_object **o);
DLLIMPORT int CALLING_CONVENTION
aw_j2k_create_with_memory_manager(aw_j2k_object **j2k_object, void *user_data,
                                  void *(*alloc_function)(void *, size_t),
                                  void (*free_function)(void *, void *));

/* aw_j2k_destroy()
 * Section 4.1.2
 *
 * Deallocates the given library object and all memory associated with
 * it.  The library object should not be used after a call to this
 * function.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_destroy(aw_j2k_object *o);

/* aw_j2k_free()
 * Section 4.2.1
 *
 * Deallocates the pointer given as argument.  This pointer should
 * have come from a call to one of the following functions:
 * - aw_j2k_get_input_j2k_comments()
 * - aw_j2k_get_output_image()
 * - aw_j2k_get_output_image_type()
 * - aw_j2k_get_output_image_raw()
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_free(aw_j2k_object *o, void *ptr);

/* aw_j2k_get_library_version()
 * Section 4.3.1
 *
 * Returns the current library version.  As this function does not
 * take the library object as an argument, it cannot allocate memory
 * for the version_string buffer.  Therefore, the version_string
 * buffer must be allocated by the caller; its length should be at
 * least AW_J2K_LIBRARY_VERSION_STRING_MINIMUM_LENGTH bytes.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_library_version(unsigned long *version,
                           char *version_string,
                           unsigned long version_string_buffer_length);


/* aw_j2k_reset_all_options()
 * Section 4.3.2
 *
 * Resets the J2K library object to its initial state.  Calling this
 * function is equivalent to calling aw_j2k_destroy() on the object
 * and then obtaining a new object using aw_j2k_create().
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_reset_all_options(aw_j2k_object *j2k_object);

/* aw_j2k_set_internal_option()
 * Section 4.3.3
 *
 * This function allows the user to choose fixed or floating point arithmetic
 * operations.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_internal_option(aw_j2k_object *j2k_object, int option, int value);



/*
 * Chapter 5. Input Image Functions
 *
 */

/* aw_j2k_set_input_image()
 * Section 5.1.1
 *
 * Reads an input image from the provided buffer.  The type of the
 * image will be determined automatically.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_input_image(aw_j2k_object *j2k_object, unsigned char *image_buffer,
                       unsigned long int image_buffer_length);

/* aw_j2k_set_input_image_type()
 * Section 5.1.2
 *
 * Reads an input image from the provided buffer.  The type of the
 * image is provided is an argument to this function.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_input_image_type(aw_j2k_object *j2k_object, int image_type,
                            unsigned char *image_buffer,
                            unsigned long int image_buffer_length);

/* aw_j2k_set_input_image_raw()
 * Section 5.1.3
 *
 * Reads a raw image from the provided buffer.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_input_image_raw(aw_j2k_object *j2k_object,
                           unsigned char *image_buffer,
                           unsigned long int rows,
                           unsigned long int cols,
                           unsigned long int nChannels,
                           unsigned long int bpp,
                           BOOL bInterleaved);
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_input_image_raw_ex(aw_j2k_object *j2k_object, 
                              unsigned char *image_buffer,
                              unsigned long int rows,
                              unsigned long int cols,
                              unsigned long int nChannels,
                              long int bpp_allocated,
                              long int bpp_stored,
                              BOOL bInterleaved);

/* aw_j2k_set_input_image_raw_channel()
 * Section 5.1.4
 *
 * Reads a single channel's data (in raw format) from the provided
 * buffer.  The dimensions of the image can be provided via a call to
 * aw_j2k_set_input_raw_information().
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_input_image_raw_channel(aw_j2k_object *j2k_object, 
                           unsigned long int channel,
                           unsigned char *channel_buffer,
                           unsigned long int buffer_length);

/* aw_j2k_set_input_image_file()
 * Section 5.1.5
 *
 * Reads an image from a file.  The type of the image will be
 * determined automatically.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_input_image_file(aw_j2k_object *j2k_object, char *filename);

/* aw_j2k_set_input_image_file_type()
 * Section 5.1.6
 *
 * Reads an image from a file.  The type of the image is take from the
 * function argument.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_input_image_file_type(aw_j2k_object *j2k_object, char *filename,
                                 int type);

/* aw_j2k_set_input_image_raw()
 * Section 5.1.7
 *
 * Reads a raw image from a file.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_input_image_file_raw(aw_j2k_object *j2k_object, char *filename, 
                                unsigned long int rows,
                                unsigned long int cols,
                                unsigned long int nChannels, 
                                unsigned long int bpp,
                                BOOL bInterleaved);

/* aw_j2k_set_input_raw_information()
 * Section 5.1.8
 *
 * Use this function to provide the library with the dimensions of an
 * image, without providing the image itself.  The image data can be
 * provided later using aw_j2k_set_input_image_raw_channel().
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_input_raw_information(aw_j2k_object *j2k_object, 
                                 unsigned long int rows,
                                 unsigned long int cols,
                                 unsigned long int nChannels,
                                 long int bpp,
                                 BOOL bInterleaved);
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_input_raw_information_ex(
  aw_j2k_object *j2k_object, unsigned long int rows, unsigned long int cols,
  unsigned long int nChannels, long int bpp_allocated, long int bpp_stored,
  BOOL bInterleaved
  );

/* aw_j2k_set_input_raw_channel_bpp()
 * Section 5.1.9
 *
 * Specifies to the library the bitdepth of the data in each channel.
 * If the data is signed, the bitdepth should be negative; it should
 * be positive for unsigned data.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_input_raw_channel_bpp(aw_j2k_object *j2k_object, 
                                 unsigned long int channel,
                                 long int bpp);

/* aw_j2k_set_input_raw_endianness()
 * Section 5.1.10
 *
 * Specifies the endianness of multi-byte-per-channel raw images.
 * This function must be called before aw_j2k_set_input_image_raw()
 * and aw_j2k_set_input_image_file_raw().
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_input_raw_endianness(aw_j2k_object *j2k_object, 
                                unsigned long int fEndianness);

/* aw_j2k_set_input_raw_channel_subsampling()
 * Section 5.1.11
 *
 * Specifies the subsampling of a specific channel relative to the
 * full image dimensions.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_input_raw_channel_subsampling(aw_j2k_object *j2k_object, 
                           unsigned long int channel,
                           unsigned long int Y_subsampling,
                           unsigned long int X_subsampling);


/* aw_j2k_get_input_image_info()
 * Section 5.2.1
 *
 * Returns the dimensions, total bitdepth, and number of channels in
 * the image.  The bitdepth returned here is the sum of the bitdepths
 * of all the channels, and does not indicate whether the data is
 * signed or not.  Use aw_j2k_get_input_channel_bpp() to determine the
 * bitdepth of each channel, as well as whether the data in the
 * channel is signed.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_input_image_info(aw_j2k_object *j2k_object, 
                            unsigned long int *cols, 
                            unsigned long int *rows,
                            unsigned long int *bpp, 
                            unsigned long int *nChannels);


/* aw_j2k_get_input_channel_bpp()
 * Section 5.2.2
 *
 * Returns the bitdepth of a channel in the image, as well as whether
 * the data in the channel is signed or not.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_input_channel_bpp(aw_j2k_object *j2k_object,
                             unsigned long int channel, long int *bpp);

/* aw_j2k_get_input_j2k_channel_bpp()
 * Section 5.2.3
 *
 * This function is deprecated.  Use aw_j2k_get_input_channel_bpp()
 * instead.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_input_j2k_channel_bpp(aw_j2k_object *j2k_object, 
                                 unsigned long int channel, long int *bpp);

/* aw_j2k_get_input_j2k_channel_subsampling()
 * Section 5.2.4
 *
 * Returns the subsampling of a channel in a JPEG 2000 image relative
 * to the full image dimensions.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_input_j2k_channel_subsampling(aw_j2k_object *j2k_object, 
                                         unsigned long int channel,
                                         unsigned long int *Y_subsampling,
                                         unsigned long int *X_subsampling);


/* aw_j2k_get_input_j2k_num_comments()
 * Section 5.2.5
 *
 * Returns the number of comments that are embedded in a JPEG 2000
 * image.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_input_j2k_num_comments(aw_j2k_object *j2k_object, int *n_comments);


/* aw_j2k_get_input_j2k_comments()
 * Section 5.2.6
 *
 * Returns a comment from a JPEG 2000 image.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_input_j2k_comments(aw_j2k_object *j2k_object, 
                              int comment_index, 
                              unsigned char **comment_data,
                              unsigned long int *length,
                              unsigned long int *type,
                              unsigned long int *location);


/* aw_j2k_get_input_j2k_progression_info()
 * Section 5.2.7
 *
 * Returns the progression order, number of wavelet transform levels,
 * number of quality layers, and number of color channels in a JPEG
 * 2000 image.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_input_j2k_progression_info(aw_j2k_object *j2k_object, 
                                      unsigned long int *order, 
                                      unsigned long int *prog_levels,
                                      unsigned long int *transform_levels,
                                      unsigned long int *layers,
                                      unsigned long int *channels,
                                      unsigned long int *precincts,
                                      unsigned long int *prog_available);

/* aw_j2k_get_input_j2k_progression_byte_count()
 * Section 5.2.8
 *
 * Returns the number of bytes needed to decode a given progression
 * level.  The type of progression level is determined by the
 * progression order of the JPEG 2000 image.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_input_j2k_progression_byte_count(aw_j2k_object *j2k_object, 
                                            int index, 
                                            unsigned long int *prog_offset);

/* aw_j2k_get_input_j2k_tile_info()
 * Section 5.2.9
 *
 * Returns the tile size and image and tile offsets in a JPEG 2000
 * image.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_input_j2k_tile_info(aw_j2k_object *j2k_object,
                               unsigned long int *tile_offset_x,
                               unsigned long int *tile_offset_y,
                               unsigned long int *tile_cols,
                               unsigned long int *tile_rows,
                               unsigned long int *image_offset_x,
                               unsigned long int *image_offset_y);

/* aw_j2k_get_input_j2k_selected_tile_geometry()
 * Section 5.2.10
 *
 * Returns the size of a tile and its offset from the image origin.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_input_j2k_selected_tile_geometry(aw_j2k_object *j2k_object,
                                            unsigned long int tileindex,
                                            unsigned long int *tile_cols,
                                            unsigned long int *tile_rows,
                                            unsigned long int *tile_offset_x,
                                            unsigned long int *tile_offset_y);

/* aw_j2k_get_input_j2k_component_registration()
 * Section 5.2.11
 *
 * Returns a color channel's registration offset from a JPEG 2000
 * image.  The registration offsets indicate how much to offset each
 * color channel relative to the image grid for display.  The offsets
 * are given in units of 1/65536 of a pixel.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_input_j2k_component_registration(aw_j2k_object *j2k_object,
                                            WORD component,
                                            WORD *Xreg, WORD *Yreg);

/* aw_j2k_get_input_j2k_bytes_read()
 * Section 5.2.12
 *
 * Returns the number of bytes actually used from a JPEG 2000 image.
 * If the full image was decompressed, this will return the size of
 * the original image.  If a partial decompression was performed
 * (e.g. only a single tile or a reduced resolution was decoded) then
 * this number may be smaller than the full image.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_input_j2k_bytes_read(aw_j2k_object *j2k_object, DWORD *bytes);

/* aw_j2k_get_input_j2k_decoder_status()
 * Section 5.2.13
 *
 * When called after one of the aw_j2k_get_output_image family of
 * functions, indicates whether the JPEG 2000 image was fully decoded
 * or whether the decoder encoutered a corrupted or truncated
 * codestream.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_input_j2k_decoder_status(aw_j2k_object *j2k_object,
                                    unsigned long int *status);

/* aw_j2k_set_input_j2k_rvalue()
 * Section 5.3.1
 *
 * This function is deprecated.  The dequantization offset parameter
 * is fixed to 0.5 and cannot be changed via this API call.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_input_j2k_rvalue(aw_j2k_object *j2k_object, float rvalue);


/* aw_j2k_set_input_j2k_progression_level()
 * Section 5.3.2
 *
 * Sets the number of progression levels that will be decoded form the
 * JPEG 2000 image.  The progression type is determined by the
 * progression order of the image.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_input_j2k_progression_level(aw_j2k_object *j2k_object,
                                       int progression_level);


/* aw_j2k_set_input_j2k_resolution_level()
 * Section 5.3.3
 *
 * Sets the number of resolution levels to decode from the JPEG 2000
 * image.  The full number of resolution levels is always one more
 * than the number of wavelet transform levels in the JPEG 2000 image.
 * The full_xform_flag indicates whether the full wavelet transform
 * should be performed (resulting in a full size image of lower
 * quality) or not (resulting in a reduced size image).
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_input_j2k_resolution_level(aw_j2k_object *j2k_object,
                                      int resolution_level,
                                      int full_xform_flag);


/* aw_j2k_set_input_j2k_quality_level()
 * Section 5.3.4
 *
 * Sets the number of quality layers to decode from a JPEG 2000 image.
 * Setting this value to 1 decodes the quality layers; setting it to 2
 * drops one layer.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_input_j2k_quality_level(aw_j2k_object *j2k_object,
                                   int quality_level);


/* aw_j2k_set_input_j2k_color_level()
 * Section 5.3.5
 *
 * Sets the number of color channels that to decode from a JPEG 2000
 * image.  Setting this value to 1 decodes all the color channels.
 * Setting it to 2 drops the last color channel.  The color_xform_flag
 * indicates whether the color transform will be performed or not.
 * The flag AW_J2K_CT_PERFORM indicates that the color transform
 * should be performed, if possible.  AW_J2K_CT_SKIP indicates the
 * color transform should not be performed.  AW_J2K_CT_DEFAULT
 * indicates that the color transform should be performed if so
 * indicated in the JPEG 2000 image.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_input_j2k_color_level(aw_j2k_object *j2k_object,
                                 int color_channels,
                                 int color_xform_flag);


/* aw_j2k_set_input_j2k_region_level()
 * Section 5.3.6
 *
 * Defines a rectangular subregion to be decoded from a JPEG 2000
 * image.  The library will decode only those precincts that intersect
 * with the defined region.  Precincts are set by calling
 * aw_j2k_set_output_j2k_channel_precinct_size (described in Section
 * 6.3.13, below).
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_input_j2k_region_level(aw_j2k_object *j2k_object,
                                  unsigned long int x0, 
                                  unsigned long int y0, 
                                  unsigned long int x1,
                                  unsigned long int y1);


/* aw_j2k_set_input_j2k_selected_channel()
 * Section 5.3.7
 *
 * Selects a specific single color channel to decode from a JPEG 2000
 * image.  The color channels are indexed starting at 0.  Any color
 * rotations specified in the JPEG 2000 image will not be performed on
 * this channel.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_input_j2k_selected_channel(aw_j2k_object *j2k_object, 
                                      unsigned long int channel);


/* aw_j2k_set_input_j2k_selected_tile()
 * Section 5.3.8
 *
 * Selects a specific single tile to decode from a JPEG 2000 image.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_input_j2k_selected_tile(aw_j2k_object *j2k_object, int tile);


/* aw_j2k_set_input_j2k_error_handling()
 * Section 5.3.9
 *
 * Selects whether the JPEG 2000 decoder works in the resilient mode,
 * in which it tries to recover from errors such as bitstream
 * corruption and truncation, or in strict mode, in which it signals
 * the first error it encounters.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_input_j2k_error_handling(aw_j2k_object *j2k_object, int mode);

/* aw_j2k_set_input_dcm_frame_index()
 * Section 5.3.xx
 * Selects the desired frame index in a multiframe DICOM file.
 * All compression operations will only be performed on the target frame
 * The default value is 0
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_input_dcm_frame_index(aw_j2k_object *j2k_object, int frame_index);

/* aw_j2k_input_reset_options()
 * Section 5.3.10
 *
 * Resets all the input options set by the above mentioned API
 * functions to their default values.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_input_reset_options(aw_j2k_object *j2k_object);


/* aw_j2k_get_input_jp2_num_metadata_boxes()
 * Section 5.4.1
 *
 * Returns the number of metadata boxes of the given type from a JP2 image.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_input_jp2_num_metadata_boxes(aw_j2k_object *j2k_object,
                                        unsigned long int type,
                                        unsigned long int *num_metadata_boxes);


/* aw_j2k_get_input_jp2_metadata_box()
 * Section 5.4.2
 *
 * Returns the contents of the selected metadata box of the given type
 * from a JP2 image.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_input_jp2_metadata_box(aw_j2k_object *j2k_object,
                                  unsigned long int type,
                                  unsigned long int index, 
                                  unsigned char **metadata,
                                  unsigned long int *metadata_length,
                                  unsigned char **uuid,
                                  unsigned long int *uuid_length);


/* aw_j2k_get_input_jp2_UUIDInfo_box()
 * Section 5.4.3
 *
 * Returns the contents of the selected UUID information box from a
 * JP2 image.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_input_jp2_UUIDInfo_box(aw_j2k_object *j2k_object,
                                  unsigned long int index,
                                  unsigned char **uuid_data,
                                  unsigned long int *num_uuid,
                                  char **url, unsigned long int *url_length);


/* aw_j2k_get_input_jp2_enum_colorspace()
 * Section 5.4.4
 *
 * Returns the enumerated color space of a JP2 image, if one is present.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_input_jp2_enum_colorspace(aw_j2k_object *j2k_object,
                                     long int *colorspace);


/* aw_j2k_get_input_jp2_restricted_ICCProfile()
 * Section 5.4.5
 *
 * Returns the color space of a JP2 image as specified by a restricted
 * ICC Profile, if one is present in the image.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_input_jp2_restricted_ICCProfile(aw_j2k_object *j2k_object,
                                           unsigned char **icc_data,
                                           unsigned long int *icc_data_length);


/*
 * Chapter 6. Output Image Functions
 *
 */

/* aw_j2k_set_output_type()
 * Section 6.1.1
 *
 * Selects the type for the output image.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_type(aw_j2k_object *j2k_object, int image_type);


/* aw_j2k_get_output_image()
 * Section 6.1.2
 *
 * Creates a new image from the input image and returns it in the
 * image_buffer.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_output_image(aw_j2k_object *j2k_object,
                        unsigned char **image_buffer,
                        unsigned long int *image_buffer_length);


/* aw_j2k_get_output_image_type()
 * Section 6.1.3
 *
 * Creates a new image of the given type from the input image and
 * returns it in the image_buffer.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_output_image_type(aw_j2k_object *j2k_object, int image_type, 
                             unsigned char **image_buffer,
                             unsigned long int *image_buffer_length);


/* aw_j2k_get_output_image_raw()
 * Section 6.1.4
 *
 * Creates a new raw image from the input image and returns it in the
 * image_buffer, along with the size of the image.  The bInterleaved
 * flag indicates whether the data the color channels should be
 * interleaved or not.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_output_image_raw(aw_j2k_object *j2k_object,
                            unsigned char **image_buffer,
                            unsigned long int *image_buffer_length,
                            unsigned long int *rows, 
                            unsigned long int *cols,
                            unsigned long int *nChannels,
                            unsigned long int *bpp,
                            BOOL bInterleaved);
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_output_image_raw_ex(aw_j2k_object *j2k_object,
                               unsigned char **image_buffer,
                               unsigned long int *image_buffer_length,
                               unsigned long int *rows,
                               unsigned long int *cols,
                               unsigned long int *nChannels,
                               long int *bpp_stored,
                               long int bpp_allocated,
                               BOOL bInterleaved);



/* aw_j2k_get_output_image_file()
 * Section 6.1.5
 *
 * Creates an image in the file named by filename.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_output_image_file(aw_j2k_object *j2k_object, char *filename);


/* aw_j2k_get_output_image_file_type()
 * Section 6.1.6
 *
 * Creates an image of the given type in the file named by filename.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_output_image_file_type(aw_j2k_object *j2k_object, char *filename,
                                  int type);

/* aw_j2k_get_output_image_file_raw()
 * Section 6.1.7
 *
 * Creates a raw image in the file named by filename, and returns the
 * size of the image.  The bInterleaved flag indicates whether the
 * data the color channels should be interleaved or not.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_output_image_file_raw(aw_j2k_object *j2k_object, 
                                 char *filename,
                                 unsigned long int *rows, 
                                 unsigned long int *cols,
                                 unsigned long int *nChannels,
                                 unsigned long int *bpp,
                                 BOOL bInterleaved);


/* aw_j2k_set_output_j2k_bitrate()
 * Section 6.2.1
 *
 * Sets the output image bitrate, in bits per pixel.  A bitrate of 0
 * indicates that all the quantized data should be included in the
 * image.  This creates lossless images if the R53 wavelet is chosen
 * using aw_j2k_set_output_j2k_xform().
  */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_bitrate(aw_j2k_object *j2k_object, float bpp);


/* aw_j2k_set_output_j2k_ratio()
 * Section 6.2.2
 *
 * Sets the compression ratio for the output image.  A ratio of 0
 * indicates that all the quantized data should be included in the
 * image.  This creates lossless images if the R53 wavelet is chosen
 * using aw_j2k_set_output_j2k_xform().
  */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_ratio(aw_j2k_object *j2k_object, float ratio);


/* aw_j2k_set_output_j2k_filesize()
 * Section 6.2.3
 *
 * Sets the output image size, in bytes.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_filesize(aw_j2k_object *j2k_object,
                               unsigned int cbBytes);


/* aw_j2k_set_output_j2k_psnr()
 * Section 6.2.4
 *
 * Sets the output image pSNR value, in dB.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_psnr(aw_j2k_object *j2k_object, float psnr);


/* aw_j2k_set_output_j2k_tolerance()
 * Section 6.2.5
 *
 * This function is deprecated.  Setting the tolerance of the rate
 * control process is not enabled at this time.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_tolerance(aw_j2k_object *j2k_object, float tolerance);


/* aw_j2k_set_output_j2k_color_xform()
 * Section 6.2.6
 *
 * Sets whether the color transform will be performed.  The color
 * transform can only be performed only if there are 3 or more
 * channels and the first three channels have the same bitdepth, data
 * type (signed or unsigned), and subsampling.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_color_xform(aw_j2k_object *j2k_object, int color_xform);
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_color_xform_ex(aw_j2k_object *j2k_object, int tile_index,
                                     int color_xform);


/* aw_j2k_set_output_j2k_progression_order()
 * Section 6.2.7
 *
 * Sets the progression order of the compressed image file.  The
 * progression order is one of the following:
 *
 * - AW_J2K_PO_LAYER_RESOLUTION_COMPONENT_POSITION
 * - AW_J2K_PO_RESOLUTION_LAYER_COMPONENT_POSITION
 * - AW_J2K_PO_RESOLUTION_POSITION_COMPONENT_LAYER
 * - AW_J2K_PO_POSITION_COMPONENT_RESOLUTION_LAYER
 * - AW_J2K_PO_COMPONENT_POSITION_RESOLUTION_LAYER
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_progression_order(aw_j2k_object *j2k_object, int order);


/* aw_j2k_set_output_j2k_tile_size()
 * Section 6.2.8
 *
 * Sets the tile size for JPEG 2000 output.  All tiles, except those
 * at the edges of the image, will be of the same size.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_tile_size(aw_j2k_object *j2k_object,
                                 unsigned long int width, 
                                 unsigned long int height);


/* aw_j2k_set_output_j2k_add_comment()
 * Section 6.2.9
 *
 * Adds a comment to the JPEG 2000 image.  The comment may be in the
 * main header (set the location to AW_J2K_CO_LOCATION_MAIN_HEADER) or
 * in a tile-part header (set location to the index of the tile).  The
 * comment may be in an unspecified binary format (set type to
 * AW_J2K_CO_BINARY) or it may be in Latin-1 (ISO 8859-15:1999) text
 * (set type to AW_J2K_CO_ISO_8859).
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_add_comment(aw_j2k_object *j2k_object, char *data,
                                  int type, int length, int location);


/* aw_j2k_set_output_j2k_image_offset()
 * Section 6.3.1
 *
 * Offsets the image boundary from the top-left corner of the image
 * grid, thereby cropping the image.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_image_offset(aw_j2k_object *j2k_object,
                                   unsigned long int x, unsigned long int y);


/* aw_j2k_set_output_j2k_tile_offset()
 * Section 6.3.2
 *
 * Offsets the tile boundary from the top-left corner of the image
 * grid.  The tile offset must be within the rectangle defined by the
 * origin and the image offset.
 */


DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_tile_offset(aw_j2k_object *j2k_object,
                                  unsigned long int x, 
                                  unsigned long int y);


/* aw_j2k_set_output_j2k_error_resilience()
 * Section 6.3.3
 *
 * Enables and disables the use of the error resilience features of
 * JPEG 2000.  Allows Start of Packet (SOP) and End of Packet Header
 * (EPH) markers to be added to the codestream, as well as
 * Segmentation Symbols to be embedded in it.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_error_resilience(aw_j2k_object *j2k_object, int SOP,
                                       int EPH, int SEG_SYMB);
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_error_resilience_ex(aw_j2k_object *j2k_object,
                                          int tile_index, int channel_index,
                                          int SOP, int EPH, int SEG_SYMB);


/* aw_j2k_set_output_j2k_xform()
 * Section 6.3.4
 *
 * Selects the type of wavelet and the transform depth to use on
 * compression.  The wavelet choices are:
 * - AW_J2K_WV_TYPE_I97
 * - AW_J2K_WV_TYPE_R53
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_xform(aw_j2k_object *j2k_object, int type, int levels);


DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_xform_ex(aw_j2k_object *j2k_object, int tile_index,
                               int channel_index, int type, int levels);


/* aw_j2k_set_output_j2k_wavelet_mct()
 * Part 2 Manual Supplement
 *
 * Sets the wavelet multi-component transform, the number of transform levels 
 * and the number of components in each component collection. The wavelet choices are:
 * - AW_J2K_WV_TYPE_I97
 * - AW_J2K_WV_TYPE_R53
 */

DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_wavelet_mct(aw_j2k_object *j2k_object, int type, int levels, int collection_size);



/* aw_j2k_set_output_j2k_layers()
 * Section 6.3.5
 *
 * Sets the number of quality layers to be embedded in a JPEG 2000
 * image.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_layers(aw_j2k_object *j2k_object, int layers);


/* aw_j2k_set_output_j2k_layer_bitrate()
 * Section 6.3.6
 *
 * Sets the target bitrate, in bits per pixel, for the selected
 * quality layer.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_layer_bitrate(aw_j2k_object *j2k_object, int layer_index,
                                    float bpp);
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_layer_bitrate_ex(aw_j2k_object *j2k_object,
                                       int tile_index, int layer_index,
                                       float bpp);

/* aw_j2k_set_output_j2k_layer_ratio()
 * Section 6.3.7
 *
 * Sets the target compression ratio for the selected quality layer.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_layer_ratio(aw_j2k_object *j2k_object, int layer_index,
                                  float ratio);
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_layer_ratio_ex(aw_j2k_object *j2k_object,
                                     int tile_index, int layer_index,
                                     float ratio);

/* aw_j2k_set_output_j2k_layer_size()
 * Section 6.3.8
 *
 * Sets the target size, in bytes, of the selected quality layer.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_layer_size(aw_j2k_object *j2k_object,
                                 int layer_index, unsigned int cbBytes);
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_layer_size_ex(aw_j2k_object *j2k_object, int tile_index,
                                    int layer_index, unsigned int cbBytes);



/* aw_j2k_set_output_j2k_layer_psnr()
 * Section 6.3.9
 *
 * Sets the pSNR value, in dB, of the selected quality layer .
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_layer_psnr(aw_j2k_object *j2k_object, 
                                 int layer_index, float psnr);
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_layer_psnr_ex(aw_j2k_object *j2k_object, int tile_index,
                                    int layer_index, float psnr);


/* aw_j2k_set_output_j2k_channel_quantization()
 * Section 6.3.10
 *
 * Sets the quantization type for a JPEG 2000 image.  The supported
 * types are:
 * - AW_J2K_QUANTIZATION_REVERSIBLE
 * - AW_J2K_QUANTIZATION_DERIVED
 * - AW_J2K_QUANTIZATION_EXPOUNDED
 *
 * The ability to change quantization on a per channel basis is not
 * yet available; set channel_index to AW_J2K_SELECT_ALL_CHANNELS to
 * set the quantization for all channels at once.
 */



DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_channel_quantization(aw_j2k_object *j2k_object,
                                           int channel_index,
                                           int quantization_option);

DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_quantization_ex(aw_j2k_object *j2k_object,
                                      int tile_index,
                                      int channel_index,
                                      int quantization_option);


/* aw_j2k_set_output_j2k_quant_options()
 * Section 6.3.11
 *
 * aw_j2k_set_output_j2k_quant_options() is deprecated; use
 * aw_j2k_set_output_j2k_channel_quantization() instead.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_quant_options(aw_j2k_object *j2k_object,
                                    int quant_option);


/* aw_j2k_set_output_j2k_quantization_binwidth_scale()
 * Section 6.3.12
 *
 * Scales the default binwidths by the factor binwidth_scale.  This
 * scale is only applied to the derived and expounded quantization
 * options.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_quantization_binwidth_scale(aw_j2k_object *j2k_object,
                                                  float binwidth_scale);
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_quantization_binwidth_scale_ex(aw_j2k_object *j2k_object,
                                                     int tile_index,
                                                     int channel_index,
                                                     float binwidth_scale);


/* aw_j2k_set_output_j2k_guard_bits()
 * Section 6.3.13
 *
 * Sets the number of guard bits, which are used to ensure the the
 * block encoder does not overflow.  The legal values for this number
 * range from 0 to 7.  The default is 2.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_guard_bits(aw_j2k_object *j2k_object, int guard_bits);
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_guard_bits_ex(aw_j2k_object *j2k_object, int tile_index,
                                    int channel_index, int guard_bits);


/* aw_j2k_set_output_j2k_channel_precinct_size()
 * Section 6.3.14
 *
 * Sets the dimensions of the precincts in a JPEG 2000 image.  The
 * wavelet transform converts the pixels of the image into
 * coefficients, which are divided into different frequency subbands.
 * Each subband is then quantized and divided into precincts. Dividing
 * the subbands into precincts allows subregions of the subbands to be
 * decoded independently of the rest of the subband.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_channel_precinct_size(aw_j2k_object *j2k_object,
                                            int channel_index,
                                            int resolution_level,
                                            int precinct_height,
                                            int precinct_width);
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_precinct_size_ex(aw_j2k_object *j2k_object,
                                       int tile_index, int channel_index,
                                       int resolution_level,
                                       int precinct_height,
                                       int precinct_width);

/* aw_j2k_set_output_j2k_codeblock_size()
 * Section 6.3.15
 *
 * Sets the dimensions of the codeblocks.  The values for height and
 * width are the base-2 logarithm of the actual codeblock sizes.  Each
 * of height and width may range from 2 to 10, and their sum must be
 * less than or equal to 12.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_codeblock_size(aw_j2k_object *j2k_object, int height,
                                     int width);
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_codeblock_size_ex(aw_j2k_object *j2k_object,
                                        int tile_index, int channel_index,
                                        int height, int width);


/* aw_j2k_set_output_j2k_arithmetic_coding_option()
 * Section 6.3.16
 *
 * Sets any of the following arithmetic coding options:
 *
 * - AW_J2K_ARITH_OPT_CONTEXT_RESET - sets how frequently the
 *   arithmetic coder is reset.  The allowed values are:
 *   - AW_J2K_ACR_ONLY_AT_CODEBLOCK_END 
 *   - AW_J2K_ACR_AT_EACH_CODEPASS_END
 *
 * - AW_J2K_ARITH_OPT_ARITHMETIC_TERMINATION - sets how frequently the
 *   arithmetic coder is terminated.  The allowed values are:
 *   - AW_J2K_AT_ONLY_AT_CODEBLOCK_END
 *   - AW_J2K_AT_AT_EACH_CODEPASS_END
 *
 * - AW_J2K_ARITH_OPT_PREDICTABLE_TERMINATION - determines whether
 *   predictable termination will be used.  The allowed values are:
 *   - AW_J2K_PT_NO_PREDICTABLE_TERMINATION
 *   - AW_J2K_PT_USE_PREDICTABLE_TERMINATION
 *
 * - AW_J2K_ARITH_OPT_VERTICALLY_CAUSAL_CONTEXT - sets whether the
 *   aritmetic coder's context will be vertically causal or not.  The
 *   allowed values are:
 *   - AW_J2K_VC_NO_VERTICALLY_CAUSAL_CONTEXT
 *   - AW_J2K_VC_USE_VERTICALLY_CAUSAL_CONTEXT
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_arithmetic_coding_option(aw_j2k_object *j2k_object,
                                               int option, int value);
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_arithmetic_coding_option_ex(aw_j2k_object *j2k_object,
                                                  int tile_index,
                                                  int channel_index,
                                                  int option, int value);


/* aw_j2k_set_output_j2k_coding_style()
 * Section 6.3.17
 *
 * This function is deprecated; use
 * aw_j2k_set_output_arithmetic_coding_option() instead.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_coding_style(aw_j2k_object *j2k_object,
                                   int coding_style);



/* aw_j2k_set_output_j2k_coding_predictor_offset()
 * Section 6.3.18
 *
 * The rate-control algorithm uses a predictor to decide how much data
 * to encode.  As not all of the data that is encoded will actually be
 * kept, this predictor can have a large impact on the run time of the
 * compressor, as well as on the quality of the resulting image.
 *
 * The default value is 2; a value of 1 will speed up the compressor
 * while reducing image quality, while a value of 3 will slow the
 * compressor down while increasing image quality.  Use
 * AW_J2K_PREDICTOR_CODE_ALL_DATA to disable the predictor, which will
 * result in the highest quality images at the lowest compression
 * speed.  Note that this will not result in lossless compression --
 * the target bitrate, compression ratio, or filesize will still be
 * met.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_coding_predictor_offset(aw_j2k_object *j2k_object,
                                              int predictor_offset);
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_coding_predictor_offset_ex(aw_j2k_object *j2k_object,
                                                 int tile_index,
                                                 int predictor_offset);


/* aw_j2k_set_output_j2k_component_registration()
 * Section 6.3.19
 *
 * Sets a color channel's registration offset in a JPEG 2000 image.
 * The registration offsets indicate how much to offset each color
 * channel relative to the image grid for display.  The offsets are
 * given in units of 1/65536 of a pixel.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_component_registration(aw_j2k_object *j2k_object,
                                             WORD component,
                                             WORD Xreg, WORD Yreg);


/* aw_j2k_set_output_j2k_tile_toc()
 * Section 6.3.20
 *
 * This option adds to the JPEG 2000 image a Tile Length Marker (TLM)
 * segment.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_tile_toc(aw_j2k_object *j2k_object);


/* aw_j2k_set_output_j2k_tile_data_toc()
 * Section 6.3.21
 *
 * This option adds to the JPEG 2000 image a Packet Length, Tilepart
 * Header Marker (PLT) segment.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_tile_data_toc(aw_j2k_object *j2k_object);
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_tile_data_toc_ex(aw_j2k_object *j2k_object,
                                       int tile_index, BOOL inclusion_flag);


/* aw_j2k_set_output_j2k_clear_comments()
 * Section 6.3.22
 *
 * Clears all comments from a JPEG 2000 image.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_clear_comments(aw_j2k_object *j2k_object);


/* aw_j2k_get_output_j2k_layer_psnr_estimate()
 * Section 6.3.23
 *
 * Returns an estimate of the JPEG2000 output image pSNR (after 
 * compression), for the specified layer. 
 */

DLLIMPORT int CALLING_CONVENTION
aw_j2k_get_output_j2k_layer_psnr_estimate(aw_j2k_object *j2k_object,
                                        int layer_index, 
                                        float *psnr);
 

/* aw_j2k_output_reset_options()
 * Section 6.3.24 
 *
 * Resets all of the options set by the output image functions.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_output_reset_options(aw_j2k_object *j2k_object);



/* aw_j2k_set_output_j2k_lambda()
 * Section 6.3.24
 *
 * This function is deprecated.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_lambda(aw_j2k_object *j2k_object, float lambda);



/* aw_j2k_set_output_j2k_roi_from_image()
 * Section 6.4.1
 *
 * Defines a region of interest from an image; the image is read from
 * the buffer, and its type is automatically determined.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_roi_from_image(aw_j2k_object *j2k_object, char *image,
                                     unsigned long image_length);


/* aw_j2k_set_output_j2k_roi_from_image_type()
 * Section 6.4.2
 *
 * Defines a region of interest from an image; the image is read from
 * the buffer, and its type is given.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_roi_from_image_type(aw_j2k_object *j2k_object,
                                          char *image,
                                          unsigned long image_length,
                                          int type);


/* aw_j2k_set_output_j2k_roi_from_image_raw()
 * Section 6.4.3
 *
 * Defines a region of interest from an image; the raw image is read
 * from the buffer.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_roi_from_image_raw(aw_j2k_object *j2k_object,
                                         char *image, int  rows, int cols,
                                         int bpp, BOOL bInterlaced);


/* aw_j2k_set_output_j2k_roi_from_file()
 * Section 6.4.4
 *
 * Defines a region of interest from an image; the image is read from
 * the file, and its type automatically determined.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_roi_from_file(aw_j2k_object *j2k_object, char *filename);


/* aw_j2k_set_output_j2k_roi_from_file_raw()
 * Section 6.4.5
 *
 * Defines a region of interest from an image; the raw image is read
 * from the file.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_roi_from_file_raw(aw_j2k_object *j2k_object,
                                        char *filename,
                                        int rows, int cols, int bpp,
                                        BOOL bInterleaved);


/* aw_j2k_set_output_j2k_roi_add_shape()
 * Section 6.4.6
 *
 * A filled shape is added to the region of interest.  The shapes are:
 * - AW_ROISHAPE_RECTANGLE
 * - AW_ROISHAPE_ELLIPSE
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_roi_add_shape(aw_j2k_object *j2k_object, int shape,
                                    int x, int y, int width, int height);


/* aw_j2k_set_output_j2k_clear_roi()
 * Section 6.4.7
 *
 * Clears all region of interest information.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_clear_roi(aw_j2k_object *j2k_object);


/* aw_j2k_set_output_enum_colorspace()
 * Section 6.5.1
 *
 * Sets the color space of an output image to the enumerated color
 * space.  Rotates the data of the image from the input color space to
 * the output color space, if the input image is not a JP2 image.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_enum_colorspace(aw_j2k_object *j2k_object,
                                  long int colorspace);


/* aw_j2k_set_output_jp2_restricted_ICCProfile()
 * Section 6.5.2
 *
 * Sets the color space of an output image to the color space
 * specified by the given restricted ICC profile.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_jp2_restricted_ICCProfile(aw_j2k_object *j2k_object,
                                            unsigned char *icc_buffer,
                                            unsigned long int icc_length_length);


/* aw_j2k_set_output_jp2_add_metadata_box()
 * Section 6.5.3
 *
 * Adds a metadata box of the given type with the given contents to a
 * JP2 image.  Multiple metadataboxes can be added to an image.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_jp2_add_metadata_box(aw_j2k_object *j2k_object,
                                       unsigned long int box_type, char *data,
                                       unsigned long int data_length,
                                       unsigned char *uuid,
                                       unsigned long int uuid_length);


/* aw_j2k_set_output_jp2_add_UUIDInfo_box()
 * Section 6.5.4
 *
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_jp2_add_UUIDInfo_box(aw_j2k_object *j2k_object,
                                       unsigned char *uuid, int num_uuid,
                                       char *url, unsigned long int url_length);


/* aw_j2k_set_output_jpg_options()
 * Section 6.6.1
 *
 * Sets the quality for JPEG (not JPEG 2000).
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_jpg_options(aw_j2k_object *j2k_object, long int quality);


/* aw_j2k_set_output_com_geometry_rotation()
 * Section 6.7.1
 *
 * Rotates the output image in 90 degree increments
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_com_geometry_rotation(aw_j2k_object *j2k_object, int angle);

/* aw_j2k_set_output_raw_endianness()
 * Section 6.7.2
 *
 * Sets the endianness of an output raw image.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_raw_endianness(aw_j2k_object *j2k_object, 
                                 unsigned long int fEndianness);


/* aw_j2k_set_input_image_raw_region()
 * Section 5.1.5
 *
 * allows input of raw image in separate regions
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_input_image_raw_region(aw_j2k_object *j2k_object, 
                           unsigned long int row_offset,
                           unsigned long int cols_offset,
                           unsigned long int rows,
                           unsigned long int cols,
                           unsigned long int nChannels,
                           BYTE *buffer,
                           BOOL bInterleaved
                           );

/* aw_j2k_set_output_j2k_header_option()
 * Section 6.3.24
 *
 * specifies weather the output j2k image should have header and end of stream marker
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_set_output_j2k_header_option(aw_j2k_object *j2k_object, BOOL header, BOOL end_marker);


/* aw_j2k_register_callbacks()
 *
 * This function is not yet enabled.
 */
DLLIMPORT int CALLING_CONVENTION
aw_j2k_register_callbacks(aw_j2k_object *j2k_object,
                          int (*TestAbortProc)(void *),
                          void (*UpdateProgressProc)(void *),
                          void (*SetProgressDoneProc)(void *, int done),
                          void (*SetProgressTotalProc)(void *, int total),
                          int (*GetProgressDoneProc)(void *));

#ifdef __cplusplus
}
#endif

/* Do not add anything below this line! */
#endif /* _J2K_H_ */
