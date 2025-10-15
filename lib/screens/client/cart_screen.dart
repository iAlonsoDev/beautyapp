import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Color uthGreen = const Color.fromARGB(255, 68, 139, 85);
  final Color uthGreen2 = const Color.fromARGB(255, 125, 190, 140);
  final Color uthGrey = Color.fromARGB(255, 82, 83, 82);
  Map<String, Map<String, dynamic>> salonsMap = {};
  Map<String, Map<String, dynamic>> productsMap = {};

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reservaciones')),
        backgroundColor: uthGreen2,
        body: const Center(child: Text('No estás autenticado')),
      );
    }

    final appointmentsStream = FirebaseFirestore.instance
        .collection('appointments')
        .where('userId', isEqualTo: user.uid)
        .limit(25)
        .snapshots();

    return Scaffold(
       appBar: AppBar(
        title: const Text('Detalle del Salón'),
        backgroundColor: uthGreen2,
        elevation: 2,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: uthGrey,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('salons').snapshots(),
        builder: (context, salonsSnapshot) {
          if (salonsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!salonsSnapshot.hasData) {
            return const Center(
              child: Text('No se pudieron cargar los salones'),
            );
          }

          salonsMap = {
            for (var doc in salonsSnapshot.data!.docs)
              doc.id: doc.data() as Map<String, dynamic>,
          };

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .snapshots(),
            builder: (context, productsSnapshot) {
              if (productsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!productsSnapshot.hasData) {
                return const Center(
                  child: Text('No se pudieron cargar los productos'),
                );
              }

              productsMap = {
                for (var doc in productsSnapshot.data!.docs)
                  doc.id: doc.data() as Map<String, dynamic>,
              };

              return StreamBuilder<QuerySnapshot>(
                stream: appointmentsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No tienes reservaciones'));
                  }

                  final now = DateTime.now();
                  final appointments = snapshot.data!.docs;

                  final upcoming = appointments.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final dateTime = (data['dateTime'] as Timestamp).toDate();
                    return dateTime.isAfter(now) ||
                        dateTime.isAtSameMomentAs(now);
                  }).toList();

                  final past = appointments.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final dateTime = (data['dateTime'] as Timestamp).toDate();
                    return dateTime.isBefore(now);
                  }).toList();

                  return ListView(
                    padding: const EdgeInsets.all(16),
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
                      if (upcoming.isEmpty)
                        const Text('No tienes reservaciones pendientes.'),
                      ...upcoming.map(
                        (doc) => _buildAppointmentTile(doc, false),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'Históricas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: uthGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (past.isEmpty)
                        const Text('No tienes reservaciones históricas.'),
                      ...past.map((doc) => _buildAppointmentTile(doc, true)),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAppointmentTile(QueryDocumentSnapshot doc, bool isExpired) {
    final appointmentData = doc.data() as Map<String, dynamic>;
    final dateTime = (appointmentData['dateTime'] as Timestamp).toDate();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);

    final salon = salonsMap[appointmentData['salonId']];
    final product = productsMap[appointmentData['productId']];

    final salonName = salon != null
        ? salon['name'] ?? 'Sin nombre'
        : 'Salón no encontrado';
    final productDesc = product != null
        ? product['description'] ?? 'Sin descripción'
        : 'Producto no encontrado';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: isExpired ? Colors.grey.shade300 : null,
      child: ListTile(
        leading: Icon(
          Icons.calendar_today,
          color: isExpired ? Colors.grey : Colors.black,
        ),
        title: Text(
          'Salón: $salonName',
          style: TextStyle(color: isExpired ? Colors.grey : uthGreen),
        ),
        subtitle: Text(
          'Producto: $productDesc\nFecha: $formattedDate',
          style: TextStyle(color: isExpired ? Colors.grey : uthGreen),
        ),
        isThreeLine: true,
      ),
    );
  }
}
