# TypeScript Patterns - Type-Safe React Native

This document covers TypeScript patterns for React Native development. These are **PRIORITY 2** patterns (after code quality, alongside modern React).

## Core Principles

1. **Type-safe props** - Always define interfaces for component props
2. **Use generics** - Create reusable type-safe components and hooks
3. **Discriminated unions** - Model complex state with type safety
4. **Utility types** - Leverage built-in TypeScript utilities
5. **Type guards** - Narrow types safely at runtime

## Type-Safe Component Props

### Rule: Always Define Prop Interfaces

```typescript
// ❌ BAD: No prop types
export const UserCard = ({ user, onPress }) => {
  return (
    <TouchableOpacity onPress={onPress}>
      <Text>{user.name}</Text>
    </TouchableOpacity>
  );
};

// ❌ BAD: any props
export const UserCard: React.FC<any> = (props) => {
  return <Text>{props.user?.name}</Text>;
};

// ✅ GOOD: Proper interface with typed props
interface UserCardProps {
  user: User;
  onPress?: () => void;
  style?: StyleProp<ViewStyle>;
}

export const UserCard: React.FC<UserCardProps> = ({ user, onPress, style }) => {
  return (
    <TouchableOpacity onPress={onPress} style={style}>
      <Text>{user.name}</Text>
    </TouchableOpacity>
  );
};
```

### Optional vs Required Props

```typescript
interface ButtonProps {
  // Required props
  title: string;
  onPress: () => void;

  // Optional props (marked with ?)
  disabled?: boolean;
  loading?: boolean;
  variant?: 'primary' | 'secondary' | 'outline';

  // Optional with default in destructuring
  size?: 'small' | 'medium' | 'large';
}

export const Button: React.FC<ButtonProps> = ({
  title,
  onPress,
  disabled = false,
  loading = false,
  variant = 'primary',
  size = 'medium',
}) => {
  // Implementation
};
```

### Children Prop Typing

```typescript
// ✅ Option 1: ReactNode (most flexible)
interface ContainerProps {
  children: ReactNode;
}

export const Container: React.FC<ContainerProps> = ({ children }) => {
  return <View>{children}</View>;
};

// ✅ Option 2: Specific element type
interface ModalProps {
  children: ReactElement;
}

export const Modal: React.FC<ModalProps> = ({ children }) => {
  return <View>{children}</View>;
};

// ✅ Option 3: Render prop pattern
interface ListProps<T> {
  data: T[];
  renderItem: (item: T) => ReactElement;
}

export function List<T>({ data, renderItem }: ListProps<T>) {
  return (
    <View>
      {data.map((item, index) => (
        <View key={index}>{renderItem(item)}</View>
      ))}
    </View>
  );
}
```

## Generic Components and Hooks

### Rule: Use Generics for Reusable Components

```typescript
// ✅ GOOD: Generic list component
interface ListProps<T> {
  data: T[];
  renderItem: (item: T, index: number) => ReactElement;
  keyExtractor: (item: T, index: number) => string;
  onItemPress?: (item: T) => void;
}

export function List<T>({
  data,
  renderItem,
  keyExtractor,
  onItemPress,
}: ListProps<T>) {
  return (
    <FlatList
      data={data}
      renderItem={({ item, index }) => (
        <TouchableOpacity onPress={() => onItemPress?.(item)}>
          {renderItem(item, index)}
        </TouchableOpacity>
      )}
      keyExtractor={keyExtractor}
    />
  );
}

// Usage with type inference
const users: User[] = [/* ... */];

<List
  data={users} // TypeScript infers T = User
  renderItem={(user) => <Text>{user.name}</Text>} // user is typed as User
  keyExtractor={(user) => user.id}
  onItemPress={(user) => console.log(user.email)} // user is typed as User
/>;
```

### Generic Hooks

```typescript
// ✅ GOOD: Generic fetch hook
interface UseFetchResult<T> {
  data: T | null;
  loading: boolean;
  error: Error | null;
  refetch: () => void;
}

export function useFetch<T>(url: string): UseFetchResult<T> {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      const response = await fetch(url);
      const json = await response.json();
      setData(json as T);
    } catch (err) {
      setError(err as Error);
    } finally {
      setLoading(false);
    }
  }, [url]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return { data, loading, error, refetch: fetchData };
}

// Usage with type parameter
const { data: user, loading } = useFetch<User>('/api/user/123');
// data is typed as User | null

const { data: posts } = useFetch<Post[]>('/api/posts');
// data is typed as Post[] | null
```

### Generic Utility Functions

```typescript
// ✅ GOOD: Type-safe array utilities
export function groupBy<T, K extends keyof any>(
  array: T[],
  getKey: (item: T) => K,
): Record<K, T[]> {
  return array.reduce((acc, item) => {
    const key = getKey(item);
    acc[key] = acc[key] || [];
    acc[key].push(item);
    return acc;
  }, {} as Record<K, T[]>);
}

// Usage
const users: User[] = [/* ... */];
const byRole = groupBy(users, (user) => user.role);
// byRole is typed as Record<string, User[]>

// ✅ GOOD: Type-safe pick function
export function pick<T, K extends keyof T>(obj: T, keys: K[]): Pick<T, K> {
  return keys.reduce((result, key) => {
    result[key] = obj[key];
    return result;
  }, {} as Pick<T, K>);
}

// Usage
const user: User = { id: '1', name: 'John', email: 'john@example.com' };
const userPreview = pick(user, ['id', 'name']);
// userPreview is typed as { id: string; name: string }
```

## Discriminated Unions for State Management

### Rule: Use Discriminated Unions for Complex State

```typescript
// ❌ BAD: Multiple boolean flags (hard to maintain)
interface State {
  loading: boolean;
  error: Error | null;
  data: User | null;
}

// Problem: Invalid states are possible
// { loading: true, error: new Error(), data: user } <- Invalid!

// ✅ GOOD: Discriminated union (impossible states are impossible)
type State =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'error'; error: Error }
  | { status: 'success'; data: User };

export const UserProfile: React.FC<Props> = ({ userId }) => {
  const [state, setState] = useState<State>({ status: 'idle' });

  useEffect(() => {
    const fetchUser = async () => {
      setState({ status: 'loading' });

      try {
        const user = await api.get(`/users/${userId}`);
        setState({ status: 'success', data: user });
      } catch (error) {
        setState({ status: 'error', error: error as Error });
      }
    };

    fetchUser();
  }, [userId]);

  // TypeScript narrows types based on status
  switch (state.status) {
    case 'idle':
    case 'loading':
      return <ActivityIndicator />;

    case 'error':
      return <Text>Error: {state.error.message}</Text>; // state.error is Error

    case 'success':
      return <Text>{state.data.name}</Text>; // state.data is User
  }
};
```

### Discriminated Unions for Actions

```typescript
// ✅ GOOD: Type-safe reducer with discriminated unions
type Action =
  | { type: 'SET_LOADING' }
  | { type: 'SET_ERROR'; error: Error }
  | { type: 'SET_USER'; user: User }
  | { type: 'UPDATE_USER_NAME'; name: string }
  | { type: 'LOGOUT' };

interface State {
  user: User | null;
  loading: boolean;
  error: Error | null;
}

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'SET_LOADING':
      return { ...state, loading: true, error: null };

    case 'SET_ERROR':
      return { ...state, loading: false, error: action.error }; // action.error is Error

    case 'SET_USER':
      return { ...state, loading: false, user: action.user }; // action.user is User

    case 'UPDATE_USER_NAME':
      if (!state.user) return state;
      return {
        ...state,
        user: { ...state.user, name: action.name }, // action.name is string
      };

    case 'LOGOUT':
      return { ...state, user: null };

    default:
      return state;
  }
}

// Usage
const [state, dispatch] = useReducer(reducer, initialState);

dispatch({ type: 'SET_USER', user: fetchedUser }); // Type-safe!
dispatch({ type: 'SET_USER', name: 'John' }); // TypeScript error! Wrong payload
```

## Utility Types

### Built-in TypeScript Utilities

```typescript
interface User {
  id: string;
  name: string;
  email: string;
  age: number;
  role: 'admin' | 'user';
}

// Partial<T> - All properties optional
type PartialUser = Partial<User>;
// { id?: string; name?: string; email?: string; age?: number; role?: 'admin' | 'user' }

function updateUser(id: string, updates: Partial<User>) {
  // Only update provided fields
}

// Required<T> - All properties required
type RequiredUser = Required<Partial<User>>;
// Back to: { id: string; name: string; email: string; age: number; role: 'admin' | 'user' }

// Pick<T, K> - Select specific properties
type UserPreview = Pick<User, 'id' | 'name'>;
// { id: string; name: string }

// Omit<T, K> - Remove specific properties
type UserWithoutEmail = Omit<User, 'email'>;
// { id: string; name: string; age: number; role: 'admin' | 'user' }

// Record<K, T> - Create object type with specific keys
type UserRoles = Record<string, User[]>;
// { [key: string]: User[] }

// Readonly<T> - Make all properties readonly
type ReadonlyUser = Readonly<User>;
// { readonly id: string; readonly name: string; ... }

// ReturnType<T> - Extract return type of function
function getUser(): User {
  return { id: '1', name: 'John', email: 'john@example.com', age: 30, role: 'user' };
}

type UserType = ReturnType<typeof getUser>;
// User
```

### Custom Utility Types

```typescript
// ✅ GOOD: Deep partial type
type DeepPartial<T> = {
  [K in keyof T]?: T[K] extends object ? DeepPartial<T[K]> : T[K];
};

interface Config {
  api: {
    baseUrl: string;
    timeout: number;
  };
  theme: {
    colors: {
      primary: string;
      secondary: string;
    };
  };
}

// Can update nested properties
const partialConfig: DeepPartial<Config> = {
  api: {
    timeout: 5000, // Only update timeout
  },
};

// ✅ GOOD: Non-nullable type
type NonNullable<T> = T extends null | undefined ? never : T;

type MaybeUser = User | null | undefined;
type DefiniteUser = NonNullable<MaybeUser>;
// User

// ✅ GOOD: Extract keys of specific type
type KeysOfType<T, V> = {
  [K in keyof T]: T[K] extends V ? K : never;
}[keyof T];

type StringKeys = KeysOfType<User, string>;
// 'name' | 'email' | 'role'

type NumberKeys = KeysOfType<User, number>;
// 'age'
```

## Type Guards for Runtime Type Checking

### Rule: Use Type Guards to Narrow Types

```typescript
// ✅ GOOD: Custom type guard
interface Dog {
  type: 'dog';
  bark: () => void;
}

interface Cat {
  type: 'cat';
  meow: () => void;
}

type Pet = Dog | Cat;

// Type guard function
function isDog(pet: Pet): pet is Dog {
  return pet.type === 'dog';
}

function isCat(pet: Pet): pet is Cat {
  return pet.type === 'cat';
}

// Usage
function handlePet(pet: Pet) {
  if (isDog(pet)) {
    pet.bark(); // TypeScript knows pet is Dog
  } else {
    pet.meow(); // TypeScript knows pet is Cat
  }
}
```

### Common Type Guard Patterns

```typescript
// ✅ GOOD: Null/undefined check
function isNotNull<T>(value: T | null | undefined): value is T {
  return value !== null && value !== undefined;
}

const users: (User | null)[] = [user1, null, user2];
const validUsers = users.filter(isNotNull);
// validUsers is typed as User[] (no nulls)

// ✅ GOOD: Array type guard
function isArray<T>(value: T | T[]): value is T[] {
  return Array.isArray(value);
}

function processValue(value: string | string[]) {
  if (isArray(value)) {
    value.forEach((v) => console.log(v)); // value is string[]
  } else {
    console.log(value.toUpperCase()); // value is string
  }
}

// ✅ GOOD: Error type guard
function isError(error: unknown): error is Error {
  return error instanceof Error;
}

try {
  throw new Error('Something went wrong');
} catch (error) {
  if (isError(error)) {
    console.error(error.message); // error is Error
  }
}

// ✅ GOOD: API response type guard
interface SuccessResponse<T> {
  success: true;
  data: T;
}

interface ErrorResponse {
  success: false;
  error: string;
}

type ApiResponse<T> = SuccessResponse<T> | ErrorResponse;

function isSuccess<T>(response: ApiResponse<T>): response is SuccessResponse<T> {
  return response.success === true;
}

const response: ApiResponse<User> = await fetchUser();

if (isSuccess(response)) {
  console.log(response.data.name); // response is SuccessResponse<User>
} else {
  console.error(response.error); // response is ErrorResponse
}
```

## Advanced TypeScript Patterns

### Conditional Types

```typescript
// ✅ GOOD: Conditional type based on input
type IsString<T> = T extends string ? true : false;

type Test1 = IsString<string>; // true
type Test2 = IsString<number>; // false

// ✅ GOOD: Flatten array type
type Flatten<T> = T extends Array<infer U> ? U : T;

type Test3 = Flatten<string[]>; // string
type Test4 = Flatten<number>; // number

// ✅ GOOD: Extract Promise value type
type UnwrapPromise<T> = T extends Promise<infer U> ? U : T;

type Test5 = UnwrapPromise<Promise<User>>; // User
type Test6 = UnwrapPromise<string>; // string
```

### Mapped Types

```typescript
// ✅ GOOD: Make properties optional recursively
type Optional<T> = {
  [K in keyof T]?: T[K];
};

type OptionalUser = Optional<User>;
// All properties optional

// ✅ GOOD: Make properties readonly
type ReadonlyDeep<T> = {
  readonly [K in keyof T]: T[K] extends object ? ReadonlyDeep<T[K]> : T[K];
};

type ImmutableUser = ReadonlyDeep<User>;
// All properties (including nested) readonly

// ✅ GOOD: Transform property types
type Stringify<T> = {
  [K in keyof T]: string;
};

type UserStrings = Stringify<User>;
// { id: string; name: string; email: string; age: string; role: string }
```

### Template Literal Types

```typescript
// ✅ GOOD: Type-safe event names
type EventName = 'click' | 'focus' | 'blur';
type EventHandlerName = `on${Capitalize<EventName>}`;
// 'onClick' | 'onFocus' | 'onBlur'

interface ButtonProps {
  onClick?: () => void;
  onFocus?: () => void;
  onBlur?: () => void;
}

// ✅ GOOD: Type-safe API routes
type HttpMethod = 'get' | 'post' | 'put' | 'delete';
type ApiRoute = `/api/${string}`;
type ApiCall = `${HttpMethod} ${ApiRoute}`;
// 'get /api/users' | 'post /api/users' | ...
```

## Complete TypeScript Checklist

- [ ] All component props have typed interfaces
- [ ] Generic types used for reusable components/hooks
- [ ] Complex state uses discriminated unions
- [ ] Utility types (Partial, Pick, Omit) used appropriately
- [ ] Type guards narrow types for runtime checks
- [ ] No `any` types (use `unknown` or proper types)
- [ ] Optional props marked with `?`
- [ ] Function return types explicitly declared
- [ ] Event handlers properly typed

## Common TypeScript Violations

### Violation 1: Missing Prop Types

```typescript
// ❌ CRITICAL: No prop types
export const Button = ({ title, onPress }) => {
  return <TouchableOpacity onPress={onPress}><Text>{title}</Text></TouchableOpacity>;
};

// ✅ FIXED: Proper prop interface
interface ButtonProps {
  title: string;
  onPress: () => void;
}

export const Button: React.FC<ButtonProps> = ({ title, onPress }) => {
  return <TouchableOpacity onPress={onPress}><Text>{title}</Text></TouchableOpacity>;
};
```

### Violation 2: any Types

```typescript
// ❌ CRITICAL: any type defeats TypeScript
function handleData(data: any) {
  return data.value;
}

// ✅ FIXED: Proper type or generic
interface Data {
  value: string;
}

function handleData(data: Data): string {
  return data.value;
}

// Or use generic
function handleData<T extends { value: string }>(data: T): string {
  return data.value;
}
```

### Violation 3: No Type Guards

```typescript
// ❌ BAD: No type narrowing
function processValue(value: string | number) {
  return value.toUpperCase(); // Error if number!
}

// ✅ FIXED: Type guard
function processValue(value: string | number): string {
  if (typeof value === 'string') {
    return value.toUpperCase();
  }
  return value.toString();
}
```

## Conclusion

TypeScript provides powerful type safety for React Native development. Use proper types, generics, discriminated unions, and type guards to catch errors at compile time and improve code maintainability.
