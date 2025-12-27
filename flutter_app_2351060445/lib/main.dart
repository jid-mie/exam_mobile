import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/doctors_screen.dart';
import 'screens/doctor_detail_screen.dart';
import 'screens/register_patient_screen.dart';
import 'screens/register_doctor_screen.dart';
import 'screens/doctor_home_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/patient_home_screen.dart';
import 'screens/patient_appointments_screen.dart';
import 'services/api.dart';

void main() {
  runApp(const MyApp());
}

String _resolveBaseUrl() {
  const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  if (envUrl.isNotEmpty) return envUrl;
  if (kIsWeb) return 'http://localhost:3000';
  return 'http://10.0.2.2:3000';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiClient(baseUrl: _resolveBaseUrl());

    return MaterialApp(
      title: 'Clinic App',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
      routes: {
        '/': (_) => LoginScreen(api: api),
        '/doctors': (_) => DoctorsScreen(api: api),
        '/register/patient': (_) => RegisterPatientScreen(api: api),
        '/register/doctor': (_) => RegisterDoctorScreen(api: api),
        '/doctor/home': (_) => DoctorHomeScreen(api: api),
        '/admin/home': (_) => AdminHomeScreen(api: api),
        '/patient/home': (_) => PatientHomeScreen(api: api),
        '/patient/appointments': (_) => PatientAppointmentsScreen(api: api),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/doctor') {
          final id = settings.arguments as int;
          return MaterialPageRoute(builder: (_) => DoctorDetailScreen(api: api, doctorId: id));
        }
        return null;
      },
    );
  }
}
