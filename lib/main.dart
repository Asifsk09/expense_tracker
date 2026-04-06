import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  print("Firebase Initialized");

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
      home: const MyHomePage(title: 'Expense Tracker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController incomeController = TextEditingController();

  final List<String> categories = ["All", "Food", "Travel", "Shopping", "Bills", "Other"];
  String selectedCategory = "All";

  // ✅ SAVE INCOME
  void _saveIncome() async {
    double value = double.tryParse(incomeController.text) ?? 0;
    if (value <= 0) return;

    await FirebaseFirestore.instance
        .collection('income')
        .doc('monthly')
        .set({'amount': value});
  }

  // ✅ CREATE
  void _addExpense() async {
    String title = titleController.text;
    double amount = double.tryParse(amountController.text) ?? 0;

    if (title.isEmpty || amount <= 0) return;

    await FirebaseFirestore.instance.collection('expense').add({
      'title': title,
      'amount': amount,
      'category': selectedCategory == "All" ? "Other" : selectedCategory,
      'timestamp': DateTime.now(),
    });

    titleController.clear();
    amountController.clear();
  }

  // ✅ UPDATE
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
                      return DropdownMenuItem(value: cat, child: Text(cat));
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

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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

            // 🔹 INCOME
            TextField(
              controller: incomeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monthly Income'),
            ),

            ElevatedButton(
              onPressed: _saveIncome,
              child: const Text("Save Income"),
            ),

            const SizedBox(height: 10),

            // 🔹 EXPENSE INPUT
            TextField(controller: titleController),
            TextField(controller: amountController),

            ElevatedButton(
              onPressed: _addExpense,
              child: const Text("Add Expense"),
            ),

            const SizedBox(height: 20),

            // ✅ TOTAL + BALANCE
            StreamBuilder(
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
                      return const SizedBox();
                    }

                    var docs = expenseSnapshot.data!.docs;

                    double total = 0;

                    for (var doc in docs) {
                      total += (doc['amount'] as num).toDouble();
                    }

                    double balance = income - total;

                    return Column(
                      children: [
                        Text("Total: ₹$total"),
                        Text(
                          "Balance: ₹$balance",
                          style: TextStyle(
                            color: balance >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            // 🔹 LIST WITH FUNNY EMPTY STATE
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

                  var filteredDocs = selectedCategory == "All"
                      ? docs
                      : docs.where((doc) =>
                          doc['category'] == selectedCategory).toList();

                  // ✅ FUNNY EMPTY STATE
                  if (filteredDocs.isEmpty) {

                    String message;

                    if (selectedCategory == "All") {
                      message = "You're a super saver 😎💰";
                    } else {
                      message = "No $selectedCategory expenses... good job 👍";
                    }

                    return Center(
                      child: Text(
                        message,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      var data = filteredDocs[index];

                      return ListTile(
                        title: Text(data['title']),
                        subtitle:
                            Text("${data['amount']} • ${data['category']}"),
                        onTap: () {
                          _editExpense(
                            filteredDocs[index].id,
                            data['title'],
                            data['amount'],
                            data['category'],
                          );
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('expense')
                                .doc(filteredDocs[index].id)
                                .delete();
                          },
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