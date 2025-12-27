import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../services/api.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  late Future<List<DoctorSummary>> _future;
  String? _role;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _loadRole();
  }

  Future<List<DoctorSummary>> _load() async {
    final resp = await widget.api.getJson('/api/doctors');
    final list = (resp['data'] as List).cast<Map<String, dynamic>>();
    return list.map(DoctorSummary.fromJson).toList();
  }

  Future<void> _loadRole() async {
    final role = await widget.api.getRole();
    if (!mounted) return;
    setState(() => _role = role);
  }

  Future<void> _logout() async {
    await widget.api.clearAuth();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách bác sĩ'),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      body: FutureBuilder<List<DoctorSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
          final items = snapshot.data ?? const [];
          if (items.isEmpty) return const Center(child: Text('Không có dữ liệu'));

          final showBanner = _role != null && _role != 'patient';
          return ListView.separated(
            itemCount: items.length + (showBanner ? 1 : 0),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (showBanner && index == 0) {
                return ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text('Bạn đang đăng nhập role: $_role'),
                  subtitle: const Text('Ứng dụng này ưu tiên chức năng cho bệnh nhân.'),
                );
              }
              final d = items[showBanner ? index - 1 : index];
              return ListTile(
                leading: CircleAvatar(child: Text(d.fullName.isNotEmpty ? d.fullName[0] : '?')),
                title: Text(d.fullName),
                subtitle: Text('${d.specialization} • Rating: ${d.rating.toStringAsFixed(1)}'),
                trailing: Text('${d.consultationFee}đ'),
                onTap: () => Navigator.of(context).pushNamed('/doctor', arguments: d.id),
              );
            },
          );
        },
      ),
    );
  }
}
