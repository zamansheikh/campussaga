# Business Process Model
```plaintext
+-----------------------------------------+
|       Campus Saga Business Process      |
+-----------------------------------------+
| Start                                   |
|                                         |
| 1. User Registration/Login              |
|   - User selects "Register" or "Login"  |
|   - If Register:                        |
|     - System prompts for registration  |
|       details                           |
|     - User provides details            |
|       - Validate input data             |
|       - Check for existing username    |
|       - Create a new user account      |
|   - If Login:                           |
|     - System prompts for credentials   |
|     - User provides login details      |
|       - Validate input data             |
|       - Authenticate user              |
|     - If valid, user logged in;         |
|       if invalid, return to login prompt|
|                                         |
| 2. Concern and Interaction Management  |
|   - User actions: Raise Concern, Vote   |
|     on Post, Interact with Promotion    |
|   - For Each Action:                    |
|     - Validate user and action details  |
|     - Record user action in the system  |
|     - For "Raise Concern":              |
|       - Create a new concern            |
|     - For "Vote on Post":               |
|       - Record user's vote on the post  |
|     - For "Interact with Promotion":    |
|       - Record user's interaction       |
|                                         |
| 3. Anonymous Interaction               |
|   - User selects "Anonymous Interaction"|
|   - System allows anonymous interaction |
|     - Record anonymous interaction     |
|                                         |
| 4. University Administrator Activities  |
|   - Univ Admin actions: Review Concerns,|
|     Manage Promotions                   |
|   - For "Review Concerns":              |
|     - Display concerns for review       |
|       - Filter concerns by university   |
|     - Univ Admin reviews concerns      |
|       - Resolve or mark concerns        |
|         for further action              |
|   - For "Manage Promotions":            |
|     - Display promotions for management|
|       - Filter promotions by university |
|     - Univ Admin manages promotions    |
|       - Approve, reject, or edit        |
|         promotions as needed            |
|                                         |
| 5. App Administrator Activities        |
|   - App Admin actions: Manage Users,    |
|     Manage Rankings                     |
|   - For "Manage Users":                 |
|     - Display user management options  |
|     - App Admin manages users           |
|       - Suspend, delete, or modify      |
|         user accounts as needed         |
|   - For "Manage Rankings":              |
|     - Display ranking management options|
|     - App Admin manages rankings        |
|       - Update university rankings     |
|         based on metrics                |
|                                         |
| 6. Logout                               |
|   - User selects "Logout"               |
|   - System logs out the user            |
|                                         |
| End                                     |
+-----------------------------------------+
```

This detailed breakdown provides a more granular view of the activities within each major process in the Campus Saga system. Each step involves specific actions, validations, and interactions to capture the intricacies of the system's functionality.
