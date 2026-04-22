use railway;

CREATE TABLE Vehicle (
    id INT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(50) NOT NULL,
    registration_year INT CHECK (registration_year >= 1980),
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    transmission VARCHAR(20) CHECK (transmission IN ('Manual','Automatic')),
    mileage INT CHECK (mileage >= 0)
);
alter table Vehicle add photo varchar(500) Default NULL;

CREATE TABLE Driver (
    driver_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone_number VARCHAR(20) UNIQUE,
    address TEXT,
    license_number VARCHAR(50) UNIQUE NOT NULL,
    available BOOLEAN DEFAULT TRUE
);

CREATE TABLE Customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    driver_id INT UNIQUE,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone_number VARCHAR(20) UNIQUE,
    address TEXT,
    license_number VARCHAR(50) UNIQUE,
    FOREIGN KEY (driver_id) REFERENCES Driver(driver_id)
);

CREATE TABLE Rental_Booking (
    booking_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    driver_id INT,
    booking_status VARCHAR(20) 
        CHECK (booking_status IN ('Pending','Confirmed','Cancelled','Completed')),
    pickup_date DATE NOT NULL,
    return_date DATE NOT NULL,
    CHECK (return_date >= pickup_date),

    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    FOREIGN KEY (vehicle_id) REFERENCES Vehicle(id),
    FOREIGN KEY (driver_id) REFERENCES Driver(driver_id)
);

CREATE TABLE Maintenance (
    maintenance_id INT AUTO_INCREMENT PRIMARY KEY,
    vehicle_id INT NOT NULL,
    service_date DATE NOT NULL,
    next_service_mileage INT CHECK (next_service_mileage > 0),
    service_type VARCHAR(100),

    FOREIGN KEY (vehicle_id) REFERENCES Vehicle(id)
        ON DELETE CASCADE
);

CREATE TABLE Insurance (
    policy_id INT AUTO_INCREMENT PRIMARY KEY,
    vehicle_id INT NOT NULL,
    provider VARCHAR(100),
    start_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    premium_amount DECIMAL(10,2) CHECK (premium_amount > 0),
    CHECK (expiry_date > start_date),

    FOREIGN KEY (vehicle_id) REFERENCES Vehicle(id)
        ON DELETE CASCADE
);

CREATE TABLE Purchases (
    purchase_id INT AUTO_INCREMENT PRIMARY KEY,
    vehicle_id INT NOT NULL,
    customer_id INT NOT NULL,
    price DECIMAL(12,2) CHECK (price > 0),
    date DATE NOT NULL,
    status VARCHAR(20)
        CHECK (status IN ('Pending','Completed','Cancelled')),

    FOREIGN KEY (vehicle_id) REFERENCES Vehicle(id),
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
);

CREATE TABLE Payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT,
    purchase_id INT,
    payment_type VARCHAR(20)
        CHECK (payment_type IN ('Booking','Purchase')),
    amount DECIMAL(10,2) CHECK (amount > 0),
    method VARCHAR(30),
    isPaid BOOLEAN DEFAULT FALSE,

    FOREIGN KEY (booking_id) REFERENCES Rental_Booking(booking_id),
    FOREIGN KEY (purchase_id) REFERENCES Purchases(purchase_id)
);

CREATE TABLE Damage_Report (
    damage_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL,
    policy_id INT,
    damage_description TEXT,
    damage_part VARCHAR(100),
    repair_cost DECIMAL(10,2) DEFAULT 0,
    inspection_cost DECIMAL(10,2) DEFAULT 0,
    isResolved BOOLEAN DEFAULT FALSE,

    FOREIGN KEY (booking_id) REFERENCES Rental_Booking(booking_id),
    FOREIGN KEY (policy_id) REFERENCES Insurance(policy_id)
);

CREATE TABLE Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(50),
    email VARCHAR(100) UNIQUE NOT NULL,
    hire_date DATE,
    isActive BOOLEAN DEFAULT TRUE
);
ALTER TABLE Users ADD password VARCHAR(255);

-- INDEXES
CREATE INDEX idx_vehicle_make ON Vehicle(make);
CREATE INDEX idx_booking_vehicle ON Rental_Booking(vehicle_id);
CREATE INDEX idx_booking_customer ON Rental_Booking(customer_id);
CREATE INDEX idx_payment_booking ON Payments(booking_id);
CREATE INDEX idx_purchase_customer ON Purchases(customer_id);
CREATE INDEX idx_damage_booking ON Damage_Report(booking_id);

-- VIEW
-- Vehicle Insurance Status
CREATE VIEW Vehicle_Insurance_Status AS
SELECT v.id,
       v.make,
       v.model,
       i.provider,
       i.expiry_date,
       CASE 
           WHEN i.expiry_date >= CURDATE() THEN 'Valid'
           ELSE 'Expired'
       END AS insurance_status
FROM Vehicle v
LEFT JOIN Insurance i ON v.id = i.vehicle_id;

-- Customer Payment Summary
CREATE VIEW Customer_Payment_Summary AS
SELECT c.customer_id,
       c.name,
       SUM(p.amount) AS total_paid
FROM Customer c
JOIN Rental_Booking b ON c.customer_id = b.customer_id
JOIN Payments p ON b.booking_id = p.booking_id
WHERE p.isPaid = TRUE
GROUP BY c.customer_id, c.name;

ALTER TABLE Users 
MODIFY role VARCHAR(50) 
CHECK (role IN ('Admin','Customer','Employee','Driver'));

ALTER TABLE Vehicle
ADD COLUMN isAvailable BOOLEAN DEFAULT TRUE;

DELIMITER $$

CREATE TRIGGER trg_vehicle_sold
AFTER UPDATE ON Purchases
FOR EACH ROW
BEGIN
    IF NEW.status = 'Completed' THEN
        UPDATE Vehicle
        SET isAvailable = FALSE
        WHERE id = NEW.vehicle_id;
    END IF;
END$$

DELIMITER ;

-- 1. Add missing columns to Vehicle
ALTER TABLE Vehicle ADD COLUMN rent_per_day DECIMAL(10,2) NOT NULL DEFAULT 0;
ALTER TABLE Vehicle ADD COLUMN isRented BOOLEAN DEFAULT FALSE;

-- 2. Add total_amount to Rental_Booking
ALTER TABLE Rental_Booking ADD COLUMN total_amount DECIMAL(12,2) DEFAULT 0;

-- 3. Drop and recreate Active_Bookings view (adds customer_id, vehicle_id, total_amount)
DROP VIEW IF EXISTS Active_Bookings;
CREATE VIEW Active_Bookings AS
SELECT b.booking_id, c.customer_id, c.name AS customer_name,
       CONCAT(v.make,' ',v.model) AS vehicle, v.id AS vehicle_id,
       b.pickup_date, b.return_date, b.total_amount, b.booking_status
FROM Rental_Booking b
JOIN Customer c ON b.customer_id = c.customer_id
JOIN Vehicle  v ON b.vehicle_id  = v.id
WHERE b.booking_status IN ('Pending','Confirmed');

-- 4. Create Payment_History view
DROP VIEW IF EXISTS Payment_History;
CREATE VIEW Payment_History AS
SELECT p.payment_id, p.payment_type, p.amount, p.method, p.isPaid,
       b.booking_id, b.pickup_date, b.return_date, b.booking_status, b.total_amount AS booking_total,
       c.customer_id, c.name AS customer_name, c.email AS customer_email, c.phone_number AS customer_phone,
       CONCAT(v.make,' ',v.model) AS vehicle_name, v.rent_per_day, v.photo AS vehicle_photo,
       pur.purchase_id, pur.price AS purchase_price, pur.status AS purchase_status
FROM Payments p
LEFT JOIN Rental_Booking b ON p.booking_id  = b.booking_id
LEFT JOIN Purchases pur    ON p.purchase_id = pur.purchase_id
LEFT JOIN Customer c ON COALESCE(b.customer_id, pur.customer_id) = c.customer_id
LEFT JOIN Vehicle  v ON COALESCE(b.vehicle_id,  pur.vehicle_id)  = v.id
ORDER BY p.payment_id DESC;

-- 5. Create Sold_Vehicles view
DROP VIEW IF EXISTS Sold_Vehicles;
CREATE VIEW Sold_Vehicles AS
SELECT pur.purchase_id, pur.date AS sold_date, pur.price AS purchase_amount, pur.status,
       c.customer_id, c.name AS customer_name, c.email AS customer_email, c.phone_number AS customer_phone,
       CONCAT(v.make,' ',v.model) AS vehicle_name, v.id AS vehicle_id, v.type AS vehicle_type, v.photo AS vehicle_photo
FROM Purchases pur
JOIN Customer c ON pur.customer_id = c.customer_id
JOIN Vehicle  v ON pur.vehicle_id  = v.id
ORDER BY pur.date DESC;

-- 6. New triggers — drop old ones first if they exist
DROP TRIGGER IF EXISTS trg_driver_unavailable;
DROP TRIGGER IF EXISTS trg_auto_complete;
DROP TRIGGER IF EXISTS trg_payment_validation;
DROP TRIGGER IF EXISTS trg_vehicle_sold;

DELIMITER $$

CREATE TRIGGER trg_booking_confirmed
AFTER UPDATE ON Rental_Booking FOR EACH ROW
BEGIN
    IF NEW.booking_status = 'Confirmed' AND OLD.booking_status != 'Confirmed' THEN
        IF NEW.driver_id IS NOT NULL THEN
            UPDATE Driver SET available = FALSE WHERE driver_id = NEW.driver_id;
        END IF;
        UPDATE Vehicle SET isAvailable = FALSE, isRented = TRUE WHERE id = NEW.vehicle_id;
    END IF;
END$$

CREATE TRIGGER trg_booking_released
AFTER UPDATE ON Rental_Booking FOR EACH ROW
BEGIN
    IF (NEW.booking_status = 'Completed' OR NEW.booking_status = 'Cancelled')
       AND OLD.booking_status = 'Confirmed' THEN
        UPDATE Vehicle SET isAvailable = TRUE, isRented = FALSE WHERE id = NEW.vehicle_id;
        IF NEW.driver_id IS NOT NULL THEN
            UPDATE Driver SET available = TRUE WHERE driver_id = NEW.driver_id;
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_auto_complete
BEFORE UPDATE ON Rental_Booking FOR EACH ROW
BEGIN
    IF NEW.return_date < CURDATE() AND NEW.booking_status = 'Confirmed' THEN
        SET NEW.booking_status = 'Completed';
    END IF;
END$$

CREATE TRIGGER trg_payment_validation
BEFORE INSERT ON Payments FOR EACH ROW
BEGIN
    IF NEW.booking_id IS NULL AND NEW.purchase_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Payment must reference a booking or purchase';
    END IF;
END$$

CREATE TRIGGER trg_vehicle_sold
AFTER UPDATE ON Purchases FOR EACH ROW
BEGIN
    IF NEW.status = 'Completed' AND OLD.status != 'Completed' THEN
        UPDATE Vehicle SET isAvailable = FALSE, isRented = FALSE WHERE id = NEW.vehicle_id;
    END IF;
END$$

DELIMITER ;

ALTER TABLE Purchases DROP CONSTRAINT purchases_chk_1;
ALTER TABLE Purchases ADD CONSTRAINT purchases_chk_1 CHECK (price >= 0);
ALTER TABLE Purchases DROP CONSTRAINT purchases_chk_2;
ALTER TABLE Purchases ADD CONSTRAINT purchases_chk_2 
CHECK (status IN ('Pending','Confirmed','Completed','Cancelled'));
-- SET SQL_SAFE_UPDATES = 0;

-- 1. Mark vehicles as SOLD where a Completed purchase exists
UPDATE Vehicle v
JOIN Purchases p ON v.id = p.vehicle_id
SET v.isAvailable = FALSE, v.isRented = FALSE
WHERE p.status = 'Completed';
 
-- 2. Mark vehicles as RENTED where a Confirmed booking exists
--    (and the vehicle hasn't been sold)
UPDATE Vehicle v
JOIN Rental_Booking b ON v.id = b.vehicle_id
SET v.isAvailable = FALSE, v.isRented = TRUE
WHERE b.booking_status = 'Confirmed'
  AND v.id NOT IN (
    SELECT vehicle_id FROM Purchases WHERE status = 'Completed'
  );
 -- SET SQL_SAFE_UPDATES = 0;
-- 3. Free vehicles where booking is Completed/Cancelled
--    (and no active confirmed booking remains)
UPDATE Vehicle v
SET v.isAvailable = TRUE, v.isRented = FALSE
WHERE v.isRented = TRUE
  AND v.id NOT IN (
    SELECT vehicle_id FROM Rental_Booking WHERE booking_status = 'Confirmed'
  )
  AND v.id NOT IN (
    SELECT vehicle_id FROM Purchases WHERE status = 'Completed'
  );
 
 ALTER TABLE Purchases DROP CONSTRAINT purchases_chk_1;
ALTER TABLE Purchases ADD CONSTRAINT purchases_chk_1 
CHECK (price >= 0);

ALTER TABLE Purchases DROP CONSTRAINT purchases_chk_2;
ALTER TABLE Purchases ADD CONSTRAINT purchases_chk_2 
CHECK (status IN ('Pending','Confirmed','Completed','Cancelled'));