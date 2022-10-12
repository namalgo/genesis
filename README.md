# What is This?
Sega Genesis/MegaDrive assembly code examples from articles on [namelessalgorithm.com](https://namelessalgorithm.com/genesis/).

# Prerequisites
1. Download:

   [vasmm68k_mot_Win64](http://sun.hasenbraten.de/vasm/bin/rel/vasmm68k_mot_Win64.zip) and
   [vasmz80_std_Win64](http://sun.hasenbraten.de/vasm/bin/rel/vasmz80_std_Win64.zip)

   Extract and put `vasmm68k_mot.exe` and `vasmz80_std.exe` in [bin/](bin/).

2. Open example dir and run `assemble.bat`.
3. Load ROM from [roms/](roms/) in your favourite emulator.
4. The MAME Debug example requires Ruby.

# Examples
## Very Minimal
- **Very Minimal**: Minimal Sega Genesis ROM.
  [Article: 'SEGA Genesis: Building a ROM'](https://namelessalgorithm.com/genesis/blog/genesis/)
  
  ![Very Minimal Screenshot](screenshots/very_minimal.png | width=300)
  <img src="https://raw.githubusercontent.com/namalgo/genesis/main/screenshots/very_minimal.png" align="right" width="400px" >
  
  [Source code](src/very_minimal/very_minimal.asm) | [Download ROM](roms/very_minimal.gen?raw=true)

## MAME Debug
- **MAME Debug**: MAME Debug example.
  [Article: 'SEGA Genesis: Debugging'](https://namelessalgorithm.com/genesis/blog/debug/).
  
  ![Hello Screenshot](screenshots/mame-symbols.png | width=300)
  
  [MAME label Ruby script](scripts/mamelabels-vasm.rb)

- **Hello**: Hello world text demo.
  [Article: 'SEGA Genesis: Printing Text'](https://namelessalgorithm.com/genesis/blog/text/).
  
  ![Hello Screenshot](screenshots/hello.png | width=300)
  
  [Source code](src/hello_world/hello.asm) | [Download ROM](roms/hello.gen?raw=true)

- **Framebuffer**: Framebuffer rendering.
  [Article: 'SEGA Genesis: Framebuffer Rendering'](https://namelessalgorithm.com/genesis/blog/framebuf/).
  
  ![Framebuffer demo screenshot](screenshots/framebuf.png | width=300)
  
  [Source code](src/framebuf/demo.asm) | [Download ROM](roms/framebuf.gen?raw=true)

# Copyright and License
All source code in this repository has the following copyright:
```
Copyright 2022 Nameless Algorithm
See https://namelessalgorithm.com/ for more information.
```
And the following license:
```
You may use this source code for any purpose. If you do so, please attribute
'Nameless Algorithm' in your source, or mention us in your game/demo credits.
Thank you.
```

# Thanks
In no particular order:
- Matt Phillips for the BigEvilCorporation tutorials
- iwis for Plutiedev
- MarkeyJester for MC68000 tutorials
- Flint/DARKNESS for MC 680x0 Reference 1.1
- Alexey Melnikov/sorgelig for the MiSTer
- Gregory Estrade for the fpgagen Sega Genesis/MegaDrive FPGA core
- Mednafen Team for a great emulator
- Sonic Retro/Sega Retro Team for segaretro.org and the Sonic disassembly (s1disasm)
- Dr. Volker Barthelmann for vasm
