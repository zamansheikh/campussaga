# Activity Diagram

```plaintext
+-----------------------------------------+
|             Campus Saga System           |
+-----------------------------------------+
|                Start                    |
|-----------------------------------------|
|                                         |
| 1. User selects 'Register'               |
|   - System prompts for registration     |
|   - User enters registration details    |
|   - System creates a new user account   |
|   - End                                 |
|-----------------------------------------|
|                                         |
| 2. User selects 'Login'                  |
|   - System prompts for login credentials|
|   - User provides username and password |
|   - System verifies credentials         |
|   - If valid, user logged in            |
|   - End                                 |
|   - If invalid, return to login prompt  |
|-----------------------------------------|
|                                         |
| 3. User selects 'Raise Concern'          |
|   - User enters concern details         |
|   - System creates a new concern        |
|   - End                                 |
|-----------------------------------------|
|                                         |
| 4. User selects 'Vote on Post'           |
|   - User selects a post to vote on      |
|   - System records user's vote          |
|   - End                                 |
|-----------------------------------------|
|                                         |
| 5. User selects 'Interact with Promotion'|
|   - User selects a promotion to interact|
|   - System records interaction          |
|   - End                                 |
|-----------------------------------------|
|                                         |
| 6. User selects 'View Promotions'        |
|   - System displays promotions           |
|   - End                                 |
|-----------------------------------------|
|                                         |
| 7. User selects 'Logout'                 |
|   - System logs out the user             |
|   - End                                 |
|-----------------------------------------|
|                Anonymous                |
|                Interaction              |
|-----------------------------------------|
|                                         |
| 8. User selects 'Anonymous Interaction'  |
|   - User interacts anonymously          |
|   - End                                 |
|-----------------------------------------|
|            University Administrator     |
|                Activities               |
|-----------------------------------------|
|                                         |
| 9. Univ Admin selects 'Review Concerns'  |
|   - System displays concerns to review   |
|   - Univ Admin reviews and resolves      |
|   - End                                 |
|-----------------------------------------|
|                                         |
|10. Univ Admin selects 'Manage Promotions'|
|   - System displays promotions to manage|
|   - Univ Admin manages promotions        |
|   - End                                 |
|-----------------------------------------|
|              App Administrator           |
|                Activities               |
|-----------------------------------------|
|                                         |
|11. App Admin selects 'Manage Users'      |
|   - System displays user management     |
|   - App Admin manages users              |
|   - End                                 |
|-----------------------------------------|
|                                         |
|12. App Admin selects 'Manage Rankings'   |
|   - System displays ranking management  |
|   - App Admin manages rankings           |
|   - End                                 |
|-----------------------------------------|
```

Explanation:

1. **User Registration and Login:**
   - Users can register or log in to the system.

2. **Concerns and Interactions:**
   - Users can raise concerns, vote on posts, interact with promotions, and view promotions.

3. **Anonymous Interaction:**
   - Users can choose to interact with the system anonymously.

4. **University Administrator Activities:**
   - University administrators can review and resolve concerns and manage promotions.

5. **App Administrator Activities:**
   - App administrators can manage users and rankings.
