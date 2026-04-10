import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:csv/csv.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {

  final List<String> categories = ["All", "Food", "Travel", "Shopping", "Bills", "Other"];
  String selectedCategory = "All";

  DateTime? fromDate;
  DateTime? toDate;

  String quickFilter = "This Month";

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get expenseRef => FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('expense');

  String get currentMonth =>
      "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

  // ✅ SAFE DATE
  DateTime getDate(doc) {
    try {
      if (doc.data().toString().contains('date')) {
        return (doc['date'] as Timestamp).toDate();
      } else {
        return (doc['timestamp'] as Timestamp).toDate();
      }
    } catch (e) {
      return DateTime.now();
    }
  }

  // ✅ NORMALIZE
  DateTime normalize(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  // 📅 PICKERS
  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    
    if (!mounted) return;

    if (picked != null) setState(() => fromDate = picked);
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (!mounted) return;

    if (picked != null) setState(() => toDate = picked);
  }

  // 🔎 FILTER (OPTIMIZED)
  List<QueryDocumentSnapshot> applyFilters(List<QueryDocumentSnapshot> docs) {

    if (docs.isEmpty) return [];

    List<QueryDocumentSnapshot> result = List.from(docs);
    DateTime now = DateTime.now();

    if (quickFilter == "Today") {
      DateTime today = normalize(now);
      result = result.where((doc) =>
          normalize(getDate(doc)) == today).toList();
    }

    else if (quickFilter == "This Month") {
      result = result.where((doc) =>
          doc['month'] == currentMonth).toList();
    }

    else if (quickFilter == "Custom") {

      if (fromDate == null || toDate == null) return [];

      DateTime from = normalize(fromDate!);
      DateTime to = normalize(toDate!);

      result = result.where((doc) {
        DateTime d = normalize(getDate(doc));
        return (d.isAtSameMomentAs(from) || d.isAfter(from)) &&
               (d.isAtSameMomentAs(to) || d.isBefore(to));
      }).toList();
    }

    if (selectedCategory != "All") {
      result = result.where((doc) =>
          doc['category'] == selectedCategory).toList();
    }

    return result;
  }

  // 📤 EXPORT
  Future<void> _exportCSV(List<QueryDocumentSnapshot> filteredDocs) async {

    List<List<dynamic>> rows = [
      ["Title", "Amount", "Category", "Date"]
    ];

    for (var doc in filteredDocs) {
      DateTime d = getDate(doc);

      rows.add([
        doc['title'],
        doc['amount'],
        doc['category'],
        "${d.day}/${d.month}/${d.year}",
      ]);
    }

    String csvData = ListToCsvConverter().convert(rows);

    final file = File(
        "/storage/emulated/0/Download/expenses_${DateTime.now().millisecondsSinceEpoch}.csv");

    await file.writeAsString(csvData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saved to Downloads ✔")),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Transactions")),

      body: Column(
        children: [

          // 🔹 FILTER TYPE
          DropdownButton<String>(
            value: quickFilter,
            items: ["Today", "This Month", "Custom"].map((e) {
              return DropdownMenuItem(value: e, child: Text(e));
            }).toList(),
            onChanged: (value) => setState(() => quickFilter = value!),
          ),

          // 🔹 DATE UI
          if (quickFilter == "Custom")
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _pickFromDate,
                  child: Text(fromDate == null
                      ? "From"
                      : "${fromDate!.day}/${fromDate!.month}/${fromDate!.year}"),
                ),
                const SizedBox(width: 20),
                TextButton(
                  onPressed: _pickToDate,
                  child: Text(toDate == null
                      ? "To"
                      : "${toDate!.day}/${toDate!.month}/${toDate!.year}"),
                ),
              ],
            ),

          // 🔹 CATEGORY
          DropdownButton<String>(
            value: selectedCategory,
            items: categories.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Text("Category: $cat"),
              );
            }).toList(),
            onChanged: (value) => setState(() => selectedCategory = value!),
          ),

          Expanded(
            child: StreamBuilder(
              stream: expenseRef
                  .orderBy("timestamp", descending: true)
                  .limit(50)
                  .snapshots(), // 🔥 PERFORMANCE FIX
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;

                List<QueryDocumentSnapshot> filteredDocs;
                try {
                  filteredDocs = applyFilters(docs);
                } catch (e) {
                  filteredDocs = [];
                }

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text("No expenses 👍"));
                }

                return Column(
                  children: [

                    ElevatedButton(
                      onPressed: () => _exportCSV(filteredDocs),
                      child: const Text("Export CSV"),
                    ),

                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {

                          var data = filteredDocs[index];
                          DateTime d = getDate(data);

                          return Card(
                            child: ListTile(
                              title: Text(data['title']),
                              subtitle: Text(
                                  "₹${data['amount']} • ${data['category']} • ${d.day}/${d.month}/${d.year}"),

                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [

                                  // EDIT
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {

                                      TextEditingController titleCtrl =
                                          TextEditingController(text: data['title']);
                                      TextEditingController amountCtrl =
                                          TextEditingController(text: data['amount'].toString());

                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text("Update Expense"),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextField(controller: titleCtrl),
                                              TextField(
                                                controller: amountCtrl,
                                                keyboardType: TextInputType.number,
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text("Cancel"),
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                await expenseRef.doc(data.id).update({
                                                  "title": titleCtrl.text,
                                                  "amount": double.parse(amountCtrl.text),
                                                });

                                                Navigator.pop(context);

                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text("Updated ✔")),
                                                );
                                              },
                                              child: const Text("Update"),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),

                                  // DELETE
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {

                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text("Confirm Delete"),
                                          content: const Text("Are you sure?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text("Cancel"),
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                await expenseRef.doc(data.id).delete();

                                                Navigator.pop(context);

                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text("Deleted ✔")),
                                                );
                                              },
                                              child: const Text("Delete"),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}