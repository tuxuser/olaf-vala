@echo off
echo Build called

set PATH=%PATH%;C:\msys64\mingw64\bin;C:\msys64\usr\bin

set command="%1"
rem if %command% == "build" (
    cmake -G"MSYS Makefiles" .. && cmake --build .
rem )

rem if %command% == "run" (
    olaf.exe
rem )

