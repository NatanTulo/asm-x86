@echo off
D:\bin\ml.exe /Fl /Fm /Zi /c %1.asm
if errorlevel 1 goto koniec
D:\binr\link.exe /codeview %1.obj
:koniec


