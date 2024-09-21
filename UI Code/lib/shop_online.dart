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
    {
      'name': 'Soda cans',
      'price': 10,
      'image':
          'https://www.spirospathis.com/wp-content/uploads/2023/08/Apple-Transparent.png'
    },
    {
      'name': 'Coffee',
      'price': 30,
      'image':
          'https://insanelygoodrecipes.com/wp-content/uploads/2020/07/Cup-Of-Creamy-Coffee.png'
    },
    {
      'name': 'Vegetables',
      'price': 25,
      'image':
          'https://cdn.britannica.com/17/196817-050-6A15DAC3/vegetables.jpg'
    },
    {
      'name': 'Fruits',
      'price': 50,
      'image':
          'https://www.healthyeating.org/images/default-source/home-0.0/nutrition-topics-2.0/general-nutrition-wellness/2-2-2-3foodgroups_fruits_detailfeature.jpg?sfvrsn=64942d53_4'
    },
    {
      'name': 'Fish',
      'price': 80,
      'image':
          'https://cdn.britannica.com/05/88205-050-9EEA563C/Bigmouth-buffalo-fish.jpg'
    },
    {
      'name': 'Meat',
      'price': 400,
      'image':
          'https://www.meatemporium.com.au/cdn/shop/products/JA_AME_FeedTheFamily_41.jpg?v=1652748939'
    },
    {
      'name': 'Noodles',
      'price': 10,
      'image':
          'https://vcdn1-english.vnecdn.net/2023/11/07/bottom-view-chopsticks-asian-r-3141-5095-1699343377.jpg?w=680&h=0&q=100&dpr=2&fit=crop&s=U1zFMpDXFLF6K0z_bdVUSQ'
    },
    {
      'name': 'Bakery',
      'price': 5,
      'image':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR6jQJbimMqb-0gLfd1ZbAbUVb9RX9TOKoGIQ&s'
    },
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
    // mqttClientWrapper.publishMessage('mall/buy/online', '${index + 1}');

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
    // final userCart = {
    //   'cart': cart,
    //   'totalPrice': totalPrice,
    // };

    // // Upload cart data to Firebase Firestore
    // await FirebaseFirestore.instance.collection('user_cart').add(userCart);

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
