const bcrypt = require("bcryptjs");
const { PrismaClient } = require("@prisma/client");

const prisma = new PrismaClient();

function dateUtcMidnight(dateStr) {
  return new Date(`${dateStr}T00:00:00.000Z`);
}

async function main() {
  await prisma.appointment.deleteMany();
  await prisma.doctorSchedule.deleteMany();
  await prisma.doctor.deleteMany();
  await prisma.patient.deleteMany();

  const passwordHash = await bcrypt.hash("password123", 10);

  await prisma.patient.createMany({
    data: [
      {
        email: "patient1@example.com",
        password: passwordHash,
        fullName: "Nguyễn Văn A",
        phoneNumber: "0123456789",
        dateOfBirth: dateUtcMidnight("1990-01-01"),
        gender: "male",
        address: "123 Đường ABC",
        bloodType: "A",
        emergencyContact: "0987654321",
      },
      {
        email: "patient2@example.com",
        password: passwordHash,
        fullName: "Trần Thị B",
        phoneNumber: "0909009009",
        dateOfBirth: dateUtcMidnight("1995-03-12"),
        gender: "female",
        address: "Hà Nội",
        bloodType: "O",
      },
      {
        email: "patient3@example.com",
        password: passwordHash,
        fullName: "Lê Văn C",
        phoneNumber: "0911222333",
        gender: "male",
        address: "Đà Nẵng",
        bloodType: "B",
      },
      {
        email: "patient4@example.com",
        password: passwordHash,
        fullName: "Phạm Thị D",
        phoneNumber: "0988111222",
        gender: "female",
        address: "TP.HCM",
        bloodType: "AB",
      },
      {
        email: "patient5@example.com",
        password: passwordHash,
        fullName: "Hoàng Văn E",
        phoneNumber: "0977000111",
        gender: "other",
        address: "Cần Thơ",
        bloodType: "A",
      },
    ],
  });

  const patients = await prisma.patient.findMany({ orderBy: { id: "asc" } });

  const doctorsData = [
    {
      email: "doctor1@example.com",
      fullName: "BS Nguyễn Văn 1",
      specialization: "Cardiology",
      experience: 10,
      consultationFee: "500000",
      rating: "4.50",
    },
    {
      email: "doctor2@example.com",
      fullName: "BS Trần Thị 2",
      specialization: "Dermatology",
      experience: 6,
      consultationFee: "350000",
      rating: "4.20",
    },
    {
      email: "doctor3@example.com",
      fullName: "BS Lê Văn 3",
      specialization: "Pediatrics",
      experience: 8,
      consultationFee: "400000",
      rating: "4.70",
    },
    {
      email: "doctor4@example.com",
      fullName: "BS Phạm Thị 4",
      specialization: "Orthopedics",
      experience: 12,
      consultationFee: "600000",
      rating: "4.10",
    },
    {
      email: "doctor5@example.com",
      fullName: "BS Hoàng Văn 5",
      specialization: "General",
      experience: 4,
      consultationFee: "250000",
      rating: "3.90",
    },
    {
      email: "doctor6@example.com",
      fullName: "BS Nguyễn Văn 6",
      specialization: "General",
      experience: 7,
      consultationFee: "300000",
      rating: "4.00",
    },
    {
      email: "doctor7@example.com",
      fullName: "BS Trần Thị 7",
      specialization: "Cardiology",
      experience: 9,
      consultationFee: "520000",
      rating: "4.60",
    },
    {
      email: "doctor8@example.com",
      fullName: "BS Lê Văn 8",
      specialization: "Dermatology",
      experience: 5,
      consultationFee: "320000",
      rating: "4.05",
    },
  ];

  const doctors = [];
  for (const d of doctorsData) {
    const doctor = await prisma.doctor.create({
      data: {
        email: d.email,
        password: passwordHash,
        fullName: d.fullName,
        specialization: d.specialization,
        qualification: "MD",
        experience: d.experience,
        consultationFee: d.consultationFee,
        rating: d.rating,
        isActive: true,
      },
    });
    doctors.push(doctor);
  }

  const schedules = [];
  for (const doctor of doctors) {
    for (let dayOfWeek = 1; dayOfWeek <= 6; dayOfWeek += 1) {
      schedules.push({
        doctorId: doctor.id,
        dayOfWeek,
        startTime: "09:00",
        endTime: "17:00",
        isAvailable: true,
      });
    }
  }
  await prisma.doctorSchedule.createMany({ data: schedules });

  const appointmentSlots = [
    { date: "2026-01-05", time: "09:00" },
    { date: "2026-01-05", time: "10:00" },
    { date: "2026-01-06", time: "11:00" },
    { date: "2026-01-06", time: "14:00" },
    { date: "2026-01-07", time: "15:00" },
    { date: "2026-01-08", time: "16:00" },
    { date: "2026-01-09", time: "09:00" },
    { date: "2026-01-09", time: "10:00" },
  ];

  const statuses = ["scheduled", "confirmed", "completed", "cancelled"];
  for (let i = 0; i < 12; i += 1) {
    const patientId = patients[i % patients.length].id;
    const doctorId = doctors[i % doctors.length].id;
    const cycleOffset = Math.floor(i / 8);
    const slot = appointmentSlots[(i + cycleOffset) % appointmentSlots.length];
    const status = statuses[i % statuses.length];
    const activeSlot = status === "cancelled" ? 0 : 1;

    await prisma.appointment.create({
      data: {
        patientId,
        doctorId,
        appointmentDate: dateUtcMidnight(slot.date),
        appointmentTime: slot.time,
        reason: `Khám định kỳ #${i + 1}`,
        status,
        activeSlot,
        diagnosis: status === "completed" ? "Bệnh nhân ổn định" : null,
        prescription: status === "completed" ? "Vitamin C 500mg" : null,
        notes: status === "completed" ? "Tái khám sau 1 tháng" : null,
      },
    });
  }
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });
