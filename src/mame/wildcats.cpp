// license:BSD-3-Clause
// copyright-holders:Aaron Giles, gregre365
/***************************************************************************

    wildcats.cpp

    Specific (per target) constants for the Retro Pachislot Emulator build
    (SUBTARGET=wildcats).  scripts/src/main.lua uses this file in place of
    mame.cpp when it exists, so mame.cpp stays as in upstream MAME.

    Not to be confused with the driver, src/mame/arktechnico/wildcats.cpp.

****************************************************************************/

#include "emu.h"
#include "main.h"

#define APPNAME                 "Retro Pachislot Emulator"
#define APPNAME_LOWER           "retropachislotemu"
#define CONFIGNAME              "retropachislot"
#define COPYRIGHT               "Copyright MAMEdev and contributors\nRetro Pachislot Emulator customization by gregre365\nhttps://mamedev.org"
#define COPYRIGHT_INFO          "Copyright MAMEdev and contributors. Retro Pachislot Emulator customization by gregre365"

const char * emulator_info::get_appname() { return APPNAME;}
const char * emulator_info::get_appname_lower() { return APPNAME_LOWER;}
const char * emulator_info::get_configname() { return CONFIGNAME;}
const char * emulator_info::get_copyright() { return COPYRIGHT;}
const char * emulator_info::get_copyright_info() { return COPYRIGHT_INFO;}
