import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageScreen extends StatefulWidget {
  const ManageScreen({super.key});

  @override
  State<ManageScreen> createState() => _ManageScreenState();
}

class _ManageScreenState extends State<ManageScreen> {

  final TextEditingController incomeController = TextEditingController();
  final TextEditingController expenseTitleController = TextEditingController();
  final TextEditingController expenseAmountController = TextEditingController();

  String selectedIncomeCategory = "Salary";
  String selectedExpenseCategory = "Food";

  DateTime selectedDate = DateTime.now();

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  final List<String> incomeCategories = [
    "Salary",
    "Bonus",
    "Freelance",
    "Other"
  ];

  final List<String> expenseCategories = [
    "Food",
    "Travel",
    "Shopping",
    "Bills",
    "Other"
  ];

  // 📅 PICK DATE
  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  // ✅ ADD INCOME
  Future<void> addIncome() async {

    double amount = double.tryParse(incomeController.text) ?? 0;
    if (amount <= 0) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('income')
        .add({
      "amount": amount,
      "category": selectedIncomeCategory,
      "date": Timestamp.fromDate(selectedDate),
    });

    incomeController.clear();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Income added ✔")),
    );
  }

  // ✅ ADD EXPENSE
  Future<void> addExpense() async {

    double amount = double.tryParse(expenseAmountController.text) ?? 0;
    String title = expenseTitleController.text.trim();

    if (amount <= 0 || title.isEmpty) return;

    String monthKey =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}";

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('expense')
        .add({
      "title": title,
      "amount": amount,
      "category": selectedExpenseCategory,
      "date": Timestamp.fromDate(selectedDate),
      "timestamp": Timestamp.fromDate(selectedDate),
      "month": monthKey,
    });

    expenseTitleController.clear();
    expenseAmountController.clear();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Expense added ✔")),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Manage")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // 🔹 ADD INCOME
            const Text("Add Income",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            
            //Show Added Income
            StreamBuilder(
  stream: FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('income')
      .snapshots(),
  builder: (context, snapshot) {

    double totalIncome = 0;

    if (snapshot.hasData) {
      for (var doc in snapshot.data!.docs) {
        totalIncome += (doc['amount'] as num).toDouble();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        "Total Income: ₹${totalIncome.toStringAsFixed(2)}",
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  },
),

const Divider(height: 40),

            TextField(
              controller: incomeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount"),
            ),

            DropdownButton<String>(
              value: selectedIncomeCategory,
              items: incomeCategories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (value) {
                setState(() => selectedIncomeCategory = value!);
              },
            ),

            Row(
              children: [
                Expanded(
                  child: Text(
                      "Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"),
                ),
                TextButton(
                  onPressed: pickDate,
                  child: const Text("Select Date"),
                ),
              ],
            ),

            ElevatedButton(
              onPressed: addIncome,
              child: const Text("Add Income"),
            ),

            const Divider(height: 40),

            // 🔹 ADD EXPENSE
            const Text("Add Expense",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            TextField(
              controller: expenseTitleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),

            TextField(
              controller: expenseAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount"),
            ),

            DropdownButton<String>(
              value: selectedExpenseCategory,
              items: expenseCategories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (value) {
                setState(() => selectedExpenseCategory = value!);
              },
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: addExpense,
              child: const Text("Add Expense"),
            ),
          ],
        ),
      ),
    );
  }
}