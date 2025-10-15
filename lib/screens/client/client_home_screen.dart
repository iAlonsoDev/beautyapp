import 'dart:async';

import 'package:beautyapp/screens/client/salon_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final Color uthGreen = const Color.fromARGB(255, 68, 139, 85);
  final Color uthGreen2 = const Color.fromARGB(255, 125, 190, 140);
  final Color uthGrey = Color.fromARGB(255, 82, 83, 82);
  

  String? displayName;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _startPeriodicCheck();
  }

  void _fetchUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (doc.exists && mounted) {
      setState(() {
        displayName = doc.data()?['name'] ?? 'Cliente';
      });
    }
  }

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _startPeriodicCheck() {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _checkForUpcomingAppointments();
    });
    _checkForUpcomingAppointments();
  }

  Future<void> _checkForUpcomingAppointments() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();

    final snapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('userId', isEqualTo: uid)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final appointmentDateTime = (data['dateTime'] as Timestamp).toDate();
      final diffMinutes = appointmentDateTime.difference(now).inMinutes;

      if (diffMinutes > 0 && diffMinutes <= 10) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Recordatorio de cita'),
              content: Text(
                'Tienes una cita en $diffMinutes minutos a las ${TimeOfDay.fromDateTime(appointmentDateTime).format(context)}.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        break;
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${displayName ?? '...'}'),
        backgroundColor: uthGreen2,
         titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: uthGrey,
        ),
        actions: [
          IconButton(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('salons').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay salones disponibles.'));
          }

          final salons = snapshot.data!.docs;

          return ListView.builder(
            itemCount: salons.length,
            itemBuilder: (context, index) {
              final salon = salons[index].data() as Map<String, dynamic>;
              final salonId = salons[index].id;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: uthGreen, width: 1),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Icon(Icons.storefront, color: uthGreen),
                  title: Text(
                    salon['name'] ?? 'Sin nombre',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: uthGreen,
                    ),
                  ),
                  subtitle: Text(
                    salon['address'] ?? 'Sin dirección',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, color: uthGreen),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SalonDetailScreen(salonId: salonId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: uthGreen2,
        child: const Icon(Icons.shopping_cart),
        onPressed: () {
          Navigator.pushNamed(context, '/cart');
        },
      ),
    );
  }
}
