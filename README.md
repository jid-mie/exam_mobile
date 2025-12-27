# Web API 2351060445 (Node.js + MySQL + Prisma) + Flutter Client

## 1) Cấu hình Database (MySQL)

- **Database name bắt buộc:** `db_exam_2351060445`
- Tạo database:
  - `CREATE DATABASE db_exam_2351060445 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`

## 2) Cấu hình môi trường

- Copy `.env.example` → `.env` và chỉnh `DATABASE_URL` đúng user/password MySQL của bạn.

## 3) Migration + Seed

- Generate Prisma Client: `npm run prisma:generate`
- Apply migrations: `npm run prisma:deploy`
- Seed data: `npm run prisma:seed`

Seeder tạo:
- 5 patients, 8 doctors, doctor_schedules (Mon-Sat 09:00-17:00) cho mỗi doctor, 12 appointments.

## 4) Chạy API

- Dev: `npm run dev`
- Prod: `npm start`

Health check: `GET /health`

## 5) Admin account

Admin không lưu trong DB, dùng biến môi trường:
- `ADMIN_EMAIL`, `ADMIN_PASSWORD`

Login admin: `POST /api/auth/login`

## 6) Flutter app

Project Flutter nằm ở: `flutter_app_2351060445`

Chạy:
- `cd flutter_app_2351060445`
- `flutter pub get`
- `flutter run`

## 7) API Docs

Xem file: `API_DOCUMENTATION.md`

## 8) Postman

Import:
- `postman_collection.json`
- `postman_environment.json`
