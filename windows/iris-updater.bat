@echo off
title Iris Updater
setlocal enabledelayedexpansion

set "api_url=https://api.github.com/repos/nini22P/Iris/releases/latest"
set "download_folder=%~dp0temps"

:: Try to delete the download folder if it exists
if exist "%download_folder%" (
    rd /s /q "%download_folder%"
)

:: Create download folder
mkdir "%download_folder%"

echo Fetching latest release from GitHub...

:: Fetch JSON data using curl
powershell -Command "try { Invoke-WebRequest -Uri '%api_url%' -UseBasicParsing | Select-Object -ExpandProperty Content | Out-File -Encoding UTF8 '%download_folder%\release.json' } catch { Write-Host 'Error fetching release info: ' $_.Exception.Message; exit 1 }"

if not exist "%download_folder%\release.json" (
    echo Error: Could not fetch release data. Please check your internet connection.
    goto :end
)

for /f "delims=" %%a in ('powershell -command "try { Get-Content '%download_folder%\release.json' | ConvertFrom-Json | Select-Object -ExpandProperty tag_name } catch { Write-Host 'Error parsing JSON: ' $_.Exception.Message; exit 1 }"') do (
    set "version_tag=%%a"
    if defined version_tag (
        goto :version_found
    )
)

echo Error: Could not extract version tag from release info.
goto :end

:version_found

set "download_url=https://github.com/nini22P/Iris/releases/latest/download/Iris-windows.zip"
set "zip_file=%download_folder%\Iris-windows.zip"
set "extract_folder=%download_folder%"

title Download Iris !version_tag!

where curl >nul 2>nul
if %errorlevel% equ 0 (
    echo Download Iris !version_tag!
    curl -L -o "%zip_file%" "%download_url%"
    if %errorlevel% neq 0 (
        echo Error downloading file with curl.
        exit /b 1
    )
) else (
    echo Download Iris !version_tag!
    powershell -Command "try { Invoke-WebRequest -Uri '%download_url%' -OutFile '%zip_file%' } catch { Write-Host 'Error downloading file: ' $_.Exception.Message; exit 1 }"
)

if not exist "%zip_file%" (
    echo Error: Failed to download Iris-windows.zip.
    goto :end
)

echo Extracting Iris-windows.zip...
powershell -Command "try { Add-Type -Assembly 'System.IO.Compression.FileSystem'; [System.IO.Compression.ZipFile]::ExtractToDirectory('%zip_file%', '%extract_folder%'); } catch { Write-Host 'Error extracting zip: ' $_.Exception.Message; exit 1 }"

:: Check if Iris folder exists before moving
if not exist "%extract_folder%\Iris" (
    echo Error: "Iris" folder not found within the extracted files.
    goto :cleanup
)

echo Starting file move and cleanup...
:: Start a new cmd window to perform move and cleanup, then current bat will close
start cmd /c "timeout /t 2 /nobreak && xcopy temps\Iris\* .\ /E /I /Y && rd /s /q temps && start iris"

:cleanup
exit

:end
endlocal
