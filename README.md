# Equitec HR Workforce Management System

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)
![Riverpod](https://img.shields.io/badge/Riverpod-%23000000.svg?style=for-the-badge&logo=riverpod&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%2304d3ff.svg?style=for-the-badge&logo=dart&logoColor=white)

EquitecHR is a high-performance HR management solution designed to eliminate "Operational Opacity" in the workplace. Built with Flutter and powered by Firebase, it provides real-time workforce tracking, automated payroll, and seamless task orchestration for both administrators and employees.

---

## 🚀 Key Features

### 🛠️ For Administrators (HR/Managers)
*   **Dynamic Dashboard**: Real-time telemetry cards and workforce heatmaps for immediate operational awareness.
*   **Employee Lifecycle Management**: Full CRUD operations for employee profiles, departments, and designations.
*   **Automated Attendance**: Monitor punch-in/out times, late marks, and half-day calculations automatically based on configurable HR rules.
*   **Intelligent Leave Management**: Review, approve, or reject leave requests with automated balance tracking.
*   **Payroll Processing**: Generate and manage payroll records based on attendance and leave data.
*   **Policy Configuration**: Define office timings, grace periods, and leave types directly within the app.
*   **Comprehensive Reports**: Exportable data for attendance, payroll, and tasks.

### 👥 For Employees
*   **One-Tap Attendance**: Quick punch-in and punch-out with location-aware validation (potential).
*   **Task Management**: View assigned tasks, update progress, and log work hours directly.
*   **Leave Application**: Submit leave requests and track approval status in real-time.
*   **Payslip Access**: View and download monthly payroll details.
*   **Profile Management**: Keep personal and professional information up to date.
*   **In-App Notifications**: Stay informed about task assignments, leave approvals, and company announcements.

---

## 🏗️ Technical Architecture

EquitecHR follows a **Feature-First Architecture**, ensuring high modularity and scalability.

*   **Frontend**: [Flutter](https://flutter.dev) (Single codebase for Android, iOS, and Web).
*   **State Management**: [Riverpod](https://riverpod.dev) — Robust, compile-safe reactive state handling.
*   **Navigation**: [GoRouter](https://pub.dev/packages/go_router) — Declarative routing for deep-linking and complex navigation.
*   **Backend as a Service (BaaS)**: [Firebase](https://firebase.google.com)
    *   **Authentication**: Secure username-based auth (silently mapped to Firebase Email/Pass).
    *   **Cloud Firestore**: Real-time NoSQL database for structured data.
    *   **Cloud Storage**: Secure storage for profile images and documents.
*   **UI/UX**: Custom design system using 'Syne' (headings) and 'Inter' (body) fonts for a premium aesthetic.
*   **Charts**: [FL Chart](https://pub.dev/packages/fl_chart) for data visualization.

---

## 🛠️ Getting Started

### Prerequisites
*   Flutter SDK (^3.11.0)
*   Dart SDK
*   Firebase Account

### Installation

1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/your-repo/HR-Workforce-Tracking-System.git
    cd HR-Workforce-Tracking-System/HR_Workforce_Management_System
    ```

2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Firebase Configuration**:
    This project requires a Firebase project. Detailed steps are provided in [FIREBASE_SETUP.md](HR_Workforce_Management_System/FIREBASE_SETUP.md).
    *   Initialize Firebase using FlutterFire CLI:
        ```bash
        flutterfire configure
        ```

4.  **Seed Initial Data**:
    Upon first run, log in as an admin and ensure the following services are called to seed default HR rules and leave types:
    ```dart
    await HrRulesService.seedDefaults();
    await LeaveService.seedLeaveTypes();
    ```

5.  **Run the App**:
    ```bash
    flutter run
    ```

---

## 🔐 Security & Roles

EquitecHR implements a strict Role-Based Access Control (RBAC) system:
*   **Admin**: Full access to all HR tools, employee data, and configurations.
*   **Employee**: Restricted access to personal data, assigned tasks, and own attendance/leave records.

Firestore security rules (documented in [FIREBASE_SETUP.md](HR_Workforce_Management_System/FIREBASE_SETUP.md)) ensure that users can only access data they are authorized to see.

---

## 🧪 Testing

Run internal tests using:
```bash
flutter test
```

---

## 🤝 Made By

*   **Mohammad Ali Sayyed**
*   **Harshal Pednekar**
*   **Nihar Gudekar**
*   **Devanand Prajapati**
