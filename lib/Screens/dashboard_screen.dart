import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  String selectedView = "Month";

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  final Map<String, Color> categoryColors = {
    "Food": Colors.blue,
    "Travel": Colors.green,
    "Shopping": Colors.orange,
    "Bills": Colors.red,
    "Other": Colors.purple,
  };

  DateTime getDate(doc) {
    if (doc.data().toString().contains('date')) {
      return (doc['date'] as Timestamp).toDate();
    } else {
      return (doc['timestamp'] as Timestamp).toDate();
    }
  }

  @override
  Widget build(BuildContext context) {

    DateTime now = DateTime.now();

    String currentMonth =
        "${now.year}-${now.month.toString().padLeft(2, '0')}";
    String currentYear = now.year.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (!mounted) return;
              
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            // 🔹 TOGGLE
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Day"),
                  selected: selectedView == "Day",
                  onSelected: (_) => setState(() => selectedView = "Day"),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Month"),
                  selected: selectedView == "Month",
                  onSelected: (_) => setState(() => selectedView = "Month"),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Year"),
                  selected: selectedView == "Year",
                  onSelected: (_) => setState(() => selectedView = "Year"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('income')
                    .snapshots(),
                builder: (context, incomeSnap) {

                  double totalIncome = 0;

                  if (incomeSnap.hasData) {
                    for (var doc in incomeSnap.data!.docs) {
                      totalIncome += (doc['amount'] as num).toDouble();
                    }
                  }

                  return StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('expense')
                        .snapshots(),
                    builder: (context, snapshot) {

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var docs = snapshot.data!.docs;

                      var filteredDocs;

                      if (selectedView == "Day") {
                        filteredDocs = docs.where((doc) {
                          DateTime d = getDate(doc);
                          return d.year == now.year &&
                              d.month == now.month &&
                              d.day == now.day;
                        }).toList();
                      } else if (selectedView == "Month") {
                        filteredDocs = docs.where((doc) =>
                            doc['month'] == currentMonth).toList();
                      } else {
                        filteredDocs = docs.where((doc) =>
                            doc['month'].toString().startsWith(currentYear)).toList();
                      }

                      double totalExpense = 0;
                      double fullMonthExpense = 0;

                      Map<String, double> categoryData = {};

                      for (var doc in filteredDocs) {
                        double amt = (doc['amount'] as num).toDouble();
                        totalExpense += amt;

                        categoryData[doc['category']] =
                            (categoryData[doc['category']] ?? 0) + amt;
                      }

                      for (var doc in docs.where((d) => d['month'] == currentMonth)) {
                        fullMonthExpense += (doc['amount'] as num).toDouble();
                      }

                      double balance = totalIncome - fullMonthExpense;

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [

                            // 🔹 INCOME
                            Card(
                              child: ListTile(
                                title: const Text("Income"),
                                subtitle: Text("₹${totalIncome.toStringAsFixed(2)}"),
                              ),
                            ),

                            // 🔹 EXPENSE
                            Card(
                              child: ListTile(
                                title: const Text("Expense"),
                                subtitle: Text("₹${totalExpense.toStringAsFixed(2)}"),
                              ),
                            ),

                            // 🔹 BALANCE
                            Card(
                              color: balance >= 0
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              child: ListTile(
                                title: const Text("Balance"),
                                subtitle: Text(
                                  "₹${balance.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: balance >= 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // 🔥 PIE CHART WITH %
                            if (categoryData.isNotEmpty && totalExpense > 0)
                              SizedBox(
                                height: 250,
                                child: PieChart(
                                  PieChartData(
                                    sections: categoryData.entries.map((e) {
                                      double percent =
                                          (e.value / totalExpense) * 100;

                                      return PieChartSectionData(
                                        value: e.value,
                                        color: categoryColors[e.key] ?? Colors.grey,
                                        title: "${percent.toStringAsFixed(0)}%",
                                        radius: 60,
                                        titleStyle: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 20),

                            // 🔥 LEGEND
                            ...categoryData.entries.map((entry) {
                              return Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    color: categoryColors[entry.key] ?? Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                      "${entry.key} - ₹${entry.value.toStringAsFixed(0)}"),
                                ],
                              );
                            }),

                            const SizedBox(height: 20),

                            // 🔹 EMPTY STATE
                            if (filteredDocs.isEmpty)
                              const Center(
                                child: Text("You're a super saver 😎"),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}