import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VendorReservationsScreen extends StatefulWidget {
  const VendorReservationsScreen({super.key});

  @override
  State<VendorReservationsScreen> createState() =>
      _VendorReservationsScreenState();
}

class _VendorReservationsScreenState extends State<VendorReservationsScreen> {
  final Color uthGreen = const Color.fromARGB(255, 68, 139, 85);
  final Color uthGreen2 = const Color.fromARGB(255, 125, 190, 140);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text('Usuario no autenticado'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservaciones'),
        backgroundColor: uthGreen2,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('salons')
            .where('ownerId', isEqualTo: uid)
            .get(),
        builder: (context, salonSnapshot) {
          if (salonSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!salonSnapshot.hasData || salonSnapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No tienes salones registrados',
                style: TextStyle(color: uthGreen),
              ),
            );
          }

          final salonIds = salonSnapshot.data!.docs
              .map((doc) => doc.id)
              .toList();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('appointments')
                .where('salonId', whereIn: salonIds)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'No tienes reservaciones',
                    style: TextStyle(color: uthGreen),
                  ),
                );
              }

              final now = DateTime.now();
              final reservations = snapshot.data!.docs;

              // Clasificar
              final upcoming = reservations.where((doc) {
                final res = doc.data() as Map<String, dynamic>;
                final dateTime = (res['dateTime'] as Timestamp).toDate();
                return dateTime.isAfter(now) || dateTime.isAtSameMomentAs(now);
              }).toList();

              final past = reservations.where((doc) {
                final res = doc.data() as Map<String, dynamic>;
                final dateTime = (res['dateTime'] as Timestamp).toDate();
                return dateTime.isBefore(now);
              }).toList();

              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Text(
                    'Pendientes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: uthGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._buildReservationTiles(upcoming),

                  const SizedBox(height: 20),
                  Text(
                    'Históricas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: uthGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._buildReservationTiles(past),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildReservationTiles(
    List<QueryDocumentSnapshot> reservations,
  ) {
    if (reservations.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'No hay reservaciones en esta sección.',
            style: TextStyle(color: uthGreen),
          ),
        ),
      ];
    }

    return reservations.map((doc) {
      final res = doc.data() as Map<String, dynamic>;
      final dateTime = (res['dateTime'] as Timestamp).toDate();
      final productId = res['productId'] ?? '';
      final userId = res['userId'] ?? '';

      final productFuture = FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      final userFuture = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      return FutureBuilder<DocumentSnapshot>(
        future: productFuture,
        builder: (context, productSnapshot) {
          String productName = 'Cargando producto...';
          if (productSnapshot.hasData && productSnapshot.data!.exists) {
            final productData =
                productSnapshot.data!.data() as Map<String, dynamic>;
            productName = productData['description'] ?? 'Sin descripción';
          }

          return FutureBuilder<DocumentSnapshot>(
            future: userFuture,
            builder: (context, userSnapshot) {
              String clientName = 'Cargando cliente...';
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                clientName = userData['name'] ?? 'Sin nombre';
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: dateTime.isBefore(DateTime.now())
                    ? Colors.grey.shade300
                    : null,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.event_available,
                    color: dateTime.isBefore(DateTime.now())
                        ? Colors.grey
                        : uthGreen,
                  ),
                  title: Text(
                    'Producto: $productName',
                    style: TextStyle(
                      color: dateTime.isBefore(DateTime.now())
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    'Cliente: $clientName\nFecha: ${dateTime.toLocal()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: dateTime.isBefore(DateTime.now())
                          ? Colors.grey
                          : Colors.black87,
                    ),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      );
    }).toList();
  }
}
