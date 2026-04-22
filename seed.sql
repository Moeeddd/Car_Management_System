USE ADBMS_project;

-- ================= USERS =================
INSERT INTO Users (name, role, email, password, hire_date, isActive) VALUES
('Admin', 'Admin', 'admin@gmail.pk', '$2a$10$rjM7CYJ2copg5jryYhUT2ufdQOGFsdIBK8owSdj8JmGT47JN0soWS', CURDATE(), TRUE),
('Ali Customer', 'Customer', 'ali@gmail.com', '$2a$10$rjM7CYJ2copg5jryYhUT2ufdQOGFsdIBK8owSdj8JmGT47JN0soWS', CURDATE(), TRUE),
('Sara Customer', 'Customer', 'sara@gmail.com', '$2a$10$rjM7CYJ2copg5jryYhUT2ufdQOGFsdIBK8owSdj8JmGT47JN0soWS', CURDATE(), TRUE),
('Driver User', 'Driver', 'driver@gmail.com', '$2a$10$rjM7CYJ2copg5jryYhUT2ufdQOGFsdIBK8owSdj8JmGT47JN0soWS', CURDATE(), TRUE);
UPDATE Users SET password = '123456' WHERE user_id = 12;
UPDATE Users SET password = '123456' WHERE email = 'ali@gmail.com';
UPDATE Users SET password = '123456' WHERE email = 'sara@gmail.com';
UPDATE Users SET password = '123456' WHERE email = 'driver@gmail.com';
UPDATE Users SET password = '123456' WHERE email = 'abd@gmail.com';

-- ================= DRIVERS =================
INSERT INTO Driver (name, email, phone_number, address, license_number, available) VALUES
('Driver User', 'driver@gmail.com', '03001234567', 'Lahore', 'LIC123', TRUE),
('Ahmed Driver', 'ahmed.driver@gmail.com', '03007654321', 'Karachi', 'LIC456', TRUE);

-- ================= CUSTOMERS =================
INSERT INTO Customer (name, email, phone_number, address, license_number) VALUES
('Ali Customer', 'ali@gmail.com', '03111111111', 'Lahore', 'CUST123'),
('Sara Customer', 'sara@gmail.com', '03222222222', 'Karachi', 'CUST456');

-- ================= VEHICLES =================
INSERT INTO Vehicle (type, registration_year, make, model, transmission, mileage, isAvailable) VALUES
('Car', 2020, 'Toyota', 'Corolla', 'Automatic', 50000, TRUE),
('Car', 2019, 'Honda', 'Civic', 'Manual', 60000, TRUE),
('SUV', 2022, 'Kia', 'Sportage', 'Automatic', 30000, TRUE);

-- DELETE FROM Rental_Booking;
-- ALTER TABLE Rental_Booking AUTO_INCREMENT = 1;
-- SET SQL_SAFE_UPDATES = 0;
-- ================= INSURANCE =================
INSERT INTO Insurance (vehicle_id, provider, start_date, expiry_date, premium_amount) VALUES
(1, 'State Life', '2024-01-01', '2026-01-01', 50000),
(2, 'Jubilee', '2024-06-01', '2026-06-01', 45000);

-- ================= BOOKINGS =================
INSERT INTO Rental_Booking (customer_id, vehicle_id, driver_id, booking_status, pickup_date, return_date) VALUES
(1, 1, 1, 'Pending', '2026-04-10', '2026-04-15'),
(2, 2, NULL, 'Pending', '2026-04-12', '2026-04-18');

-- ================= PURCHASES =================
INSERT INTO Purchases (vehicle_id, customer_id, price, date, status) VALUES
(3, 1, 3500000, '2026-04-01', 'Pending');

-- ================= PAYMENTS =================
INSERT INTO Payments (booking_id, payment_type, amount, method, isPaid) VALUES
(1, 'Booking', 5000, 'Cash', FALSE);

-- ================= DAMAGE REPORT =================
INSERT INTO Damage_Report (booking_id, damage_description, damage_part, repair_cost, inspection_cost, isResolved) VALUES
(1, 'Scratch on door', 'Door', 2000, 500, FALSE);