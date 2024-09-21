import 'package:flutter/material.dart';
import 'mqtt.dart'; // Your MQTT wrapper class

class go_shop_page extends StatefulWidget {
  const go_shop_page({super.key});

  @override
  go_shop_page_state createState() => go_shop_page_state();
}

class go_shop_page_state extends State<go_shop_page> {
  // List of goods available in the shop
  final List<Map<String, dynamic>> goods = [
    {'name': 'Chips', 'price': 5, 'icon': Icons.local_offer, 'quantity': 0},
    {
      'name': 'Soda cans',
      'price': 10,
      'icon': Icons.local_drink,
      'quantity': 0
    },
    {'name': 'Coffee', 'price': 30, 'icon': Icons.local_cafe, 'quantity': 0},
    {'name': 'Vegetables', 'price': 25, 'icon': Icons.spa, 'quantity': 0},
    {
      'name': 'Fruits',
      'price': 50,
      'icon': Icons.local_grocery_store,
      'quantity': 0
    },
    {'name': 'Fish', 'price': 80, 'icon': Icons.set_meal, 'quantity': 0},
    {'name': 'Meat', 'price': 400, 'icon': Icons.fastfood, 'quantity': 0},
    {'name': 'Noodles', 'price': 10, 'icon': Icons.ramen_dining, 'quantity': 0},
    {'name': 'Bakery', 'price': 5, 'icon': Icons.bakery_dining, 'quantity': 0},
  ];

  // Cart to hold items added by the user
  List<Map<String, dynamic>> cart = [];
  late MQTTClientWrapper mqttClientWrapper;

  @override
  void initState() {
    super.initState();
    mqttClientWrapper = MQTTClientWrapper();
    mqttClientWrapper.onMessageReceived = handleMQTTMessage;
    mqttClientWrapper.prepareMqttClient(); // Initialize MQTT connection
    // Subscribe to relevant topics
    mqttClientWrapper.subscribeToTopic('mall/item/added');
    mqttClientWrapper.subscribeToTopic('mall/items/canceled');
    mqttClientWrapper.subscribeToTopic('mall/items/removed');
    mqttClientWrapper.subscribeToTopic('mall/items/summary');
    mqttClientWrapper.subscribeToTopic('mall/items/buy');
    mqttClientWrapper.subscribeToTopic('mall/items/error');
  }

  // Handle messages received from the MQTT broker
  void handleMQTTMessage(String message) {
    setState(() {
      // Different actions based on received message
      if (message == '0') {
        clearCart();
      } else if (message == 'A') {
        goToCartSummary();
      } else if (message == 'B') {
        removeLastItem();
      } else if (message == 'C') {
        goToCheckout();
      } else {
        // Handle numbers 1-9 for adding items to the cart
        int itemIndex = int.tryParse(message) ?? -1;
        if (itemIndex > 0 && itemIndex <= goods.length) {
          addItemToCart(itemIndex - 1);
        }
      }
    });
  }

  // Add selected item to the cart
  void addItemToCart(int index) {
    var selectedItem = goods[index];
    // Check if the item is already in the cart
    var existingItem = cart.firstWhere(
        (item) => item['name'] == selectedItem['name'],
        orElse: () => {});
    if (existingItem.isNotEmpty) {
      // Item already in cart, increment quantity
      existingItem['quantity']++;
    } else {
      // Add new item to cart
      selectedItem['quantity'] = 1;
      cart.add({...selectedItem});
    }

    // Publish message indicating an item was added to the cart
    mqttClientWrapper.publishMessage(
        'mall/item/added', 'Item ${selectedItem['name']} added to cart');
  }

  // Clear all items from the cart
  void clearCart() {
    cart.clear();
    mqttClientWrapper.publishMessage('mall/items/canceled', 'Cart cleared');
  }

  // Remove the last item from the cart
  void removeLastItem() {
    if (cart.isNotEmpty) {
      var lastItem = cart.removeLast();
      mqttClientWrapper.publishMessage(
          'mall/items/removed', 'Removed ${lastItem['name']} from cart');
    } else {
      mqttClientWrapper.publishMessage('mall/items/error', 'Cart is empty');
    }
  }

  // Navigate to cart summary page
  void goToCartSummary() {
    Navigator.pushNamed(context, '/my_cart');
  }

  // Navigate to checkout page
  void goToCheckout() {
    Navigator.pushNamed(context, '/checkout');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Welcome to the Super Market',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        backgroundColor: Colors.greenAccent,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Here is the list of items you can buy:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: goods.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(goods[index]['icon']),
                  title: Text(goods[index]['name']),
                  trailing: Text('${goods[index]['price']} EGP'),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: goToCheckout,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Check Out'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
