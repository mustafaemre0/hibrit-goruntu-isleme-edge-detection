param(
    [switch]$RunDemo,
    [switch]$NoVenv
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

function Refresh-PathFromSystem {
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
}

function Ensure-WingetAvailable {
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
        return
    }

    throw "winget not found. Install App Installer from Microsoft Store, then rerun setup.ps1."
}

function Get-PortableGccPath {
    $portableRoot = Join-Path $projectRoot "tools/winlibs"
    if (-not (Test-Path $portableRoot)) {
        return $null
    }

    $gccCandidate = Get-ChildItem -Path $portableRoot -Filter gcc.exe -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match "\\bin\\gcc\.exe$" } |
        Select-Object -First 1

    if ($gccCandidate) {
        return $gccCandidate.FullName
    }

    return $null
}

function Install-PortableWinLibs {
    $toolsDir = Join-Path $projectRoot "tools"
    $portableRoot = Join-Path $toolsDir "winlibs"
    $zipPath = Join-Path $toolsDir "winlibs.zip"

    if (-not (Test-Path $toolsDir)) {
        New-Item -ItemType Directory -Path $toolsDir | Out-Null
    }

    Write-Host "[tool] winget ile gcc kurulamazsa portable WinLibs indiriliyor..."
    $winlibsUrl = "https://github.com/brechtsanders/winlibs_mingw/releases/download/16.1.0posix-14.0.0-ucrt-r2/winlibs-x86_64-posix-seh-gcc-16.1.0-mingw-w64ucrt-14.0.0-r2.zip"
    Invoke-WebRequest -Uri $winlibsUrl -OutFile $zipPath

    if (Test-Path $portableRoot) {
        Remove-Item -Recurse -Force $portableRoot
    }
    New-Item -ItemType Directory -Path $portableRoot | Out-Null

    Expand-Archive -Path $zipPath -DestinationPath $portableRoot -Force
    Remove-Item -Force $zipPath

    $portableGcc = Get-PortableGccPath
    if (-not $portableGcc) {
        throw "Portable WinLibs indirildi ama gcc.exe bulunamadi."
    }

    return $portableGcc
}

function Get-PythonCommand {
    if (Get-Command py -ErrorAction SilentlyContinue) {
        return @("py", "-3")
    }

    if (Get-Command python -ErrorAction SilentlyContinue) {
        return @("python")
    }

    return $null
}

function Ensure-PythonAvailable {
    $pythonCmd = Get-PythonCommand
    if ($pythonCmd) {
        return $pythonCmd
    }

    Write-Host "[tool] Python bulunamadi. Otomatik kurulum deneniyor..."
    Ensure-WingetAvailable

    winget install --id Python.Python.3.13 -e --accept-package-agreements --accept-source-agreements

    Refresh-PathFromSystem
    $pythonCmd = Get-PythonCommand
    if ($pythonCmd) {
        return $pythonCmd
    }

    throw "Python kurulumu tamamlanamadi. Python 3 kurup setup.ps1 scriptini tekrar calistirin."
}

function Invoke-BasePython {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    $cmd = @($basePythonCmd)

    if ($cmd.Length -gt 1) {
        & $cmd[0] $cmd[1] @Arguments
    }
    else {
        & $cmd[0] @Arguments
    }

    if ($LASTEXITCODE -ne 0) {
        throw "Base Python command failed with exit code $LASTEXITCODE"
    }
}

function Ensure-ProjectVenv {
    $venvPath = Join-Path $projectRoot ".venv"
    $venvPython = Join-Path $venvPath "Scripts/python.exe"

    if (Test-Path $venvPath) {
        Write-Host "[tool] Mevcut .venv siliniyor..."
        Remove-Item -Recurse -Force $venvPath
    }

    Write-Host "[tool] Proje icin .venv olusturuluyor..."
    Invoke-BasePython -m venv .venv

    if (-not (Test-Path $venvPython)) {
        throw "Virtual environment olusturuldu ama python.exe bulunamadi: $venvPython"
    }

    return @($venvPython)
}

function Ensure-GccAvailable {
    $gcc = Get-Command gcc -ErrorAction SilentlyContinue
    if ($gcc) {
        return $gcc.Source
    }

    # Kurulum araci PATH'i degistirmis olabilecegi icin kabuk PATH'ini yenile.
    Refresh-PathFromSystem
    $gcc = Get-Command gcc -ErrorAction SilentlyContinue
    if ($gcc) {
        return $gcc.Source
    }

    $portableGcc = Get-PortableGccPath
    if ($portableGcc) {
        return $portableGcc
    }

    Write-Host "[tool] gcc bulunamadi. Otomatik kurulum deneniyor..."
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
        winget install --id BrechtSanders.WinLibs.POSIX.UCRT -e --accept-package-agreements --accept-source-agreements | Out-Null

        Refresh-PathFromSystem
        $gcc = Get-Command gcc -ErrorAction SilentlyContinue
        if ($gcc) {
            return $gcc.Source
        }
    }

    # Son yedek: yonetici izni gerektirmeyen portable gcc (project/tools altinda).
    return Install-PortableWinLibs
}

Write-Host "[1/5] Checking tools..."
$basePythonCmd = Ensure-PythonAvailable
$gccExe = Ensure-GccAvailable
$gccExe = @($gccExe) |
    Where-Object { $_ -is [string] -and -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path $_) } |
    Select-Object -First 1

if (-not $gccExe) {
    throw "gcc executable path resolve edilemedi. GCC kurulumunu kontrol edip setup.ps1'i tekrar calistirin."
}

if ($NoVenv) {
    $pythonCmd = $basePythonCmd
    Write-Host "[2/5] Virtual environment: devre disi (NoVenv)"
}
else {
    Write-Host "[2/5] Preparing project virtual environment..."
    $pythonCmd = Ensure-ProjectVenv
}

function Invoke-Python {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    $cmd = @($pythonCmd)

    if ($cmd.Length -gt 1) {
        & $cmd[0] $cmd[1] @Arguments
    }
    else {
        & $cmd[0] @Arguments
    }

    if ($LASTEXITCODE -ne 0) {
        throw "Python command failed with exit code $LASTEXITCODE"
    }
}

Write-Host "[3/5] Installing Python dependencies..."
Invoke-Python -m pip install -r requirements.txt

Write-Host "[4/5] Building C shared library..."
if (-not (Test-Path "build")) {
    New-Item -ItemType Directory -Path "build" | Out-Null
}

if ($env:OS -eq "Windows_NT") {
    & $gccExe -shared -O2 -Wall -o build/edge_detection.dll src/edge_detection.c -lm
    if ($LASTEXITCODE -ne 0) {
        throw "gcc build failed with exit code $LASTEXITCODE"
    }
    $libraryPath = "build/edge_detection.dll"
}
else {
    & $gccExe -shared -fPIC -O2 -Wall -o build/edge_detection.so src/edge_detection.c -lm
    if ($LASTEXITCODE -ne 0) {
        throw "gcc build failed with exit code $LASTEXITCODE"
    }
    $libraryPath = "build/edge_detection.so"
}

if (-not (Test-Path $libraryPath)) {
    throw "Build finished but library not found: $libraryPath"
}

Write-Host "[5/5] Running smoke test..."
$smokeTestPath = Join-Path "build" "_smoke_test.py"
$smokeTest = @'
import ctypes
import os
import platform

lib_name = "edge_detection.dll" if platform.system() == "Windows" else "edge_detection.so"
lib_path = os.path.join("build", lib_name)
ctypes.CDLL(lib_path)
print("Smoke test passed:", lib_path)
'@

Set-Content -Path $smokeTestPath -Value $smokeTest -Encoding ASCII
Invoke-Python $smokeTestPath
Remove-Item -Force $smokeTestPath

Write-Host "Setup complete."
Write-Host "Run application with:"
if ($NoVenv) {
    Write-Host "  python src/main.py"
}
else {
    Write-Host "  .\\.venv\\Scripts\\python.exe src/main.py"
}

if ($RunDemo) {
    Invoke-Python src/main.py
}
