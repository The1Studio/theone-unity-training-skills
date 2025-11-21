# scout-block.ps1 - PowerShell implementation for blocking heavy directories
# Blocks: node_modules, __pycache__, .git/, dist/, build/
#
# Blocking Rules:
# - File paths: Blocks any file_path/path/pattern containing blocked directories
# - Bash commands: Blocks directory access (cd, ls, cat, etc.) but ALLOWS build commands
#   - Blocked: cd node_modules, ls build/, cat dist/file.js
#   - Allowed: npm build, pnpm build, yarn build, npm run build

# Read JSON input from stdin
$inputJson = $input | Out-String

# Validate input not empty
if ([string]::IsNullOrWhiteSpace($inputJson)) {
    Write-Error "ERROR: Empty input"
    exit 2
}

# Parse JSON (PowerShell 5.1+ compatible)
try {
    $hookData = $inputJson | ConvertFrom-Json
} catch {
    Write-Error "ERROR: Failed to parse JSON input"
    exit 2
}

# Validate JSON structure
if (-not $hookData.tool_input) {
    Write-Error "ERROR: Invalid JSON structure - missing tool_input"
    exit 2
}

# Extract tool input
$toolInput = $hookData.tool_input

# Pattern for directory paths (used for file_path, path, pattern)
$blockedDirPattern = '(^|/|\s)node_modules(/|$|\s)|(^|/|\s)__pycache__(/|$|\s)|(^|/|\s)\.git(/|$|\s)|(^|/|\s)dist(/|$|\s)|(^|/|\s)build(/|$|\s)'

# Pattern for Bash commands - only block directory access, not build commands
# Blocks: cd node_modules, ls build/, cat dist/file.js
# Allows: npm build, pnpm build, yarn build, npm run build
$blockedBashPattern = '(cd\s+|ls\s+|cat\s+|rm\s+|cp\s+|mv\s+|find\s+)(node_modules|__pycache__|\.git|dist|build)(/|$|\s)|(\s|^|/)node_modules/|(\s|^|/)__pycache__/|(\s|^|/)\.git/|(\s|^|/)dist/|(\s|^|/)build/'

# Check file path parameters (strict blocking)
$fileParams = @(
    $toolInput.file_path,    # Read, Edit, Write tools
    $toolInput.path,         # Grep, Glob tools
    $toolInput.pattern       # Glob, Grep tools
)

foreach ($param in $fileParams) {
    if ($param -and ($param -is [string]) -and ($param -match $blockedDirPattern)) {
        Write-Error "ERROR: Blocked directory pattern (node_modules, __pycache__, .git/, dist/, build/)"
        exit 2
    }
}

# Check Bash command (selective blocking - only directory access)
if ($toolInput.command -and ($toolInput.command -is [string])) {
    if ($toolInput.command -match $blockedBashPattern) {
        Write-Error "ERROR: Blocked directory pattern (node_modules, __pycache__, .git/, dist/, build/)"
        exit 2
    }
}

# Allow command to proceed (exit 0)
exit 0
