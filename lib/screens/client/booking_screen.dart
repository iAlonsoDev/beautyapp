import 'package:beautyapp/notifications/local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingDialog extends StatefulWidget {
  final String salonId;
  final String productId;

  const BookingDialog({
    super.key,
    required this.salonId,
    required this.productId,
  });

  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  DateTime? selectedDateTime;
  String? productName;
  final Color uthGreen = const Color.fromARGB(255, 68, 139, 85);

  @override
  void initState() {
    super.initState();
    _fetchProductName();
  }

  Future<void> _fetchProductName() async {
    final doc = await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .get();
    if (doc.exists && mounted) {
      setState(() {
        productName = doc.data()?['name'] ?? doc.data()?['description'] ?? 'Servicio';
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una fecha y hora')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Guarda en Firestore
    final docRef = await FirebaseFirestore.instance.collection('appointments').add({
      'salonId': widget.salonId,
      'productId': widget.productId,
      'userId': user.uid,
      'dateTime': selectedDateTime,
      'createdAt': Timestamp.now(),
    });

    await LocalNotificationService().scheduleNotification(
      selectedDateTime!,
      'Recordatorio de cita',
      'Tu cita para $productName es en 10 minutos',
      docRef.hashCode,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reservación realizada')),
    );

    Navigator.pop(context);
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: uthGreen),
          ),
          child: child!,
        );
      },
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: uthGreen),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return;

    setState(() {
      selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = selectedDateTime != null
        ? DateFormat('EEEE, dd MMMM yyyy').format(selectedDateTime!)
        : 'No seleccionada';
    final formattedTime = selectedDateTime != null
        ? DateFormat('hh:mm a').format(selectedDateTime!)
        : '';

    return AlertDialog(
      title: Text(
        'Agendar Cita - ${productName ?? "Cargando..."}',
        style: TextStyle(color: uthGreen, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        height: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: uthGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.calendar_today, color: Colors.white),
              label: const Text(
                'Seleccionar Fecha y Hora',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: _selectDateTime,
            ),
            const SizedBox(height: 16),
            Text(
              'Servicio: ${productName ?? "Cargando..."}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Fecha: $formattedDate',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              'Hora: $formattedTime',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancelar', style: TextStyle(color: uthGreen)),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: uthGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _bookAppointment,
          child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}