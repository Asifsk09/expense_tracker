import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {

  final List<String> categories = ["All", "Food", "Travel", "Shopping", "Bills", "Other"];
  String selectedCategory = "All";

  String get currentMonth =>
      "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

  // ✅ DELETE WITH CONFIRMATION + SNACKBAR
  void _deleteExpense(String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Expense"),
          content: const Text("Are you sure?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('expense')
                    .doc(docId)
                    .delete();

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Expense deleted ❌")),
                );
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  // ✅ EDIT WITH UPDATE SNACKBAR
  void _editExpense(String docId, String oldTitle, dynamic oldAmount, String oldCategory) {

    final TextEditingController editTitleController =
        TextEditingController(text: oldTitle);

    final TextEditingController editAmountController =
        TextEditingController(text: oldAmount.toString());

    String editCategory = oldCategory;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Edit Expense"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: editTitleController),
                  TextField(controller: editAmountController),

                  DropdownButton<String>(
                    value: editCategory,
                    items: categories.where((c) => c != "All").map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setStateDialog(() {
                        editCategory = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('expense')
                        .doc(docId)
                        .update({
                      'title': editTitleController.text,
                      'amount': double.tryParse(editAmountController.text) ?? 0,
                      'category': editCategory,
                    });

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Expense updated ✏️")),
                    );
                  },
                  child: const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 📤 EXPORT TO DOWNLOADS (NO PERMISSION REQUIRED)
  Future<void> _exportCSV() async {

    final snapshot = await FirebaseFirestore.instance
        .collection("expense")
        .orderBy("timestamp", descending: true)
        .get();

    var docs = snapshot.docs;

    // 🔹 Apply filters (same as UI)
    var monthDocs = docs.where((doc) =>
        doc.data().containsKey('month') &&
        doc['month'] == currentMonth).toList();

    var filteredDocs = selectedCategory == "All"
        ? monthDocs
        : monthDocs.where((doc) =>
            doc['category'] == selectedCategory).toList();

    // 🔹 Prepare CSV
    List<List<dynamic>> rows = [
      ["Title", "Amount", "Category", "Month"]
    ];

    for (var doc in filteredDocs) {
      rows.add([
        doc['title'],
        doc['amount'],
        doc['category'],
        doc['month'],
      ]);
    }

    String csvData = ListToCsvConverter().convert(rows);

    // 📁 SAVE TO DOWNLOADS
    final directory = Directory('/storage/emulated/0/Download');
    final path =
        "${directory.path}/expenses_${DateTime.now().millisecondsSinceEpoch}.csv";

    final file = File(path);
    await file.writeAsString(csvData);

    // ✅ FEEDBACK
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saved to Downloads ✔")),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transactions"),

        // 📤 EXPORT BUTTON
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportCSV,
          ),
        ],
      ),

      body: Column(
        children: [

          // 🔹 FILTER
          DropdownButton<String>(
            value: selectedCategory,
            items: categories.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Text("Filter: $cat"),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCategory = value!;
              });
            },
          ),

          // 🔹 LIST
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("expense")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;

                var monthDocs = docs.where((doc) =>
                    doc.data().containsKey('month') &&
                    doc['month'] == currentMonth).toList();

                var filteredDocs = selectedCategory == "All"
                    ? monthDocs
                    : monthDocs.where((doc) =>
                        doc['category'] == selectedCategory).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text("No expenses... you're doing great 👍"),
                  );
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var data = filteredDocs[index];

                    return Card(
                      child: ListTile(
                        title: Text(data['title']),
                        subtitle: Text(
                            "₹${data['amount']} • ${data['category']}"),

                        // EDIT
                        onTap: () {
                          _editExpense(
                            filteredDocs[index].id,
                            data['title'],
                            data['amount'],
                            data['category'],
                          );
                        },

                        // DELETE
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteExpense(filteredDocs[index].id);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

        ],
      ),
    );
  }
}