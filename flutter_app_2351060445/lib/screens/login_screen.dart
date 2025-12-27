import 'package:flutter/material.dart';
import '../services/api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'patient1@example.com');
  final _passwordCtrl = TextEditingController(text: 'password123');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      if (!_formKey.currentState!.validate()) return;
      final resp = await widget.api.postJson('/api/auth/login', body: {
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text,
      });
      final data = resp['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final role = (data['role'] as String?) ?? 'patient';
      final user = data['user'] as Map<String, dynamic>?;
      final userId = user != null ? user['id'] as int? : null;
      await widget.api.setAuth(token: token, role: role, userId: userId);
      if (!mounted) return;
      if (role != 'patient') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bạn đang đăng nhập với role: $role')),
        );
      }
      if (role == 'doctor') {
        Navigator.of(context).pushReplacementNamed('/doctor/home');
      } else if (role == 'admin') {
        Navigator.of(context).pushReplacementNamed('/admin/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/patient/home');
      }
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
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
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
                validator: (v) => (v == null || v.isEmpty) ? 'Nhập mật khẩu' : null,
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
                  child: _loading ? const CircularProgressIndicator() : const Text('Đăng nhập'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/register/patient'),
                    child: const Text('Đăng ký bệnh nhân'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/register/doctor'),
                    child: const Text('Đăng ký bác sĩ'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Demo seed: patient1@example.com / password123',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
