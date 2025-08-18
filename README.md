# 📱 Share Mart

Share Mart is a **community-driven marketplace app** built with **Flutter & Firebase**, where users can **Sell, Donate, Exchange, or Request** items.  
It provides a sustainable and collaborative platform that encourages sharing while reducing waste.

---

## 🚀 Features

### 👤 User Features

- **Authentication & Profiles**
    - Sign up / Login with Firebase Authentication
    - User profile management (personal info, uploaded items, and orders)

- **Item Categories**
    - **Sell**: Post items for sale with details, images, and price
    - **Donate**: Share unused items for free with others in need
    - **Exchange**: Swap items with other community members
    - **Request**: Post requests for items you need

- **Item Management**
    - Upload items with images (Firebase Storage)
    - Edit or delete uploaded items
    - View item details with rich UI

- **Orders & Tracking**
    - Place and manage orders for items
    - Track order status: **Pending / Success**
    - Admin approval system for pending requests

- **Real-time Chat**
    - Chat with sellers, donators, and exchangers via Firebase Realtime Database
    - Support for **text & image messages**
    - WhatsApp-like message ticks:
        - ✓ Sent
        - ✓✓ Delivered
        - ✓✓ Blue (Read)
    - Chats sorted by latest message

---

### 🛠️ Admin Features

- View all pending and completed orders
- Approve or mark orders as successful
- Manage reported items and users

---

## 🏗️ Tech Stack

### **Frontend (Mobile App)**
- Flutter (Dart)
- Firebase SDKs (Firestore, Auth, Storage, Realtime Database)
- State management with **Provider**
- UI: Material Design & Custom Widgets

### **Backend**
- **Firebase Firestore** → User profiles, items, orders
- **Firebase Auth** → Authentication
- **Firebase Storage** → Item images, user profile pictures
- **Firebase Realtime Database** → Real-time chat system

---

## 📂 Project Structure

share_mart/
│
├── client/ # Flutter App
│ ├── lib/
│ │ ├── data/ # Models & Firebase Services
│ │ ├── screens/ # UI Screens
│ │ │ ├── auth/ # Login & Signup
│ │ │ ├── home/ # Home page & categories
│ │ │ ├── chat/ # Real-time chat screens
│ │ │ ├── orders/ # Orders & Admin panel
│ │ │ └── details/ # Item detail pages
│ │ ├── widgets/ # Reusable custom widgets
│ │ └── main.dart # App entry point




---

## ⚙️ Setup Instructions

### 🔑 Prerequisites
- Flutter SDK installed ([Install Guide](https://docs.flutter.dev/get-started/install))
- Firebase project configured
- Android Studio / VS Code

### 📝 Steps

1. Clone this repo
   ```bash
   git clone https://github.com/your-username/share_mart.git
   cd share_mart/client


Install dependencies

flutter pub get

Configure Firebase

    Add google-services.json (Android) in android/app/

    Add GoogleService-Info.plist (iOS) in ios/Runner/

Run the app

    flutter run

📸 Screenshots

(Add app screenshots here — e.g., home screen, item details, chat screen, orders page, etc.)



Would you like me to also make a **shorter, student-friendly version** (2–3 pages only) that you can directly paste in your **FYP Report**?

