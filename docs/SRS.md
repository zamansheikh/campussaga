# Software Requirements Specification (SRS) for Campus Saga

## 1. Introduction

### 1.1 Purpose

The purpose of this document is to define the software requirements for the **Campus Saga** app, outlining its features, functionality, and constraints.

### 1.2 Scope

The **Campus Saga** app aims to provide a platform for university students to anonymously post and review issues within their respective institutions, interact with university authorities, and engage with promotions or advertisements.The users can view the issues of other universitys if they are not a student of that university.The users who are not varified through their respective institutions id cards, can't post any issues or promotions. 

## 2. System Overview

### 2.1 System Description

The system will consist of a mobile application developed using Flutter and the GetX library. It will follow the Model-View-Controller (MVC) pattern for organization, firebase for database managment and authentication.

### 2.2 Key Features

- User registration and authentication.
- Anonymous posting of university-related issues.
- Rating of universities based on user reviews.
- Interaction between users and university authorities.
- Voting on the credibility of posted issues.
- Prioritization of issues based on urgency.
- Viewing and posting advertisements or promotions.
- Institute identification via student ID cards.

## 3. Specific Requirements

### 3.1 Functional Requirements

#### User Registration:

- Users must be able to create accounts using their university email addresses/Phone Number.
- User authentication should be implemented securely.

#### Institute Identification:

- Users must be identified by their student ID cards.
- Access to features is restricted based on the user's university affiliation.

#### Anonymous Issue Posting:

- Users can post issues related to their university anonymously.
- Each issue must include a description and category.
- Location tagging is optional but encouraged.

#### University Rating:

- The system will calculate a university rating based on isuue solving period, solved issue ratio, engagement.

#### Interaction with University Authorities:

- University authorities can view posted issues.
- They can provide comments to address the issues, marking them as resolved or unresolved.

#### User Interaction:

- Users can vote on the credibility of posted issues (true or false).
- They can upvote or downvote issues based on urgency.

#### Advertisement and Promotion:

- Users can view advertisements and promotions.
- A mechanism for posting advertisements must be provided to authorized users.



## 4. External Interface Requirements

### 4.1 User Interfaces

The app will have user-friendly interfaces for registration, issue posting, issue browsing, ranking universities, and interacting with university authorities, user profile.

### 4.2 API Interfaces

The app will interact with external APIs for location services (optional), authentication and user database management.

## 5. Performance Requirements

- The app should respond to user actions promptly, with minimal latency.
- The system must handle a large number of concurrent users efficiently.

## 6. Security Requirements

- User data, including registration details and posts, must be securely stored and transmitted.
- Authentication should be robust to prevent unauthorized access.
- Access control mechanisms should ensure data privacy.

## 7. Software Quality Attributes

- The app should be reliable, with minimal downtime.
- It should be maintainable and easy to update.
- Scalability should be considered to accommodate future growth.

## 8. Constraints

- The development team will work within the defined budget and timeline.
- Compliance with relevant privacy and data protection regulations is mandatory.

## 9. Assumptions and Dependencies

- The availability of Flutter and GetX libraries for development.
- Users have access to valid university email addresses/phone number for registration.

## 10. Appendices

- Glossary of terms and acronyms.
- Diagrams illustrating the system architecture or user workflows.

## 11. Review and Approval

The SRS document will undergo review and approval by org:deCodersFamily.

## 12. Change History

A record of changes made to the SRS document will be maintained.

## 13. References

N/A
