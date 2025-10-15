import 'package:beautyapp/screens/client/booking_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SalonDetailScreen extends StatelessWidget {
  final String salonId;

  const SalonDetailScreen({super.key, required this.salonId});

  @override
  Widget build(BuildContext context) {
    final Color uthGreen = const Color.fromARGB(255, 68, 139, 85);
    final Color uthGreen2 = const Color.fromARGB(255, 125, 190, 140);
  final Color uthGrey = Color.fromARGB(255, 82, 83, 82);

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
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('salonId', isEqualTo: salonId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: uthGreen));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Este salón no tiene productos.',
                style: TextStyle(
                  fontSize: 16,
                  color: uthGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index].data() as Map<String, dynamic>;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: uthGreen, width: 1),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: product['imageUrl'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: product['imageUrl'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => CircularProgressIndicator(
                              color: uthGreen,
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 60,
                            ),
                          ),
                        )
                      : Icon(Icons.spa, color: uthGreen, size: 60),
                  title: Text(
                    product['name'] ?? product['description'] ?? 'Sin descripción',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: uthGreen,
                    ),
                  ),
                  subtitle: Text(
                    'Precio: L${product['price']?.toStringAsFixed(2) ?? '0.00'}\nDuración: ${product['duration'] ?? 0} min',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: uthGreen,
                    size: 20,
                  ),
                  onTap: () {
                    final productId = products[index].id;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingDialog(
                          salonId: salonId,
                          productId: productId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}