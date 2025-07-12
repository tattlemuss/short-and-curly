Source code and tools for "Short and Curly" by Reservoir Gods and Avena

The code is complete except for the file "save_restore.s", which contained
code from the [DHS Demo System v1.0](https://dhs.nu/files.php?t=single&ID=138)
Since the licencing is unclear, I have removed that file.

Directory structure:

	+ tools - utilities for creating data for the build
		+ font 	- extracts font glyphs and calculates kerning
		+ perlin1	- generates flowmaps and tests movement
		+ spritegen	- generates rotated sprites
		+ wipes - generates the order of tiles for flipping between flowmaps
	+ atari - source code and runtime data
		+ demo - demo-specific code and data
		+ sys - shared setup and main loop, definitions

