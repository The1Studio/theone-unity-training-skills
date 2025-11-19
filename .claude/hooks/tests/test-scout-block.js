#!/usr/bin/env node

/**
 * Test script for scout-block.sh hook
 * Tests various tool inputs to verify blocking logic
 */

const { execSync } = require('child_process');
const path = require('path');

const testCases = [
  {
    name: 'Bash with node_modules',
    input: { tool_name: 'Bash', tool_input: { command: 'ls node_modules' } },
    expected: 'BLOCKED'
  },
  {
    name: 'Grep with node_modules path',
    input: { tool_name: 'Grep', tool_input: { pattern: 'test', path: 'node_modules' } },
    expected: 'BLOCKED'
  },
  {
    name: 'Glob with node_modules pattern',
    input: { tool_name: 'Glob', tool_input: { pattern: '**/node_modules/**' } },
    expected: 'BLOCKED'
  },
  {
    name: 'Read with node_modules file_path',
    input: { tool_name: 'Read', tool_input: { file_path: 'node_modules/package.json' } },
    expected: 'BLOCKED'
  },
  {
    name: 'Grep with safe path',
    input: { tool_name: 'Grep', tool_input: { pattern: 'test', path: 'src' } },
    expected: 'ALLOWED'
  },
  {
    name: 'Read with safe file_path',
    input: { tool_name: 'Read', tool_input: { file_path: 'src/index.js' } },
    expected: 'ALLOWED'
  }
];

console.log('Testing scout-block.sh hook...\n');

const scriptPath = path.join(__dirname, '..', 'scout-block.sh');
let passed = 0;
let failed = 0;

for (const test of testCases) {
  try {
    const input = JSON.stringify(test.input);
    const result = execSync(`bash "${scriptPath}"`, {
      input,
      encoding: 'utf-8',
      stdio: ['pipe', 'pipe', 'pipe']
    });

    const actual = 'ALLOWED';
    const success = actual === test.expected;

    if (success) {
      console.log(`✓ ${test.name}: ${actual}`);
      passed++;
    } else {
      console.log(`✗ ${test.name}: expected ${test.expected}, got ${actual}`);
      failed++;
    }
  } catch (error) {
    const actual = error.status === 2 ? 'BLOCKED' : 'ERROR';
    const success = actual === test.expected;

    if (success) {
      console.log(`✓ ${test.name}: ${actual}`);
      passed++;
    } else {
      console.log(`✗ ${test.name}: expected ${test.expected}, got ${actual}`);
      console.log(`  Error: ${error.stderr.toString().trim()}`);
      failed++;
    }
  }
}

console.log(`\nResults: ${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
