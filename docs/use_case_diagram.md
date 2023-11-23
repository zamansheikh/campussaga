# Use Case Diagram

```plaintext
+----------------------------------------+
|             Campus Saga System          |
+----------------------------------------+
|               <<extends>>               |
|      +------------------------+        |
|      |   University Ranking   |        |
|      |        System          |        |
|      +------------------------+        |
|      | - calculateRanking()  |        |
|      +------------------------+        |
|                                        |
+----------------------------------------+
|              <<include>>               |
|       +------------------+             |
|       |   User Account   |             |
|       |     Management   |             |
|       +------------------+             |
|       | - register()     |             |
|       | - login()        |             |
|       | - logout()       |             |
|       | - editProfile()  |             |
|       | - viewProfile()  |             |
|       +------------------+             |
|                                        |
+----------------------------------------+
|               <<include>>               |
|         +-------------------+           |
|         |   Concern and    |           |
|         |   Interaction    |           |
|         |      Management   |           |
|         +-------------------+           |
|         | - raiseConcern() |           |
|         | - voteOnPost()   |           |
|         | - interactPromo()|           |
|         +-------------------+           |
|                                        |
+----------------------------------------+
|           <<include>>                  |
|       +----------------------+         |
|       | University Promotion |         |
|       |      Management      |         |
|       +----------------------+         |
|       | - postPromotion()   |         |
|       | - managePromotions()|         |
|       +----------------------+         |
|                                        |
+----------------------------------------+
|         <<extend>>                      |
|   +--------------------------+         |
|   | Anonymous Interaction    |         |
|   |       Extension           |         |
|   +--------------------------+         |
|   | - anonymousInteract()    |         |
|   +--------------------------+         |
|                                        |
+----------------------------------------+
|               <<extend>>               |
|      +------------------------+        |
|      | University Administrator|        |
|      |      Extension         |        |
|      +------------------------+        |
|      | - reviewPosts()       |        |
|      | - resolvePost()       |        |
|      | - managePromotions()  |        |
|      +------------------------+        |
|                                        |
+----------------------------------------+
|               <<extend>>               |
|          +----------------+            |
|          | App Administrator|            |
|          |    Extension    |            |
|          +----------------+            |
|          | - manageUsers()  |            |
|          | - manageRankings()|            |
|          +----------------+            |
+----------------------------------------+
```

Explanation:

1. **University Ranking System:**
   - This includes the functionality to calculate and update university rankings based on various metrics.

2. **User Account Management:**
   - Users can register, log in, log out, edit their profiles, and view their profiles.

3. **Concern and Interaction Management:**
   - Users can raise concerns, vote on posts, and interact with promotions.

4. **University Promotion Management:**
   - Users can post promotions, and administrators can manage promotions.

5. **Anonymous Interaction Extension:**
   - Users can interact with the system anonymously without creating an account.

6. **University Administrator Extension:**
   - University administrators can review and resolve concerns, as well as manage promotions.

7. **App Administrator Extension:**
   - App administrators can manage users and rankings.
