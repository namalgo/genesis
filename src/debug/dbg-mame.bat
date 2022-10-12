:: @echo off
set SRC_DIR=%~dp0
set ROOT_DIR=%~dp0\..\..
set MAME_OPTS=-debug -dfont "Cascadia Code SemiLight" -dfontsize 11 -debugscript %SRC_DIR%\mamelabels -window

call config.bat
call assemble.bat

:: Generate labels for MAME debugger
ruby %ROOT_DIR%\scripts\mamelabels-vasm.rb > mamelabels

cd %ROOT_DIR%\bin\mame
mame64 genesis %MAME_OPTS% -cart roms\%OUTPUT_ROM%.gen
