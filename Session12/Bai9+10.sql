CREATE TABLE patients (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL unique,
    dob DATE NOT NULL,
    gender ENUM('Male', 'Female') NOT NULL,
    phone VARCHAR(15) NOT NULL UNIQUE
);

CREATE TABLE doctors (
    doctor_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    specialization VARCHAR(100) NOT NULL,
    phone VARCHAR(15) NOT NULL UNIQUE,
    salary DECIMAL(10,2) NOT NULL
);

CREATE TABLE appointments (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATETIME NOT NULL,
    status ENUM('Scheduled', 'Completed', 'Cancelled') NOT NULL,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
);

CREATE TABLE prescriptions (
    prescription_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL,
    medicine_name VARCHAR(100) NOT NULL,
    dosage VARCHAR(50) NOT NULL,
    duration INT NOT NULL,
    notes VARCHAR(255),
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
);

-- 2
CREATE TABLE patient_error_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_name VARCHAR(100),
    phone_number VARCHAR(15),
    error_message VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
); 

-- 3
delimiter &&
create trigger trg_before_inserts before insert on patients
for each row
begin
    if exists (
		select 1 from patients where name = NEW.name
    ) then
		insert into patient_error_log(patient_name, phone_number, error_message)
        values(NEW.name, NEW.phone, 'Bệnh nhân đã tồn tại');
        
        signal sqlstate '45000'
        set message_text = 'Bệnh nhân đã tồn tại trong hệ thống!';
	end if;
end &&
delimiter && 

drop trigger trg_before_inserts;

-- 4
delete from patients;
INSERT INTO patients (name, dob, gender, phone) VALUES ('John Doe', '1990-01-01', 'Male', '1234567890'); 

INSERT INTO patients (name, dob, gender, phone) VALUES ('John Doe', '1990-01-01', 'Male', '0987654321');

-- 5
delimiter &&
create trigger trg_before_insertPhone before insert on patients
for each row
begin
    if NEW.phone not regexp '^[0-9]{10}$' then
		insert into patient_error_log(patient_name, phone_number, error_message)
        values(NEW.name, NEW.phone, 'Số điện thoại không hợp lệ!');
        
        signal sqlstate '45000'
        set message_text = 'Số điện thoại không hợp lệ!';
	end if;
end &&
delimiter && 

delete from patients;
INSERT INTO patients (name, dob, gender, phone) VALUES
('Alice Smith', '1985-06-15', 'Female', '0123456789'),
('Bob Johnson', '1990-02-25', 'Male', '0234567890'),
('Carol Williams', '1975-03-10', 'Female', '0345678901'),

('Dave Brown', '1992-09-05', 'Male', '4567890abc'),  -- Số điện thoại không hợp lệ

('Eve Davis', '1980-12-30', 'Female', '56789xyz'),      -- Số điện thoại không hợp lệ

('Eve', '1980-12-13', 'Female', '56789');      -- Số điện thoại không hợp lệ

-- 7
select * from patient_error_log;

-- 8
delimiter &&
create procedure update_appointment_status(
    in p_appointment_id int,
    in p_status enum('scheduled', 'completed', 'cancelled')
)
begin
    update appointments
    set status = p_status
    where appointment_id = p_appointment_id;
end &&
delimiter ;

-- 9
delimiter &&
create trigger update_status_after_prescription_insert
after insert on prescriptions
for each row
begin
    call update_appointment_status(new.appointment_id, 'completed');
end &&
delimiter ;

-- 10+11
-- Them bac si

INSERT INTO doctors (name, specialization, phone, salary) 

VALUES ('Dr. John Smith', 'Cardiology', '1234567890', 5000.00);

INSERT INTO doctors (name, specialization, phone, salary) 

VALUES ('Dr. Alice Brown', 'Neurology', '0987654321', 6000.00);

-- Thêm cuộc hẹn 

INSERT INTO appointments (patient_id, doctor_id, appointment_date, status) 

VALUES (1, 1, '2025-02-15 09:00:00', 'Scheduled');

INSERT INTO appointments (patient_id, doctor_id, appointment_date, status) 

VALUES (2, 2, '2025-02-16 10:00:00', 'Scheduled');

INSERT INTO appointments (patient_id, doctor_id, appointment_date, status) 

VALUES (3, 1, '2025-02-17 14:00:00', 'Scheduled');


SELECT * FROM appointments;

-- Thêm một đơn thuốc cho cuộc hẹn với ID = 1

INSERT INTO prescriptions (appointment_id, medicine_name, dosage, duration, notes) 

VALUES (1, 'Paracetamol', '500mg', 5, 'Take one tablet every 6 hours');

SELECT * FROM appointments; 

-- Bài 10
-- 2
delimiter &&
create procedure get_doctor_details(in input_doctor_id int)
begin
    select 
        d.name as doctor_name,
        d.specialization,
        count(distinct a.patient_id) as total_patients,
        coalesce(sum(d.salary), 0) as total_revenue,
        coalesce(count(p.prescription_id), 0) as total_medicines_prescribed
    from doctors d
    left join appointments a on d.doctor_id = a.doctor_id
    left join prescriptions p on a.appointment_id = p.appointment_id
    where d.doctor_id = input_doctor_id
    group by d.doctor_id;
end &&
delimiter ;

-- 3
create table cancellation_logs (
    log_id int auto_increment primary key,
    appointment_id int not null,
    log_message varchar(255) not null,
    log_date datetime default current_timestamp
);

-- 4
create table appointment_logs (
    log_id int auto_increment primary key,
    appointment_id int not null,
    log_message varchar(255) not null,
    log_date datetime default current_timestamp
);


-- 5
delimiter &&
create trigger after_delete_appointments
after delete on appointments
for each row
begin
    -- Xóa đơn thuốc liên quan đến cuộc hẹn đã xóa
    delete from prescriptions where appointment_id = old.appointment_id;

    -- Kiểm tra trạng thái cuộc hẹn và ghi vào bảng logs tương ứng
    if old.status = 'Cancelled' then
        insert into cancellation_logs (appointment_id, log_message, log_date)
        values (old.appointment_id, 'Cancelled appointment was deleted', now());
    elseif old.status = 'Completed' then
        insert into appointment_logs (appointment_id, log_message, log_date)
        values (old.appointment_id, 'Completed appointment was deleted', now());
    end if;
end &&
delimiter ;
   
-- 6
CREATE VIEW FullRevenueReport AS  
SELECT   
    d.doctor_id,  
    d.name AS doctor_name,  
    COUNT(a.appointment_id) AS total_appointments,  
    COUNT(DISTINCT a.patient_id) AS total_patients,  
    SUM(CASE WHEN a.status = 'Completed' THEN d.salary ELSE 0 END) AS total_revenue,  
    COUNT(p.medicine_name) AS total_medicines  
FROM   
    doctors d  
LEFT JOIN   
    appointments a ON d.doctor_id = a.doctor_id  
LEFT JOIN   
    prescriptions p ON a.appointment_id = p.appointment_id  
GROUP BY   
    d.doctor_id, d.name;
    
-- 7
call get_doctor_details(1);

-- 8
delete from appointments where appointment_id = 3; 
delete from appointments where appointment_id = 2; 
 
-- 9
select * from FullRevenueReport; 
 