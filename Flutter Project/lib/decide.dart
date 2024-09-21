import 'package:flutter/material.dart';

// Page for deciding whether the user wants to move the servo or see sensor readings
class decide_page extends StatelessWidget {
  const decide_page({super.key});

  @override
  Widget build(BuildContext context) {
    // Create the visual structure of the decide page
    return Scaffold(
      // Create app bar for the decide page
      appBar: AppBar(
        // Set the background color of the app bar
        backgroundColor: Colors.green,
        // Center the title text in the app bar
        title: const Center(
          child: Text(
            // Title of the app bar
            'WHO ARE YOU',
            // Style of the title text
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Text color
            ),
          ),
        ),
      ),
      // Set the background color of the page
      backgroundColor: const Color.fromARGB(212, 178, 50, 50),
      // Body of the decide page
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Welcome text
            const Text(
              'Welcome to our smart supermarket',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),

            // Prompt for the user to choose their role
            const Text(
              'Please choose who you are',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            // Row containing two buttons (Admin and User)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Button for admin
                ElevatedButton(
                  onPressed: () {
                    // Navigate to admin login page
                    Navigator.pushNamed(context, '/login_as_admin');
                  },
                  child: const Text(
                    'Admin',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.red),
                  ),
                ),
                const SizedBox(width: 10),
                // Button for user
                ElevatedButton(
                  onPressed: () {
                    // Navigate to user login page
                    Navigator.pushNamed(context, '/login_as_user');
                  },
                  child: const Text(
                    'User',
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
