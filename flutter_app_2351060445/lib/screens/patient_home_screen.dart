import 'package:flutter/material.dart';
import '../services/api.dart';

class PatientHomeScreen extends StatelessWidget {
  const PatientHomeScreen({super.key, required this.api});

  final ApiClient api;

  Future<void> _logout(BuildContext context) async {
    await api.clearAuth();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bệnh nhân'),
        actions: [
          IconButton(onPressed: () => _logout(context), icon: const Icon(Icons.logout)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.medical_services),
              title: const Text('Danh sách bác sĩ'),
              subtitle: const Text('Xem bác sĩ và đặt lịch'),
              onTap: () => Navigator.of(context).pushNamed('/doctors'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.event_note),
              title: const Text('Lịch hẹn của tôi'),
              subtitle: const Text('Xem và hủy lịch hẹn'),
              onTap: () => Navigator.of(context).pushNamed('/patient/appointments'),
            ),
          ],
        ),
      ),
    );
  }
}

