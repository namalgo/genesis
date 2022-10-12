@set ROOT_DIR=%~dp0\..\..
@call config.bat
@call gen-gfx.bat
@%ROOT_DIR%\bin\vasmZ80 -quiet -Fbin z80.asm -o z80.bin
@%ROOT_DIR%\bin\vasm -quiet -L rom.lst -Fbin %SRC_MAIN% -o %ROOT_DIR%\roms\%OUTPUT_ROM%.gen 
:: @%ROOT_DIR%\bin\vasm -quiet -Felf %SRC_MAIN% -o %OUTPUT_ROM%.elf 
