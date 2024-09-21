import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mqtt.dart';

// Define the shop_info_page class
class shop_info_page extends StatefulWidget {
  const shop_info_page({super.key});

  @override
  shop_info_page_state createState() => shop_info_page_state();
}

class shop_info_page_state extends State<shop_info_page> {
  int _customerCountValue = 0; // Counter for the number of customers
  String _customerCount = "0"; // String representation of customer count
  double _totalEarnings = 0.0; // Total earnings variable
  String _earnings = "0.00"; // String representation of earnings
  final MQTTClientWrapper _mqttClient = MQTTClientWrapper(); // MQTT client instance

  @override
  void initState() {
    super.initState();
    _fetchData(); // Fetch data from Firestore
    _initializeMqttClient(); // Initialize MQTT client
  }

  // Initialize MQTT client and subscribe to the topic
  Future<void> _initializeMqttClient() async {
    await _mqttClient.prepareMqttClient(); // Prepare the MQTT client
    _mqttClient.onMessageReceived = _handleMqttMessage; // Set the message handler
    _mqttClient.subscribeToTopic('mall/enter'); // Subscribe to customer enter topic
  }

  // Handle incoming MQTT messages
  void _handleMqttMessage(String message) {
    setState(() {
      if (message == "Person Entered") { // Check for "Person Entered" message
        _customerCountValue++; // Increment customer count
        _customerCount = _customerCountValue.toString(); // Update customer count string
      }
    });
  }

  // Fetch data from Firestore and update the earnings
  Future<void> _fetchData() async {
    // Retrieve transactions from Firestore and calculate total earnings
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    for (var userDoc in usersSnapshot.docs) {
      final userUid = userDoc.id; // Get user ID
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('carts')
          .doc(userUid)
          .get();
      if (cartSnapshot.exists) { // Check if the cart document exists
        final totalPrice = cartSnapshot['totalPrice']?.toDouble() ?? 0.0; // Get total price or default to 0
        _totalEarnings += totalPrice; // Add to total earnings
      }
    }

    // Update the earnings display
    setState(() {
      _earnings = _totalEarnings.toStringAsFixed(2); // Format earnings to two decimal places
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[800], // Dark background color
        title: const Center(
          child: Text(
            'Welcome Admin',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Text color
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Padding around the body
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center the content
          children: <Widget>[
            // Number of customers Text
            Text(
              'Number of Customers Entered: $_customerCount',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20), // Space between elements
            // Earnings Text
            Text(
              'Earnings Today: $_earnings',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20), // Space between elements
            // Button to navigate to Sensor_page
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/sensor'); // Navigate to sensor page
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Button color
                ),
                child: const Text('Shop Sensors'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mqttClient.disconnect(); // Disconnect MQTT client
    super.dispose(); // Call the superclass dispose method
  }
}
