// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

// Class for Admin Login page
class login_as_admin_page extends StatelessWidget {
  const login_as_admin_page({super.key});

  @override
  Widget build(BuildContext context) {
    const String admin_username = "admin"; // Admin username constant
    const int admin_ID = 123456789; // Admin ID constant
    const String admin_password = "admin12"; // Admin password constant

    // Controllers for the text fields
    final TextEditingController user_name = TextEditingController();
    final TextEditingController ID = TextEditingController();
    final TextEditingController password = TextEditingController();

    // Function to display an alert dialog
    void alert_message(BuildContext context, String title, String content) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      // Create AppBar with a light red background
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: const Center(
          child: Text(
            'Admin Login',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Text color
            ),
          ),
        ),
      ),
      // Body of the Admin login page
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Admin Username TextField
            TextField(
              controller: user_name,
              decoration: const InputDecoration(labelText: 'Admin Username'),
            ),
            // Admin ID TextField
            TextField(
              controller: ID,
              decoration: const InputDecoration(labelText: 'Admin ID'),
              keyboardType: TextInputType.number,
            ),
            // Admin Password TextField
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Admin Password'),
            ),
            const SizedBox(height: 20),
            // Login Button
            ElevatedButton(
              onPressed: () {
                // Check if all fields are filled
                if (user_name.text.isEmpty ||
                    ID.text.isEmpty ||
                    password.text.isEmpty) {
                  alert_message(
                    context,
                    'Error',
                    'All fields must be filled. Please complete the form.',
                  );
                  return; // Prevent further execution if fields are empty
                }
                int? parsedId;
                try {
                  parsedId = int.parse(ID.text);
                } catch (e) {
                  alert_message(
                    context,
                    'Invalid ID',
                    'Please enter a valid numeric ID.',
                  );
                  return; // Stop further execution if the ID is not an integer
                }

                // Validate the admin credentials (example check)
                if (user_name.text != admin_username ||
                    parsedId != admin_ID ||
                    password.text != admin_password) {
                  alert_message(
                    context,
                    'Invalid Info',
                    'Please enter your admin information correctly.',
                  );
                  return; // Prevent further execution for wrong credentials
                }

                // If validation passes, navigate to the decide page
                Navigator.popAndPushNamed(context, '/shop_info');
              },
              child: const Text('Login as Admin'),
            ),
          ],
        ),
      ),
    );
  }
}
