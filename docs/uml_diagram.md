1. **User Account Hierarchy:**

   - Student
   - University Administrator
   - App Administrator

```plaintext
   +-----------------------------------+
   |               User                |
   +-----------------------------------+
          /         |           \
         /          |            \
+----------------+ +-----------------+ +---------------------+
|    Student     | | Univ Administrator | | App Administrator |
+----------------+ +-----------------+ +---------------------+
| - username     | | - username        | | - username          |
| - password     | | - password        | | - password          |
| - email        | | - email           | | - email             |
| - university   | | - university      | |                     |
+----------------+ +-----------------+ +---------------------+
| +raiseConcern()| | +reviewPosts()    | | +manageUsers()      |
| +voteOnPost()  | | +resolvePost()    | | +manageRankings()   |
| +interactPromo()| | +managePromotions| | +manageConcerns()   |
|                | |                   | |                     |
+----------------+ +-----------------+ +---------------------+
```

2. **Concerns and Interactions:**

```plaintext
+------------------+
|     Concern      |
+------------------+
| - description    |
| - category       |
| - isResolved      |
| - votes           |
| - timestamp       |
+------------------+
| +markResolved()  |
| +getVotes()      |
| +vote()          |
+------------------+

+------------------+
|  Promotion       |
+------------------+
| - content        |
| - university     |
| - timestamp      |
+------------------+
| +interact()      |
+------------------+
```

3. **Ranking Metrics:**

```plaintext
+---------------------+
|     University      |
+---------------------+
| - name              |
| - ranking           |
| - resolutionRate   |
| - engagement       |
| - problemSolving    |
| - satisfaction     |
+---------------------+
| +calculateRanking() |
| +updateMetrics()    |
+---------------------+
```

4. **Profile Management:**

```plaintext
+---------------------+
|       Profile       |
+---------------------+
| - name              |
| - email             |
| - university        |
| - verificationStatus|
+---------------------+
| +viewProfile()      |
| +editProfile()      |
| +verifyProfile()    |
+---------------------+
```

5. **Vote and Interaction:**

```plaintext
+------------------------+       +------------------------+
|         Vote           |       |      Interaction      |
+------------------------+       +------------------------+
| - voterUsername       |       | - username             |
| - isAgree              |       | - content              |
+------------------------+       | - timestamp            |
| +getVoter()            |       +------------------------+
| +isAgree()             |       | +getUser()             |
+------------------------+       | +getContent()          |
                                 +------------------------+
```

