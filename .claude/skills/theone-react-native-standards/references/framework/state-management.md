# State Management - Zustand & Jotai Patterns

**PRIORITY 3** - Choose ONE state management solution per project: Zustand OR Jotai (never mix both).

## Zustand (Recommended for Simple State)

### Basic Store Setup

```typescript
// stores/user-store.ts
import { create } from 'zustand';

interface UserState {
  user: User | null;
  token: string | null;
  setUser: (user: User | null) => void;
  setToken: (token: string | null) => void;
  logout: () => void;
}

export const useUserStore = create<UserState>((set) => ({
  user: null,
  token: null,
  setUser: (user) => set({ user }),
  setToken: (token) => set({ token }),
  logout: () => set({ user: null, token: null }),
}));

// Usage
const user = useUserStore((state) => state.user);
const setUser = useUserStore((state) => state.setUser);
```

### Zustand with Persistence

```typescript
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';

export const useSettingsStore = create<SettingsState>()(
  persist(
    (set) => ({
      theme: 'light',
      language: 'en',
      setTheme: (theme) => set({ theme }),
      setLanguage: (language) => set({ language }),
    }),
    {
      name: 'settings-storage',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);
```

### Zustand Selectors (Prevent Rerenders)

```typescript
// ❌ BAD: Selects entire store (rerenders on any change)
const store = useUserStore();

// ✅ GOOD: Select only what you need
const user = useUserStore((state) => state.user);
const userName = useUserStore((state) => state.user?.name);

// ✅ GOOD: Select multiple fields with shallow equality
const { user, token } = useUserStore(
  (state) => ({ user: state.user, token: state.token }),
  shallow
);
```

## Jotai (Recommended for Atomic State)

### Basic Atoms

```typescript
// stores/atoms.ts
import { atom } from 'jotai';

export const userAtom = atom<User | null>(null);
export const tokenAtom = atom<string | null>(null);
export const themeAtom = atom<'light' | 'dark'>('light');

// Derived atom
export const userNameAtom = atom((get) => get(userAtom)?.name ?? 'Guest');

// Usage
const [user, setUser] = useAtom(userAtom);
const userName = useAtomValue(userNameAtom); // read-only
```

### Jotai with Persistence

```typescript
import { atom } from 'jotai';
import { atomWithStorage, createJSONStorage } from 'jotai/utils';
import AsyncStorage from '@react-native-async-storage/async-storage';

const storage = createJSONStorage<string>(() => AsyncStorage);

export const tokenAtom = atomWithStorage('token', null, storage);
```

### Jotai Async Atoms

```typescript
// Async data fetching
export const userAtom = atom(async (get) => {
  const userId = get(userIdAtom);
  if (!userId) return null;

  const response = await fetch(`/api/users/${userId}`);
  return response.json();
});

// Usage with Suspense
<Suspense fallback={<ActivityIndicator />}>
  <UserProfile />
</Suspense>
```

## State Management Best Practices

### ✅ DO:
- Choose ONE solution (Zustand OR Jotai) per project
- Use selectors to prevent unnecessary rerenders
- Persist authentication state
- Keep state normalized (flat, not nested)
- Extract actions into methods

### ❌ DON'T:
- Mix Zustand and Jotai in same project
- Use Redux (too much boilerplate for React Native)
- Use Context for frequently changing state
- Store derived state (calculate it)
- Mutate state directly (always use set functions)

## Zustand vs Jotai Decision Matrix

| Factor | Zustand | Jotai |
|--------|---------|-------|
| Learning curve | Easier | Moderate |
| Boilerplate | Minimal | Minimal |
| Best for | App-level state | Atomic/derived state |
| Performance | Good | Excellent |
| DevTools | Yes | Yes |
| TypeScript | Excellent | Excellent |

## Common Violations

```typescript
// ❌ CRITICAL: Using useState for app-level state
const [user, setUser] = useState(null); // Lost on unmount!

// ✅ FIXED: Use Zustand/Jotai
const user = useUserStore((state) => state.user);

// ❌ BAD: Selecting entire store
const store = useUserStore();

// ✅ GOOD: Select only needed fields
const user = useUserStore((state) => state.user);
```
