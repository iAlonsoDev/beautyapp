import 'dart:async';
import 'package:beautyapp/screens/vendor/add_product_screen.dart';
import 'package:beautyapp/screens/vendor/add_salon_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  final Color uthGreen = const Color.fromARGB(255, 68, 139, 85);
  final Color uthGreen2 = const Color.fromARGB(255, 125, 190, 140);
  final Color uthGrey = Color.fromARGB(255, 82, 83, 82);

  String? displayName;
  List<Map<String, dynamic>> salons = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchUserName());
    _loadSalonsAndStartCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _fetchUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && mounted) {
      setState(() {
        displayName = doc.data()?['name'] ?? 'Vendedor';
      });
    }
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showAddSalonDialog() async {
  final result = await showDialog(
    context: context,
    builder: (context) => const AddSalonDialog(),
  );

  if (result == true) {
    _loadSalonsAndStartCheck();
  }
}

  void _showAddProductDialog() {
    if (salons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debes crear un salón')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: Color.fromARGB(255, 68, 139, 85),
            width: 3,
          ),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: AddProductDialog(
            salons: salons,
          ),
        ),
      ),
    );
  }

  void _showViewReservation() {
    Navigator.pushNamed(context, '/vendor-reservations');
  }

  void _loadSalonsAndStartCheck() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('salons')
        .where('ownerId', isEqualTo: uid)
        .get();

    salons = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'Sin nombre',
        'address': data['address'] ?? 'Sin dirección',
      };
    }).toList();

    if (mounted) setState(() {});

    _timer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _checkAppointments();
    });
    _checkAppointments();
  }

  Future<void> _checkAppointments() async {
    final now = DateTime.now();

    for (final salon in salons) {
      final appointments = await FirebaseFirestore.instance
          .collection('appointments')
          .where('salonId', isEqualTo: salon['id'])
          .get();

      for (final doc in appointments.docs) {
        final data = doc.data();
        final appointmentDateTime = (data['dateTime'] as Timestamp).toDate();
        final diffMinutes = appointmentDateTime.difference(now).inMinutes;

        if (diffMinutes > 0 && diffMinutes <= 10) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Cita próxima'),
                content: Text(
                  'Hay una cita próxima en $diffMinutes minutos para tu salón: ${salon['name']}',
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
          return; // Una sola alerta por vez
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

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
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _signOut,
          ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('Usuario no autenticado'))
          : salons.isEmpty
              ? Center(
                  child: Text(
                    'Aún no tienes salones.\nUsa el botón para agregar uno.',
                    style: TextStyle(fontSize: 16, color: uthGreen),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: salons.length,
                  itemBuilder: (context, index) {
                    final salon = salons[index];

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: uthGreen, width: 1),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          salon['name'] ?? 'Sin nombre',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: uthGreen,
                          ),
                        ),
                        subtitle: Text(
                          salon['address'] ?? 'Sin dirección',
                          style: const TextStyle(fontSize: 14),
                        ),
                        children: [
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('products')
                                .where('salonId', isEqualTo: salon['id'])
                                .snapshots(),
                            builder: (context, productSnapshot) {
                              if (productSnapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (!productSnapshot.hasData || productSnapshot.data!.docs.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'No hay productos para este salón.',
                                    style: TextStyle(color: uthGreen),
                                  ),
                                );
                              }

                              final products = productSnapshot.data!.docs;

                              return ListView.separated(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: products.length,
                                separatorBuilder: (_, _) => const Divider(),
                                itemBuilder: (context, i) {
                                  final product = products[i].data() as Map<String, dynamic>;
                                  return ListTile(
                                    leading: product['imageUrl'] != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              product['imageUrl'],
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => const Icon(
                                                Icons.broken_image,
                                                color: Colors.grey,
                                                size: 50,
                                              ),
                                            ),
                                          )
                                        : const Icon(Icons.spa, color: Colors.pink, size: 50),
                                    title: Text(product['description'] ?? 'Sin descripción'),
                                    subtitle: Text(
                                      'Precio: L${product['price']?.toStringAsFixed(2) ?? '0.00'} | Duración: ${product['duration'] ?? 0} min',
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'add_salon',
            onPressed: _showAddSalonDialog,
            backgroundColor: uthGreen2,
            icon: const Icon(Icons.add_business),
            label: const Text('Agregar Salón'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add_product',
            onPressed: _showAddProductDialog,
            backgroundColor: uthGreen2,
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Agregar Producto'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'view_reservation',
            onPressed: _showViewReservation,
            backgroundColor: uthGreen2,
            icon: const Icon(Icons.calendar_today),
            label: const Text('Ver Reservaciones'),
          ),
        ],
      ),
    );
  }
}