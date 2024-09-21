// Import necessary packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Page for welcoming the user
class welcome_user_page extends StatefulWidget {
  const welcome_user_page({super.key});

  @override
  welcome_user_page_state createState() => welcome_user_page_state();
}

class welcome_user_page_state extends State<welcome_user_page> {
  // Variable to hold user's first name
  String firstName = '';

  @override
  void initState() {
    super.initState();
    get_user_name(); // Fetch user's first name from Firebase
  }

  // Fetch user's first name from Firebase
  Future<void> get_user_name() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        firstName = userDoc['First name'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Create the visual structure of the welcome page
    return Scaffold(
      // Create app bar for the welcome page
      appBar: AppBar(
        // Background color of the app bar
        backgroundColor: const Color.fromARGB(255, 207, 205, 205),
        // Title of the app bar
        title: Text(
          'Welcome, $firstName',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black, // Text color
          ),
        ),
      ),
      // Background color of the page
      backgroundColor: Colors.green,
      // Drawer with user options
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              tileColor: Colors.lightGreenAccent,
              title: const Text('User Information'),
              onTap: () {
                Navigator.pushNamed(context, '/user_info');
              },
            ),
            ListTile(
              tileColor: Colors.lightGreen,
              title: const Text('Shopping History'),
              onTap: () {
                Navigator.pushNamed(context, '/user_history');
              },
            ),
            ListTile(
              tileColor: Colors.green,
              title: const Text('LOG OUT'),
              onTap: () {
                Navigator.pushNamed(context, '/decide');
              },
            ),
          ],
        ),
      ),

      // The body of the welcome page
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Row containing two buttons (Admin and User)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Button for admin
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/go_shop');
                  },
                  child: const Text(
                    'Go shopping at the super market',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.red),
                  ),
                ),
                const SizedBox(width: 10),
                // Button for user
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/shop_online');
                  },
                  child: const Text(
                    'Online shopping',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
