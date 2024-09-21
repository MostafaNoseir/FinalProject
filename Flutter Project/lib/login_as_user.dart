// ignore_for_file: unnecessary_null_comparison, unused_label, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Class for login page
class login_as_user_page extends StatelessWidget {
  const login_as_user_page({super.key});

  @override
  Widget build(BuildContext context) {
    // Controllers for text fields
    final TextEditingController yourGmail = TextEditingController();
    final TextEditingController password = TextEditingController();

    // Function to display an alert dialog
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

    // Create the visual structure of the app
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Center(
          child: Text(
            'Login Page',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Email TextField
            TextField(
              controller: yourGmail,
              decoration: const InputDecoration(labelText: 'example@gmail.com'),
            ),
            // Password TextField
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            // Login Button
            ElevatedButton(
              onPressed: () async {
                // Check if all fields are filled
                if (yourGmail.text.isEmpty || password.text.isEmpty) {
                  alertMessage(
                    context,
                    'Error',
                    'All fields must be filled. Please complete the form.',
                  );
                  return;
                }

                try {
                  // Sign in with Firebase Authentication
                  final userCredential = await FirebaseAuth.instance
                      .signInWithEmailAndPassword(
                    email: yourGmail.text,
                    password: password.text,
                  );
                  String? uid = userCredential.user?.uid;

                  if (uid != null) {
                    DocumentSnapshot userSnapshot = await FirebaseFirestore
                        .instance
                        .collection('users')
                        .doc(uid)
                        .get();
                    if (userSnapshot.exists) {
                      Map<String, dynamic> userData =
                          userSnapshot.data() as Map<String, dynamic>;
                      bool verified = userCredential.user!.emailVerified;

                      if (verified) {
                        String firstName = userData['First name'];
                        String lastName = userData['Last name'];
                        alertMessage(context, 'Welcome',
                            '$firstName $lastName connected successfully');
                        Navigator.popAndPushNamed(context, '/welcome_user');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text("Verify your email to continue"),
                          action: SnackBarAction(
                            label: 'Send Again',
                            onPressed: () {
                              userCredential.user!.sendEmailVerification();
                            },
                          ),
                        ));
                      }
                    }
                  }
                } catch (e) {
                  if (e is FirebaseAuthException) {
                    if (e.code == 'user-not-found') {
                      alertMessage(
                        context,
                        'Login Failed',
                        'No such user or incorrect credentials. Please try again.',
                      );
                    } else {
                      alertMessage(
                        context,
                        'Error',
                        'Something went wrong, please try again.',
                      );
                    }
                  }
                }
              },
              child: const Text('Login'),
            ),
            const SizedBox(height: 10),
            // Signup Button
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              child: const Text('Signup'),
            ),
          ],
        ),
      ),
    );
  }
}
