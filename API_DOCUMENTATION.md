# API Documentation (Exam 04)

Base URL: `http://localhost:3000`

Response format:
- Success: `{ "success": true, "message": null|"...", "data": ... }`
- Error: `{ "success": false, "message": "...", "errors": ... }`

Auth:
- Header: `Authorization: Bearer <token>`
- Roles: `patient`, `doctor`, `admin`
- Login response luôn có `student_id = "2351060445"`

## Auth

### Register patient
- `POST /api/auth/register/patient`

### Register doctor
- `POST /api/auth/register/doctor`

### Login (patient/doctor/admin)
- `POST /api/auth/login`

Admin login dùng `.env`:
- `ADMIN_EMAIL`, `ADMIN_PASSWORD`

### Me
- `GET /api/auth/me`

## Patients

### List patients (admin)
- `GET /api/patients`

### Get patient by id (admin or self patient)
- `GET /api/patients/:id`

### Update patient (admin or self patient)
- `PUT /api/patients/:id`

### Patient appointments (admin or self patient)
- `GET /api/patients/:id/appointments?page=1&limit=10&status=scheduled`

## Doctors

### List doctors
- `GET /api/doctors?search=...&specialization=Cardiology&available_only=true`

### Get doctor by id (includes schedules)
- `GET /api/doctors/:id`

### Update doctor (admin or self doctor)
- `PUT /api/doctors/:id`

### Schedules (doctor self / admin for write)
- `POST /api/doctors/:id/schedules`
- `GET /api/doctors/:id/schedules`
- `PUT /api/doctors/:id/schedules/:schedule_id`
- `DELETE /api/doctors/:id/schedules/:schedule_id`

### Doctor appointments (admin or self doctor)
- `GET /api/doctors/:id/appointments?page=1&limit=10&status=confirmed&date=2026-01-05`

## Appointments

### Create appointment (patient)
- `POST /api/appointments`
Body:
```json
{
  "doctor_id": 1,
  "appointment_date": "2026-01-05",
  "appointment_time": "10:00",
  "reason": "Khám sức khỏe định kỳ"
}
```
Rules:
- `appointment_date` không được quá khứ
- Doctor phải có `doctor_schedules` phù hợp (day_of_week + time in range)
- Không được trùng slot `doctor_id + appointment_date + appointment_time` khi `status != cancelled`

### Get appointment by id (admin or related patient/doctor)
- `GET /api/appointments/:id` (includes patient + doctor)

### List appointments by date (admin)
- `GET /api/appointments?date=2026-01-05`

### Confirm (doctor self or admin)
- `PUT /api/appointments/:id/confirm`

### Complete (doctor self or admin)
- `PUT /api/appointments/:id/complete`
Body:
```json
{
  "diagnosis": "Bệnh nhân khỏe mạnh",
  "prescription": "Vitamin D 1000IU, uống 1 viên/ngày",
  "notes": "Tái khám sau 3 tháng"
}
```

### Cancel (patient self / doctor self / admin)
- `DELETE /api/appointments/:id`

