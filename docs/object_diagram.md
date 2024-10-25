# Object diagram
```plaintext
+-----------------------------------------+
|             Campus Saga System           |
+-----------------------------------------+
|                                         |
| +-------------------------------------+ |
| |          UserRegistration           | |
| |-------------------------------------| |
| | - users: [User]                    | |
| | +registerUser(userDetails): User   | |
| | +findUser(username): User           | |
| +-------------------------------------+ |
|            |                            |
|            | creates                    |
|            |                            |
| +-------------------------------------+ |
| |               User                  | |
| |-------------------------------------| |
| | - username: string                 | |
| | - password: string                 | |
| | - email: string                    | |
| | - university: University            | |
| +-------------------------------------+ |
|                                         |
| +-------------------------------------+ |
| |           UserManager               | |
| |-------------------------------------| |
| | - loggedInUsers: [User]             | |
| | +login(username, password): User   | |
| | +logout(user: User): void          | |
| +-------------------------------------+ |
|            |                            |
|            | creates                    |
|            |                            |
| +-------------------------------------+ |
| |             Concern                 | |
| |-------------------------------------| |
| | - description: string              | |
| | - category: string                 | |
| | - isResolved: boolean              | |
| | - votes: int                       | |
| +-------------------------------------+ |
|                                         |
| +-------------------------------------+ |
| |          ConcernManager            | |
| |-------------------------------------| |
| | - concerns: [Concern]              | |
| | +raiseConcern(user, details): void | |
| +-------------------------------------+ |
|            |                            |
|            | creates                    |
|            |                            |
| +-------------------------------------+ |
| |               Profile               | |
| |-------------------------------------| |
| | - name: string                     | |
| | - email: string                    | |
| | - university: University            | |
| +-------------------------------------+ |
|                                         |
| +-------------------------------------+ |
| |           UserProfile              | |
| |-------------------------------------| |
| | - profiles: [Profile]              | |
| | +viewProfile(user): Profile        | |
| | +editProfile(user, details): void  | |
| +-------------------------------------+ |
|            |                            |
|            | creates                    |
|            |                            |
| +-------------------------------------+ |
| |          University                | |
| |-------------------------------------| |
| | - name: string                     | |
| | - ranking: int                     | |
| +-------------------------------------+ |
|            |                            |
|            | creates                    |
|            |                            |
| +-------------------------------------+ |
| |        UniversityRanking            | |
| |-------------------------------------| |
| | - universities: [University]       | |
| | +calculateRanking(): void          | |
| | +updateMetrics(univ, metrics): void| |
| +-------------------------------------+ |
+-----------------------------------------+
```

Explanation:

1. **UserRegistration:**
   - Manages user registration, includes methods for registering users and finding users.

2. **User:**
   - Represents a user account with details like username, password, email, and associated university.

3. **UserManager:**
   - Manages user login and logout, keeps track of logged-in users.

4. **Concern:**
   - Represents a concern raised by a user with attributes like description, category, resolution status, and votes.

5. **ConcernManager:**
   - Manages concerns raised by users, includes a method to raise concerns.

6. **Profile:**
   - Represents a user's profile with attributes like name, email, and associated university.

7. **UserProfile:**
   - Manages user profiles, includes methods to view and edit profiles.

8. **University:**
   - Represents a university with attributes like name and ranking.

9. **UniversityRanking:**
   - Manages university rankings, includes methods to calculate rankings and update metrics.
