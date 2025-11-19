#!/bin/bash
# scout-block.sh - Bash implementation for blocking heavy directories
# Blocks: node_modules, __pycache__, .git/, dist/, build/
# Supports: Bash, Glob, Grep, Read tools

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
  const blocked = /(^|\/|\s)node_modules(\/|$|\s)|(^|\/|\s)__pycache__(\/|$|\s)|(^|\/|\s)\.git(\/|$|\s)|(^|\/|\s)dist(\/|$|\s)|(^|\/|\s)build(\/|$|\s)/;

  // Check different tool parameter combinations
  const checkParams = [
    toolInput.command,      // Bash tool
    toolInput.file_path,    // Read, Edit, Write tools
    toolInput.path,         // Grep, Glob tools
    toolInput.pattern       // Glob, Grep tools
  ];

  // Check if any parameter matches blocked pattern
  for (const param of checkParams) {
    if (param && typeof param === 'string' && blocked.test(param)) {
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