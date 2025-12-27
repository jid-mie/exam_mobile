import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../models/patient.dart';
import '../services/api.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  DateTime _selectedDate = DateTime.now();
  Future<List<AppointmentItem>>? _appointmentsFuture;
  Future<List<PatientItem>>? _patientsFuture;
  final _doctorIdCtrl = TextEditingController();
  Future<List<AppointmentItem>>? _doctorAppointmentsFuture;
  int? _currentDoctorId;

  @override
  void initState() {
    super.initState();
    _appointmentsFuture = _fetchAppointments();
    _patientsFuture = _fetchPatients();
  }

  @override
  void dispose() {
    _doctorIdCtrl.dispose();
    super.dispose();
  }

  String _dateStr(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<List<AppointmentItem>> _fetchAppointments() async {
    final dateStr = _dateStr(_selectedDate);
    final resp = await widget.api.getJson('/api/appointments?date=$dateStr', auth: true);
    final list = (resp['data'] as List).cast<Map<String, dynamic>>();
    return list.map(AppointmentItem.fromJson).toList();
  }

  Future<List<PatientItem>> _fetchPatients() async {
    final resp = await widget.api.getJson('/api/patients', auth: true);
    final list = (resp['data'] as List).cast<Map<String, dynamic>>();
    return list.map(PatientItem.fromJson).toList();
  }

  Future<List<AppointmentItem>> _fetchDoctorAppointments(int doctorId) async {
    final resp = await widget.api.getJson('/api/doctors/$doctorId/appointments', auth: true);
    final list = (resp['data']['items'] as List).cast<Map<String, dynamic>>();
    return list.map(AppointmentItem.fromJson).toList();
  }

  Future<void> _confirmAppointment(AppointmentItem item) async {
    try {
      await widget.api.putJson('/api/appointments/${item.id}/confirm', auth: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xác nhận lịch thành công')));
      setState(() {
        _appointmentsFuture = _fetchAppointments();
        if (_currentDoctorId != null) {
          _doctorAppointmentsFuture = _fetchDoctorAppointments(_currentDoctorId!);
        }
      });
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
      await widget.api.putJson('/api/appointments/${item.id}/complete', auth: true, body: {
        'diagnosis': diagnosisCtrl.text.trim().isEmpty ? 'Chẩn đoán' : diagnosisCtrl.text.trim(),
        'prescription': prescriptionCtrl.text.trim().isEmpty ? 'Đơn thuốc' : prescriptionCtrl.text.trim(),
        'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hoàn thành lịch hẹn')));
      setState(() {
        _appointmentsFuture = _fetchAppointments();
        if (_currentDoctorId != null) {
          _doctorAppointmentsFuture = _fetchDoctorAppointments(_currentDoctorId!);
        }
      });
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
      setState(() {
        _appointmentsFuture = _fetchAppointments();
        if (_currentDoctorId != null) {
          _doctorAppointmentsFuture = _fetchDoctorAppointments(_currentDoctorId!);
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _editPatient(PatientItem patient) async {
    final detail = await widget.api.getJson('/api/patients/${patient.id}', auth: true);
    final data = detail['data'] as Map<String, dynamic>;
    final nameCtrl = TextEditingController(text: (data['full_name'] ?? '').toString());
    final phoneCtrl = TextEditingController(text: (data['phone_number'] ?? '').toString());
    final addressCtrl = TextEditingController(text: (data['address'] ?? '').toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật bệnh nhân'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Họ tên')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'SĐT')),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Địa chỉ')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await widget.api.putJson('/api/patients/${patient.id}', auth: true, body: {
        'full_name': nameCtrl.text.trim(),
        'phone_number': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
        'address': addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật bệnh nhân thành công')));
      setState(() => _patientsFuture = _fetchPatients());
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _selectedDate,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = picked;
      _appointmentsFuture = _fetchAppointments();
    });
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
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(onPressed: _pickDate, icon: const Icon(Icons.date_range)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Lịch hẹn theo ngày', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FutureBuilder<List<AppointmentItem>>(
            future: _appointmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) return Text(snapshot.error.toString());
              final items = snapshot.data ?? const [];
              if (items.isEmpty) return const Text('Không có lịch hẹn');
              return Column(
                children: items
                    .map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${item.doctorName ?? 'Bác sĩ'} • ${item.appointmentTime}'),
                        subtitle: Text('${item.patientName ?? 'Bệnh nhân'} • ${item.status}'),
                        trailing: Wrap(
                          spacing: 6,
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
                            OutlinedButton(
                              onPressed: () => _cancelAppointment(item),
                              child: const Text('Hủy'),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const Divider(height: 32),
          Text('Lịch hẹn theo bác sĩ (ID)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _doctorIdCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Doctor ID'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  final id = int.tryParse(_doctorIdCtrl.text.trim());
                  if (id == null) return;
                  setState(() {
                    _currentDoctorId = id;
                    _doctorAppointmentsFuture = _fetchDoctorAppointments(id);
                  });
                },
                child: const Text('Xem'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<AppointmentItem>>(
            future: _doctorAppointmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) return Text(snapshot.error.toString());
              final items = snapshot.data ?? const [];
              if (items.isEmpty) return const Text('Không có dữ liệu');
              return Column(
                children: items
                    .map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${item.patientName ?? 'Bệnh nhân'} • ${item.appointmentTime}'),
                        subtitle: Text('${item.reason} • ${item.status}'),
                        trailing: Wrap(
                          spacing: 6,
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
                            OutlinedButton(
                              onPressed: () => _cancelAppointment(item),
                              child: const Text('Hủy'),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const Divider(height: 32),
          Text('Danh sách bệnh nhân', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FutureBuilder<List<PatientItem>>(
            future: _patientsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) return Text(snapshot.error.toString());
              final items = snapshot.data ?? const [];
              if (items.isEmpty) return const Text('Không có bệnh nhân');
              return Column(
                children: items
                    .map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.fullName),
                        subtitle: Text(item.email),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            Text(item.phone ?? ''),
                            IconButton(
                              onPressed: () => _editPatient(item),
                              icon: const Icon(Icons.edit),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
