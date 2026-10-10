@echo off
setlocal EnableExtensions
set "TOOLS_DIR=%~dp0"
if "%TOOLS_DIR:~-1%"=="\" set "TOOLS_DIR=%TOOLS_DIR:~0,-1%"

call :ENSURE_PATH

if "%~1"=="" goto LIST
if /i "%~1"=="-create" goto CREATE

echo Kullanim: %~nx0
echo   %~nx0            bu dizindeki java komutlarini listeler
echo   %~nx0 -create    Java kurulumlarini tarar ve komutlari yeniden olusturur
exit /b 1

:LIST
echo Java komutlari: %TOOLS_DIR%
echo.
set "FOUND=0"
for /L %%N in (1,1,40) do if exist "%TOOLS_DIR%\java%%N.bat" call :SHOW_ONE "%TOOLS_DIR%\java%%N.bat" %%N
if "%FOUND%"=="0" echo Komut yok. Olusturmak icin: %~nx0 -create
exit /b 0

:SHOW_ONE
set "FOUND=1"
set "VER="
set "TARGET="
findstr /b /c:"rem VER=" /c:"rem EXE=" "%~1" > "%TEMP%\java-init-show.txt" 2>nul
for /f "usebackq tokens=1,* delims==" %%A in ("%TEMP%\java-init-show.txt") do call :SHOW_LINE "%%A" "%%B"
echo   java%~2.bat  %VER%
echo     %TARGET%
echo.
goto :EOF

:SHOW_LINE
if /i "%~1"=="rem VER" set "VER=%~2"
if /i "%~1"=="rem EXE" set "TARGET=%~2"
goto :EOF

:CREATE
echo Java kurulumlari taraniyor...
echo.

if defined JAVA_HOME call :ADD_HOME "%JAVA_HOME%"

call :SCAN_TREE "%ProgramFiles%" 1
call :SCAN_TREE "%ProgramFiles(x86)%" 1
call :SCAN_TREE "%LOCALAPPDATA%\Programs" 1
call :SCAN_TREE "%USERPROFILE%\.jdks"
call :SCAN_TREE "%USERPROFILE%\scoop\apps"
call :SCAN_TREE "%ProgramData%\chocolatey\lib"

call :SCAN_REG "HKLM\SOFTWARE\JavaSoft" JavaHome
call :SCAN_REG "HKLM\SOFTWARE\WOW6432Node\JavaSoft" JavaHome
call :SCAN_REG "HKLM\SOFTWARE\Eclipse Adoptium" Path
call :SCAN_REG "HKLM\SOFTWARE\AdoptOpenJDK" Path
call :SCAN_REG "HKLM\SOFTWARE\Microsoft\JDK" Path
call :SCAN_REG "HKLM\SOFTWARE\Amazon Corretto" Path
call :SCAN_REG "HKLM\SOFTWARE\Azul Systems" JavaHome
call :SCAN_REG "HKLM\SOFTWARE\BellSoft" JavaHome
call :SCAN_REG "HKLM\SOFTWARE\Semeru" Path
call :SCAN_REG "HKCU\SOFTWARE\JavaSoft" JavaHome
call :SCAN_REG "HKCU\SOFTWARE\Eclipse Adoptium" Path

where java > "%TEMP%\java-init-where.txt" 2>nul
if exist "%TEMP%\java-init-where.txt" for /f "usebackq delims=" %%J in ("%TEMP%\java-init-where.txt") do call :ADD_JAVA "%%~fJ"

call :DELETE_OLD

echo.
set "COUNT=0"
for /f "tokens=1,* delims==" %%A in ('set JAVA_VER_ 2^>nul') do call :WRITE_ONE "%%A" "%%B"

if "%COUNT%"=="0" (
    echo Java kurulumu bulunamadi.
) else (
    echo %COUNT% komut olusturuldu: %TOOLS_DIR%
)
exit /b 0

:ENSURE_PATH
set "MARKFILE=%TOOLS_DIR%\.path-ok"
set "MARKED="
if exist "%MARKFILE%" set /p MARKED=<"%MARKFILE%"
if /i "%MARKED%"=="%TOOLS_DIR%" goto :EOF

reg query "HKCU\Environment" /v Path > "%TEMP%\java-init-userpath.txt" 2>nul
if errorlevel 1 goto PATH_CREATE
findstr /b /c:"    Path    " "%TEMP%\java-init-userpath.txt" > "%TEMP%\java-init-pathline.txt"
set "PATHLINE="
set /p PATHLINE=<"%TEMP%\java-init-pathline.txt"
if not defined PATHLINE goto :EOF

setlocal EnableDelayedExpansion
set "PTYPE=REG_SZ"
echo(!PATHLINE!| findstr /i /c:"REG_EXPAND_SZ" >nul
if not errorlevel 1 set "PTYPE=REG_EXPAND_SZ"
set "PVAL=!PATHLINE!"
if /i "!PTYPE!"=="REG_EXPAND_SZ" (
    set "PVAL=!PVAL:*REG_EXPAND_SZ=!"
) else (
    set "PVAL=!PVAL:*REG_SZ=!"
)
:TRIM_PATH
if not defined PVAL goto PATH_APPEND
if "!PVAL:~0,1!"==" " (
    set "PVAL=!PVAL:~1!"
    goto TRIM_PATH
)
echo(;!PVAL!;| findstr /i /l /c:";%TOOLS_DIR%;" /c:";%TOOLS_DIR%\;" >nul
if not errorlevel 1 goto PATH_FOUND
:PATH_APPEND
if not defined PVAL (
    set "NEWPATH=%TOOLS_DIR%"
) else if "!PVAL:~-1!"==";" (
    set "NEWPATH=!PVAL!%TOOLS_DIR%"
) else (
    set "NEWPATH=!PVAL!;%TOOLS_DIR%"
)
reg add "HKCU\Environment" /v Path /t !PTYPE! /d "!NEWPATH!" /f >nul
if errorlevel 1 goto PATH_FAIL
endlocal
goto PATH_ADDED

:PATH_FOUND
endlocal
goto PATH_MARK

:PATH_FAIL
endlocal
goto :EOF

:PATH_CREATE
reg add "HKCU\Environment" /v Path /t REG_EXPAND_SZ /d "%TOOLS_DIR%" /f >nul
if errorlevel 1 goto :EOF

:PATH_ADDED
> "%MARKFILE%" echo %TOOLS_DIR%
setx JAVA_TOOLS_NOTIFY 1 >nul 2>&1
reg delete "HKCU\Environment" /v JAVA_TOOLS_NOTIFY /f >nul 2>&1
echo Klasor kullanici PATH icine eklendi:
echo   %TOOLS_DIR%
echo Yeni bir terminal acinca java17 gibi komutlar dogrudan calisir.
echo.
goto :EOF

:PATH_MARK
> "%MARKFILE%" echo %TOOLS_DIR%
goto :EOF

:DELETE_OLD
for %%F in ("%TOOLS_DIR%\java*.bat") do (
    echo %%~nF | findstr /r /i "^java[0-9][0-9]*$" >nul
    if not errorlevel 1 del "%%~fF"
)
goto :EOF

:SCAN_TREE
if not exist "%~1\" goto :EOF
set "FILTER=%~2"
pushd "%~1" || goto :EOF
for /d %%V in (*) do call :SCAN_NODE "%%~fV" "%%~nxV"
popd
goto :EOF

:SCAN_NODE
if "%FILTER%"=="1" (
    echo(%~2| findstr /i /r "java jdk jre adopt corretto zulu liberica semeru sapmachine openjdk graal openlogic temurin bellsoft amazon microsoft hotspot" >nul
    if errorlevel 1 goto :EOF
)
if /i "%~2"=="WindowsApps" goto :EOF
if /i "%~2"=="Common Files" goto :EOF
if exist "%~1\bin\java.exe" call :ADD_JAVA "%~1\bin\java.exe"
for /d %%D in ("%~1\*") do (
    if /i not "%%~nxD"=="latest" (
        if exist "%%~fD\bin\java.exe" call :ADD_JAVA "%%~fD\bin\java.exe"
        for /d %%E in ("%%D\*") do if exist "%%~fE\bin\java.exe" call :ADD_JAVA "%%~fE\bin\java.exe"
    )
)
goto :EOF

:SCAN_REG
reg query "%~1" /s /v "%~2" > "%TEMP%\java-init-reg.txt" 2>nul
if errorlevel 1 goto :EOF
set "VALNAME=%~2"
for /f "usebackq tokens=1,2,*" %%A in ("%TEMP%\java-init-reg.txt") do call :REG_LINE "%%A" "%%B" "%%C"
goto :EOF

:REG_LINE
if /i not "%~1"=="%VALNAME%" goto :EOF
if /i "%~2"=="REG_SZ" call :ADD_HOME "%~3"
if /i "%~2"=="REG_EXPAND_SZ" call :ADD_HOME "%~3"
goto :EOF

:ADD_HOME
set "HOME=%~1"
if not defined HOME goto :EOF
call set "HOME=%HOME%"
if exist "%HOME%\bin\java.exe" call :ADD_JAVA "%HOME%\bin\java.exe"
goto :EOF

:ADD_JAVA
set "EXE_PATH=%~f1"
if not exist "%EXE_PATH%" goto :EOF
echo(%EXE_PATH%| findstr /i /c:"\bin\java.exe" >nul
if errorlevel 1 goto :EOF
echo(%EXE_PATH%| findstr /i /c:"\jre\bin\java.exe" /c:"\javapath\java.exe" /c:"\latest\" >nul
if not errorlevel 1 goto :EOF

set "MARK=%EXE_PATH:\=_%"
set "MARK=%MARK::=%"
set "MARK=%MARK: =_%"
set "MARK=%MARK:(=%"
set "MARK=%MARK:)=%"
if defined SEEN_%MARK% goto :EOF
set "SEEN_%MARK%=1"

for %%R in ("%~dp1..\release") do set "REL=%%~fR"
set "HASLIB=0"
if exist "%REL%" set "HASLIB=1"
if exist "%~dp1..\lib\modules" set "HASLIB=1"
if exist "%~dp1..\lib\rt.jar" set "HASLIB=1"
if "%HASLIB%"=="0" goto :EOF

set "RAW_VER="
if exist "%REL%" call :VER_FROM_RELEASE "%REL%"
if not defined RAW_VER call :VER_FROM_EXE "%EXE_PATH%"
if not defined RAW_VER goto :EOF

set "MAJOR="
for /f "tokens=1,2 delims=._-+" %%A in ("%RAW_VER%") do (
    if "%%A"=="1" (set "MAJOR=%%B") else set "MAJOR=%%A"
)
if not defined MAJOR goto :EOF
echo(%MAJOR%| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 goto :EOF

call set "OLD_VER=%%JAVA_VER_%MAJOR%%%"
if not defined OLD_VER goto STORE_JAVA
call :IS_NEWER "%RAW_VER%" "%OLD_VER%"
if errorlevel 1 goto :EOF

:STORE_JAVA
set "JAVA_VER_%MAJOR%=%RAW_VER%"
set "JAVA_EXE_%MAJOR%=%EXE_PATH%"
echo   bulundu: Java %MAJOR% ^(%RAW_VER%^)
echo            %EXE_PATH%
goto :EOF

:VER_FROM_RELEASE
findstr /b /c:"JAVA_VERSION=" "%~1" > "%TEMP%\java-init-rel.txt" 2>nul
for /f "usebackq tokens=1,* delims==" %%A in ("%TEMP%\java-init-rel.txt") do set "RAW_VER=%%~B"
goto :EOF

:VER_FROM_EXE
"%~1" -version > "%TEMP%\java-init-ver.txt" 2>&1
findstr /i /c:"version " "%TEMP%\java-init-ver.txt" > "%TEMP%\java-init-ver2.txt" 2>nul
for /f "usebackq tokens=3" %%V in ("%TEMP%\java-init-ver2.txt") do if not defined RAW_VER set "RAW_VER=%%~V"
goto :EOF

:WRITE_ONE
set "NAME=%~1"
set "VER=%~2"
set "MAJOR=%NAME:JAVA_VER_=%"
call set "JEXE=%%JAVA_EXE_%MAJOR%%%"
set "BAT_FILE=%TOOLS_DIR%\java%MAJOR%.bat"
> "%BAT_FILE%" echo @echo off
>> "%BAT_FILE%" echo rem VER=%VER%
>> "%BAT_FILE%" echo rem EXE=%JEXE%
>> "%BAT_FILE%" echo "%JEXE%" %%*
set /a COUNT+=1
echo   java%MAJOR%.bat  %VER%
echo     %JEXE%
echo.
goto :EOF

:IS_NEWER
setlocal EnableExtensions EnableDelayedExpansion
set "NEW=%~1"
set "OLD=%~2"
set "NEW=!NEW:_=.!"
set "NEW=!NEW:-=.!"
set "NEW=!NEW:+=.!"
set "OLD=!OLD:_=.!"
set "OLD=!OLD:-=.!"
set "OLD=!OLD:+=.!"
for /f "tokens=1-4 delims=." %%A in ("!NEW!") do (
    set "N1=%%A"
    set "N2=%%B"
    set "N3=%%C"
    set "N4=%%D"
)
for /f "tokens=1-4 delims=." %%A in ("!OLD!") do (
    set "O1=%%A"
    set "O2=%%B"
    set "O3=%%C"
    set "O4=%%D"
)
if not defined N1 set "N1=0"
if not defined N2 set "N2=0"
if not defined N3 set "N3=0"
if not defined N4 set "N4=0"
if not defined O1 set "O1=0"
if not defined O2 set "O2=0"
if not defined O3 set "O3=0"
if not defined O4 set "O4=0"
for %%K in (N1 N2 N3 N4 O1 O2 O3 O4) do (
    for /f "delims=0123456789" %%X in ("!%%K!") do set "%%K=0"
)
set /a N1=N1, N2=N2, N3=N3, N4=N4, O1=O1, O2=O2, O3=O3, O4=O4
if !N1! gtr !O1! (endlocal & exit /b 0)
if !N1! lss !O1! (endlocal & exit /b 1)
if !N2! gtr !O2! (endlocal & exit /b 0)
if !N2! lss !O2! (endlocal & exit /b 1)
if !N3! gtr !O3! (endlocal & exit /b 0)
if !N3! lss !O3! (endlocal & exit /b 1)
if !N4! gtr !O4! (endlocal & exit /b 0)
endlocal & exit /b 1
