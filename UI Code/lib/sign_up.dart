// ignore_for_file: use_build_context_synchronously

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Signup_page extends StatelessWidget {
  const Signup_page({super.key});

  @override
  Widget build(BuildContext context) {
    // Controllers for text fields
    final TextEditingController firstName = TextEditingController();
    final TextEditingController lastName = TextEditingController();
    final TextEditingController gmail = TextEditingController();
    final TextEditingController password = TextEditingController();
    final TextEditingController confirmPassword = TextEditingController();
    final TextEditingController mobileNumber = TextEditingController();
    final TextEditingController address = TextEditingController();
    final TextEditingController creditcardNumber = TextEditingController();
    final TextEditingController creditcardPassword = TextEditingController();

    // Function to display alert messages
    void alertMessage(BuildContext context, String title, String content) {
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

    // Function to register a user
    Future<void> registerUser() async {
      // Validate input fields
      if (address.text.isEmpty ||
          firstName.text.isEmpty ||
          lastName.text.isEmpty ||
          gmail.text.isEmpty ||
          password.text.isEmpty ||
          creditcardPassword.text.isEmpty ||
          mobileNumber.text.isEmpty ||
          creditcardNumber.text.isEmpty ||
          confirmPassword.text.isEmpty) {
        alertMessage(context, 'Error', 'All fields cannot be empty');
        return;
      }

      if (mobileNumber.text.length != 11) {
        alertMessage(context, 'Error', 'Mobile number must be 11 digits');
        return;
      }

      if (creditcardNumber.text.length != 16) {
        alertMessage(context, 'Error', 'Credit card number must be 16 digits');
        return;
      }

      if (password.text != confirmPassword.text) {
        Fluttertoast.showToast(msg: 'Passwords do not match');
        return;
      }

      // try {
      //   // Create user with email and password
      //    final UserCredential userCredential = await FirebaseAuth.instance
      //       .createUserWithEmailAndPassword(
      //           email: gmail.text, password: password.text);

      //   // Store user details in Firestore
      //   await FirebaseFirestore.instance
      //       .collection('users')
      //       .doc(userCredential.user?.uid)
      //       .set({
      //     'First name': firstName.text,
      //     'Last name': lastName.text,
      //     'Email': gmail.text,
      //     'Password': password.text, // Consider not storing plaintext passwords
      //     'Credit Card Number': creditcardNumber.text,
      //     'Credit Card Password': creditcardPassword.text,
      //     'Mobile Number': mobileNumber.text,
      //     'Address': address.text,
      //   });
      //   alertMessage(context, 'Success', 'Registration successful! Check your email for verification.' );
        Navigator.popAndPushNamed(context, '/login_as_user');

      //   alertMessage(context, 'Success', '$e' );

      // } catch (e) {
       
      // }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Center(
          child: Text(
            'Signup Screen',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: firstName,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              TextField(
                controller: lastName,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
              TextField(
                controller: gmail,
                decoration: const InputDecoration(labelText: 'Gmail: example@gmail.com'),
              ),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              TextField(
                controller: confirmPassword,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
              ),
              TextField(
                controller: mobileNumber,
                decoration: const InputDecoration(labelText: 'Mobile Number'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: creditcardNumber,
                decoration: const InputDecoration(labelText: 'Credit Card Number'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: creditcardPassword,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Credit Card Password'),
              ),
              TextField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: registerUser, // Call the register function
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Text('Register'),
              ),
       
            ],
          ),
        ),
      ),
    );
  }
}
