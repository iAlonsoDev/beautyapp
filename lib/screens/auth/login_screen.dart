// lib/screens/auth/login_screen.dart

import 'package:beautyapp/screens/auth/register_screen.dart';
import 'package:beautyapp/screens/client/client_home_screen.dart';
import 'package:beautyapp/screens/vendor/vendor_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _signIn() async {
  try {
    final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    final uid = userCredential.user!.uid;

    // Lee el rol desde Firestore
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    final role = doc.data()?['role'];

    if (!mounted) return;
    if (role == 'vendedor') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VendorHomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ClientHomeScreen()),
      );
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}

 @override
Widget build(BuildContext context) {
  // Color UTH
  const uthGreen = Color.fromRGBO(68, 139, 85, 1);

  return Scaffold(
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            // Título principal
            const Text(
              'Beauty App',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: uthGreen, // Verde UTH
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Estudio de Factibilidad para la Creación\n'
              'de una Aplicación Móvil para Agendar Citas\n'
              'en un Salón de Belleza',
              style: TextStyle(
                fontSize: 16,
                color: uthGreen, // Verde UTH
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Integrantes:\n'
              'Angie C. Sarmiento\n'
              'Lester O. Hernández\n'
              'Maryori G. García\n'
              'Raúl R. Yanez\n'
              'Sandra N. Aguirre\n'
              'Sindy J. Funes\n'
              'Solyeri J. Morales\n\n'
              'Universidad Tecnológica de Honduras\n'
              'EE-0917 Elaboración y Evaluación de Proyectos\n'
              'Dra. Exibia Paz de Medina',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Email
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Password
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Botón de Login con verde UTH
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: uthGreen, // Color UTH
                ),
                onPressed: _signIn,
                child: const Text(
                  'Iniciar Sesión',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            // Enlace a registro
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  ),
                );
              },
              child: const Text(
                '¿No tienes cuenta? Regístrate',
                style: TextStyle(
                  color: uthGreen, // Link en verde UTH
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

}

