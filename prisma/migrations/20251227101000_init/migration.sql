-- Generated from prisma/schema.prisma (offline-friendly)

CREATE TABLE `patients` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `email` VARCHAR(191) NOT NULL,
  `password` VARCHAR(191) NOT NULL,
  `full_name` VARCHAR(191) NOT NULL,
  `phone_number` VARCHAR(191) NULL,
  `date_of_birth` DATETIME(3) NULL,
  `gender` ENUM('male', 'female', 'other') NULL,
  `address` VARCHAR(191) NULL,
  `blood_type` VARCHAR(191) NULL,
  `emergency_contact` VARCHAR(191) NULL,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE INDEX `patients_email_key`(`email`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `doctors` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `email` VARCHAR(191) NOT NULL,
  `password` VARCHAR(191) NOT NULL,
  `full_name` VARCHAR(191) NOT NULL,
  `phone_number` VARCHAR(191) NULL,
  `specialization` ENUM('Cardiology', 'Dermatology', 'Pediatrics', 'Orthopedics', 'General') NOT NULL,
  `qualification` VARCHAR(191) NULL,
  `experience` INT NOT NULL DEFAULT 0,
  `consultation_fee` DECIMAL(12, 2) NOT NULL,
  `rating` DECIMAL(3, 2) NOT NULL DEFAULT 0.0,
  `is_active` BOOLEAN NOT NULL DEFAULT true,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE INDEX `doctors_email_key`(`email`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `doctor_schedules` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `doctor_id` INT NOT NULL,
  `day_of_week` INT NOT NULL,
  `start_time` VARCHAR(191) NOT NULL,
  `end_time` VARCHAR(191) NOT NULL,
  `is_available` BOOLEAN NOT NULL DEFAULT true,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  INDEX `doctor_schedules_doctor_id_idx` (`doctor_id`),
  INDEX `doctor_schedules_doctor_id_day_of_week_idx` (`doctor_id`, `day_of_week`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE `appointments` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `patient_id` INT NOT NULL,
  `doctor_id` INT NOT NULL,
  `appointment_date` DATETIME(3) NOT NULL,
  `appointment_time` VARCHAR(191) NOT NULL,
  `reason` VARCHAR(191) NOT NULL,
  `status` ENUM('scheduled', 'confirmed', 'completed', 'cancelled', 'no_show') NOT NULL DEFAULT 'scheduled',
  `diagnosis` TEXT NULL,
  `prescription` TEXT NULL,
  `notes` TEXT NULL,
  `active_slot` INT NOT NULL DEFAULT 1,
  `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  INDEX `appointments_patient_id_idx` (`patient_id`),
  INDEX `appointments_doctor_id_idx` (`doctor_id`),
  INDEX `appointments_appointment_date_idx` (`appointment_date`),
  UNIQUE INDEX `uniq_doctor_date_time_active` (`doctor_id`, `appointment_date`, `appointment_time`, `active_slot`),
  PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE `appointments`
  ADD CONSTRAINT `appointments_patient_id_fkey` FOREIGN KEY (`patient_id`) REFERENCES `patients`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `appointments_doctor_id_fkey` FOREIGN KEY (`doctor_id`) REFERENCES `doctors`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE `doctor_schedules`
  ADD CONSTRAINT `doctor_schedules_doctor_id_fkey` FOREIGN KEY (`doctor_id`) REFERENCES `doctors`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

