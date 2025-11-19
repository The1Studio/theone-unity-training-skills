# Component Patterns - React Native Architecture

This document covers React Native component architecture patterns. These are **PRIORITY 3** patterns (after code quality and modern React/TypeScript).

## Core Principles

1. **Functional components only** - No class components
2. **Composition over inheritance** - Build complex UIs from simple components
3. **Single responsibility** - Each component does one thing well
4. **Props down, events up** - Data flows down, events bubble up
5. **Presentational vs Container** - Separate UI from logic

## Component File Structure

### Rule: Consistent Component Organization

```typescript
// user-card.tsx - Standard component file structure

// 1. Imports (React → RN → Libraries → Local)
import React, { useCallback } from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';

import { Avatar } from '@/components/avatar';
import { Badge } from '@/components/badge';
import { User } from '@/types/user';

// 2. Type definitions
interface UserCardProps {
  user: User;
  onPress?: (userId: string) => void;
  showBadge?: boolean;
}

// 3. Component implementation
export const UserCard: React.FC<UserCardProps> = ({
  user,
  onPress,
  showBadge = false,
}) => {
  // 4. Hooks at top
  const handlePress = useCallback(() => {
    onPress?.(user.id);
  }, [user.id, onPress]);

  // 5. Early returns
  if (!user) {
    return null;
  }

  // 6. Render JSX
  return (
    <TouchableOpacity style={styles.container} onPress={handlePress}>
      <Avatar uri={user.avatar} size={48} />
      <View style={styles.content}>
        <Text style={styles.name}>{user.name}</Text>
        <Text style={styles.email}>{user.email}</Text>
      </View>
      {showBadge && <Badge count={user.notificationCount} />}
    </TouchableOpacity>
  );
};

// 7. Styles at bottom
const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    backgroundColor: '#fff',
  },
  content: {
    flex: 1,
    marginLeft: 12,
  },
  name: {
    fontSize: 16,
    fontWeight: '600',
  },
  email: {
    fontSize: 14,
    color: '#666',
  },
});
```

## Composition Over Inheritance

### Rule: Build Complex Components from Simple Ones

```typescript
// ❌ BAD: Monolithic component (hard to reuse, test, maintain)
export const UserProfile: React.FC<Props> = ({ userId }) => {
  const user = useUser(userId);
  const posts = useUserPosts(userId);
  const followers = useFollowers(userId);

  return (
    <ScrollView>
      <View style={styles.header}>
        <Image source={{ uri: user.avatar }} style={styles.avatar} />
        <Text style={styles.name}>{user.name}</Text>
        <Text style={styles.bio}>{user.bio}</Text>
      </View>

      <View style={styles.stats}>
        <Text>{posts.length} posts</Text>
        <Text>{followers.length} followers</Text>
      </View>

      <View style={styles.posts}>
        {posts.map(post => (
          <View key={post.id}>
            <Text>{post.title}</Text>
            <Text>{post.content}</Text>
          </View>
        ))}
      </View>
    </ScrollView>
  );
};

// ✅ GOOD: Composed from smaller components
// components/profile-header.tsx
export const ProfileHeader: React.FC<Props> = ({ user }) => {
  return (
    <View style={styles.container}>
      <Avatar uri={user.avatar} size={80} />
      <Text style={styles.name}>{user.name}</Text>
      <Text style={styles.bio}>{user.bio}</Text>
    </View>
  );
};

// components/profile-stats.tsx
export const ProfileStats: React.FC<Props> = ({ postsCount, followersCount }) => {
  return (
    <View style={styles.container}>
      <StatItem label="Posts" count={postsCount} />
      <StatItem label="Followers" count={followersCount} />
    </View>
  );
};

// components/post-list.tsx
export const PostList: React.FC<Props> = ({ posts }) => {
  return (
    <FlatList
      data={posts}
      renderItem={({ item }) => <PostCard post={item} />}
      keyExtractor={(item) => item.id}
    />
  );
};

// screens/user-profile-screen.tsx (composed)
export const UserProfileScreen: React.FC<Props> = ({ userId }) => {
  const user = useUser(userId);
  const posts = useUserPosts(userId);
  const followers = useFollowers(userId);

  return (
    <ScrollView>
      <ProfileHeader user={user} />
      <ProfileStats postsCount={posts.length} followersCount={followers.length} />
      <PostList posts={posts} />
    </ScrollView>
  );
};
```

## Presentational vs Container Components

### Rule: Separate UI from Logic

```typescript
// ✅ GOOD: Presentational component (UI only)
// components/user-card-view.tsx
interface UserCardViewProps {
  name: string;
  email: string;
  avatar: string;
  isOnline: boolean;
  onPress: () => void;
}

export const UserCardView: React.FC<UserCardViewProps> = ({
  name,
  email,
  avatar,
  isOnline,
  onPress,
}) => {
  return (
    <TouchableOpacity style={styles.container} onPress={onPress}>
      <Avatar uri={avatar} size={48} />
      {isOnline && <View style={styles.onlineBadge} />}
      <View style={styles.content}>
        <Text style={styles.name}>{name}</Text>
        <Text style={styles.email}>{email}</Text>
      </View>
    </TouchableOpacity>
  );
};

// ✅ GOOD: Container component (logic only)
// components/user-card-container.tsx
interface UserCardContainerProps {
  userId: string;
}

export const UserCardContainer: React.FC<UserCardContainerProps> = ({ userId }) => {
  const navigation = useNavigation();
  const user = useUser(userId);
  const isOnline = useUserOnlineStatus(userId);

  const handlePress = useCallback(() => {
    navigation.navigate('UserProfile', { userId });
  }, [userId, navigation]);

  if (!user) {
    return <ActivityIndicator />;
  }

  return (
    <UserCardView
      name={user.name}
      email={user.email}
      avatar={user.avatar}
      isOnline={isOnline}
      onPress={handlePress}
    />
  );
};

// Usage: Only use container component
<UserCardContainer userId="123" />
```

## Props Pattern: Props Down, Events Up

### Rule: Data Flows Down, Events Bubble Up

```typescript
// ✅ GOOD: Clear data flow
interface ParentProps {}

export const Parent: React.FC<ParentProps> = () => {
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [users, setUsers] = useState<User[]>([]);

  // Event handlers in parent
  const handleUserSelect = useCallback((user: User) => {
    setSelectedUser(user);
  }, []);

  const handleUserDelete = useCallback((userId: string) => {
    setUsers((prev) => prev.filter((u) => u.id !== userId));
  }, []);

  // Pass data down, receive events up
  return (
    <View>
      <UserList
        users={users} // Data down
        onUserSelect={handleUserSelect} // Event up
        onUserDelete={handleUserDelete} // Event up
      />
      {selectedUser && (
        <UserDetails user={selectedUser} /> // Data down
      )}
    </View>
  );
};

interface UserListProps {
  users: User[];
  onUserSelect: (user: User) => void;
  onUserDelete: (userId: string) => void;
}

const UserList: React.FC<UserListProps> = ({
  users,
  onUserSelect,
  onUserDelete,
}) => {
  return (
    <FlatList
      data={users}
      renderItem={({ item }) => (
        <UserCard
          user={item} // Data down
          onPress={() => onUserSelect(item)} // Event up
          onDelete={() => onUserDelete(item.id)} // Event up
        />
      )}
    />
  );
};
```

## Compound Components Pattern

### Rule: Components That Work Together

```typescript
// ✅ GOOD: Compound components with context
// components/card/context.tsx
interface CardContextValue {
  variant: 'default' | 'outlined' | 'elevated';
}

const CardContext = React.createContext<CardContextValue | null>(null);

// components/card/card.tsx
interface CardProps {
  children: ReactNode;
  variant?: 'default' | 'outlined' | 'elevated';
}

export const Card: React.FC<CardProps> = ({ children, variant = 'default' }) => {
  return (
    <CardContext.Provider value={{ variant }}>
      <View style={[styles.card, styles[variant]]}>{children}</View>
    </CardContext.Provider>
  );
};

// components/card/card-header.tsx
export const CardHeader: React.FC<Props> = ({ children }) => {
  return <View style={styles.header}>{children}</View>;
};

// components/card/card-content.tsx
export const CardContent: React.FC<Props> = ({ children }) => {
  return <View style={styles.content}>{children}</View>;
};

// components/card/card-footer.tsx
export const CardFooter: React.FC<Props> = ({ children }) => {
  return <View style={styles.footer}>{children}</View>;
};

// Export as compound component
export const CardComponents = {
  Root: Card,
  Header: CardHeader,
  Content: CardContent,
  Footer: CardFooter,
};

// Usage
import { CardComponents as Card } from '@/components/card';

<Card.Root variant="elevated">
  <Card.Header>
    <Text>Card Title</Text>
  </Card.Header>
  <Card.Content>
    <Text>Card content goes here</Text>
  </Card.Content>
  <Card.Footer>
    <Button title="Action" onPress={() => {}} />
  </Card.Footer>
</Card.Root>
```

## Render Props Pattern

### Rule: Share Logic via Render Props

```typescript
// ✅ GOOD: Render props for flexible rendering
interface DataFetcherProps<T> {
  url: string;
  children: (data: T | null, loading: boolean, error: Error | null) => ReactElement;
}

export function DataFetcher<T>({ url, children }: DataFetcherProps<T>) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        const response = await fetch(url);
        const json = await response.json();
        setData(json);
      } catch (err) {
        setError(err as Error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [url]);

  return children(data, loading, error);
}

// Usage: Flexible rendering based on state
export const UserProfile: React.FC<Props> = ({ userId }) => {
  return (
    <DataFetcher<User> url={`/api/users/${userId}`}>
      {(user, loading, error) => {
        if (loading) return <ActivityIndicator />;
        if (error) return <ErrorView error={error} />;
        if (!user) return <Text>User not found</Text>;

        return (
          <View>
            <Text>{user.name}</Text>
            <Text>{user.email}</Text>
          </View>
        );
      }}
    </DataFetcher>
  );
};
```

## Higher-Order Components (HOCs)

### Rule: Use HOCs for Cross-Cutting Concerns

```typescript
// ✅ GOOD: HOC for error boundary
export function withErrorBoundary<P extends object>(
  Component: React.ComponentType<P>,
  fallback?: ReactElement,
) {
  return (props: P) => (
    <ErrorBoundary fallback={fallback}>
      <Component {...props} />
    </ErrorBoundary>
  );
}

// Usage
const SafeUserProfile = withErrorBoundary(UserProfile);

// ✅ GOOD: HOC for loading state
export function withLoadingState<P extends object>(
  Component: React.ComponentType<P>,
  isLoading: boolean,
) {
  return (props: P) => {
    if (isLoading) {
      return <ActivityIndicator />;
    }
    return <Component {...props} />;
  };
}

// ✅ GOOD: HOC for authentication
export function withAuth<P extends object>(Component: React.ComponentType<P>) {
  return (props: P) => {
    const { user, loading } = useAuth();

    if (loading) return <ActivityIndicator />;
    if (!user) return <LoginScreen />;

    return <Component {...props} />;
  };
}

// Usage
const ProtectedScreen = withAuth(UserDashboard);
```

## Component Organization by Feature

### Rule: Feature-Based Folder Structure

```
src/
├── features/
│   ├── auth/
│   │   ├── components/
│   │   │   ├── login-form.tsx
│   │   │   ├── signup-form.tsx
│   │   │   └── auth-provider.tsx
│   │   ├── hooks/
│   │   │   ├── use-auth.ts
│   │   │   └── use-login.ts
│   │   ├── screens/
│   │   │   ├── login-screen.tsx
│   │   │   └── signup-screen.tsx
│   │   ├── types/
│   │   │   └── auth.ts
│   │   └── index.ts
│   │
│   ├── profile/
│   │   ├── components/
│   │   │   ├── profile-header.tsx
│   │   │   ├── profile-stats.tsx
│   │   │   └── edit-profile-form.tsx
│   │   ├── hooks/
│   │   │   └── use-profile.ts
│   │   ├── screens/
│   │   │   ├── profile-screen.tsx
│   │   │   └── edit-profile-screen.tsx
│   │   └── index.ts
│   │
│   └── posts/
│       ├── components/
│       │   ├── post-card.tsx
│       │   ├── post-list.tsx
│       │   └── create-post-form.tsx
│       ├── hooks/
│       │   ├── use-posts.ts
│       │   └── use-create-post.ts
│       ├── screens/
│       │   ├── posts-screen.tsx
│       │   └── post-detail-screen.tsx
│       └── index.ts
│
└── shared/
    ├── components/
    │   ├── button.tsx
    │   ├── input.tsx
    │   ├── card.tsx
    │   └── avatar.tsx
    └── hooks/
        ├── use-fetch.ts
        └── use-debounce.ts
```

## Component Patterns Checklist

- [ ] Components are functional (no class components)
- [ ] Components follow single responsibility principle
- [ ] Complex UIs built through composition
- [ ] Presentational components separated from container components
- [ ] Props flow down, events bubble up
- [ ] Compound components used for related UI elements
- [ ] HOCs used for cross-cutting concerns
- [ ] Feature-based folder structure maintained
- [ ] Styles defined with StyleSheet at bottom of file
- [ ] Types defined above component implementation

## Common Component Violations

### Violation 1: God Component

```typescript
// ❌ CRITICAL: Monolithic component doing too much
export const Dashboard: React.FC = () => {
  const [users, setUsers] = useState([]);
  const [posts, setPosts] = useState([]);
  const [comments, setComments] = useState([]);
  // 500 lines of logic and UI...

  return (
    <View>
      {/* 1000 lines of JSX */}
    </View>
  );
};

// ✅ FIXED: Split into smaller components
export const Dashboard: React.FC = () => {
  return (
    <View>
      <DashboardHeader />
      <UserSection />
      <PostSection />
      <CommentSection />
    </View>
  );
};
```

### Violation 2: Props Drilling

```typescript
// ❌ BAD: Passing props through many levels
<Parent>
  <Child user={user} theme={theme}>
    <GrandChild user={user} theme={theme}>
      <GreatGrandChild user={user} theme={theme} />
    </GrandChild>
  </Child>
</Parent>

// ✅ FIXED: Use context or state management
const UserContext = React.createContext();

<UserContext.Provider value={user}>
  <ThemeContext.Provider value={theme}>
    <Parent>
      <Child>
        <GrandChild>
          <GreatGrandChild />
        </GrandChild>
      </Child>
    </Parent>
  </ThemeContext.Provider>
</UserContext.Provider>
```

### Violation 3: Inline Anonymous Functions

```typescript
// ❌ BAD: Creates new function every render
<TouchableOpacity onPress={() => handlePress(item.id)}>
  <Text>{item.name}</Text>
</TouchableOpacity>

// ✅ FIXED: Memoize or extract to component
const handlePress = useCallback(() => {
  onPress(item.id);
}, [item.id, onPress]);

<TouchableOpacity onPress={handlePress}>
  <Text>{item.name}</Text>
</TouchableOpacity>

// Or extract to separate component
<ItemCard item={item} onPress={onPress} />
```

## Conclusion

Component architecture patterns focus on building maintainable, reusable, and testable components. Use composition, separate concerns, and organize code by feature to create scalable React Native applications.
