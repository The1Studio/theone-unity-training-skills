# Navigation Patterns - Expo Router & React Navigation

**PRIORITY 3** - Choose ONE navigation solution: Expo Router (recommended) OR React Navigation 7.

## Expo Router (File-Based Routing)

### Directory Structure
```
app/
├── (tabs)/
│   ├── _layout.tsx       # Tab navigator
│   ├── index.tsx         # Home tab
│   ├── profile.tsx       # Profile tab
│   └── settings.tsx      # Settings tab
├── user/
│   └── [id].tsx          # Dynamic route: /user/123
├── _layout.tsx           # Root layout
└── index.tsx             # Landing screen
```

### Basic Navigation
```typescript
import { router } from 'expo-router';

// Navigate to screen
router.push('/user/123');
router.replace('/login');
router.back();

// Navigate with params
router.push({
  pathname: '/user/[id]',
  params: { id: '123', name: 'John' },
});

// Access params
import { useLocalSearchParams } from 'expo-router';

export default function User() {
  const { id } = useLocalSearchParams();
  return <Text>User ID: {id}</Text>;
}
```

### Typed Routes (Expo Router)
```typescript
// Use generated routes for type safety
import { Link } from 'expo-router';

<Link href="/user/123">View User</Link>
<Link href={{ pathname: '/user/[id]', params: { id: '123' } }}>
  View User
</Link>
```

## React Navigation 7

### Stack Navigator
```typescript
import { createNativeStackNavigator } from '@react-navigation/native-stack';

type RootStackParamList = {
  Home: undefined;
  UserProfile: { userId: string };
  Settings: undefined;
};

const Stack = createNativeStackNavigator<RootStackParamList>();

export function AppNavigator() {
  return (
    <Stack.Navigator>
      <Stack.Screen name="Home" component={HomeScreen} />
      <Stack.Screen name="UserProfile" component={UserProfileScreen} />
      <Stack.Screen name="Settings" component={SettingsScreen} />
    </Stack.Navigator>
  );
}

// Navigate with type safety
navigation.navigate('UserProfile', { userId: '123' });
```

### Tab Navigator
```typescript
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';

const Tab = createBottomTabNavigator();

<Tab.Navigator>
  <Tab.Screen name="Home" component={HomeScreen} />
  <Tab.Screen name="Profile" component={ProfileScreen} />
</Tab.Navigator>
```

## Deep Linking

### Expo Router Deep Links
```json
// app.json
{
  "expo": {
    "scheme": "myapp",
    "plugins": [
      [
        "expo-router",
        {
          "origin": "https://myapp.com"
        }
      ]
    ]
  }
}
```

```typescript
// Handles: myapp://user/123 or https://myapp.com/user/123
// Automatically works with file-based routing!
```

## Navigation Best Practices

### ✅ DO:
- Choose ONE navigation solution per project
- Use TypeScript for type-safe navigation
- Implement deep linking from day 1
- Keep navigation logic in screens, not components

### ❌ DON'T:
- Mix Expo Router and React Navigation
- Pass complex objects in params (use IDs)
- Navigate from deep in component tree
- Store navigation state in Zustand/Jotai

## Common Violations

```typescript
// ❌ BAD: Navigating from child component
function ChildComponent() {
  const navigation = useNavigation();
  return <Button onPress={() => navigation.navigate('Profile')} />;
}

// ✅ GOOD: Pass event handler from parent
function ParentScreen() {
  const navigation = useNavigation();
  const handlePress = () => navigation.navigate('Profile');
  return <ChildComponent onPress={handlePress} />;
}
```
