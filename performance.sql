use ADBMS_project;

SELECT *
FROM Rental_Booking
WHERE customer_id = 4;

EXPLAIN ANALYZE
SELECT *
FROM Rental_Booking
WHERE customer_id = 4;

EXPLAIN ANALYZE
SELECT c.name, v.make, v.model
FROM Rental_Booking b
JOIN Customer c ON b.customer_id = c.customer_id
JOIN Vehicle v ON b.vehicle_id = v.id
WHERE b.booking_status = 'Confirmed';

EXPLAIN ANALYZE
SELECT *
FROM Vehicle
WHERE make = 'Toyota';

select * from users;