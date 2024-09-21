import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class history_page extends StatefulWidget {
  const history_page({super.key});

  @override
  history_page_state createState() => history_page_state();
}

class history_page_state extends State<history_page> {
  String? userEmail; // To store the user's email
  bool isLoading = true; // To handle loading state
  List<Map<String, dynamic>> transactions = []; // To store the fetched transactions

  @override
  void initState() {
    super.initState();
    fetchUserTransactions();
  }

  // Method to fetch user transactions from Firestore
  Future<void> fetchUserTransactions() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        // Fetch user email from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            userEmail = userDoc['Email'];
          });

          // Fetch transactions for the user based on their email
          QuerySnapshot transactionSnapshot = await FirebaseFirestore.instance
              .collection('User_transactions')
              .where('User gmail', isEqualTo: userEmail)
              .orderBy('timestamp', descending: true) // Order by most recent transactions
              .get();

          if (transactionSnapshot.docs.isNotEmpty) {
            // Add each transaction to the list
            setState(() {
              transactions = transactionSnapshot.docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .toList();
              isLoading = false; // Loading completed
            });
          } else {
            // No transactions found
            setState(() {
              isLoading = false;
            });
          }
        } else {
          setState(() {
            isLoading = false; // Loading completed
          });
        }
      } catch (e) {
        setState(() {
          isLoading = false; // Loading completed
        });
        // Show an error message if fetching fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching transactions: $e')),
        );
      }
    } else {
      setState(() {
        isLoading = false; // Loading completed
      });
    }
  }

  // Widget to show when no transactions exist
  Widget noHistoryWidget() {
    return const Center(
      child: Text(
        'No history available',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Color.fromARGB(255, 52, 52, 52),
        ),
      ),
    );
  }

  // Widget to display transaction list
  Widget transactionList() {
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final cart = transaction['cart'] as List;
        final totalPrice = transaction['totalPrice'];
        final timestamp = (transaction['timestamp'] as Timestamp).toDate();

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction Date: ${timestamp.toString().substring(0, 16)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: cart.map((item) {
                    return Text(
                      '${item['name']} x ${item['quantity']}',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Price: \$${totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 94, 174, 132),
        title: const Center(
          child: Text(
            'Your Cart History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loader while fetching data
          : transactions.isEmpty
              ? noHistoryWidget() // Show 'No history' if no transactions
              : transactionList(), // Display the list of transactions
    );
  }
}
