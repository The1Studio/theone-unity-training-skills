#!/bin/bash
# scout-block.sh - Bash implementation for blocking heavy directories
# Blocks: node_modules, __pycache__, .git/, dist/, build/
#
# Blocking Rules:
# - File paths: Blocks any file_path/path/pattern containing blocked directories
# - Bash commands: Blocks directory access (cd, ls, cat, etc.) but ALLOWS build commands
#   - Blocked: cd node_modules, ls build/, cat dist/file.js
#   - Allowed: npm build, pnpm build, yarn build, npm run build

# Read stdin
INPUT=$(cat)

# Validate input not empty
if [ -z "$INPUT" ]; then
  echo "ERROR: Empty input" >&2
  exit 2
fi

# Parse JSON and extract all relevant parameters using Node.js
CHECK_RESULT=$(echo "$INPUT" | node -e "
try {
  const input = require('fs').readFileSync(0, 'utf-8');
  const data = JSON.parse(input);

  if (!data.tool_input || typeof data.tool_input !== 'object') {
    console.error('ERROR: Invalid JSON structure');
    process.exit(2);
  }

  const toolInput = data.tool_input;

  // Pattern for directory paths (used for file_path, path, pattern)
  const blockedDirPattern = /(^|\/|\s)node_modules(\/|$|\s)|(^|\/|\s)__pycache__(\/|$|\s)|(^|\/|\s)\.git(\/|$|\s)|(^|\/|\s)dist(\/|$|\s)|(^|\/|\s)build(\/|$|\s)/;

  // Pattern for Bash commands - only block directory access, not build commands
  // Blocks: cd node_modules, ls build/, cat dist/file.js
  // Allows: npm build, pnpm build, yarn build, npm run build
  const blockedBashPattern = /(cd\s+|ls\s+|cat\s+|rm\s+|cp\s+|mv\s+|find\s+)(node_modules|__pycache__|\.git|dist|build)(\/|$|\s)|(\s|^|\/)node_modules\/|(\s|^|\/)__pycache__\/|(\s|^|\/)\.git\/|(\s|^|\/)dist\/|(\s|^|\/)build\//;

  // Check file path parameters (strict blocking)
  const fileParams = [
    toolInput.file_path,    // Read, Edit, Write tools
    toolInput.path,         // Grep, Glob tools
    toolInput.pattern       // Glob, Grep tools
  ];

  for (const param of fileParams) {
    if (param && typeof param === 'string' && blockedDirPattern.test(param)) {
      console.log('BLOCKED');
      process.exit(0);
    }
  }

  // Check Bash command (selective blocking - only directory access)
  if (toolInput.command && typeof toolInput.command === 'string') {
    if (blockedBashPattern.test(toolInput.command)) {
      console.log('BLOCKED');
      process.exit(0);
    }
  }

  console.log('ALLOWED');
} catch (error) {
  console.error('ERROR: JSON parse failed');
  process.exit(2);
}
")

# Check if parsing failed
if [ $? -ne 0 ]; then
  exit 2
fi

# Check result
if [ "$CHECK_RESULT" = "BLOCKED" ]; then
  echo "ERROR: Blocked directory pattern (node_modules, __pycache__, .git/, dist/, build/)" >&2
  exit 2
fi

# Allow command (exit 0)
exit 0