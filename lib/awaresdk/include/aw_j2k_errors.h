/**********************************************************************
 *
 * Copyright 1994-1998 Aware, Inc.
 *
 * $Workfile: aw_j2k_errors.h $    $Revision: 21 $   
 * Last Modified: $Date: 1/04/05 4:48p $ by: $Author: Rgut $
 *
 **********************************************************************/
#ifndef _ERRORS_H_
#define _ERRORS_H_
static const char id_errors_h[] = "@(#) $Header: /JPEG2000/platform/solaris/src/aw_j2k_errors.h 21    1/04/05 4:48p Rgut $ Aware Inc.";

/***********************************/
/* Return Error Codes */
/***********************************/

/* Error return values from compression and decompression functions. */
#ifndef NO_ERROR
#  define NO_ERROR 0
#endif
#define AW_J2K_ERROR_MALLOC_ERROR                   1
#define AW_J2K_ERROR_UNSUPPORTED_JP2K_TYPE_ERROR    2
#define AW_J2K_ERROR_MISSING_COD_MARKER             3
#define AW_J2K_ERROR_MISSING_QCD_MARKER             4
#define AW_J2K_ERROR_ROWS_RANGE_ERROR               5
#define AW_J2K_ERROR_COLS_RANGE_ERROR               6
#define AW_J2K_ERROR_ASPECT_RATIO_ERROR             7
#define AW_J2K_ERROR_RATIO_RANGE_ERROR              8
#define AW_J2K_ERROR_NULL_DATA                      9
#define AW_J2K_ERROR_COMPRESS_ERROR                10
#define AW_J2K_ERROR_MALLAT_LEVELS_ERROR           11
#define AW_J2K_ERROR_RESOLUTION_LEVELS_ERROR       12
#define AW_J2K_ERROR_BYTESTREAM_ERROR              13
#define AW_J2K_ERROR_MARKER_ERROR                  14
#define AW_J2K_ERROR_MARKER_LENGTH_ERROR           15
#define AW_J2K_ERROR_USER_ABORT                    16
#define AW_J2K_ERROR_TOLERANCE_ERROR               17
#define AW_J2K_ERROR_OUT_OF_DATA_ERROR             18
#define AW_J2K_ERROR_SHORT_DATA_ERROR              19
#define AW_J2K_ERROR_IMAGE_MISMATCH_ERROR          20
#define AW_J2K_ERROR_LOG_RATIO_ERROR               21
#define AW_J2K_ERROR_BPP_ERROR                     22
#define AW_J2K_ERROR_GUARD_BITS_TOO_FEW            23
#define AW_J2K_ERROR_ILLEGAL_CODESTREAM_ERROR      24
#define AW_J2K_ERROR_BAD_COMPONENT                 25
#define AW_J2K_ERROR_BAD_PRECINCT_SPECIFICATION    26

#define AW_J2K_ERROR_INVALID_OBJECT                30
#define AW_J2K_ERROR_BAD_PARAMETER                 31
#define AW_J2K_ERROR_BUFFER_TOO_SHORT              32

#define AW_J2K_ERROR_FILE_OPEN                    100
#define AW_J2K_ERROR_FILE_CREATE                  101
#define AW_J2K_ERROR_FILE_READ                    102
#define AW_J2K_ERROR_FILE_WRITE                   103

#define AW_J2K_ERROR_INPUT_FORMAT_MISMATCH        110
#define AW_J2K_ERROR_INPUT_NOTSET                 111
#define AW_J2K_ERROR_UNKNOWN_IMAGE_TYPE           200
#define AW_J2K_ERROR_UNSUPPORTED_IMAGE_TYPE       201
#define AW_J2K_ERROR_INVALID_IMAGE                202
#define AW_J2K_ERROR_INVALID_PARAMETER            203
#define AW_J2K_JP2_PARSE_ERROR                    204
#define AW_J2K_JP2_NO_ICCPROFILE                  205
#define AW_J2K_JP2_NO_ENUM_COLORSPACE             206
#define AW_J2K_ERROR_DICOM_LIBRARY                207
#define AW_J2K_ERROR_INVALID_CALL_SEQUENCE        208
#define AW_J2K_ERROR_UNSUPPORTED_FUNCTION         209

#define AW_J2K_ERROR_MEMORYMAP_OUTPUT             210
#define AW_J2K_ERROR_MEMORYMAP_INPUT              211
#define AW_J2K_ERROR_TIFF                         212

#define AW_J2K_ERROR_LIBRARY_EXPIRED              900
#define AW_J2K_ERROR_LIBRARY_INTERNAL             999

/* do not add anything beyond this line! */
#endif /* _ERRORS_H_ */
