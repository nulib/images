/**********************************************************************
 *
 * Copyright 1994-1996,2000 Aware, Inc.
 *
 * $Workfile: get_precise_time.c $    $Revision: 7 $
 * Last Modified: $Date: 10/24/03 2:09p $ by: $Author: Alexis $
 *
 **********************************************************************/
static const char id_get_precise_time_c[] = "@(#) $Header: /JPEG2000/platform/solaris/src/get_precise_time.c 7     10/24/03 2:09p Alexis $ Aware Inc.";

/* function to return system time in seconds */
/* stdio.h is needed because on linux that is where NULL is defined... */
#include <stdio.h>

#include <sys/types.h>
#ifdef _WIN32
#include <windows.h>
#include <sys/timeb.h>
#else
#include <sys/time.h>
#endif
#ifdef ALTIVEC
#include <mcos.h>
#endif
#include "get_precise_time.h"

#ifdef ALTIVEC
#define SECS_PER_CLOCKTICK  6.e-8
#endif


double get_precise_time(void)
{
#ifdef _WIN32
  struct _timeb Tb;
  LARGE_INTEGER counter, frequency;

  if (QueryPerformanceFrequency(&frequency) &&
      QueryPerformanceCounter(&counter))
    return (double)counter.QuadPart / (double)frequency.QuadPart;

  _ftime(&Tb);
  return (double)Tb.time + ((double)Tb.millitm)/1.0e3;
#elif defined(ALTIVEC)
  TMR_ts timeval;
  tmr_timestamp(&timeval);
  return timeval.ts.timestamp*SECS_PER_CLOCKTICK; /* number of clock ticks * clock interval */
#else
  struct timeval Tp;
  gettimeofday(&Tp, NULL);
  return Tp.tv_sec + Tp.tv_usec/1.0e6;
#endif
}
