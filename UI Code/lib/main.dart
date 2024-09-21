// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'decide.dart';
import 'go_shop.dart';
import 'login_as_admin.dart';
import 'login_as_user.dart';
import 'sensors_info.dart';
import 'shop_info.dart';
import 'shop_online.dart';
import 'sign_up.dart';
import 'user_info.dart';
import 'welcome_user.dart';
import 'checkout.dart';
import 'cart.dart';
import 'user_history.dart';

Future<void> main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart supermarket',
      theme: ThemeData(
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const decide_page(),
      routes: {
        '/login_as_user': (context) => const login_as_user_page(),
        '/login_as_admin': (context) => const login_as_admin_page(),
        '/signup': (context) => const Signup_page(),
        '/sensor': (context) => const Sensor_page(),
        '/shop_online': (context) => const Shop_online_page(),
        '/go_shop': (context) => const go_shop_page(),
        '/shop_info': (context) => const shop_info_page(),
        '/decide': (context) => const decide_page(),
        '/user_info': (context) => const user_info_page(),
        '/welcome_user': (context) => const welcome_user_page(),
        '/checkout': (context) => const checkout_page(),
        '/my_cart': (context) => const cart_page(),
        '/user_history': (context) => const history_page(),
      },
    );
  }
}
