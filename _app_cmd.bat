@echo off
set _cmd=%1
shift
:loop
if "%1"=="" goto end
call %_cmd% %1
shift
goto loop
:end
set _smd=
