# Modern React Patterns - Functional Components & Hooks

This document covers modern React patterns with functional components and Hooks for React Native. These are **PRIORITY 2** rules (after code quality).

## Core Principles

1. **ALWAYS use functional components** - No class components
2. **Follow Hooks rules strictly** - No conditionals, no loops, no nesting
3. **Extract custom hooks** - Reuse logic across components
4. **Memoize appropriately** - useCallback for functions, useMemo for values
5. **Clean up effects** - Return cleanup functions to prevent memory leaks

## Functional Components (NO Class Components)

### Rule: Always Use Functional Components

```typescript
// ❌ BAD: Class component (outdated)
import React, { Component } from 'react';
import { View, Text } from 'react-native';

class UserProfile extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = {
      user: null,
      loading: true,
    };
  }

  componentDidMount() {
    this.fetchUser();
  }

  async fetchUser() {
    const user = await api.get(`/users/${this.props.userId}`);
    this.setState({ user, loading: false });
  }

  render() {
    if (this.state.loading) return <Text>Loading...</Text>;
    return <Text>{this.state.user?.name}</Text>;
  }
}

// ✅ GOOD: Functional component with hooks
import React, { useEffect, useState } from 'react';
import { View, Text } from 'react-native';

interface UserProfileProps {
  userId: string;
}

export const UserProfile: React.FC<UserProfileProps> = ({ userId }) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchUser = async () => {
      const userData = await api.get(`/users/${userId}`);
      setUser(userData);
      setLoading(false);
    };

    fetchUser();
  }, [userId]);

  if (loading) return <Text>Loading...</Text>;
  return <Text>{user?.name}</Text>;
};
```

## Hooks Rules (Strictly Enforced)

### Rule 1: Only Call Hooks at Top Level

**NEVER call hooks conditionally, in loops, or nested:**

```typescript
// ❌ BAD: Hook called conditionally
function UserProfile({ userId }: Props) {
  if (userId) {
    const user = useUser(userId); // WRONG! Conditional hook
  }

  return <Text>Profile</Text>;
}

// ❌ BAD: Hook called in loop
function UserList({ userIds }: Props) {
  const users = userIds.map(id => useUser(id)); // WRONG! Hook in loop
  return <View>{/* ... */}</View>;
}

// ❌ BAD: Hook called in nested function
function UserProfile({ userId }: Props) {
  const fetchUser = () => {
    const user = useUser(userId); // WRONG! Nested hook
  };

  return <Text>Profile</Text>;
}

// ✅ GOOD: Hooks at top level only
function UserProfile({ userId }: Props) {
  const user = useUser(userId); // Correct!

  if (!user) {
    return <Text>Loading...</Text>;
  }

  return <Text>{user.name}</Text>;
}

// ✅ GOOD: Handle conditionals AFTER calling hooks
function UserProfile({ userId }: Props) {
  const user = userId ? useUser(userId) : null; // Conditional result, not hook call

  if (!user) return <Text>No user</Text>;
  return <Text>{user.name}</Text>;
}
```

### Rule 2: Only Call Hooks from React Functions

```typescript
// ❌ BAD: Hook called from regular function
function fetchUser(userId: string) {
  const user = useUser(userId); // WRONG! Not in React function
  return user;
}

// ❌ BAD: Hook called from class method
class UserService {
  getUser(userId: string) {
    return useUser(userId); // WRONG! Not in React function
  }
}

// ✅ GOOD: Hook called from functional component
export const UserProfile: React.FC<Props> = ({ userId }) => {
  const user = useUser(userId); // Correct!
  return <Text>{user?.name}</Text>;
};

// ✅ GOOD: Hook called from custom hook
export function useUserProfile(userId: string) {
  const user = useUser(userId); // Correct! In custom hook
  const [profile, setProfile] = useState<Profile | null>(null);

  useEffect(() => {
    if (user) {
      loadProfile(user).then(setProfile);
    }
  }, [user]);

  return profile;
}
```

## Custom Hooks for Logic Reuse

### Rule: Extract Reusable Logic into Custom Hooks

**Custom hooks MUST start with "use" prefix:**

```typescript
// ✅ GOOD: Custom hook for API calls
export function useUser(userId: string) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    let cancelled = false;

    const fetchUser = async () => {
      try {
        setLoading(true);
        const data = await api.get(`/users/${userId}`);

        if (!cancelled) {
          setUser(data);
          setError(null);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err as Error);
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    };

    fetchUser();

    return () => {
      cancelled = true; // Cleanup flag
    };
  }, [userId]);

  return { user, loading, error };
}

// Usage in components
export const UserProfile: React.FC<Props> = ({ userId }) => {
  const { user, loading, error } = useUser(userId);

  if (loading) return <Text>Loading...</Text>;
  if (error) throw error;
  if (!user) return <Text>User not found</Text>;

  return <Text>{user.name}</Text>;
};
```

### Common Custom Hooks Patterns

#### 1. Data Fetching Hook

```typescript
// src/hooks/use-fetch.ts
export function useFetch<T>(url: string) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    let cancelled = false;

    const fetchData = async () => {
      try {
        setLoading(true);
        const response = await fetch(url);

        if (!response.ok) {
          throw new Error(`HTTP error: ${response.status}`);
        }

        const json = await response.json();

        if (!cancelled) {
          setData(json);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err as Error);
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    };

    fetchData();

    return () => {
      cancelled = true;
    };
  }, [url]);

  return { data, loading, error };
}

// Usage
export const PostList: React.FC = () => {
  const { data: posts, loading, error } = useFetch<Post[]>('/api/posts');

  if (loading) return <ActivityIndicator />;
  if (error) throw error;

  return (
    <FlatList
      data={posts}
      renderItem={({ item }) => <PostCard post={item} />}
      keyExtractor={(item) => item.id}
    />
  );
};
```

#### 2. Form State Hook

```typescript
// src/hooks/use-form.ts
export function useForm<T extends Record<string, any>>(initialValues: T) {
  const [values, setValues] = useState<T>(initialValues);
  const [errors, setErrors] = useState<Partial<Record<keyof T, string>>>({});
  const [touched, setTouched] = useState<Partial<Record<keyof T, boolean>>>({});

  const handleChange = useCallback((field: keyof T, value: any) => {
    setValues((prev) => ({ ...prev, [field]: value }));
    setTouched((prev) => ({ ...prev, [field]: true }));
  }, []);

  const handleBlur = useCallback((field: keyof T) => {
    setTouched((prev) => ({ ...prev, [field]: true }));
  }, []);

  const setFieldError = useCallback((field: keyof T, error: string) => {
    setErrors((prev) => ({ ...prev, [field]: error }));
  }, []);

  const reset = useCallback(() => {
    setValues(initialValues);
    setErrors({});
    setTouched({});
  }, [initialValues]);

  return {
    values,
    errors,
    touched,
    handleChange,
    handleBlur,
    setFieldError,
    reset,
  };
}

// Usage
export const LoginForm: React.FC = () => {
  const { values, errors, handleChange, handleBlur } = useForm({
    email: '',
    password: '',
  });

  return (
    <View>
      <TextInput
        value={values.email}
        onChangeText={(text) => handleChange('email', text)}
        onBlur={() => handleBlur('email')}
      />
      {errors.email && <Text style={styles.error}>{errors.email}</Text>}

      <TextInput
        value={values.password}
        onChangeText={(text) => handleChange('password', text)}
        onBlur={() => handleBlur('password')}
        secureTextEntry
      />
      {errors.password && <Text style={styles.error}>{errors.password}</Text>}
    </View>
  );
};
```

#### 3. Debounce Hook

```typescript
// src/hooks/use-debounce.ts
export function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => {
      clearTimeout(handler);
    };
  }, [value, delay]);

  return debouncedValue;
}

// Usage
export const SearchScreen: React.FC = () => {
  const [query, setQuery] = useState('');
  const debouncedQuery = useDebounce(query, 500);

  useEffect(() => {
    if (debouncedQuery) {
      // Only search when user stops typing
      searchAPI(debouncedQuery);
    }
  }, [debouncedQuery]);

  return (
    <TextInput
      value={query}
      onChangeText={setQuery}
      placeholder="Search..."
    />
  );
};
```

## useCallback for Function Memoization

### Rule: Memoize Functions Passed as Props

```typescript
// ❌ BAD: Function recreated every render
export const UserList: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);

  // Function recreated every render -> causes child rerenders
  const handleUserPress = (userId: string) => {
    navigation.navigate('UserProfile', { userId });
  };

  return (
    <FlatList
      data={users}
      renderItem={({ item }) => (
        <UserCard user={item} onPress={handleUserPress} /> // Rerenders every time!
      )}
    />
  );
};

// ✅ GOOD: Memoized function with useCallback
export const UserList: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const navigation = useNavigation();

  // Function memoized -> prevents unnecessary rerenders
  const handleUserPress = useCallback(
    (userId: string) => {
      navigation.navigate('UserProfile', { userId });
    },
    [navigation],
  );

  return (
    <FlatList
      data={users}
      renderItem={({ item }) => (
        <UserCard user={item} onPress={handleUserPress} />
      )}
    />
  );
};
```

### useCallback Dependencies

```typescript
// ❌ BAD: Missing dependencies
const handleSubmit = useCallback(() => {
  api.post('/users', formData); // formData not in deps!
}, []);

// ❌ BAD: Too many dependencies (defeats memoization)
const handleSubmit = useCallback(() => {
  console.log('Submitting');
}, [formData, user, settings, theme]); // Rerenders too often

// ✅ GOOD: Correct dependencies
const handleSubmit = useCallback(() => {
  api.post('/users', formData);
}, [formData]); // Only recreate when formData changes

// ✅ GOOD: Use functional updates to avoid dependencies
const increment = useCallback(() => {
  setCount((prev) => prev + 1); // No count dependency needed!
}, []);
```

## useMemo for Expensive Calculations

### Rule: Memoize Expensive Calculations

```typescript
// ❌ BAD: Expensive calculation runs every render
export const ProductList: React.FC<Props> = ({ products, filters }) => {
  // Filters 10,000 products on EVERY render (even unrelated state changes)
  const filteredProducts = products.filter((p) =>
    p.name.toLowerCase().includes(filters.search.toLowerCase())
  );

  return (
    <FlatList
      data={filteredProducts}
      renderItem={({ item }) => <ProductCard product={item} />}
    />
  );
};

// ✅ GOOD: Memoized calculation with useMemo
export const ProductList: React.FC<Props> = ({ products, filters }) => {
  // Only recalculates when products or filters change
  const filteredProducts = useMemo(
    () =>
      products.filter((p) =>
        p.name.toLowerCase().includes(filters.search.toLowerCase())
      ),
    [products, filters.search],
  );

  return (
    <FlatList
      data={filteredProducts}
      renderItem={({ item }) => <ProductCard product={item} />}
    />
  );
};
```

### useMemo vs useCallback

```typescript
// useMemo returns a VALUE
const expensiveValue = useMemo(() => {
  return computeExpensiveValue(a, b);
}, [a, b]);

// useCallback returns a FUNCTION (syntactic sugar for useMemo)
const memoizedFunction = useCallback((x) => {
  return doSomething(x);
}, []);

// These are equivalent:
const memoizedFunction = useMemo(() => {
  return (x) => doSomething(x);
}, []);
```

### When to Use useMemo

```typescript
// ✅ Use useMemo for:
// 1. Expensive calculations
const sortedUsers = useMemo(
  () => users.sort((a, b) => a.name.localeCompare(b.name)),
  [users],
);

// 2. Complex filtering/mapping
const activeUsers = useMemo(
  () => users.filter((u) => u.isActive && u.lastSeen > threshold),
  [users, threshold],
);

// 3. Object/array creation that's used as dependency
const config = useMemo(
  () => ({
    apiKey,
    timeout: 5000,
  }),
  [apiKey],
);

// ❌ Don't use useMemo for:
// 1. Simple calculations
const fullName = `${firstName} ${lastName}`; // No useMemo needed

// 2. Direct prop access
const userName = user.name; // No useMemo needed

// 3. Single number/string operations
const doubled = count * 2; // No useMemo needed
```

## Effect Cleanup to Prevent Memory Leaks

### Rule: Always Return Cleanup Functions

```typescript
// ❌ BAD: No cleanup -> memory leak
export const TimerComponent: React.FC = () => {
  const [seconds, setSeconds] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setSeconds((s) => s + 1);
    }, 1000);
    // Missing cleanup! Interval keeps running after unmount
  }, []);

  return <Text>{seconds}s</Text>;
};

// ✅ GOOD: Cleanup function clears interval
export const TimerComponent: React.FC = () => {
  const [seconds, setSeconds] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setSeconds((s) => s + 1);
    }, 1000);

    return () => {
      clearInterval(interval); // Cleanup!
    };
  }, []);

  return <Text>{seconds}s</Text>;
};
```

### Common Cleanup Patterns

#### 1. Event Listeners

```typescript
// ✅ GOOD: Remove event listeners on cleanup
export const KeyboardAwareView: React.FC = ({ children }) => {
  const [keyboardHeight, setKeyboardHeight] = useState(0);

  useEffect(() => {
    const showListener = Keyboard.addListener('keyboardDidShow', (e) => {
      setKeyboardHeight(e.endCoordinates.height);
    });

    const hideListener = Keyboard.addListener('keyboardDidHide', () => {
      setKeyboardHeight(0);
    });

    return () => {
      showListener.remove(); // Cleanup!
      hideListener.remove();
    };
  }, []);

  return <View style={{ paddingBottom: keyboardHeight }}>{children}</View>;
};
```

#### 2. Subscriptions

```typescript
// ✅ GOOD: Unsubscribe on cleanup
export const RealtimeUpdates: React.FC = () => {
  const [data, setData] = useState<Data[]>([]);

  useEffect(() => {
    const subscription = firestore
      .collection('items')
      .onSnapshot((snapshot) => {
        setData(snapshot.docs.map((doc) => doc.data()));
      });

    return () => {
      subscription(); // Unsubscribe cleanup!
    };
  }, []);

  return <FlatList data={data} />;
};
```

#### 3. Async Operations

```typescript
// ✅ GOOD: Cancel async operations on cleanup
export const UserProfile: React.FC<Props> = ({ userId }) => {
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    let cancelled = false; // Cancellation flag

    const fetchUser = async () => {
      const data = await api.get(`/users/${userId}`);

      if (!cancelled) {
        // Only update if not cancelled
        setUser(data);
      }
    };

    fetchUser();

    return () => {
      cancelled = true; // Cleanup: set cancellation flag
    };
  }, [userId]);

  return user ? <Text>{user.name}</Text> : <ActivityIndicator />;
};
```

## React.memo for Component Memoization

### Rule: Wrap Expensive Components in React.memo

```typescript
// ❌ BAD: Child component rerenders when parent rerenders
export const UserCard: React.FC<Props> = ({ user, onPress }) => {
  console.log('UserCard rendered'); // Logs on every parent rerender

  return (
    <TouchableOpacity onPress={onPress}>
      <Text>{user.name}</Text>
    </TouchableOpacity>
  );
};

// ✅ GOOD: React.memo prevents unnecessary rerenders
export const UserCard = React.memo<Props>(({ user, onPress }) => {
  console.log('UserCard rendered'); // Only logs when props change

  return (
    <TouchableOpacity onPress={onPress}>
      <Text>{user.name}</Text>
    </TouchableOpacity>
  );
});

// ✅ GOOD: Custom comparison function
export const UserCard = React.memo<Props>(
  ({ user, onPress }) => {
    return (
      <TouchableOpacity onPress={onPress}>
        <Text>{user.name}</Text>
      </TouchableOpacity>
    );
  },
  (prevProps, nextProps) => {
    // Return true if props are equal (skip rerender)
    return prevProps.user.id === nextProps.user.id;
  },
);
```

## Complete Modern React Checklist

- [ ] All components are functional (no class components)
- [ ] Hooks only called at top level (no conditionals/loops)
- [ ] Reusable logic extracted into custom hooks
- [ ] Functions passed as props memoized with useCallback
- [ ] Expensive calculations memoized with useMemo
- [ ] Effect cleanup functions provided (intervals, listeners, subscriptions)
- [ ] Expensive components wrapped in React.memo
- [ ] Hook dependencies arrays correct (ESLint exhaustive-deps)

## Common Modern React Violations

### Violation 1: Hooks in Conditionals

```typescript
// ❌ CRITICAL: Hook in conditional
function Component({ userId }: Props) {
  if (userId) {
    const user = useUser(userId); // WRONG!
  }
}

// ✅ FIXED: Conditional logic AFTER hook
function Component({ userId }: Props) {
  const user = useUser(userId || '');

  if (!userId) return null;
  return <Text>{user?.name}</Text>;
}
```

### Violation 2: Missing Cleanup

```typescript
// ❌ CRITICAL: No cleanup -> memory leak
useEffect(() => {
  const interval = setInterval(() => {
    fetchData();
  }, 5000);
}, []);

// ✅ FIXED: Cleanup function
useEffect(() => {
  const interval = setInterval(() => {
    fetchData();
  }, 5000);

  return () => clearInterval(interval);
}, []);
```

### Violation 3: Functions Causing Rerenders

```typescript
// ❌ BAD: Recreates function every render
const handlePress = () => {
  doSomething();
};

// ✅ FIXED: Memoize with useCallback
const handlePress = useCallback(() => {
  doSomething();
}, []);
```

## Conclusion

Modern React patterns with Hooks provide cleaner, more maintainable code than class components. Follow the Hooks rules strictly, extract reusable logic into custom hooks, and memoize appropriately to prevent performance issues.
