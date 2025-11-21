# Skills Installation Script for Windows (PowerShell)
# Installs all dependencies for Claude Code skills

param(
    [switch]$SkipChocolatey = $false,
    [switch]$Help = $false
)

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$VenvDir = Join-Path $ScriptDir ".venv"

# Colors for output
function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "===================================================" -ForegroundColor Blue
    Write-Host $Message -ForegroundColor Blue
    Write-Host "===================================================" -ForegroundColor Blue
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check if command exists
function Test-Command {
    param([string]$Command)
    try {
        if (Get-Command $Command -ErrorAction SilentlyContinue) {
            return $true
        }
    } catch {
        return $false
    }
    return $false
}

# Install Chocolatey
function Install-Chocolatey {
    if ($SkipChocolatey) {
        Write-Warning "Skipping Chocolatey installation (--SkipChocolatey flag)"
        return
    }

    if (Test-Command "choco") {
        Write-Success "Chocolatey already installed"
    } else {
        Write-Info "Installing Chocolatey package manager..."
        Write-Warning "This requires Administrator privileges"

        if (-not (Test-Administrator)) {
            Write-Error "Please run this script as Administrator to install Chocolatey"
            Write-Info "Right-click PowerShell and select 'Run as Administrator'"
            exit 1
        }

        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

        Write-Success "Chocolatey installed"
    }
}

# Install system dependencies
function Install-SystemDeps {
    Write-Header "Installing System Dependencies"

    # FFmpeg
    if (Test-Command "ffmpeg") {
        $ffmpegVersion = (ffmpeg -version 2>&1 | Select-Object -First 1)
        Write-Success "FFmpeg already installed ($ffmpegVersion)"
    } else {
        Write-Info "Installing FFmpeg..."
        if (Test-Command "choco") {
            choco install ffmpeg -y
            Write-Success "FFmpeg installed"
        } else {
            Write-Warning "FFmpeg not found. Please install manually from: https://ffmpeg.org/download.html"
            Write-Warning "Or run script as Administrator without --SkipChocolatey flag"
        }
    }

    # ImageMagick
    if (Test-Command "magick") {
        Write-Success "ImageMagick already installed"
    } else {
        Write-Info "Installing ImageMagick..."
        if (Test-Command "choco") {
            choco install imagemagick -y
            Write-Success "ImageMagick installed"
        } else {
            Write-Warning "ImageMagick not found. Please install manually from: https://imagemagick.org/script/download.php"
            Write-Warning "Or run script as Administrator without --SkipChocolatey flag"
        }
    }

    # Docker (optional)
    if (Test-Command "docker") {
        $dockerVersion = (docker --version)
        Write-Success "Docker already installed ($dockerVersion)"
    } else {
        Write-Warning "Docker not found. Skipping (optional)..."
        Write-Info "Install Docker from: https://docs.docker.com/desktop/install/windows-install/"
    }
}

# Install Node.js and npm packages
function Install-NodeDeps {
    Write-Header "Installing Node.js Dependencies"

    # Check Node.js
    if (Test-Command "node") {
        $nodeVersion = (node --version)
        Write-Success "Node.js already installed ($nodeVersion)"
    } else {
        Write-Info "Installing Node.js..."
        if (Test-Command "choco") {
            choco install nodejs -y
            Write-Success "Node.js installed"
        } else {
            Write-Error "Node.js not found. Please install manually from: https://nodejs.org/"
            Write-Warning "Or run script as Administrator without --SkipChocolatey flag"
            exit 1
        }
    }

    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    # Install global npm packages
    Write-Info "Installing global npm packages..."

    $npmPackages = @(
        "rmbg-cli",
        "pnpm",
        "wrangler",
        "repomix"
    )

    foreach ($package in $npmPackages) {
        try {
            $installed = npm list -g $package 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Success "$package already installed"
            } else {
                Write-Info "Installing $package..."
                npm install -g $package
                Write-Success "$package installed"
            }
        } catch {
            Write-Info "Installing $package..."
            npm install -g $package
            Write-Success "$package installed"
        }
    }

    # Install local npm packages for skills
    Write-Info "Installing local npm packages for skills..."

    # chrome-devtools
    $chromeDevToolsPath = Join-Path $ScriptDir "chrome-devtools\scripts"
    $chromePackageJson = Join-Path $chromeDevToolsPath "package.json"
    if ((Test-Path $chromeDevToolsPath) -and (Test-Path $chromePackageJson)) {
        Write-Info "Installing chrome-devtools dependencies..."
        Push-Location $chromeDevToolsPath
        npm install --quiet
        Pop-Location
        Write-Success "chrome-devtools dependencies installed"
    }

    # sequential-thinking
    $seqThinkingPath = Join-Path $ScriptDir "sequential-thinking"
    $seqPackageJson = Join-Path $seqThinkingPath "package.json"
    if ((Test-Path $seqThinkingPath) -and (Test-Path $seqPackageJson)) {
        Write-Info "Installing sequential-thinking dependencies..."
        Push-Location $seqThinkingPath
        npm install --quiet
        Pop-Location
        Write-Success "sequential-thinking dependencies installed"
    }

    # mcp-management
    $mcpManagementPath = Join-Path $ScriptDir "mcp-management\scripts"
    $mcpPackageJson = Join-Path $mcpManagementPath "package.json"
    if ((Test-Path $mcpManagementPath) -and (Test-Path $mcpPackageJson)) {
        Write-Info "Installing mcp-management dependencies..."
        Push-Location $mcpManagementPath
        npm install --quiet
        Pop-Location
        Write-Success "mcp-management dependencies installed"
    }

    # Optional: Shopify CLI (ask user)
    $shopifyPath = Join-Path $ScriptDir "shopify"
    if (Test-Path $shopifyPath) {
        $confirmation = Read-Host "Install Shopify CLI for Shopify skill? (y/N)"
        if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
            Write-Info "Installing Shopify CLI..."
            npm install -g @shopify/cli @shopify/theme
            Write-Success "Shopify CLI installed"
        }
    }
}

# Setup Python virtual environment
function Setup-PythonEnv {
    Write-Header "Setting Up Python Environment"

    # Check Python
    if (Test-Command "python") {
        $pythonVersion = (python --version)
        Write-Success "Python found ($pythonVersion)"
    } else {
        Write-Error "Python not found. Please install Python 3.7+ from: https://www.python.org/downloads/"
        Write-Info "Make sure to check 'Add Python to PATH' during installation"
        exit 1
    }

    # Create virtual environment
    if (Test-Path $VenvDir) {
        Write-Success "Virtual environment already exists at $VenvDir"
    } else {
        Write-Info "Creating virtual environment at $VenvDir..."
        python -m venv $VenvDir
        Write-Success "Virtual environment created"
    }

    # Activate and install packages
    Write-Info "Activating virtual environment..."
    $activateScript = Join-Path $VenvDir "Scripts\Activate.ps1"

    if (Test-Path $activateScript) {
        & $activateScript
    } else {
        Write-Error "Failed to find activation script at $activateScript"
        exit 1
    }

    # Upgrade pip
    Write-Info "Upgrading pip..."
    python -m pip install --upgrade pip --quiet

    # Install dependencies from all skills' requirements.txt files
    Write-Info "Installing Python dependencies from all skills..."

    $installedCount = 0
    Get-ChildItem -Path $ScriptDir -Directory | ForEach-Object {
        $skillName = $_.Name

        # Skip .venv and document-skills
        if ($skillName -eq ".venv" -or $skillName -eq "document-skills") {
            return
        }

        # Install main requirements.txt
        $requirementsPath = Join-Path $_.FullName "scripts\requirements.txt"
        if (Test-Path $requirementsPath) {
            Write-Info "Installing $skillName dependencies..."
            try {
                pip install -r $requirementsPath --quiet 2>$null
                $installedCount++
            } catch {
                Write-Warning "Some $skillName dependencies failed to install (may be optional)"
            }
        }

        # Install test requirements.txt
        $testRequirementsPath = Join-Path $_.FullName "scripts\tests\requirements.txt"
        if (Test-Path $testRequirementsPath) {
            try {
                pip install -r $testRequirementsPath --quiet 2>$null
            } catch {
                Write-Warning "Some $skillName test dependencies failed to install (may be optional)"
            }
        }
    }

    if ($installedCount -eq 0) {
        Write-Warning "No skill requirements.txt files found"
    } else {
        Write-Success "Installed Python dependencies from $installedCount skills"
    }

    deactivate
}

# Verify installations
function Test-Installations {
    Write-Header "Verifying Installations"

    $tools = @{
        "ffmpeg" = "FFmpeg"
        "magick" = "ImageMagick"
        "node" = "Node.js"
        "npm" = "npm"
    }

    foreach ($tool in $tools.GetEnumerator()) {
        if (Test-Command $tool.Key) {
            Write-Success "$($tool.Value) is available"
        } else {
            Write-Warning "$($tool.Value) is not available"
        }
    }

    $npmPackages = @("rmbg", "pnpm", "wrangler", "repomix")
    foreach ($package in $npmPackages) {
        if (Test-Command $package) {
            Write-Success "$package CLI is available"
        } else {
            Write-Warning "$package CLI is not available"
        }
    }

    # Check Python packages
    if (Test-Path $VenvDir) {
        $activateScript = Join-Path $VenvDir "Scripts\Activate.ps1"
        & $activateScript

        try {
            python -c "import google.genai" 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "google-genai Python package is available"
            } else {
                Write-Warning "google-genai Python package is not available"
            }
        } catch {
            Write-Warning "google-genai Python package is not available"
        }

        deactivate
    }
}

# Print usage instructions
function Show-Usage {
    Write-Header "Installation Complete!"

    Write-Host "To use the Python virtual environment:" -ForegroundColor Green
    Write-Host "  .\.claude\skills\.venv\Scripts\Activate.ps1"
    Write-Host ""
    Write-Host "To verify installations:" -ForegroundColor Green
    Write-Host "  ffmpeg -version"
    Write-Host "  magick -version"
    Write-Host "  rmbg --version"
    Write-Host "  node --version"
    Write-Host ""
    Write-Host "To run tests:" -ForegroundColor Green
    Write-Host "  .\.claude\skills\.venv\Scripts\Activate.ps1"
    Write-Host "  cd .claude\skills\<skill-name>\scripts"
    Write-Host "  pytest tests\ -v"
    Write-Host ""
    Write-Host "Environment variables:" -ForegroundColor Green
    Write-Host "  Create .claude\skills\.env for shared config"
    Write-Host "  Create .claude\skills\<skill-name>\.env for skill-specific config"
    Write-Host ""
    Write-Host "For more information, see:" -ForegroundColor Blue
    Write-Host "  .claude\skills\INSTALLATION.md"
    Write-Host ""
}

# Show help
function Show-Help {
    Write-Host "Claude Code Skills Installation Script for Windows"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\install.ps1 [Options]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -SkipChocolatey    Skip Chocolatey installation (if already installed or not needed)"
    Write-Host "  -Help              Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\install.ps1"
    Write-Host "  .\install.ps1 -SkipChocolatey"
    Write-Host ""
    Write-Host "Requirements:"
    Write-Host "  - Administrator privileges (for Chocolatey installation)"
    Write-Host "  - PowerShell 5.1 or higher"
    Write-Host ""
}

# Main installation flow
function Main {
    if ($Help) {
        Show-Help
        exit 0
    }

    Clear-Host
    Write-Header "Claude Code Skills Installation (Windows)"
    Write-Info "Script directory: $ScriptDir"
    Write-Host ""

    # Confirm installation
    $confirmation = Read-Host "This will install system packages and Node.js dependencies. Continue? (y/N)"
    if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
        Write-Warning "Installation cancelled"
        exit 0
    }

    try {
        Install-Chocolatey
        Install-SystemDeps
        Install-NodeDeps
        Setup-PythonEnv
        Test-Installations
        Show-Usage
    } catch {
        Write-Error "Installation failed: $_"
        exit 1
    }
}

# Run main function
Main
