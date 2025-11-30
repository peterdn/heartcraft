@echo off
echo ============================================
echo    VISUAL STUDIO INSTALLATION DIAGNOSTICS
echo ============================================
echo.

echo This tool will check your Visual Studio installation and generate
echo a report to help diagnose compiler detection issues.
echo.

REM Create a diagnostic directory
set DIAGNOSTIC_DIR=%~dp0diagnostic_report
mkdir "%DIAGNOSTIC_DIR%" 2>nul
echo Creating diagnostic report in: %DIAGNOSTIC_DIR%
echo.

REM System information
echo Collecting system information...
systeminfo | findstr /C:"OS" > "%DIAGNOSTIC_DIR%\system_info.txt"
echo %DATE% %TIME% >> "%DIAGNOSTIC_DIR%\system_info.txt"

REM Check for vswhere.exe
echo Checking Visual Studio installation...
set VS_INSTALLER="%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if exist %VS_INSTALLER% (
    echo vswhere.exe found: %VS_INSTALLER%

    echo Detecting Visual Studio installations...
    %VS_INSTALLER% -all -format json > "%DIAGNOSTIC_DIR%\vs_installations.json"

    echo Checking for C++ components...
    %VS_INSTALLER% -all -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -format json > "%DIAGNOSTIC_DIR%\vs_cpp_installations.json"

    REM Check for specific installations
    %VS_INSTALLER% -all -property installationPath > "%DIAGNOSTIC_DIR%\vs_paths.txt"

    for /f "usebackq tokens=*" %%i in (`%VS_INSTALLER% -latest -property installationPath`) do (
        set VS_LATEST=%%i
    )

    if not "%VS_LATEST%"=="" (
        echo Most recent Visual Studio found at: %VS_LATEST%
        echo %VS_LATEST% > "%DIAGNOSTIC_DIR%\vs_latest_path.txt"

        REM Check for vcvarsall.bat
        set VC_VARS="%VS_LATEST%\VC\Auxiliary\Build\vcvarsall.bat"
        if exist %VC_VARS% (
            echo vcvarsall.bat found: %VC_VARS%
            echo %VC_VARS% > "%DIAGNOSTIC_DIR%\vcvars_path.txt"
        ) else (
            echo ERROR: vcvarsall.bat not found!
            echo Expected at: %VC_VARS%
            echo This file is required for setting up the C++ compiler environment
        )
    ) else (
        echo ERROR: No Visual Studio installation found with vswhere.exe
    )
) else (
    echo ERROR: vswhere.exe not found at expected location
    echo This suggests Visual Studio is not installed
)

REM Check environment variables
echo Checking environment variables...
set > "%DIAGNOSTIC_DIR%\environment_variables.txt"

REM Check PATH for compiler
echo Checking PATH for compiler...
echo %PATH% > "%DIAGNOSTIC_DIR%\path.txt"
where cl.exe > "%DIAGNOSTIC_DIR%\cl_location.txt" 2>&1

REM Check CMake
echo Checking for CMake...
where cmake.exe > "%DIAGNOSTIC_DIR%\cmake_location.txt" 2>&1
cmake --version > "%DIAGNOSTIC_DIR%\cmake_version.txt" 2>&1

echo.
echo Diagnostic report completed.
echo.
echo Please check the report at: %DIAGNOSTIC_DIR%
echo.
echo Next steps:
echo 1. If Visual Studio is not installed, install it with C++ components
echo 2. If installed but not detected, try running fix_compiler.bat
echo 3. If problems persist, share the diagnostic report for further help
echo.

pause
