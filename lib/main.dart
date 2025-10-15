import 'package:beautyapp/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:beautyapp/screens/auth/login_screen.dart';
import 'package:beautyapp/screens/auth/register_screen.dart';
import 'package:beautyapp/screens/auth/splash_screen.dart';
import 'package:beautyapp/screens/vendor/vendor_home_screen.dart';
import 'package:beautyapp/screens/vendor/vendor_reservations_screen.dart';
import 'package:beautyapp/screens/client/client_home_screen.dart';
import 'package:beautyapp/screens/client/cart_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:beautyapp/notifications/local_notifications.dart';


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await LocalNotificationService().initializeNotifications();

  runApp(const BeautyApp());
}

class BeautyApp extends StatelessWidget {
  const BeautyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beauty App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/vendor-home': (context) => const VendorHomeScreen(),
        '/vendor-reservations': (context) => const VendorReservationsScreen(),
        '/client-home': (context) => const ClientHomeScreen(),
        '/cart': (context) => const CartScreen(),
      },
    );
  }
}
