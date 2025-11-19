# Quality & Hygiene - React Native TypeScript Standards

This document covers code quality and hygiene practices for React Native with TypeScript. These are **PRIORITY 1** rules that must be enforced BEFORE any other patterns.

## 🔴 CRITICAL RULES (Zero Tolerance)

### 1. TypeScript Strict Mode

**Rule:** Enable all strict compiler options.

**tsconfig.json Configuration:**

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "alwaysStrict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true
  }
}
```

**Why:** Strict mode catches entire classes of bugs at compile time.

```typescript
// ❌ BAD: No strict mode, any types everywhere
function getUserName(user) {
  return user.name;
}

// ✅ GOOD: Strict mode, proper types
function getUserName(user: User): string {
  return user.name;
}
```

### 2. ESLint + Prettier Configuration

**Rule:** Enforce linting and formatting rules automatically.

**.eslintrc.js:**

```javascript
module.exports = {
  root: true,
  extends: [
    '@react-native-community',
    'plugin:@typescript-eslint/recommended',
    'plugin:react-hooks/recommended',
    'prettier',
  ],
  plugins: ['@typescript-eslint', 'react-hooks', 'import'],
  rules: {
    '@typescript-eslint/no-explicit-any': 'error',
    '@typescript-eslint/explicit-function-return-type': 'warn',
    'react-hooks/rules-of-hooks': 'error',
    'react-hooks/exhaustive-deps': 'warn',
    'import/order': [
      'error',
      {
        groups: [
          'builtin',
          'external',
          'internal',
          'parent',
          'sibling',
          'index',
        ],
        'newlines-between': 'always',
        alphabetize: { order: 'asc' },
      },
    ],
    'no-console': ['warn', { allow: ['warn', 'error'] }],
  },
};
```

**.prettierrc.js:**

```javascript
module.exports = {
  semi: true,
  trailingComma: 'all',
  singleQuote: true,
  printWidth: 100,
  tabWidth: 2,
  arrowParens: 'always',
};
```

**Why:** Consistent code style and automatic error prevention.

### 3. No `any` Types

**Rule:** NEVER use `any` type. Use proper types or `unknown`.

```typescript
// ❌ BAD: any type defeats TypeScript
function processData(data: any) {
  return data.value; // No type safety!
}

// ❌ BAD: any in arrays/objects
const items: any[] = [];
const config: { [key: string]: any } = {};

// ✅ GOOD: Proper types
interface Data {
  value: string;
}

function processData(data: Data): string {
  return data.value;
}

// ✅ GOOD: Generic types
function processItems<T>(items: T[]): T[] {
  return items.filter(Boolean);
}

// ✅ GOOD: unknown for truly unknown data
function parseJSON(json: string): unknown {
  return JSON.parse(json);
}

// Then narrow with type guards
const data = parseJSON(jsonString);
if (isUser(data)) {
  console.log(data.name); // Safe!
}
```

### 4. Path Aliases Configuration

**Rule:** Use `@/` for `src/` imports, never relative paths.

**tsconfig.json:**

```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@/components/*": ["src/components/*"],
      "@/screens/*": ["src/screens/*"],
      "@/utils/*": ["src/utils/*"],
      "@/hooks/*": ["src/hooks/*"],
      "@/stores/*": ["src/stores/*"],
      "@/types/*": ["src/types/*"],
      "@/api/*": ["src/api/*"]
    }
  }
}
```

**babel.config.js:**

```javascript
module.exports = {
  plugins: [
    [
      'module-resolver',
      {
        root: ['./src'],
        alias: {
          '@': './src',
          '@/components': './src/components',
          '@/screens': './src/screens',
          '@/utils': './src/utils',
          '@/hooks': './src/hooks',
          '@/stores': './src/stores',
          '@/types': './src/types',
          '@/api': './src/api',
        },
      },
    ],
  ],
};
```

**Usage:**

```typescript
// ❌ BAD: Relative imports
import { Button } from '../../../components/Button';
import { useAuth } from '../../../../hooks/useAuth';
import { User } from '../../../types/user';

// ✅ GOOD: Path aliases
import { Button } from '@/components/Button';
import { useAuth } from '@/hooks/useAuth';
import { User } from '@/types/user';
```

### 5. Error Handling - Throw, Never Suppress

**Rule:** ALWAYS throw errors. NEVER suppress with try/catch + console.log.

```typescript
// ❌ BAD: Suppressing errors
async function fetchUser(id: string) {
  try {
    const response = await api.get(`/users/${id}`);
    return response.data;
  } catch (error) {
    console.log('Error fetching user:', error); // Suppressed!
    return null; // Hides the problem
  }
}

// ❌ BAD: Silent failures
function parseJSON(json: string) {
  try {
    return JSON.parse(json);
  } catch {
    return {}; // Silent failure!
  }
}

// ✅ GOOD: Throw errors, let error boundary handle
async function fetchUser(id: string): Promise<User> {
  const response = await api.get(`/users/${id}`);

  if (!response.ok) {
    throw new Error(`Failed to fetch user: ${response.statusText}`);
  }

  return response.data;
}

// ✅ GOOD: Rethrow with context
async function loadUserProfile(id: string): Promise<UserProfile> {
  try {
    const user = await fetchUser(id);
    return transformToProfile(user);
  } catch (error) {
    throw new Error(`Failed to load profile for user ${id}`, { cause: error });
  }
}

// ✅ GOOD: Error boundary catches at top level
export function App() {
  return (
    <ErrorBoundary fallback={<ErrorScreen />}>
      <UserProfile userId="123" />
    </ErrorBoundary>
  );
}
```

### 6. Structured Logging

**Rule:** Use logger utility with structured data, not raw console.log.

**logger.ts:**

```typescript
// src/utils/logger.ts
type LogLevel = 'debug' | 'info' | 'warn' | 'error';

interface LogContext {
  [key: string]: unknown;
}

class Logger {
  private isDevelopment = __DEV__;

  debug(message: string, context?: LogContext): void {
    if (this.isDevelopment) {
      console.log('[DEBUG]', message, context);
    }
  }

  info(message: string, context?: LogContext): void {
    console.log('[INFO]', message, context);
  }

  warn(message: string, context?: LogContext): void {
    console.warn('[WARN]', message, context);
  }

  error(message: string, error?: Error, context?: LogContext): void {
    console.error('[ERROR]', message, error, context);
    // Could send to error tracking service here
  }
}

export const logger = new Logger();
```

**Usage:**

```typescript
// ❌ BAD: Raw console.log
console.log('User logged in');
console.log('User:', user);
console.log('Fetching data for', userId);

// ✅ GOOD: Structured logging
import { logger } from '@/utils/logger';

logger.info('User logged in', { userId: user.id, timestamp: Date.now() });
logger.debug('Fetching user data', { userId });

// ✅ GOOD: Error logging
try {
  await fetchUser(userId);
} catch (error) {
  logger.error('Failed to fetch user', error as Error, { userId });
  throw error;
}
```

### 7. Error Boundaries

**Rule:** Wrap components with ErrorBoundary to catch runtime errors.

**ErrorBoundary.tsx:**

```typescript
// src/components/ErrorBoundary.tsx
import React, { Component, ReactNode } from 'react';
import { View, Text, StyleSheet, Button } from 'react-native';

import { logger } from '@/utils/logger';

interface ErrorBoundaryProps {
  children: ReactNode;
  fallback?: ReactNode;
  onError?: (error: Error, errorInfo: React.ErrorInfo) => void;
}

interface ErrorBoundaryState {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<ErrorBoundaryProps, ErrorBoundaryState> {
  constructor(props: ErrorBoundaryProps) {
    super(props);
    this.state = {
      hasError: false,
      error: null,
    };
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return {
      hasError: true,
      error,
    };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo): void {
    logger.error('Error boundary caught error', error, {
      componentStack: errorInfo.componentStack,
    });

    this.props.onError?.(error, errorInfo);
  }

  private handleReset = (): void => {
    this.setState({ hasError: false, error: null });
  };

  render(): ReactNode {
    if (this.state.hasError) {
      if (this.props.fallback) {
        return this.props.fallback;
      }

      return (
        <View style={styles.container}>
          <Text style={styles.title}>Something went wrong</Text>
          <Text style={styles.message}>{this.state.error?.message}</Text>
          <Button title="Try Again" onPress={this.handleReset} />
        </View>
      );
    }

    return this.props.children;
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 16,
  },
  title: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  message: {
    fontSize: 14,
    color: '#666',
    marginBottom: 16,
  },
});
```

**Usage:**

```typescript
// ✅ GOOD: Wrap entire app
export function App() {
  return (
    <ErrorBoundary>
      <AppNavigator />
    </ErrorBoundary>
  );
}

// ✅ GOOD: Wrap critical sections
export function UserProfileScreen() {
  return (
    <ErrorBoundary fallback={<ProfileErrorFallback />}>
      <UserProfile />
    </ErrorBoundary>
  );
}
```

### 8. Consistent Import Order

**Rule:** React first, then libraries, then local imports.

```typescript
// ✅ GOOD: Consistent import order

// 1. React imports first
import React, { useCallback, useEffect, useState } from 'react';

// 2. React Native core
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';

// 3. Third-party libraries (alphabetical)
import { useNavigation } from '@react-navigation/native';
import { create } from 'zustand';

// 4. Local imports with path aliases (alphabetical)
import { Button } from '@/components/Button';
import { useAuth } from '@/hooks/useAuth';
import { User } from '@/types/user';
import { logger } from '@/utils/logger';

// 5. Relative imports (avoid if possible)
import { ProfileHeader } from './ProfileHeader';
```

### 9. File Naming Conventions

**Rule:** kebab-case for files, PascalCase for components.

```
✅ GOOD file structure:

src/
├── components/
│   ├── button.tsx          # Generic component
│   ├── user-card.tsx       # Component name
│   └── profile-header.tsx
├── screens/
│   ├── home-screen.tsx
│   ├── profile-screen.tsx
│   └── settings-screen.tsx
├── hooks/
│   ├── use-auth.ts
│   ├── use-user.ts
│   └── use-navigation.ts
├── utils/
│   ├── logger.ts
│   ├── api-client.ts
│   └── date-formatter.ts
├── stores/
│   ├── user-store.ts
│   ├── settings-store.ts
│   └── cart-store.ts
└── types/
    ├── user.ts
    ├── product.ts
    └── api.ts

❌ BAD file names:
- UserCard.tsx (PascalCase for files)
- user_card.tsx (snake_case)
- profileScreen.tsx (camelCase)
- useAuth.ts (should be use-auth.ts)
```

**Component File Structure:**

```typescript
// user-card.tsx - file name is kebab-case
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

// Component name is PascalCase
export const UserCard: React.FC<UserCardProps> = ({ user }) => {
  return (
    <View style={styles.container}>
      <Text style={styles.name}>{user.name}</Text>
    </View>
  );
};

interface UserCardProps {
  user: User;
}

const styles = StyleSheet.create({
  container: { padding: 16 },
  name: { fontSize: 16 },
});
```

### 10. No Inline Styles in JSX

**Rule:** Define styles outside component or use StyleSheet.create().

```typescript
// ❌ BAD: Inline styles in JSX
export const UserCard: React.FC<Props> = ({ name }) => {
  return (
    <View style={{ padding: 16, backgroundColor: '#fff' }}>
      <Text style={{ fontSize: 18, fontWeight: 'bold' }}>{name}</Text>
    </View>
  );
};

// ❌ BAD: Object literals in render
export const UserCard: React.FC<Props> = ({ name }) => {
  const containerStyle = { padding: 16, backgroundColor: '#fff' };

  return (
    <View style={containerStyle}>
      <Text>{name}</Text>
    </View>
  );
};

// ✅ GOOD: StyleSheet.create() outside component
const styles = StyleSheet.create({
  container: {
    padding: 16,
    backgroundColor: '#fff',
  },
  name: {
    fontSize: 18,
    fontWeight: 'bold',
  },
});

export const UserCard: React.FC<Props> = ({ name }) => {
  return (
    <View style={styles.container}>
      <Text style={styles.name}>{name}</Text>
    </View>
  );
};

// ✅ GOOD: Dynamic styles with array syntax
export const UserCard: React.FC<Props> = ({ name, isActive }) => {
  return (
    <View style={[styles.container, isActive && styles.active]}>
      <Text style={styles.name}>{name}</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 16,
    backgroundColor: '#fff',
  },
  active: {
    borderWidth: 2,
    borderColor: '#007AFF',
  },
  name: {
    fontSize: 18,
    fontWeight: 'bold',
  },
});
```

## Complete Quality Checklist

Before committing ANY React Native code, verify:

- [ ] TypeScript strict mode enabled in tsconfig.json
- [ ] ESLint + Prettier configured and passing
- [ ] No `any` types used (check with ESLint rule)
- [ ] Path aliases (@/) configured in tsconfig + babel
- [ ] Errors are thrown, not suppressed
- [ ] Logger utility used instead of raw console.log
- [ ] Error boundaries wrap components
- [ ] Imports follow order: React → libraries → local
- [ ] Files use kebab-case, components use PascalCase
- [ ] Styles use StyleSheet.create(), no inline objects

## Quality Enforcement Tools

**package.json scripts:**

```json
{
  "scripts": {
    "lint": "eslint . --ext .ts,.tsx --max-warnings 0",
    "lint:fix": "eslint . --ext .ts,.tsx --fix",
    "format": "prettier --write \"src/**/*.{ts,tsx,json}\"",
    "format:check": "prettier --check \"src/**/*.{ts,tsx,json}\"",
    "type-check": "tsc --noEmit",
    "validate": "npm run type-check && npm run lint && npm run format:check"
  }
}
```

**Pre-commit hook (husky):**

```bash
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

npm run type-check
npm run lint
npm run format:check
```

## Common Quality Violations

### Violation 1: any Types Everywhere

```typescript
// ❌ CRITICAL: Defeats TypeScript entirely
function handlePress(data: any) {
  console.log(data.value);
}

const items: any[] = [];

// ✅ FIXED: Proper types
interface Data {
  value: string;
}

function handlePress(data: Data): void {
  console.log(data.value);
}

const items: Item[] = [];
```

### Violation 2: Suppressed Errors

```typescript
// ❌ CRITICAL: Hides failures
try {
  await api.post('/users', userData);
} catch (error) {
  console.log('Error:', error); // Suppressed!
}

// ✅ FIXED: Throw errors
try {
  await api.post('/users', userData);
} catch (error) {
  throw new Error('Failed to create user', { cause: error });
}
```

### Violation 3: No Import Structure

```typescript
// ❌ BAD: Random import order
import { User } from '../types/user';
import React from 'react';
import { useAuth } from '../../hooks/useAuth';
import { View } from 'react-native';

// ✅ GOOD: Structured imports
import React from 'react';
import { View } from 'react-native';

import { useAuth } from '@/hooks/useAuth';
import { User } from '@/types/user';
```

### Violation 4: Inline Styles Performance

```typescript
// ❌ CRITICAL: Creates new object every render
{users.map(user => (
  <View style={{ padding: 16, backgroundColor: '#fff' }}>
    <Text>{user.name}</Text>
  </View>
))}

// ✅ FIXED: StyleSheet.create() once
const styles = StyleSheet.create({
  card: { padding: 16, backgroundColor: '#fff' },
});

{users.map(user => (
  <View style={styles.card}>
    <Text>{user.name}</Text>
  </View>
))}
```

## Conclusion

Code quality and hygiene are **PRIORITY 1**. These rules must be enforced BEFORE considering any architectural patterns or optimizations. Use automated tools (ESLint, Prettier, TypeScript) to enforce these rules at development time, not in code review.
