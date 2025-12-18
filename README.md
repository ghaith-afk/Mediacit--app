# mediatech

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
"# Mediacit--app" 
"# Mediacit--app" 



Mediacité 📚🎬

Version: 1.0
Type: Mobile application (cross-platform)
Technologies: Flutter, Dart, Firebase
Architecture: MVC (Model-View-Controller)
Platforms: Android / iOS

Table of Contents

Project Overview

Features

User Roles

Architecture

UI / UX

Security & Permissions

Advanced Features

Installation & Setup

Project Structure

Evaluation Criteria

Planning

Deliverables

Project Overview

Mediacité is a mobile application designed to modernize local cultural life by facilitating access to city library resources. The app allows citizens and library staff to manage media, events, and user interactions efficiently while reducing administrative processes.

Key Objectives:

Browse and manage media catalogs (books, magazines, films)

Reserve and borrow media

Register and manage cultural events

Communicate within the library community

Reduce administrative procedures

Features
A) Catalogue

Advanced search (title, author, category, barcode)

Filters: availability, new items, average ratings

Media details: summary, genre, pages/duration, cover image

Ratings & reviews

Tag & theme management

B) Borrowing & Reservation

Queue-based reservations

QR/Barcode scanning for borrowing & returns

Reminder notifications

Borrow extension if available

Configurable limit of simultaneous borrowings

C) Cultural Events

Interactive calendar

Online registration

Automatic notifications

Photo & report publishing

Seat availability management

D) Communication

Internal moderated messaging

Announcement wall

Push notifications

E) User Personal Space

Borrowing history

Wishlist / favorites

Personalized alerts

Profile management

Status: Active / Pending / Suspended

F) Admin Dashboard

Full CRUD: media, events, users

Permissions management

Statistics & alerts

Content moderation

User Roles
Role	Permissions
Visitor	Limited catalog access, account registration
User	Full catalog, reservations & borrowings, event participation, personal profile
Admin	Manage media, events, users, permissions, announcements
Architecture

Frontend: Flutter 3.x / Dart 3.x
Backend: Firebase (Auth, Firestore, Storage)
State Management: Provider / Riverpod
Local Storage: Hive / SharedPreferences
Notifications: Firebase Cloud Messaging
Structure:

lib/
├── models/
├── controllers/
├── views/
├── services/
├── widgets/
└── utils/

UI / UX

Modern, cultural, and accessible style

Color palette: Bordeaux, Gold, Night Blue

Icons inspired by artistic elements

Dark mode supported

Main navigation: Home | Catalogue | Events | Messages | Profile

Security & Permissions

Secure authentication with Firebase Auth

Firestore rules based on user role

Strict database permissions

Protection of content and user communications

Advanced Features (Bonus)

Automatic ISBN scanning

Intelligent recommendations based on user history

PDF export of statistics

Multi-language support (FR | EN)

Partial offline mode

Installation & Setup

Clone the repository:

git clone https://github.com/<username>/Mediacite.git


Navigate to project directory:

cd Mediacite


Install dependencies:

flutter pub get


Run the app:

flutter run


Make sure you have Flutter SDK installed and configured for Android/iOS development.

Evaluation Criteria

Main features: 40%

MVC architecture & modularity: 20%

UI/UX design & navigation: 15%

Code quality & documentation: 15%

Version control (Git): 10%

Bonus (tests, deployment, performance): +10%

Planning
Week	Objective
1	Project setup, Authentication, Models
2	Catalogue, CRUD Admin
3	Borrowing, Notifications
4	Events, Messaging
5	Polishing, Testing, Deployment
Deliverables

Source code (GitHub/GitLab)

APK / distribution link

UI mockups

Final presentation (5–10 min)

User & technical documentation

Final Goal: Provide a modern, efficient, and accessible digital solution for city libraries.
