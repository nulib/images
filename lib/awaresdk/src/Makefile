#**********************************************************************
#*
#* Copyright 2001 Aware, Inc.
#*
#* $Workfile: Makefile $   $Revision: 5 $   
#* Last Modified $Date: 2/27/04 11:52a $ by: $Author: Rgut $
#*
#* @(#) $Header: /JPEG2000/platform/irix-64/Release/src/Makefile 5     2/27/04 11:52a Rgut $
#**********************************************************************

include compiler.mak

IFLAGS      = -I../include
DESTDIR     = ../bin
CCLINK      = $(CC) $(CFLAGS) -o $(DESTDIR)/$@
RANLIB      = true
LIBRARIES   = -L../lib -lawj2k -lm

%.o: %.c
	$(CC) $(CFLAGS) $(IFLAGS) -c $<

all: j2kdriver

j2kdriver: j2kdriver.o get_precise_time.o
	$(CC) $(CFLAGS) -o $@ j2kdriver.o get_precise_time.o $(LIBRARIES)
