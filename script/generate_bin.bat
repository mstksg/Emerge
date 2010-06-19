mkdir ..\bin\logs
git log --stat -1 > ..\bin\logs\version.txt
xcopy ..\lib ..\bin\lib\ /e
xcopy ..\app ..\bin\app\ /e
xcopy ..\config ..\bin\config\ /e
xcopy ..\data ..\bin\data\ /e
xcopy ..\README.md ..\bin\
move ..\emerge.exe ..\bin\
move ..\bin\lib\SDL\libfreetype-6.dll ..\bin\
echo done