###########################################################################
#
#   useroptions.mak
#
#   User-specific build options for MAME
#
###########################################################################

# Retro Pachislot Emulator: build only the Wild Cats driver
SUBTARGET = wildcats
PTR64 = 1
IGNORE_GIT = 1
NOWERROR = 1

#-------------------------------------------------
# Windows x64 cross build from Linux (MinGW)
#-------------------------------------------------

# Only used with `make CROSS_WINDOWS=1`; a plain `make` stays a native build.
# Needs gcc-mingw-w64-x86-64-posix and g++-mingw-w64-x86-64-posix.
ifeq ($(CROSS_WINDOWS),1)
TARGETOS = windows
CROSS_BUILD = 1
OVERRIDE_CC = x86_64-w64-mingw32-gcc-posix
OVERRIDE_CXX = x86_64-w64-mingw32-g++-posix
OVERRIDE_LD = x86_64-w64-mingw32-ld
MINGW64 = /usr
endif

# To build from a single driver source instead of the driver list:
# SOURCES = src/mame/arktechnico/wildcats.cpp
