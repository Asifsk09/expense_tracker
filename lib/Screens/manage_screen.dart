import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageScreen extends StatefulWidget {
  const ManageScreen({super.key});

  @override
  State<ManageScreen> createState() => _ManageScreenState();
}

class _ManageScreenState extends State<ManageScreen> {

  final TextEditingController incomeController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  final List<String> categories = ["Food", "Travel", "Shopping", "Bills", "Other"];
  String selectedCategory = "Food";

  // ✅ SAVE INCOME
  void _saveIncome() async {
    double value = double.tryParse(incomeController.text) ?? 0;
    if (value <= 0) return;

    await FirebaseFirestore.instance
        .collection('income')
        .doc('monthly')
        .set({'amount': value});

    incomeController.clear();

    // ✅ SNACKBAR
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Income saved ✔")),
    );
  }

  // ✅ ADD EXPENSE WITH MONTH
  void _addExpense() async {
    String title = titleController.text;
    double amount = double.tryParse(amountController.text) ?? 0;

    if (title.isEmpty || amount <= 0) return;

    String currentMonth =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

    await FirebaseFirestore.instance.collection('expense').add({
      'title': title,
      'amount': amount,
      'category': selectedCategory,
      'month': currentMonth,
      'timestamp': DateTime.now(),
    });

    titleController.clear();
    amountController.clear();

    // ✅ SNACKBAR
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

            const Text("Add Income",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            TextField(
              controller: incomeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Monthly Income"),
            ),

            ElevatedButton(
              onPressed: _saveIncome,
              child: const Text("Save Income"),
            ),

            const Divider(height: 40),

            const Text("Add Expense",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Expense Title"),
            ),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount"),
            ),

            DropdownButton<String>(
              value: selectedCategory,
              items: categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),

            ElevatedButton(
              onPressed: _addExpense,
              child: const Text("Add Expense"),
            ),
          ],
        ),
      ),
    );
  }
}