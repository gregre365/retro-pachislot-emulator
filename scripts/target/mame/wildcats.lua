-- license:BSD-3-Clause
-- copyright-holders:MAMEdev Team

---------------------------------------------------------------------------
--
--   wildcats.lua
--
--   Retro Pachislot Emulator build (Wild Cats driver only)
--   Use make SUBTARGET=wildcats to build
--
---------------------------------------------------------------------------


--------------------------------------------------
-- Specify all the CPU cores necessary for the
-- drivers referenced in wildcats.lst.
--------------------------------------------------

-- 
CPUS["Z80"] = true

--------------------------------------------------
-- Specify all the sound cores necessary for the
-- drivers referenced in wildcats.lst.
--------------------------------------------------

-- SOUNDS["ASTROCADE"] = true
-- SOUNDS["AY8910"] = true
-- SOUNDS["CEM3394"] = true
-- SOUNDS["DAC"] = true
-- SOUNDS["DISCRETE"] = true
-- SOUNDS["HC55516"] = true
-- SOUNDS["OKIM6295"] = true
-- SOUNDS["SAMPLES"] = true
-- SOUNDS["TMS5220"] = true
-- SOUNDS["VOTRAX"] = true
-- SOUNDS["YM2151"] = true
-- SOUNDS["YM3812"] = true
SOUNDS["YM2413"] = true

--------------------------------------------------
-- specify available video cores
--------------------------------------------------

-- VIDEOS["MC6845"] = true


--------------------------------------------------
-- specify available machine cores
--------------------------------------------------

-- MACHINES["6821PIA"] = true
-- MACHINES["68681"] = true
-- MACHINES["ADC0808"] = true
-- MACHINES["BANKDEV"] = true
-- MACHINES["GEN_LATCH"] = true
-- MACHINES["INPUT_MERGER"] = true
-- MACHINES["NETLIST"] = true
-- MACHINES["OUTPUT_LATCH"] = true
-- MACHINES["PIT8253"] = true
-- MACHINES["RIOT6532"] = true
-- MACHINES["TICKET"] = true
-- MACHINES["TIMEKPR"] = true
-- MACHINES["TTL74148"] = true
-- MACHINES["TTL74153"] = true
-- MACHINES["TTL74157"] = true
-- MACHINES["TTL74259"] = true
-- MACHINES["TTL7474"] = true
-- MACHINES["WATCHDOG"] = true
-- MACHINES["Z80CTC"] = true
MACHINES["STEPPERS"] = true
MACHINES["Z80DAISY"] = true
-- MACHINES["Z80PIO"] = true


--------------------------------------------------
-- specify available bus cores
--------------------------------------------------

-- BUSES["CENTRONICS"] = true


--------------------------------------------------
-- This is the list of files that are necessary
-- for building all of the drivers referenced
-- in wildcats.lst
--------------------------------------------------

function createProjects_mame_wildcats(_target, _subtarget)
	project ("mame_wildcats")
	targetsubdir(_target .."_" .. _subtarget)
	kind (LIBTYPE)
	uuid (os.uuid("drv-mame-arktechnico"))
	addprojectflags()
	precompiledheaders_novs()

	includedirs {
		MAME_DIR .. "src/osd",
		MAME_DIR .. "src/emu",
		MAME_DIR .. "src/devices",
		MAME_DIR .. "src/mame/shared",
		MAME_DIR .. "src/mame/arktechnico",
		MAME_DIR .. "src/lib",
		MAME_DIR .. "src/lib/util",
		MAME_DIR .. "3rdparty",
		GEN_DIR  .. "mame/layout",
	}

files{
	MAME_DIR .. "src/mame/arktechnico/wildcats_reel.cpp",
	MAME_DIR .. "src/mame/arktechnico/wildcats.cpp",
}
end

function linkProjects_mame_wildcats(_target, _subtarget)
	links {
		"mame_wildcats",
	}
end
