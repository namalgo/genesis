@set ROOT_DIR=%~dp0\..\..
@call config.bat
@%ROOT_DIR%\bin\vasmZ80 -quiet -Fbin z80.asm -o z80.bin
@%ROOT_DIR%\bin\vasm -quiet -Fbin %SRC_MAIN% -o %ROOT_DIR%\roms\%OUTPUT_ROM%.gen 
