@set ROOT_DIR=%~dp0\..\..
@call config.bat
@%ROOT_DIR%\bin\vasmz80_std.exe -quiet -Fbin z80.asm -o z80.bin
@%ROOT_DIR%\bin\vasmm68k_mot.exe -quiet -Fbin %SRC_MAIN% -o %ROOT_DIR%\roms\%OUTPUT_ROM%.gen 
