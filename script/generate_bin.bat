mkdir ..\bin\logs
xcopy ..\lib ..\bin\lib\ /e
xcopy ..\app ..\bin\app\ /e
xcopy ..\config ..\bin\config\ /e
xcopy ..\data ..\bin\data\ /e
move ..\emerge.exe ..\bin\
move ..\bin\lib\SDL\libfreetype-6.dll ..\bin\
move ..\bin\lib\SDL\chipmunk.dll ..\bin\
echo done