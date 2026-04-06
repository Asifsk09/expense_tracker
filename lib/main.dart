import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// ✅ Import screens (we will create these next)
import 'screens/dashboard_screen.dart';
import 'screens/manage_screen.dart';
import 'screens/transaction_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MainScreen(),
    );
  }
}

// ✅ Navigation Controller
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  int selectedIndex = 0;

  // ✅ Screens list
  final List<Widget> screens = [
    const DashboardScreen(),
    const ManageScreen(),
    const TransactionScreen(),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: screens[selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Manage",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: "Transactions",
          ),
        ],
      ),
    );
  }
}