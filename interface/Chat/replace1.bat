@echo off
for /f "tokens=* delims= " %i in ('dir /b "*_brx.tga"') do Set LIST=%i& set LIST | ren "%~fi" "%LIST:_brx.tga=_brz.tga%"