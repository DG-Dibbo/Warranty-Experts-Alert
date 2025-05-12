import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_warranty_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _uid;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _uid = user.uid;
      print("🟢 Logged-in UID: $_uid");
    } else {
      print("🔴 No user logged in.");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Warranty Tracker'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('warranties')
            .where('uid', isEqualTo: _uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No warranties added yet'));
          }

          final warranties = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: warranties.length,
            itemBuilder: (context, index) {
              final data = warranties[index].data() as Map<String, dynamic>;

              DateTime startDate = (data['startDate'] as Timestamp).toDate();
              DateTime endDate = (data['endDate'] as Timestamp).toDate();
              final product = data['productName'] ?? 'Unknown Product';
              final isExpired = endDate.isBefore(DateTime.now());

              final remaining = endDate.difference(DateTime.now());
              final years = remaining.inDays ~/ 365;
              final months = (remaining.inDays % 365) ~/ 30;
              final days = (remaining.inDays % 365) % 30;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("Start: ${startDate.toLocal().toString().split(' ')[0]}"),
                      Text("End: ${endDate.toLocal().toString().split(' ')[0]}",
                          style: TextStyle(
                            color: isExpired ? Colors.red : Colors.green,
                          )),
                      const SizedBox(height: 8),
                      Text(
                        isExpired
                            ? 'Expired'
                            : 'Remaining: $years years, $months months, $days days',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isExpired ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddWarrantyScreen()),
          );
          if (result == true) {
            setState(() {}); // Refresh UI after adding
          }
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
