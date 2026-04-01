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

  // ✅ CREATE
  void _addExpense() async {
    String title = titleController.text;
    double amount = double.tryParse(amountController.text) ?? 0;

    if (title.isEmpty || amount <= 0) {
      print("Invalid input ❌");
      return;
    }

    await FirebaseFirestore.instance.collection('expense').add({
      'title': title,
      'amount': amount,
      'timestamp': DateTime.now(),
    });

    print("Expense added ✔");

    titleController.clear();
    amountController.clear();
  }

  // ✅ UPDATE
  void _editExpense(String docId, String oldTitle, dynamic oldAmount) {
    final TextEditingController editTitleController =
        TextEditingController(text: oldTitle);

    final TextEditingController editAmountController =
        TextEditingController(text: oldAmount.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Expense"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editTitleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: editAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount"),
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
                String newTitle = editTitleController.text;
                double newAmount =
                    double.tryParse(editAmountController.text) ?? 0;

                if (newTitle.isEmpty || newAmount <= 0) return;

                await FirebaseFirestore.instance
                    .collection('expense')
                    .doc(docId)
                    .update({
                  'title': newTitle,
                  'amount': newAmount,
                });

                print("Expense updated ✏️");

                Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            // 🔹 INPUT UI
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Expense Title',
              ),
            ),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _addExpense,
              child: const Text("Add Expense"),
            ),

            const SizedBox(height: 20),

            // 🔹 READ
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("expense")
                    .orderBy("timestamp", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No expense yet"));
                  }

                  var docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index];

                      String title = data.data().containsKey('title')
                          ? data['title']
                          : "No Title";

                      return ListTile(
                        title: Text(title),
                        subtitle: Text("₹${data['amount']}"),

                        onTap: () {
                          _editExpense(
                            docs[index].id,
                            title,
                            data['amount'],
                          );
                        },

                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('expense')
                                .doc(docs[index].id)
                                .delete();

                            print("Expense deleted ❌");
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