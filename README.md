# 💰 Expense Tracker App

A modern Flutter-based expense tracking application that helps users manage their income, track expenses, and visualize spending patterns with real-time analytics.

---

## 🚀 Features

### 📊 Dashboard

* View total income, expenses, and balance
* Monthly & yearly insights
* Interactive pie chart for category-wise spending
* Monthly comparison with previous data

### ➕ Manage Expenses & Income

* Add monthly income
* Add expenses with category selection
* Real-time updates using Firebase Firestore

### 📋 Transactions

* View all expenses in a clean list
* Filter by category
* Edit existing expenses
* Delete with confirmation

### 📤 Export Data

* Export filtered expenses to CSV
* Saved directly to device Downloads folder
* Compatible with Excel / Google Sheets

---

## 🛠️ Tech Stack

* **Flutter** (UI Framework)
* **Firebase Firestore** (Database)
* **fl_chart** (Charts & analytics)
* **csv** (Export functionality)

---

## 📂 Project Structure

```
lib/
│
├── main.dart
├── screens/
│   ├── dashboard_screen.dart
│   ├── transaction_screen.dart
│   └── manage_screen.dart
```

---

## ⚙️ Setup Instructions

1. Clone the repository:

```
git clone https://github.com/Asifsk09/expense_tracker.git
```

2. Navigate to project folder:

```
cd expense_tracker
```

3. Install dependencies:

```
flutter pub get
```

4. Run the app:

```
flutter run
```

---

## 🔐 Firebase Setup

* Create a Firebase project
* Add Android app
* Download `google-services.json`
* Place it inside:

```
android/app/
```

---

## 📈 Future Enhancements

* 🔐 User Authentication (Firebase Auth)
* 📊 Advanced charts & insights
* 📅 Daily tracking & custom date filters
* 📄 PDF export
* ☁️ Cloud backup per user

---

## 👨‍💻 Author

**Asif**

---

## ⭐ Support

If you like this project, consider giving it a ⭐ on GitHub!

---
