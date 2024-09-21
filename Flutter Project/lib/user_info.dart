// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Define a StatefulWidget for the user info page
class user_info_page extends StatefulWidget {
  const user_info_page({super.key});

  @override
  State<user_info_page> createState() => user_info_page_state();
}

// Define the state class for the user info page
class user_info_page_state extends State<user_info_page> {
  // Variables to hold user info
  String firstName = '';
  String lastName = '';
  String email = '';
  String mobilePhone = '';
  String address = '';
  String creditCardNumber = '';
  String creditCardPassword = '';

  // Function to display an alert message
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

  // Fetch user data from Firebase Firestore
  Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        firstName = userData['First name'];
        lastName = userData['Last name'];
        email = userData['Email'];
        mobilePhone = userData['Mobile Phone'];
        address = userData['address'];
        creditCardNumber = userData['creditCard Number'];
        creditCardPassword = userData['creditCard password'];
      });
    }
  }

  // Function to update a user field in Firebase Firestore
  Future<void> updateUserField(String field, String value) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({field: value});
    }
  }

  // Show dialog to update address
  void showUpdateAddressDialog() {
    final TextEditingController NEW_address =
        TextEditingController(text: address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Address'),
        content: TextField(
          controller: NEW_address,
          decoration: const InputDecoration(labelText: 'New Address'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close the dialog
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (NEW_address.text.isEmpty) {
                // Show alert if text is empty
                alert_message(context, "Error", "Address cannot be empty!");
              } else {
                // Update address in Firebase
                updateUserField('address', NEW_address.text);
                setState(() {
                  address = NEW_address.text;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // Show dialog to update credit card info
  void showUpdateCreditCardDialog() {
    final TextEditingController NEW_credit_number =
        TextEditingController(text: creditCardNumber);
    final TextEditingController NEW_card_password =
        TextEditingController(text: creditCardPassword);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Credit Card Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: NEW_credit_number,
              decoration:
                  const InputDecoration(labelText: 'New Credit Card Number'),
            ),
            TextField(
              controller: NEW_card_password,
              decoration:
                  const InputDecoration(labelText: 'New Credit Card Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close the dialog
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (NEW_credit_number.text.isEmpty ||
                  NEW_card_password.text.isEmpty) {
                // Show alert if any field is empty
                alert_message(context, "Error", "Both fields must be filled!");
              } else {
                // Update credit card info in Firebase
                updateUserField('creditCard Number', NEW_credit_number.text);
                updateUserField('creditCard password', NEW_card_password.text);
                setState(() {
                  creditCardNumber = NEW_credit_number.text;
                  creditCardPassword = NEW_card_password.text;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchUserData(); // Fetch the user data when the widget is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Center(
          // the text child of the background
          child: Text(
            'User information',
            //the style of the text and color of the app bar
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Text color
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Displaying user information
          INFORMATION_LAYOUT(label: 'First Name', value: firstName),
          INFORMATION_LAYOUT(label: 'Last Name', value: lastName),
          INFORMATION_LAYOUT(label: 'Email', value: email),
          INFORMATION_LAYOUT(label: 'Mobile Phone', value: mobilePhone),
          INFORMATION_LAYOUT(
            label: 'Address',
            value: address,
            trailing: ElevatedButton(
              onPressed: showUpdateAddressDialog,
              child: const Text('Change'),
            ),
          ),
          INFORMATION_LAYOUT(
            label: 'Credit Card Number',
            value: creditCardNumber,
            trailing: ElevatedButton(
              onPressed: showUpdateCreditCardDialog,
              child: const Text('Change'),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget to display each piece of user information in the list
class INFORMATION_LAYOUT extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;

  const INFORMATION_LAYOUT({
    super.key,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(value),
        trailing: trailing,
      ),
    );
  }
}