# Platform-Specific Code - iOS & Android

**PRIORITY 3** - Handle platform differences properly.

## Platform Module

### Basic Platform Checks
```typescript
import { Platform } from 'react-native';

// Simple check
if (Platform.OS === 'ios') {
  // iOS-specific code
} else {
  // Android-specific code
}

// Platform-specific values
const padding = Platform.select({
  ios: 20,
  android: 16,
  default: 16,
});

// Platform-specific components
const Component = Platform.select({
  ios: () => require('./ComponentIOS').default,
  android: () => require('./ComponentAndroid').default,
})();
```

### Platform-Specific Files
```
components/
├── user-card.tsx           # Shared code
├── user-card.ios.tsx       # iOS-specific
└── user-card.android.tsx   # Android-specific

// Import automatically selects correct file:
import { UserCard } from '@/components/user-card';
```

## Platform-Specific Styles
```typescript
const styles = StyleSheet.create({
  container: {
    padding: 16,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.25,
        shadowRadius: 3.84,
      },
      android: {
        elevation: 5,
      },
    }),
  },
});
```

## SafeAreaView Usage
```typescript
import { SafeAreaView } from 'react-native-safe-area-context';

// ✅ GOOD: Use SafeAreaView on iOS
export const Screen: React.FC = ({ children }) => {
  return (
    <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
      {children}
    </SafeAreaView>
  );
};
```

## Common Platform Differences

| Feature | iOS | Android |
|---------|-----|---------|
| Shadows | shadowColor/shadowOffset/shadowOpacity/shadowRadius | elevation |
| Status bar height | Variable (notch) | Standard |
| Safe area | Critical | Less critical |
| Haptics | Excellent | Limited |
| Navigation gestures | Swipe from left | Hardware back button |
| Date picker | Native | Custom needed |

## Best Practices

### ✅ DO:
- Use Platform.select() for platform-specific values
- Create .ios.tsx/.android.tsx files for significantly different UIs
- Test on BOTH platforms before deploying
- Use SafeAreaView for proper inset handling

### ❌ DON'T:
- Assume Android and iOS behave identically
- Ignore platform-specific design guidelines
- Use iOS-only or Android-only APIs without checks
- Forget to handle notches/safe areas

## Common Violations

```typescript
// ❌ BAD: iOS-only shadow
const styles = StyleSheet.create({
  card: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
  },
});

// ✅ FIXED: Both platforms
const styles = StyleSheet.create({
  card: {
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.25,
      },
      android: {
        elevation: 3,
      },
    }),
  },
});
```

# Performance Patterns - FlatList & Optimization

**PRIORITY 4** - Critical for smooth mobile performance.

## FlatList Optimization (MOST IMPORTANT)

### Rule: NEVER use ScrollView + map

```typescript
// ❌ CRITICAL: Terrible performance, memory leak
<ScrollView>
  {items.map(item => <Item key={item.id} {...item} />)}
</ScrollView>

// ✅ GOOD: FlatList with optimization
const ITEM_HEIGHT = 80;

<FlatList
  data={items}
  renderItem={({ item }) => <Item {...item} />}
  keyExtractor={(item) => item.id}
  getItemLayout={(data, index) => ({
    length: ITEM_HEIGHT,
    offset: ITEM_HEIGHT * index,
    index,
  })}
  removeClippedSubviews
  maxToRenderPerBatch={10}
  windowSize={11}
  initialNumToRender={10}
/>
```

### FlatList Best Practices

```typescript
// ✅ Memoize renderItem
const renderItem = useCallback(
  ({ item }) => <UserCard user={item} onPress={handlePress} />,
  [handlePress]
);

// ✅ Provide getItemLayout for fixed-height items
const getItemLayout = useCallback(
  (data, index) => ({
    length: ITEM_HEIGHT,
    offset: ITEM_HEIGHT * index,
    index,
  }),
  []
);

// ✅ Use keyExtractor
const keyExtractor = useCallback((item: User) => item.id, []);

<FlatList
  data={users}
  renderItem={renderItem}
  keyExtractor={keyExtractor}
  getItemLayout={getItemLayout}
  removeClippedSubviews
/>
```

## Prevent Unnecessary Rerenders

### React.memo for Components
```typescript
// ✅ Wrap expensive components
export const UserCard = React.memo<Props>(({ user, onPress }) => {
  return (
    <TouchableOpacity onPress={onPress}>
      <Text>{user.name}</Text>
    </TouchableOpacity>
  );
});

// ✅ Custom comparison
export const UserCard = React.memo<Props>(
  ({ user, onPress }) => {
    return <TouchableOpacity onPress={onPress}><Text>{user.name}</Text></TouchableOpacity>;
  },
  (prev, next) => prev.user.id === next.user.id
);
```

### useCallback & useMemo
```typescript
// ✅ Memoize callbacks
const handlePress = useCallback((id: string) => {
  navigation.navigate('User', { id });
}, [navigation]);

// ✅ Memoize expensive calculations
const sortedUsers = useMemo(
  () => users.sort((a, b) => a.name.localeCompare(b.name)),
  [users]
);
```

## Image Optimization

```typescript
import FastImage from 'react-native-fast-image';

// ✅ Use FastImage for better performance
<FastImage
  source={{ uri: imageUrl, priority: FastImage.priority.normal }}
  resizeMode={FastImage.resizeMode.cover}
  style={styles.image}
/>

// ✅ Preload images
FastImage.preload([
  { uri: imageUrl1 },
  { uri: imageUrl2 },
]);
```

## Memory Leak Prevention

```typescript
// ✅ Clean up effects
useEffect(() => {
  const subscription = api.subscribe(data => setData(data));

  return () => {
    subscription.unsubscribe(); // Cleanup!
  };
}, []);

// ✅ Cancel async operations
useEffect(() => {
  let cancelled = false;

  const fetchData = async () => {
    const result = await api.get('/data');
    if (!cancelled) setData(result);
  };

  fetchData();

  return () => {
    cancelled = true; // Prevent state update after unmount
  };
}, []);
```

## Bundle Size Optimization

```typescript
// ✅ Lazy load screens
const ProfileScreen = lazy(() => import('./screens/profile-screen'));

// ✅ Code splitting with Suspense
<Suspense fallback={<ActivityIndicator />}>
  <ProfileScreen />
</Suspense>
```

## Performance Checklist

- [ ] FlatList used instead of ScrollView + map
- [ ] getItemLayout provided for fixed-height lists
- [ ] renderItem memoized with useCallback
- [ ] Expensive components wrapped with React.memo
- [ ] Images optimized (FastImage, proper sizes)
- [ ] Effect cleanup functions provided
- [ ] Bundle size monitored and optimized

## Common Performance Violations

```typescript
// ❌ CRITICAL: ScrollView + map
<ScrollView>
  {users.map(u => <UserCard key={u.id} user={u} />)}
</ScrollView>

// ✅ FIXED: FlatList
<FlatList
  data={users}
  renderItem={({ item }) => <UserCard user={item} />}
  keyExtractor={(item) => item.id}
/>

// ❌ BAD: Inline function in FlatList
<FlatList
  renderItem={({ item }) => <UserCard user={item} onPress={() => handlePress(item.id)} />}
/>

// ✅ FIXED: Memoized callback
const renderItem = useCallback(
  ({ item }) => <UserCard user={item} onPress={handlePress} />,
  [handlePress]
);
```

# Architecture Review - Code Review Checklist

**PRIORITY 4** - Use for React Native PR reviews.

## 🔴 Critical Issues (Block Merge)

### Component Architecture
- [ ] All components are functional (no class components)
- [ ] Components follow single responsibility
- [ ] Complex UIs use composition (not monolithic)
- [ ] No God components (>200 lines)

### State Management
- [ ] Consistent state solution (Zustand OR Jotai, not mixed)
- [ ] No useState for app-level state
- [ ] State is normalized (flat structures)
- [ ] Selectors used to prevent rerenders

### Navigation
- [ ] Consistent navigation (Expo Router OR React Navigation)
- [ ] Type-safe navigation (typed routes/params)
- [ ] No navigation from deep component tree
- [ ] Deep linking configured

### Lists & Performance
- [ ] FlatList used (NEVER ScrollView + map)
- [ ] getItemLayout provided for fixed-height items
- [ ] keyExtractor provided
- [ ] renderItem memoized

## 🟡 Important Issues (Request Changes)

### Platform-Specific
- [ ] Platform differences handled (.ios/.android files or Platform.select)
- [ ] SafeAreaView used appropriately
- [ ] Both platforms tested

### Component Patterns
- [ ] Presentational/container separation
- [ ] Props down, events up pattern
- [ ] HOCs used for cross-cutting concerns

## 🟢 Suggestions (Non-Blocking)

### Performance
- [ ] Expensive components wrapped with React.memo
- [ ] Custom comparison functions for React.memo
- [ ] Images optimized (FastImage)
- [ ] Code splitting for large screens

### Organization
- [ ] Feature-based folder structure
- [ ] Consistent file naming (kebab-case)
- [ ] Components properly organized

## Review Questions

1. Is FlatList used instead of ScrollView + map?
2. Is state management consistent (one solution)?
3. Are components functional (no classes)?
4. Is navigation type-safe?
5. Are platform differences handled?

# Quality Review - TypeScript & Hooks

**PRIORITY 4** - TypeScript and React quality checks.

## 🔴 Critical Quality Issues

### TypeScript
- [ ] Strict mode enabled
- [ ] No `any` types used
- [ ] All props have interfaces
- [ ] Function return types declared
- [ ] Optional props marked with `?`

### Hooks Rules
- [ ] Hooks only at top level (no conditionals/loops)
- [ ] Hooks only in React functions
- [ ] useCallback for functions passed as props
- [ ] useMemo for expensive calculations
- [ ] Cleanup functions in useEffect

### ESLint & Formatting
- [ ] ESLint passing (no warnings)
- [ ] Prettier formatted
- [ ] Import order correct (React → RN → libs → local)
- [ ] No console.log (use logger utility)

## 🟡 Important Quality Issues

### Error Handling
- [ ] Errors thrown (not suppressed)
- [ ] Error boundaries wrap components
- [ ] Try/catch only for recovery, not suppression

### Code Quality
- [ ] Path aliases (@/) used
- [ ] No inline styles in JSX
- [ ] StyleSheet.create() used
- [ ] File naming consistent (kebab-case)

## 🟢 Suggestions

### Custom Hooks
- [ ] Reusable logic extracted to custom hooks
- [ ] Hook names start with "use"
- [ ] Hooks properly typed

### Type Safety
- [ ] Generics used for reusable components
- [ ] Discriminated unions for complex state
- [ ] Type guards for runtime checks

# Performance Review - Optimization Checklist

**PRIORITY 4** - Performance optimization review.

## 🔴 Critical Performance Issues

### Lists
- [ ] FlatList used (NEVER ScrollView + map)
- [ ] getItemLayout provided
- [ ] keyExtractor provided
- [ ] removeClippedSubviews enabled

### Rerenders
- [ ] React.memo used for expensive components
- [ ] useCallback for functions passed as props
- [ ] useMemo for expensive calculations
- [ ] Selectors used in Zustand/Jotai

### Memory Leaks
- [ ] useEffect cleanup functions provided
- [ ] Subscriptions unsubscribed
- [ ] Timers/intervals cleared
- [ ] Async operations cancelled on unmount

## 🟡 Important Performance Issues

### Images
- [ ] FastImage used instead of Image
- [ ] Proper image sizes (not oversized)
- [ ] Images preloaded when appropriate

### Bundle Size
- [ ] Code splitting implemented
- [ ] Lazy loading for large screens
- [ ] Bundle size monitored

## 🟢 Performance Optimizations

### Advanced
- [ ] Custom React.memo comparison functions
- [ ] Virtualized lists for large datasets
- [ ] Debouncing/throttling for expensive operations

### Monitoring
- [ ] Performance profiling done
- [ ] Memory usage monitored
- [ ] Bundle analysis performed
