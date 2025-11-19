# scout-block.ps1 - PowerShell implementation for blocking heavy directories
# Blocks: node_modules, __pycache__, .git/, dist/, build/
# Supports: Bash, Glob, Grep, Read tools

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

# Blocked pattern (regex) - matches directory names with or without slashes/spaces
$blockedPattern = '(^|/|\s)node_modules(/|$|\s)|(^|/|\s)__pycache__(/|$|\s)|(^|/|\s)\.git(/|$|\s)|(^|/|\s)dist(/|$|\s)|(^|/|\s)build(/|$|\s)'

# Check different tool parameter combinations
$paramsToCheck = @(
    $toolInput.command,      # Bash tool
    $toolInput.file_path,    # Read, Edit, Write tools
    $toolInput.path,         # Grep, Glob tools
    $toolInput.pattern       # Glob, Grep tools
)

# Check if any parameter matches blocked pattern
foreach ($param in $paramsToCheck) {
    if ($param -and ($param -is [string]) -and ($param -match $blockedPattern)) {
        Write-Error "ERROR: Blocked directory pattern (node_modules, __pycache__, .git/, dist/, build/)"
        exit 2
    }
}

# Allow command to proceed (exit 0)
exit 0
