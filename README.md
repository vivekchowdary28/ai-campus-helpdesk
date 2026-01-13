# ai_campus_helpdesk

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## iOS / Firebase notes
- Minimum iOS deployment target: **15.0**.
- Firestore security rules used in this project require authenticated reads (the app signs in anonymously after OTP verification during development). For production, use server-side checks or issue custom tokens to users.
