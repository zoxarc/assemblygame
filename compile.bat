set tar=project
tasm.exe /zi %tar%.asm
tlink.exe /v %tar%.obj
project.exe
