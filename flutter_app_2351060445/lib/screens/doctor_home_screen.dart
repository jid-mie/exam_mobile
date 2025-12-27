import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../services/api.dart';
import 'doctor_schedules_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _filterByDate = true;
  Future<List<AppointmentItem>>? _future;
  int? _doctorId;

  @override
  void initState() {
    super.initState();
    _loadDoctor();
  }

  Future<void> _loadDoctor() async {
    final id = await widget.api.getUserId();
    if (!mounted) return;
    setState(() {
      _doctorId = id;
      _future = _fetchAppointments();
    });
  }

  String _dateStr(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<List<AppointmentItem>> _fetchAppointments() async {
    if (_doctorId == null) return [];
    final dateStr = _dateStr(_selectedDate);
    final path = _filterByDate
        ? '/api/doctors/$_doctorId/appointments?date=$dateStr'
        : '/api/doctors/$_doctorId/appointments';
    final resp = await widget.api.getJson(path, auth: true);
    final list = (resp['data']['items'] as List).cast<Map<String, dynamic>>();
    return list.map(AppointmentItem.fromJson).toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _selectedDate,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = picked;
      _future = _fetchAppointments();
    });
  }

  Future<void> _confirmAppointment(AppointmentItem item) async {
    try {
      await widget.api.putJson('/api/appointments/${item.id}/confirm', auth: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xác nhận lịch thành công')));
      setState(() => _future = _fetchAppointments());
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _completeAppointment(AppointmentItem item) async {
    final diagnosisCtrl = TextEditingController();
    final prescriptionCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hoàn thành lịch hẹn'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: diagnosisCtrl, decoration: const InputDecoration(labelText: 'Chẩn đoán')),
              TextField(controller: prescriptionCtrl, decoration: const InputDecoration(labelText: 'Đơn thuốc')),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Ghi chú')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xác nhận')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await widget.api.putJson(
        '/api/appointments/${item.id}/complete',
        auth: true,
        body: {
          'diagnosis': diagnosisCtrl.text.trim().isEmpty ? 'Chẩn đoán' : diagnosisCtrl.text.trim(),
          'prescription': prescriptionCtrl.text.trim().isEmpty ? 'Đơn thuốc' : prescriptionCtrl.text.trim(),
          'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hoàn thành lịch hẹn')));
      setState(() => _future = _fetchAppointments());
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
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

  Future<void> _logout() async {
    await widget.api.clearAuth();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch hẹn bác sĩ'),
        actions: [
          if (_doctorId != null)
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DoctorSchedulesScreen(api: widget.api, doctorId: _doctorId!),
                ),
              ),
              icon: const Icon(Icons.schedule),
            ),
          IconButton(
            onPressed: _filterByDate ? _pickDate : null,
            icon: const Icon(Icons.date_range),
          ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _future == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SwitchListTile(
                  value: _filterByDate,
                  title: Text(_filterByDate
                      ? 'Lọc theo ngày: ${_dateStr(_selectedDate)}'
                      : 'Hiển thị tất cả lịch hẹn'),
                  onChanged: (val) {
                    setState(() {
                      _filterByDate = val;
                      _future = _fetchAppointments();
                    });
                  },
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
                          return ListTile(
                            title: Text('${item.patientName ?? 'Bệnh nhân'} • ${item.appointmentTime}'),
                            subtitle: Text('${item.reason} • ${item.status}'),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          if (item.status == 'scheduled')
                            OutlinedButton(
                              onPressed: () => _confirmAppointment(item),
                              child: const Text('Xác nhận'),
                            ),
                          if (item.status != 'completed' && item.status != 'cancelled')
                            FilledButton(
                              onPressed: () => _completeAppointment(item),
                              child: const Text('Hoàn thành'),
                            ),
                          if (item.status != 'cancelled')
                            OutlinedButton(
                              onPressed: () => _cancelAppointment(item),
                              child: const Text('Hủy'),
                            ),
                        ],
                      ),
                            leading: CircleAvatar(
                              backgroundColor: _statusColor(item.status),
                              child: const Icon(Icons.event, color: Colors.white),
                            ),
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
