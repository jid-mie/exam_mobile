import 'package:flutter/material.dart';
import '../services/api.dart';

class RegisterDoctorScreen extends StatefulWidget {
  const RegisterDoctorScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<RegisterDoctorScreen> createState() => _RegisterDoctorScreenState();
}

class _RegisterDoctorScreenState extends State<RegisterDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _qualificationCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController(text: '0');
  final _feeCtrl = TextEditingController();
  String _specialization = 'General';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _qualificationCtrl.dispose();
    _experienceCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildBody() {
    final body = <String, dynamic>{
      'email': _emailCtrl.text.trim(),
      'password': _passwordCtrl.text,
      'full_name': _fullNameCtrl.text.trim(),
      'specialization': _specialization,
    };
    if (_phoneCtrl.text.trim().isNotEmpty) body['phone_number'] = _phoneCtrl.text.trim();
    if (_qualificationCtrl.text.trim().isNotEmpty) body['qualification'] = _qualificationCtrl.text.trim();
    if (_experienceCtrl.text.trim().isNotEmpty) body['experience'] = _experienceCtrl.text.trim();
    body['consultation_fee'] = _feeCtrl.text.trim();
    return body;
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      if (!_formKey.currentState!.validate()) return;
      await widget.api.postJson('/api/auth/register/doctor', body: _buildBody());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký thành công')));
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký bác sĩ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
                validator: (v) => (v == null || v.length < 6) ? 'Tối thiểu 6 ký tự' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fullNameCtrl,
                decoration: const InputDecoration(labelText: 'Họ tên'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập họ tên' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'SĐT (optional)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _specialization,
                decoration: const InputDecoration(labelText: 'Chuyên khoa'),
                items: const [
                  DropdownMenuItem(value: 'Cardiology', child: Text('Cardiology')),
                  DropdownMenuItem(value: 'Dermatology', child: Text('Dermatology')),
                  DropdownMenuItem(value: 'Pediatrics', child: Text('Pediatrics')),
                  DropdownMenuItem(value: 'Orthopedics', child: Text('Orthopedics')),
                  DropdownMenuItem(value: 'General', child: Text('General')),
                ],
                onChanged: (v) => setState(() => _specialization = v ?? 'General'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qualificationCtrl,
                decoration: const InputDecoration(labelText: 'Bằng cấp (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _experienceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Kinh nghiệm (năm)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _feeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Phí khám'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập phí khám' : null,
              ),
              const SizedBox(height: 12),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading ? const CircularProgressIndicator() : const Text('Đăng ký'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

