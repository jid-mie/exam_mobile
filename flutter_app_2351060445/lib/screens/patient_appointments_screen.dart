import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../services/api.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  Future<List<AppointmentItem>>? _future;
  int? _patientId;
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  Future<void> _loadPatient() async {
    final id = await widget.api.getUserId();
    if (!mounted) return;
    setState(() {
      _patientId = id;
      _future = _fetchAppointments();
    });
  }

  Future<List<AppointmentItem>> _fetchAppointments() async {
    if (_patientId == null) return [];
    final query = _statusFilter.isEmpty ? '' : '?status=$_statusFilter';
    final resp = await widget.api.getJson('/api/patients/$_patientId/appointments$query', auth: true);
    final list = (resp['data']['items'] as List).cast<Map<String, dynamic>>();
    return list.map(AppointmentItem.fromJson).toList();
  }

  Future<void> _cancelAppointment(AppointmentItem item) async {
    try {
      await widget.api.deleteJson('/api/appointments/${item.id}', auth: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hủy lịch thành công')));
      setState(() => _future = _fetchAppointments());
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch hẹn của tôi')),
      body: _future == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: DropdownButtonFormField<String>(
                    value: _statusFilter,
                    decoration: const InputDecoration(labelText: 'Lọc theo trạng thái'),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Tất cả')),
                      DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                      DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _statusFilter = value ?? '';
                        _future = _fetchAppointments();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<AppointmentItem>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
                      final items = snapshot.data ?? const [];
                      if (items.isEmpty) return const Center(child: Text('Không có lịch hẹn'));
                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final canCancel = item.status == 'scheduled' || item.status == 'confirmed';
                          return ListTile(
                            title: Text('${item.doctorName ?? 'Bác sĩ'} • ${item.appointmentTime}'),
                            subtitle: Text('${item.reason} • ${item.status}'),
                          trailing: canCancel
                              ? OutlinedButton(
                                  onPressed: () => _cancelAppointment(item),
                                  child: const Text('Hủy'),
                                )
                                : const Text('Không thể hủy'),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
