import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  String selectedView = "Month";

  // 🎨 CATEGORY COLORS
  final Map<String, Color> categoryColors = {
    "Food": Colors.blue,
    "Travel": Colors.green,
    "Shopping": Colors.orange,
    "Bills": Colors.red,
    "Other": Colors.purple,
  };

  @override
  Widget build(BuildContext context) {

    String currentMonth =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

    String currentYear = DateTime.now().year.toString();

    // 🔥 Previous Month (for comparison)
    DateTime now = DateTime.now();
    DateTime prev = DateTime(now.year, now.month - 1);
    String previousMonth =
        "${prev.year}-${prev.month.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),

      body: Padding(
        padding: const EdgeInsets.all(16.0),

        child: Column(
          children: [

            // 🔹 TOGGLE
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                    .collection("income")
                    .doc("monthly")
                    .snapshots(),
                builder: (context, incomeSnapshot) {

                  double income = 0;

                  if (incomeSnapshot.hasData &&
                      incomeSnapshot.data!.data() != null) {
                    income =
                        (incomeSnapshot.data!['amount'] as num).toDouble();
                  }

                  return StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection("expense")
                        .snapshots(),
                    builder: (context, expenseSnapshot) {

                      if (!expenseSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var docs = expenseSnapshot.data!.docs;

                      // ✅ FILTER CURRENT
                      var filteredDocs;

                      if (selectedView == "Month") {
                        filteredDocs = docs.where((doc) =>
                            doc.data().containsKey('month') &&
                            doc['month'] == currentMonth).toList();
                      } else {
                        filteredDocs = docs.where((doc) =>
                            doc.data().containsKey('month') &&
                            doc['month'].toString().startsWith(currentYear)).toList();
                      }

                      // 🔥 PREVIOUS MONTH DATA
                      var prevDocs = docs.where((doc) =>
                          doc.data().containsKey('month') &&
                          doc['month'] == previousMonth).toList();

                      double total = 0;
                      double prevTotal = 0;

                      Map<String, double> categoryData = {};

                      for (var doc in filteredDocs) {
                        double amount = (doc['amount'] as num).toDouble();
                        String category = doc['category'];

                        total += amount;

                        categoryData[category] =
                            (categoryData[category] ?? 0) + amount;
                      }

                      for (var doc in prevDocs) {
                        prevTotal += (doc['amount'] as num).toDouble();
                      }

                      double balance = income - total;

                      // 📊 PIE DATA WITH %
                      List<PieChartSectionData> sections =
                          categoryData.entries.map((entry) {

                        double percentage =
                            total == 0 ? 0 : (entry.value / total) * 100;

                        return PieChartSectionData(
                          color: categoryColors[entry.key] ?? Colors.grey,
                          value: entry.value,
                          title: "${percentage.toStringAsFixed(0)}%",
                          radius: 60,
                          titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        );
                      }).toList();

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [

                            // 🔹 CARDS
                            Card(
                              child: ListTile(
                                title: const Text("Income"),
                                subtitle: Text("₹${income.toStringAsFixed(2)}"),
                              ),
                            ),

                            Card(
                              child: ListTile(
                                title: Text(
                                    "Total (${selectedView == "Month" ? "This Month" : "This Year"})"),
                                subtitle: Text("₹${total.toStringAsFixed(2)}"),
                              ),
                            ),

                            // 🔥 COMPARISON
                            if (selectedView == "Month")
                              Card(
                                child: ListTile(
                                  title: const Text("Last Month"),
                                  subtitle:
                                      Text("₹${prevTotal.toStringAsFixed(2)}"),
                                ),
                              ),

                            Card(
                              color: balance >= 0
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              child: ListTile(
                                title: const Text("Balance"),
                                subtitle: Text(
                                  "₹${balance.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: balance >= 0
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // 🔹 PIE CHART
                            if (sections.isNotEmpty)
                              SizedBox(
                                height: 250,
                                child: PieChart(
                                  PieChartData(sections: sections),
                                ),
                              ),

                            const SizedBox(height: 20),

                            // 🔹 LEGEND
                            ...categoryData.entries.map((entry) {
                              return Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    color: categoryColors[entry.key] ??
                                        Colors.grey,
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
                                child: Text("You're a super saver 😎💰"),
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