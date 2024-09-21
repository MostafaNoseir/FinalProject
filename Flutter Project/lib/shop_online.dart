import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mqtt.dart';

class Shop_online_page extends StatefulWidget {
  const Shop_online_page({super.key});

  @override
  State<Shop_online_page> createState() => Shop_online_page_state();
}

class Shop_online_page_state extends State<Shop_online_page> {
  List<Map<String, dynamic>> cart = []; // Cart to hold items added by the user
  int totalPrice = 0; // Total price of the items in the cart

  // List of available goods with their names, prices, and images
  final List<Map<String, dynamic>> goods = [
    {
      'name': 'Chips',
      'price': 5,
      'image':
          'https://images.deliveryhero.io/image/darkstores-eg/Virtual%20Bundles/Tiger%20Excellence%20Premium%20Thai%20Sweet%20Chili%20+%20Sea%20Salt%20&Vinegar%20+%20Lime%20Coriander%20Chips%2060-70g.jpg'
    },
    // Add other items...
  ];

  MQTTClientWrapper mqttClientWrapper = MQTTClientWrapper(); // MQTT client instance

  @override
  void initState() {
    super.initState();
    mqttClientWrapper.prepareMqttClient(); // Initialize MQTT client
  }

  // Method to add an item to the cart
  void addToCart(int index) {
    final item = goods[index];
    setState(() {
      cart.add(item); // Add item to cart
      totalPrice += item['price'] as int; // Update total price
    });

    // Publish the item's index (1-based) to the MQTT topic
    mqttClientWrapper.publishMessage('mall/buy/online', '${index + 1}');

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Item added to cart'),
        content: Text('${item['name']} has been added to your cart.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Method to upload the cart and navigate to checkout
  Future<void> uploadCartAndCheckout() async {
    final userCart = {
      'cart': cart,
      'totalPrice': totalPrice,
    };

    // Upload cart data to Firebase Firestore
    await FirebaseFirestore.instance.collection('user_cart').add(userCart);

    // Navigate to the checkout page
    Navigator.pushNamed(context, '/my_cart');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Let's fill your cart"),
        backgroundColor: Colors.lightBlue, // App bar color
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10.0),
              itemCount: goods.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two columns in the grid
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => addToCart(index), // Add item to cart on tap
                  child: GridTile(
                    footer: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(
                        goods[index]['name'], // Display item name
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          goods[index]['image'], // Display item image
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 50,
                            ); // Show error icon if image fails to load
                          },
                        ),
                        Text('${goods[index]['price']} EGP'), // Display item price
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await uploadCartAndCheckout(); // Upload cart and go to checkout
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Button color
                ),
                child: const Text('Go to Cart'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
