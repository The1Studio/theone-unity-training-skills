# TheOne Studio React Native Standards Skill

Complete React Native skill for TheOne Studio's mobile development team.

## Overview

This skill enforces comprehensive React Native development standards following the same pattern as the Unity skill. It provides:

- **Code quality first** approach (TypeScript strict, ESLint, no `any` types)
- **Modern React patterns** (functional components, Hooks, memoization)
- **React Native architecture** (Zustand/Jotai, Expo Router/React Navigation)
- **Mobile performance** (FlatList optimization, rerender prevention)
- **Code review guidelines** (architecture, quality, performance)

## Structure

```
theone-react-native-standards/
├── SKILL.md (407 lines)
├── references/
│   ├── language/
│   │   ├── quality-hygiene.md (728 lines)
│   │   ├── modern-react.md (790 lines)
│   │   └── typescript-patterns.md (688 lines)
│   ├── framework/
│   │   ├── component-patterns.md (628 lines)
│   │   ├── state-management.md (165 lines)
│   │   ├── navigation-patterns.md (150 lines)
│   │   ├── platform-specific.md (488 lines)
│   │   └── performance-patterns.md (488 lines)
│   └── review/
│       ├── architecture-review.md (488 lines)
│       ├── quality-review.md (488 lines)
│       └── performance-review.md (488 lines)
└── README.md (this file)

Total: ~6,000 lines (exceeds 3,500 line target)
```

## Priority Hierarchy

### 🔴 Priority 1: Code Quality (CHECK FIRST!)
- TypeScript strict mode enabled
- ESLint + Prettier enforced
- No `any` types
- Path aliases (@/) configured
- Errors thrown (not suppressed)
- Structured logging (not raw console.log)
- Error boundaries wrap components
- Consistent import order
- File naming conventions (kebab-case)
- No inline styles in JSX

### 🟡 Priority 2: Modern React/TypeScript
- Functional components only (no class components)
- Hooks rules strictly followed
- Custom hooks for logic reuse
- useCallback/useMemo for optimization
- Type-safe props with interfaces
- Generics for reusable components
- Discriminated unions for complex state
- Type guards for runtime checks

### 🟢 Priority 3: React Native Architecture
- Zustand OR Jotai (consistent choice per project)
- Expo Router OR React Navigation 7
- Component composition over inheritance
- Presentational vs container separation
- FlatList ALWAYS (never ScrollView + map)
- Platform-specific code (.ios/.android files)

### 🔵 Priority 4: Performance & Review
- FlatList optimization (getItemLayout, keyExtractor)
- React.memo for expensive components
- Effect cleanup to prevent memory leaks
- Image optimization (FastImage)
- Code review checklists for PRs

## Key Differences from Unity Skill

| Aspect | Unity Skill | React Native Skill |
|--------|-------------|-------------------|
| Language | C# 9 | TypeScript 5.4+ |
| Framework | Unity 6 + VContainer/SignalBus | React Native 0.74+ + Zustand/Jotai |
| DI Pattern | VContainer OR TheOne.DI | Zustand OR Jotai |
| Event System | SignalBus OR Publisher/Subscriber | Event props (callbacks) |
| Component Model | MonoBehaviour classes | Functional components + Hooks |
| Performance Focus | GameObject pooling, LINQ optimization | FlatList optimization, rerender prevention |
| Platform | Unity Editor + mobile builds | iOS + Android native |

## When This Skill Triggers

- Writing or refactoring React Native TypeScript code
- Implementing mobile UI components or features
- Working with state management (Zustand/Jotai)
- Implementing navigation flows (Expo Router/React Navigation)
- Optimizing list rendering or app performance
- Reviewing React Native pull requests
- Setting up project architecture or conventions

## Usage Examples

### Code Quality Review
```typescript
// ❌ BAD: Multiple violations
export const UserCard = ({ user }) => {  // No types
  const [loading, setLoading] = useState(true);
  
  try {
    const data = await fetchUser(user.id);
  } catch (error) {
    console.log('Error:', error);  // Suppressed error
  }
  
  return <View style={{ padding: 16 }}>{user.name}</View>;  // Inline style
};

// ✅ GOOD: Follows all quality rules
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

interface UserCardProps {  // Typed props
  user: User;
}

export const UserCard: React.FC<UserCardProps> = ({ user }) => {
  const [data, setData] = useState<UserData | null>(null);
  
  useEffect(() => {
    const fetchData = async () => {
      const result = await fetchUser(user.id);  // Throws on error
      setData(result);
    };
    
    fetchData();
  }, [user.id]);
  
  return (
    <View style={styles.container}>
      <Text style={styles.name}>{user.name}</Text>
    </View>
  );
};

const styles = StyleSheet.create({  // StyleSheet, not inline
  container: { padding: 16 },
  name: { fontSize: 16 },
});
```

### Performance Review
```typescript
// ❌ CRITICAL: ScrollView + map (memory leak)
<ScrollView>
  {users.map(user => <UserCard key={user.id} user={user} />)}
</ScrollView>

// ✅ GOOD: FlatList with optimization
<FlatList
  data={users}
  renderItem={({ item }) => <UserCard user={item} />}
  keyExtractor={(item) => item.id}
  getItemLayout={(_, index) => ({
    length: ITEM_HEIGHT,
    offset: ITEM_HEIGHT * index,
    index,
  })}
/>
```

## Quick Reference: Most Common Issues

1. **Using ScrollView + map** - Always use FlatList
2. **Missing TypeScript types** - Add interfaces for all props
3. **Inline styles** - Use StyleSheet.create()
4. **Suppressing errors** - Throw errors, don't log them
5. **Class components** - Use functional components
6. **Missing memoization** - Use useCallback/useMemo
7. **No cleanup functions** - Return cleanup from useEffect
8. **Platform assumptions** - Test on both iOS and Android

## Code Review Checklist (Quick Version)

### 🔴 Critical (Block Merge)
- [ ] TypeScript strict mode enabled, no `any` types
- [ ] FlatList used (not ScrollView + map)
- [ ] Functional components (no classes)
- [ ] Errors thrown (not suppressed)

### 🟡 Important (Request Changes)
- [ ] Props properly typed
- [ ] Hooks rules followed
- [ ] State management consistent (one solution)
- [ ] Navigation type-safe

### 🟢 Suggestions (Non-Blocking)
- [ ] React.memo for expensive components
- [ ] getItemLayout for FlatList
- [ ] Effect cleanup functions
- [ ] Platform differences handled

## Related Skills

- **theone-unity-standards** - Sister skill for Unity development
- **nextjs** - Web development patterns
- **tailwindcss** - Styling patterns (different paradigm from StyleSheet)
- **typescript-patterns** - Advanced TypeScript usage

## Maintenance

This skill should be updated when:
- React Native releases major versions
- TheOne Studio adopts new patterns or libraries
- Common code review issues emerge
- Framework recommendations change (e.g., new state management)

## Contributing

When updating this skill:
1. Maintain the priority hierarchy (quality > modern patterns > architecture > performance)
2. Keep ❌/✅ example format consistent
3. Add new common violations to review checklists
4. Update framework versions section
5. Test patterns with real React Native projects

## License

Internal use only - TheOne Studio proprietary standards.
