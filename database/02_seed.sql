-- ============================================================================
-- Smart Campus Resource & Lab Booking System
-- File: database/02_seed.sql (Aligned with Schema Version 2.0)
-- Populates 300+ meaningful, relational records across all 13 tables.
-- Includes verified conflict scenarios for Query 2 & disparity records for Query 7.
-- Author: Person B (Teammate B)
-- ============================================================================

USE smart_campus_db;

SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------------------------------------------------------
-- 1. Seed DEPARTMENT (8 records)
-- ----------------------------------------------------------------------------
INSERT INTO DEPARTMENT (department_id, department_name, head_of_dept, contact_email, phone) VALUES
(1, 'Computer Science & Engineering', 'Dr. Arvind Swaminathan', 'cse.head@campus.edu', '+91-9876540101'),
(2, 'Electronics & Communication Engineering', 'Dr. Meenakshi Sundaram', 'ece.head@campus.edu', '+91-9876540102'),
(3, 'Mechanical Engineering', 'Dr. Harish Chandra', 'me.head@campus.edu', '+91-9876540103'),
(4, 'Electrical & Electronics Engineering', 'Dr. Suresh Namboodiri', 'eee.head@campus.edu', '+91-9876540104'),
(5, 'Civil & Environmental Engineering', 'Dr. Bhaskar Sen', 'civil.head@campus.edu', '+91-9876540105'),
(6, 'Biotechnology & Bio-Engineering', 'Dr. Radhika Menon', 'biotech.head@campus.edu', '+91-9876540106'),
(7, 'Physics & Nanotechnology', 'Dr. C. Subramanian', 'physics.head@campus.edu', '+91-9876540107'),
(8, 'Central Computing & Innovation Centre', 'Dr. A.P. Srivastava', 'ccic.head@campus.edu', '+91-9876540108');

-- ----------------------------------------------------------------------------
-- 3. Seed USER (25 records)
-- ----------------------------------------------------------------------------
INSERT INTO `USER` (user_id, first_name, last_name, email, password_hash, phone, role_id, department_id, is_active) VALUES
(1, 'Aarav', 'Sharma', 'aarav.sharma@campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.AdminHashSalted101', '+91-9876543201', 4, 8, TRUE),
(2, 'Priya', 'Nair', 'priya.nair@campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.CoordHashSalted102', '+91-9876543202', 2, 1, TRUE),
(3, 'Vikram', 'Aditya', 'vikram.aditya@campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.CoordHashSalted103', '+91-9876543203', 2, 2, TRUE),
(4, 'Dr. Rajesh', 'Gupta', 'rajesh.gupta@campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.FacHashSalted104', '+91-9876543204', 2, 1, TRUE),
(5, 'Dr. Sneha', 'Kulkarni', 'sneha.kulkarni@campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.FacHashSalted105', '+91-9876543205', 2, 2, TRUE),
(6, 'Dr. Ananya', 'Roy', 'ananya.roy@campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.FacHashSalted106', '+91-9876543206', 2, 3, TRUE),
(7, 'Dr. Manish', 'Verma', 'manish.verma@campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.FacHashSalted107', '+91-9876543207', 2, 4, TRUE),
(8, 'Dr. Kavita', 'Rao', 'kavita.rao@campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.FacHashSalted108', '+91-9876543208', 2, 6, TRUE),
(9, 'Ramesh', 'Yadav', 'ramesh.yadav@campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.TechHashSalted109', '+91-9876543209', 3, 1, TRUE),
(10, 'Suresh', 'Babu', 'suresh.babu@campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.TechHashSalted110', '+91-9876543210', 3, 2, TRUE),
(11, 'Ganesh', 'Patil', 'ganesh.patil@campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.TechHashSalted111', '+91-9876543211', 3, 3, TRUE),
(12, 'Rohan', 'Mehta', 'rohan.mehta@student.campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.StudHashSalted112', '+91-9876543212', 1, 1, TRUE),
(13, 'Ishita', 'Sen', 'ishita.sen@student.campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.StudHashSalted113', '+91-9876543213', 1, 1, TRUE),
(14, 'Kabir', 'Deshmukh', 'kabir.d@student.campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.StudHashSalted114', '+91-9876543214', 1, 2, TRUE),
(15, 'Tanvi', 'Bhatia', 'tanvi.b@student.campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.StudHashSalted115', '+91-9876543215', 1, 2, TRUE),
(16, 'Aditya', 'Chopra', 'aditya.c@student.campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.StudHashSalted116', '+91-9876543216', 1, 3, TRUE),
(17, 'Neha', 'Singhania', 'neha.s@student.campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.StudHashSalted117', '+91-9876543217', 1, 3, TRUE),
(18, 'Rahul', 'Nambiar', 'rahul.n@student.campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.StudHashSalted118', '+91-9876543218', 1, 4, TRUE),
(19, 'Aniket', 'Mishra', 'aniket.m@student.campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.StudHashSalted119', '+91-9876543219', 1, 5, TRUE),
(20, 'Divya', 'Iyer', 'divya.i@student.campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.StudHashSalted120', '+91-9876543220', 1, 6, TRUE),
(21, 'Siddharth', 'Joshi', 'siddharth.j@student.campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.StudHashSalted121', '+91-9876543221', 1, 7, TRUE),
(22, 'Meera', 'Pillai', 'meera.p@student.campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.StudHashSalted122', '+91-9876543222', 1, 8, TRUE),
(23, 'Karan', 'Malhotra', 'karan.m@student.campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.StudHashSalted123', '+91-9876543223', 1, 1, TRUE),
(24, 'Ritu', 'Saxena', 'ritu.s@student.campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.StudHashSalted124', '+91-9876543224', 1, 2, TRUE),
(25, 'Arjun', 'Reddy', 'arjun.r@student.campus.edu', '$2b$12$e8Y5M1Pq9mIe3V.StudHashSalted125', '+91-9876543225', 1, 4, TRUE);

-- ----------------------------------------------------------------------------
-- 4. Seed LOCATION (12 records)
-- ----------------------------------------------------------------------------
INSERT INTO LOCATION (location_id, building_name, floor_number, room_number, campus, capacity) VALUES
(1, 'Alan Turing Block', 1, 'Lab-101', 'Main Campus', 45),
(2, 'Alan Turing Block', 1, 'Lab-102', 'Main Campus', 40),
(3, 'Alan Turing Block', 2, 'Hall-201', 'Main Campus', 120),
(4, 'Claude Shannon Complex', 2, 'Lab-201', 'Main Campus', 35),
(5, 'Claude Shannon Complex', 3, 'Studio-305', 'Main Campus', 30),
(6, 'James Watt Wing', 1, 'Bay-104', 'Main Campus', 25),
(7, 'James Watt Wing', 2, 'Lab-205', 'Main Campus', 50),
(8, 'Nikola Tesla Building', 1, 'Lab-110', 'Main Campus', 20),
(9, 'Rosalind Franklin Hall', 3, 'Suite-302', 'Main Campus', 25),
(10, 'C.V. Raman Science Wing', 2, 'Room-204', 'Main Campus', 15),
(11, 'Dr. A.P.J. Abdul Kalam Tower', 1, 'Audi-Main', 'Main Campus', 350),
(12, 'Dr. A.P.J. Abdul Kalam Tower', 4, 'Hub-401', 'Main Campus', 60);

-- ----------------------------------------------------------------------------
-- 5. Seed RESOURCE_TYPE (8 records)
-- ----------------------------------------------------------------------------
INSERT INTO RESOURCE_TYPE (resource_type_id, type_name, description) VALUES
(1, 'GPU Computing Server', 'NVIDIA A100 / RTX 4090 Deep Learning clusters'),
(2, '3D Printer & Rapid Prototyper', 'Industrial FDM and SLA Resin additive manufacturing units'),
(3, 'High-End Digital Oscilloscope', '4-Channel 1GHz Mixed Signal Test & Measurement Bench'),
(4, 'Robotic Arm Kit', '6-Axis articulated industrial robotic arms with vision module'),
(5, 'Smart Conference Audio/Video', '4K PTZ Camera, Laser Projector and Beamforming Microphones'),
(6, 'VR / AR Headset Station', 'Meta Quest Pro / HTC Vive Enterprise spatial computing stations'),
(7, 'PCB Prototyping Milling Machine', 'High-speed desktop CNC for dual-sided PCB fabrication'),
(8, 'Drone / UAV Development Rig', 'Quadcopter testbed with optical flow and telemetry sensors');

-- ----------------------------------------------------------------------------
-- 6. Seed RESOURCE (25 records)
-- ----------------------------------------------------------------------------
INSERT INTO RESOURCE (resource_id, resource_code, resource_name, resource_type_id, location_id, capacity, status, description) VALUES
(1, 'GPU-DGX-01', 'NVIDIA DGX Station A100-01', 1, 1, 1, 'available', 'Primary multi-GPU workstation for deep neural network model training'),
(2, 'GPU-DGX-02', 'NVIDIA DGX Station A100-02', 1, 1, 1, 'available', 'Secondary multi-GPU workstation for distributed inference and vision benchmarks'),
(3, 'GPU-RTX-01', 'RTX 4090 Deep Learning Rig 1', 1, 2, 1, 'available', 'Custom liquid-cooled workstation with dual RTX 4090 GPUs'),
(4, 'GPU-RTX-02', 'RTX 4090 Deep Learning Rig 2', 1, 2, 1, 'under_maintenance', 'Thermal maintenance and PCIe bus riser service'),
(5, 'PRN-3D-01', 'Ultimaker S5 Pro 3D Printer', 2, 12, 1, 'available', 'Dual-extrusion industrial grade FDM 3D printer with composite core'),
(6, 'PRN-3D-02', 'Formlabs Form 3+ SLA Printer', 2, 12, 1, 'available', 'High-precision stereolithography resin 3D printing system'),
(7, 'PRN-3D-03', 'Markforged Onyx Pro Carbon Printer', 2, 6, 1, 'available', 'Continuous carbon fiber reinforced composite rapid prototyper'),
(8, 'SCP-MSO-01', 'Tektronix MSO 1GHz Scope Bench A', 3, 4, 2, 'available', '4-Channel 1GHz digital phosphor oscilloscope with logic analyzer probes'),
(9, 'SCP-MSO-02', 'Tektronix MSO 1GHz Scope Bench B', 3, 4, 2, 'available', 'Bench B mixed-signal high-frequency waveform capture station'),
(10, 'SCP-KEY-01', 'Keysight Infiniium 4-CH Scope', 3, 5, 2, 'available', 'VLSI waveform timing jitter and eye-diagram analyzer'),
(11, 'ROB-UR5-01', 'Universal Robots UR5e Cobot Arm', 4, 6, 4, 'available', '6-Axis collaborative robot with built-in force torque sensor'),
(12, 'ROB-KUK-01', 'KUKA KR4 Agilus Robotic Arm', 4, 6, 4, 'under_maintenance', 'High-speed industrial manipulator under harmonic drive service'),
(13, 'ROB-DOB-01', 'DOBOT Magician Educational Robot', 4, 12, 2, 'available', 'Desktop robotic arm for kinematics and 3D pen dispensing'),
(14, 'AV-BAR-01', 'Barco 4K Laser Projection Alpha', 5, 3, 120, 'available', 'Dual laser 4K projection setup with surround audio for colloquiums'),
(15, 'AV-CHR-01', 'Christie Digital Cinema Projector', 5, 11, 350, 'available', 'Auditorium main stage digital laser projection system'),
(16, 'AV-POL-01', 'Polycom Trio Conference AV Setup', 5, 3, 20, 'available', 'Smart conference table with beamforming 360 audio mic array'),
(17, 'VR-QST-01', 'Meta Quest Pro Enterprise Rig 01', 6, 2, 2, 'available', 'High-fidelity spatial computing and eye-tracking development suite'),
(18, 'VR-QST-02', 'Meta Quest Pro Enterprise Rig 02', 6, 2, 2, 'available', 'Station 2 interactive virtual environment testing setup'),
(19, 'VR-HTC-01', 'HTC Vive Focus 3 VR Workspace', 6, 12, 2, 'available', 'Standalone enterprise VR station with sub-millimeter room scale tracking'),
(20, 'CNC-LPK-01', 'LPKF ProtoMat S64 PCB Milling Unit', 7, 5, 1, 'available', 'Automated tool-change PCB rapid trace router for RF circuits'),
(21, 'CNC-VOL-01', 'Voltera V-One PCB Electronics Printer', 7, 5, 1, 'retired', 'Conductive ink printer retired due to obsolete head architecture'),
(22, 'CNC-BUN-01', 'Bungard High-Precision CNC Mill', 7, 12, 1, 'available', 'Heavy-duty substrate drilling and routing bench'),
(23, 'UAV-DJI-01', 'DJI Matrice 300 RTK Flight Rig', 8, 6, 4, 'available', 'Indoor navigation testbed with RTK positioning and stereo vision cage'),
(24, 'UAV-PX4-01', 'Holybro PX4 Autonomous Drone Rig', 8, 12, 2, 'available', 'Open-source flight control quadcopter with optical flow guidance'),
(25, 'UAV-CRZ-01', 'Crazyflie Swarm Robotics Testbed', 8, 12, 6, 'available', 'Micro-quadcopter swarm localization testbed with ultra-wideband anchors');

-- ----------------------------------------------------------------------------
-- 7. Seed BOOKING (50 records)
-- ----------------------------------------------------------------------------
INSERT INTO BOOKING (booking_id, user_id, booking_date, start_time, end_time, purpose, status, total_resources) VALUES
(1, 12, '2026-11-01', '2026-11-01 10:00:00', '2026-11-01 14:00:00', 'Master Thesis Deep Learning Training', 'completed', 2),
(2, 13, '2026-11-01', '2026-11-01 11:00:00', '2026-11-01 13:00:00', 'Robotics Kinematics Capstone Project', 'completed', 2),
(3, 14, '2026-11-02', '2026-11-02 12:00:00', '2026-11-02 15:00:00', 'Faculty Research Grant Experimentation', 'completed', 1),
(4, 15, '2026-11-02', '2026-11-02 13:00:00', '2026-11-02 17:00:00', 'Hackathon Preparation & Rapid Prototyping', 'completed', 1),
(5, 16, '2026-11-03', '2026-11-03 14:00:00', '2026-11-03 16:00:00', 'Autonomous UAV Swarm Flight Testing', 'completed', 2),
(6, 17, '2026-11-03', '2026-11-03 09:00:00', '2026-11-03 12:00:00', 'VLSI Dual-Layer Circuit Verification', 'completed', 1),
(7, 18, '2026-11-04', '2026-11-04 10:00:00', '2026-11-04 14:00:00', 'Department Guest Lecture & Colloquium', 'completed', 2),
(8, 19, '2026-11-04', '2026-11-04 11:00:00', '2026-11-04 13:00:00', 'Semester End Lab Examination Mock Session', 'completed', 1),
(9, 20, '2026-11-05', '2026-11-05 12:00:00', '2026-11-05 15:00:00', 'Undergraduate Capstone Demo Practice', 'completed', 1),
(10, 21, '2026-11-05', '2026-11-05 13:00:00', '2026-11-05 17:00:00', 'Medical Imaging Bio-segmentation Run', 'completed', 1),
(11, 4, '2026-11-06', '2026-11-06 14:00:00', '2026-11-06 16:00:00', 'Bioinformatics Sequence Alignment Study', 'completed', 2),
(12, 5, '2026-11-06', '2026-11-06 09:00:00', '2026-11-06 12:00:00', 'Virtual Reality User Perception Study', 'completed', 1),
(13, 22, '2026-11-07', '2026-11-07 10:00:00', '2026-11-07 14:00:00', 'Additive Manufacturing Tensile Bar Test', 'completed', 2),
(14, 23, '2026-11-07', '2026-11-07 11:00:00', '2026-11-07 13:00:00', 'Smart Grid Inverter Frequency Analysis', 'completed', 1),
(15, 24, '2026-11-08', '2026-11-08 12:00:00', '2026-11-08 15:00:00', 'Robotics Automation Vision Tuning', 'completed', 1),
(16, 25, '2026-11-08', '2026-11-08 13:00:00', '2026-11-08 17:00:00', 'Master Thesis Deep Learning Training', 'completed', 1),
(17, 12, '2026-11-09', '2026-11-09 14:00:00', '2026-11-09 16:00:00', 'Robotics Kinematics Capstone Project', 'completed', 1),
(18, 13, '2026-11-09', '2026-11-09 09:00:00', '2026-11-09 12:00:00', 'Faculty Research Grant Experimentation', 'completed', 1),
(19, 14, '2026-11-10', '2026-11-10 10:00:00', '2026-11-10 14:00:00', 'Hackathon Preparation & Rapid Prototyping', 'completed', 1),
(20, 15, '2026-11-10', '2026-11-10 11:00:00', '2026-11-10 13:00:00', 'Autonomous UAV Swarm Flight Testing', 'completed', 1),
(21, 16, '2026-11-11', '2026-11-11 12:00:00', '2026-11-11 15:00:00', 'VLSI Dual-Layer Circuit Verification', 'completed', 1),
(22, 17, '2026-11-11', '2026-11-11 13:00:00', '2026-11-11 17:00:00', 'Department Guest Lecture & Colloquium', 'completed', 1),
(23, 6, '2026-11-12', '2026-11-12 14:00:00', '2026-11-12 16:00:00', 'Semester End Lab Examination Mock Session', 'completed', 1),
(24, 7, '2026-11-12', '2026-11-12 09:00:00', '2026-11-12 12:00:00', 'Undergraduate Capstone Demo Practice', 'completed', 1),
(25, 4, '2026-11-13', '2026-11-13 10:00:00', '2026-11-13 14:00:00', 'Medical Imaging Bio-segmentation Run', 'completed', 1),
(26, 12, '2026-11-15', '2026-11-15 11:00:00', '2026-11-15 13:00:00', 'Bioinformatics Sequence Alignment Study', 'confirmed', 2),
(27, 13, '2026-11-15', '2026-11-15 12:00:00', '2026-11-15 15:00:00', 'Virtual Reality User Perception Study', 'confirmed', 2),
(28, 14, '2026-11-16', '2026-11-16 13:00:00', '2026-11-16 17:00:00', 'Additive Manufacturing Tensile Bar Test', 'confirmed', 1),
(29, 15, '2026-11-16', '2026-11-16 14:00:00', '2026-11-16 16:00:00', 'Smart Grid Inverter Frequency Analysis', 'confirmed', 1),
(30, 16, '2026-11-17', '2026-11-17 09:00:00', '2026-11-17 12:00:00', 'Robotics Automation Vision Tuning', 'confirmed', 2),
(31, 17, '2026-11-17', '2026-11-17 10:00:00', '2026-11-17 14:00:00', 'Master Thesis Deep Learning Training', 'confirmed', 2),
(32, 18, '2026-11-18', '2026-11-18 11:00:00', '2026-11-18 13:00:00', 'Robotics Kinematics Capstone Project', 'confirmed', 1),
(33, 19, '2026-11-18', '2026-11-18 12:00:00', '2026-11-18 15:00:00', 'Faculty Research Grant Experimentation', 'confirmed', 1),
(34, 20, '2026-11-19', '2026-11-19 13:00:00', '2026-11-19 17:00:00', 'Hackathon Preparation & Rapid Prototyping', 'confirmed', 1),
(35, 21, '2026-11-19', '2026-11-19 14:00:00', '2026-11-19 16:00:00', 'Autonomous UAV Swarm Flight Testing', 'confirmed', 1),
(36, 5, '2026-11-20', '2026-11-20 09:00:00', '2026-11-20 12:00:00', 'VLSI Dual-Layer Circuit Verification', 'confirmed', 1),
(37, 22, '2026-11-20', '2026-11-20 10:00:00', '2026-11-20 14:00:00', 'Department Guest Lecture & Colloquium', 'confirmed', 1),
(38, 23, '2026-11-21', '2026-11-21 11:00:00', '2026-11-21 13:00:00', 'Semester End Lab Examination Mock Session', 'confirmed', 1),
(39, 13, '2026-11-15', '2026-11-15 11:30:00', '2026-11-15 14:30:00', 'Competing Slot: Deep Learning Model Validation', 'pending', 1),
(40, 14, '2026-11-16', '2026-11-16 15:00:00', '2026-11-16 18:00:00', 'Competing Slot: FDM Rapid Prototype Housing', 'pending', 1),
(41, 16, '2026-11-22', '2026-11-22 10:00:00', '2026-11-22 13:00:00', 'Competing Slot: AR/VR Auditorium Presentation', 'pending', 1),
(42, 18, '2026-11-22', '2026-11-22 11:00:00', '2026-11-22 14:00:00', 'Competing Slot: Robotics Project Demonstration', 'pending', 1),
(43, 20, '2026-11-25', '2026-11-25 10:00:00', '2026-11-25 14:00:00', 'Additive Manufacturing Tensile Bar Test', 'pending', 1),
(44, 22, '2026-11-25', '2026-11-25 11:00:00', '2026-11-25 13:00:00', 'Smart Grid Inverter Frequency Analysis', 'pending', 1),
(45, 13, '2026-11-20', '2026-11-20 12:00:00', '2026-11-20 15:00:00', 'PCB Trace Fabrication Test on Voltera', 'rejected', 1),
(46, 15, '2026-11-20', '2026-11-20 13:00:00', '2026-11-20 17:00:00', 'Flexible Sensor Print on Retired Unit', 'rejected', 1),
(47, 17, '2026-11-21', '2026-11-21 14:00:00', '2026-11-21 16:00:00', 'Industrial Robot Peak Speed Run', 'rejected', 1),
(48, 12, '2026-11-21', '2026-11-21 09:00:00', '2026-11-21 12:00:00', 'Faculty Research Grant Experimentation', 'cancelled', 1),
(49, 14, '2026-11-21', '2026-11-21 10:00:00', '2026-11-21 14:00:00', 'Hackathon Preparation & Rapid Prototyping', 'cancelled', 1),
(50, 16, '2026-11-22', '2026-11-22 11:00:00', '2026-11-22 13:00:00', 'Autonomous UAV Swarm Flight Testing', 'cancelled', 1);

-- ----------------------------------------------------------------------------
-- 8. Seed BOOKING_ITEM (60 records)
-- ----------------------------------------------------------------------------
INSERT INTO BOOKING_ITEM (booking_item_id, booking_id, resource_id, start_time, end_time, quantity, notes) VALUES
(1, 1, 1, '2026-11-01 10:00:00', '2026-11-01 14:00:00', 1, 'Primary allocation for booking #1'),
(2, 2, 2, '2026-11-01 11:00:00', '2026-11-01 13:00:00', 1, 'Primary allocation for booking #2'),
(3, 3, 3, '2026-11-02 12:00:00', '2026-11-02 15:00:00', 1, 'Primary allocation for booking #3'),
(4, 4, 3, '2026-11-02 13:00:00', '2026-11-02 17:00:00', 1, 'Primary allocation for booking #4'),
(5, 5, 5, '2026-11-03 14:00:00', '2026-11-03 16:00:00', 1, 'Primary allocation for booking #5'),
(6, 6, 6, '2026-11-03 09:00:00', '2026-11-03 12:00:00', 1, 'Primary allocation for booking #6'),
(7, 7, 7, '2026-11-04 10:00:00', '2026-11-04 14:00:00', 1, 'Primary allocation for booking #7'),
(8, 8, 8, '2026-11-04 11:00:00', '2026-11-04 13:00:00', 1, 'Primary allocation for booking #8'),
(9, 9, 9, '2026-11-05 12:00:00', '2026-11-05 15:00:00', 1, 'Primary allocation for booking #9'),
(10, 10, 10, '2026-11-05 13:00:00', '2026-11-05 17:00:00', 1, 'Primary allocation for booking #10'),
(11, 11, 11, '2026-11-06 14:00:00', '2026-11-06 16:00:00', 1, 'Primary allocation for booking #11'),
(12, 12, 13, '2026-11-06 09:00:00', '2026-11-06 12:00:00', 1, 'Primary allocation for booking #12'),
(13, 13, 13, '2026-11-07 10:00:00', '2026-11-07 14:00:00', 1, 'Primary allocation for booking #13'),
(14, 14, 14, '2026-11-07 11:00:00', '2026-11-07 13:00:00', 1, 'Primary allocation for booking #14'),
(15, 15, 15, '2026-11-08 12:00:00', '2026-11-08 15:00:00', 1, 'Primary allocation for booking #15'),
(16, 16, 16, '2026-11-08 13:00:00', '2026-11-08 17:00:00', 1, 'Primary allocation for booking #16'),
(17, 17, 17, '2026-11-09 14:00:00', '2026-11-09 16:00:00', 1, 'Primary allocation for booking #17'),
(18, 18, 18, '2026-11-09 09:00:00', '2026-11-09 12:00:00', 1, 'Primary allocation for booking #18'),
(19, 19, 19, '2026-11-10 10:00:00', '2026-11-10 14:00:00', 1, 'Primary allocation for booking #19'),
(20, 20, 20, '2026-11-10 11:00:00', '2026-11-10 13:00:00', 1, 'Primary allocation for booking #20'),
(21, 21, 22, '2026-11-11 12:00:00', '2026-11-11 15:00:00', 1, 'Primary allocation for booking #21'),
(22, 22, 22, '2026-11-11 13:00:00', '2026-11-11 17:00:00', 1, 'Primary allocation for booking #22'),
(23, 23, 23, '2026-11-12 14:00:00', '2026-11-12 16:00:00', 1, 'Primary allocation for booking #23'),
(24, 24, 24, '2026-11-12 09:00:00', '2026-11-12 12:00:00', 1, 'Primary allocation for booking #24'),
(25, 25, 25, '2026-11-13 10:00:00', '2026-11-13 14:00:00', 1, 'Primary allocation for booking #25'),
(26, 26, 1, '2026-11-15 11:00:00', '2026-11-15 13:00:00', 1, 'Confirmed session on DGX Station'),
(27, 27, 2, '2026-11-15 12:00:00', '2026-11-15 15:00:00', 1, 'Confirmed session on DGX Station 2'),
(28, 28, 3, '2026-11-16 13:00:00', '2026-11-16 17:00:00', 1, 'Confirmed session on RTX 4090'),
(29, 29, 5, '2026-11-16 14:00:00', '2026-11-16 16:30:00', 1, 'Confirmed 3D print session on Ultimaker'),
(30, 30, 5, '2026-11-17 09:00:00', '2026-11-17 12:00:00', 1, 'Confirmed 3D print batch on Ultimaker'),
(31, 31, 6, '2026-11-17 10:00:00', '2026-11-17 14:00:00', 1, 'Confirmed SLA print on Formlabs'),
(32, 32, 7, '2026-11-18 11:00:00', '2026-11-18 13:00:00', 1, 'Confirmed carbon print on Markforged'),
(33, 33, 8, '2026-11-18 12:00:00', '2026-11-18 15:00:00', 1, 'Confirmed scope bench testing'),
(34, 34, 9, '2026-11-19 13:00:00', '2026-11-19 17:00:00', 1, 'Confirmed scope bench B testing'),
(35, 35, 10, '2026-11-19 14:00:00', '2026-11-19 16:00:00', 1, 'Confirmed Keysight scope analysis'),
(36, 36, 11, '2026-11-20 09:00:00', '2026-11-20 12:00:00', 1, 'Confirmed UR5e robot run'),
(37, 37, 13, '2026-11-20 10:00:00', '2026-11-20 14:00:00', 1, 'Confirmed DOBOT robot session'),
(38, 38, 14, '2026-11-21 11:00:00', '2026-11-21 13:00:00', 1, 'Confirmed Barco projection colloquium'),
(39, 39, 1, '2026-11-15 11:30:00', '2026-11-15 14:30:00', 1, 'Competing reservation overlapping with booking #26'),
(40, 40, 5, '2026-11-16 15:00:00', '2026-11-16 18:00:00', 1, 'Competing reservation overlapping with booking #29'),
(41, 41, 14, '2026-11-22 10:00:00', '2026-11-22 13:00:00', 1, 'Competing request for Barco Projection Alpha'),
(42, 42, 14, '2026-11-22 11:00:00', '2026-11-22 14:00:00', 1, 'Direct collision with booking #41 for Barco Projection Alpha'),
(43, 43, 18, '2026-11-25 10:00:00', '2026-11-25 14:00:00', 1, 'Pending slot for VR Rig 02'),
(44, 44, 19, '2026-11-25 11:00:00', '2026-11-25 13:00:00', 1, 'Pending slot for HTC Vive Focus'),
(45, 45, 21, '2026-11-20 12:00:00', '2026-11-20 15:00:00', 1, 'Requested allocation for retired Voltera V-One'),
(46, 46, 21, '2026-11-20 13:00:00', '2026-11-20 17:00:00', 1, 'Second request for retired Voltera V-One'),
(47, 47, 11, '2026-11-21 14:00:00', '2026-11-21 16:00:00', 1, 'Rejected robotics slot'),
(48, 48, 23, '2026-11-21 09:00:00', '2026-11-21 12:00:00', 1, 'Cancelled drone flight test'),
(49, 49, 24, '2026-11-21 10:00:00', '2026-11-21 14:00:00', 1, 'Cancelled flight test'),
(50, 50, 25, '2026-11-22 11:00:00', '2026-11-22 13:00:00', 1, 'Cancelled swarm robotics test'),
(51, 1, 5, '2026-11-01 10:00:00', '2026-11-01 14:00:00', 1, 'Auxiliary equipment slot for booking #1'),
(52, 2, 6, '2026-11-01 11:00:00', '2026-11-01 13:00:00', 1, 'Auxiliary equipment slot for booking #2'),
(53, 5, 9, '2026-11-03 14:00:00', '2026-11-03 16:00:00', 1, 'Auxiliary equipment slot for booking #5'),
(54, 7, 11, '2026-11-04 10:00:00', '2026-11-04 14:00:00', 1, 'Auxiliary equipment slot for booking #7'),
(55, 11, 15, '2026-11-06 14:00:00', '2026-11-06 16:00:00', 1, 'Auxiliary equipment slot for booking #11'),
(56, 13, 17, '2026-11-07 10:00:00', '2026-11-07 14:00:00', 1, 'Auxiliary equipment slot for booking #13'),
(57, 26, 5, '2026-11-15 11:00:00', '2026-11-15 13:00:00', 1, 'Auxiliary equipment slot for booking #26'),
(58, 27, 6, '2026-11-15 12:00:00', '2026-11-15 15:00:00', 1, 'Auxiliary equipment slot for booking #27'),
(59, 30, 9, '2026-11-17 09:00:00', '2026-11-17 12:00:00', 1, 'Auxiliary equipment slot for booking #30'),
(60, 31, 10, '2026-11-17 10:00:00', '2026-11-17 14:00:00', 1, 'Auxiliary equipment slot for booking #31');

-- ----------------------------------------------------------------------------
-- 9. Seed APPROVAL (35 records)
-- ----------------------------------------------------------------------------
INSERT INTO APPROVAL (approval_id, booking_id, approver_id, decision, remarks, decided_at) VALUES
(1, 1, 2, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-01 04:00:00'),
(2, 2, 3, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-01 05:00:00'),
(3, 3, 1, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-02 06:00:00'),
(4, 4, 2, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-02 07:00:00'),
(5, 5, 3, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-03 08:00:00'),
(6, 6, 1, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-03 03:00:00'),
(7, 7, 2, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-04 04:00:00'),
(8, 8, 3, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-04 05:00:00'),
(9, 9, 1, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-05 06:00:00'),
(10, 10, 2, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-05 07:00:00'),
(11, 11, 3, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-06 08:00:00'),
(12, 12, 1, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-06 03:00:00'),
(13, 13, 2, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-07 04:00:00'),
(14, 14, 3, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-07 05:00:00'),
(15, 15, 1, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-08 06:00:00'),
(16, 16, 2, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-08 07:00:00'),
(17, 17, 3, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-09 08:00:00'),
(18, 18, 1, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-09 03:00:00'),
(19, 19, 2, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-10 04:00:00'),
(20, 20, 3, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-10 05:00:00'),
(21, 21, 1, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-11 06:00:00'),
(22, 22, 2, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-11 07:00:00'),
(23, 23, 3, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-12 08:00:00'),
(24, 24, 1, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-12 03:00:00'),
(25, 25, 2, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-13 04:00:00'),
(26, 26, 3, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-15 05:00:00'),
(27, 27, 1, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-15 06:00:00'),
(28, 28, 2, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-16 07:00:00'),
(29, 29, 3, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-16 08:00:00'),
(30, 30, 1, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-17 03:00:00'),
(31, 31, 2, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-17 04:00:00'),
(32, 32, 3, 'approved', 'Approved: Lab availability and user clearance verified.', '2026-11-18 05:00:00'),
(33, 45, 1, 'rejected', 'Rejected: Equipment Voltera V-One (CNC-VOL-01) is decommissioned/retired.', '2026-11-20 08:00:00'),
(34, 46, 2, 'rejected', 'Rejected: Equipment Voltera V-One (CNC-VOL-01) is decommissioned/retired.', '2026-11-20 09:00:00'),
(35, 47, 3, 'rejected', 'Rejected: Scheduling conflict with department examination.', '2026-11-21 10:00:00');

-- ----------------------------------------------------------------------------
-- 10. Seed MAINTENANCE (15 records)
-- ----------------------------------------------------------------------------
INSERT INTO MAINTENANCE (maintenance_id, resource_id, reported_by, assigned_to, issue_title, description, priority, status, reported_at, resolved_at) VALUES
(1, 4, 9, 10, 'Thermal paste degradation', 'GPU thermal throttling under moderate load', 'high', 'in_progress', '2026-11-20 10:00:00', NULL),
(2, 12, 11, 11, 'Axis 4 gearbox backlash', 'Exceeding 3 arcmin maximum manufacturer tolerance', 'critical', 'in_progress', '2026-11-21 14:00:00', NULL),
(3, 5, 10, 10, 'Print core AA nozzle wear', 'Bi-monthly nozzle replacement and bed leveling', 'low', 'open', '2026-11-22 09:00:00', NULL),
(4, 8, 10, 10, 'Annual calibration certification', 'Annual 10MHz clock standard verification by Tektronix', 'low', 'open', '2026-11-22 10:00:00', NULL),
(5, 1, 9, 9, 'Liquid cooling radiator flush', 'Coolant level topped up with low-conductivity fluid', 'low', 'resolved', '2026-11-15 13:00:00', '2026-11-16 11:00:00'),
(6, 11, 11, 11, 'Harmonic drive lubrication', 'Joint 3 synthetic grease replaced and safety stop tested', 'medium', 'closed', '2026-11-10 09:30:00', '2026-11-11 15:00:00'),
(7, 6, 10, 10, 'SLA optical tank clouding', 'Resin tank optical film clarity degraded; tank swapped', 'medium', 'closed', '2026-11-04 11:00:00', '2026-11-04 16:00:00'),
(8, 10, 10, 10, 'Channel 2 BNC input pin', 'Precision BNC front receptacle replaced', 'medium', 'closed', '2026-11-18 10:00:00', '2026-11-18 16:00:00'),
(9, 14, 9, 9, 'Laser projector intake filter', 'Cleaned electrostatic air filter and updated firmware', 'low', 'closed', '2026-11-03 08:00:00', '2026-11-03 14:00:00'),
(10, 17, 9, 9, 'Facial interface pad replacement', 'Anti-fog optical clean and silicone pad install', 'low', 'closed', '2026-11-19 14:00:00', '2026-11-19 19:00:00'),
(11, 20, 10, 10, 'HEPA dust extractor saturation', 'Replaced H13 secondary vacuum filter cartridge', 'high', 'closed', '2026-11-08 11:00:00', '2026-11-09 18:00:00'),
(12, 23, 11, 11, 'Drone carbon propeller chip', 'Replaced matched propeller pair on Arm 3', 'medium', 'closed', '2026-11-14 09:00:00', '2026-11-14 17:00:00'),
(13, 15, 9, 9, 'Auditorium projector power supply', 'Chiller relay replaced and output set to 48V DC', 'critical', 'closed', '2026-11-12 09:00:00', '2026-11-12 16:30:00'),
(14, 7, 10, 10, 'Fiberglass strand feed alignment', 'Hardened tool steel nozzle clearance set to 100um', 'low', 'closed', '2026-11-02 10:00:00', '2026-11-02 15:00:00'),
(15, 2, 9, 9, 'Ubuntu kernel security update', 'InfiniBand driver recompiled and benchmarked', 'low', 'open', '2026-11-22 11:00:00', NULL);

-- ----------------------------------------------------------------------------
-- 11. Seed USAGE_LOG (25 records)
-- ----------------------------------------------------------------------------
INSERT INTO USAGE_LOG (log_id, booking_id, resource_id, user_id, check_in_time, check_out_time, actual_usage) VALUES
(1, 1, 1, 12, '2026-11-01 09:55:00', '2026-11-01 13:58:00', 'Standard experimental laboratory session for booking #1'),
(2, 2, 2, 13, '2026-11-01 10:55:00', '2026-11-01 12:58:00', 'Standard experimental laboratory session for booking #2'),
(3, 3, 3, 14, '2026-11-02 11:55:00', '2026-11-02 14:58:00', 'Standard experimental laboratory session for booking #3'),
(4, 4, 3, 15, '2026-11-02 12:55:00', '2026-11-02 16:58:00', 'Standard experimental laboratory session for booking #4'),
(5, 5, 5, 16, '2026-11-03 13:55:00', '2026-11-03 15:58:00', 'Standard experimental laboratory session for booking #5'),
(6, 6, 6, 17, '2026-11-03 08:55:00', '2026-11-03 11:58:00', 'Standard experimental laboratory session for booking #6'),
(7, 7, 7, 18, '2026-11-04 09:55:00', '2026-11-04 13:58:00', 'Standard experimental laboratory session for booking #7'),
(8, 8, 8, 19, '2026-11-04 10:55:00', '2026-11-04 12:58:00', 'Standard experimental laboratory session for booking #8'),
(9, 9, 9, 20, '2026-11-05 11:55:00', '2026-11-05 14:58:00', 'Standard experimental laboratory session for booking #9'),
(10, 10, 10, 21, '2026-11-05 12:55:00', '2026-11-05 16:58:00', 'Standard experimental laboratory session for booking #10'),
(11, 11, 11, 4, '2026-11-06 13:55:00', '2026-11-06 15:58:00', 'Standard experimental laboratory session for booking #11'),
(12, 12, 13, 5, '2026-11-06 08:55:00', '2026-11-06 11:58:00', 'Standard experimental laboratory session for booking #12'),
(13, 13, 13, 22, '2026-11-07 09:55:00', '2026-11-07 13:58:00', 'Standard experimental laboratory session for booking #13'),
(14, 14, 14, 23, '2026-11-07 10:55:00', '2026-11-07 12:58:00', 'Standard experimental laboratory session for booking #14'),
(15, 15, 15, 24, '2026-11-08 11:55:00', '2026-11-08 14:58:00', 'Standard experimental laboratory session for booking #15'),
(16, 16, 16, 25, '2026-11-08 12:55:00', '2026-11-08 16:58:00', 'Standard experimental laboratory session for booking #16'),
(17, 17, 17, 12, '2026-11-09 13:55:00', '2026-11-09 15:58:00', 'Standard experimental laboratory session for booking #17'),
(18, 18, 18, 13, '2026-11-09 08:55:00', '2026-11-09 11:58:00', 'Standard experimental laboratory session for booking #18'),
(19, 19, 19, 14, '2026-11-10 09:55:00', '2026-11-10 13:58:00', 'Standard experimental laboratory session for booking #19'),
(20, 20, 20, 15, '2026-11-10 10:55:00', '2026-11-10 12:58:00', 'Standard experimental laboratory session for booking #20'),
(21, 21, 22, 16, '2026-11-11 11:55:00', '2026-11-11 14:58:00', 'Standard experimental laboratory session for booking #21'),
(22, 22, 22, 17, '2026-11-11 12:55:00', '2026-11-11 16:58:00', 'Standard experimental laboratory session for booking #22'),
(23, 23, 23, 6, '2026-11-12 13:55:00', '2026-11-12 15:58:00', 'Standard experimental laboratory session for booking #23'),
(24, 24, 24, 7, '2026-11-12 08:55:00', '2026-11-12 11:58:00', 'Standard experimental laboratory session for booking #24'),
(25, 25, 25, 4, '2026-11-13 09:55:00', '2026-11-13 13:58:00', 'Standard experimental laboratory session for booking #25');

-- ----------------------------------------------------------------------------
-- 12. Seed CANCELLATION (10 records)
-- ----------------------------------------------------------------------------
INSERT INTO CANCELLATION (cancellation_id, booking_id, cancelled_by, reason, cancelled_at) VALUES
(1, 48, 12, 'Emergency illness prevents student from attending scheduled hardware lab', '2026-11-21 10:15:00'),
(2, 49, 14, 'Project advisor rescheduled review meeting to next week', '2026-11-21 11:30:00'),
(3, 50, 16, 'Simulation dataset corrupted; need additional 48 hours for data pre-processing', '2026-11-22 09:00:00'),
(4, 18, 13, 'User found alternative open workstation in Central Innovation Centre', '2026-11-15 14:20:00'),
(5, 19, 14, 'Flight test cancelled due to unexpected indoor sensor calibration delay', '2026-11-16 16:45:00'),
(6, 20, 15, 'Experiment code refactoring needed before utilizing high-power GPU rig', '2026-11-17 08:30:00'),
(7, 21, 16, 'Duplicate booking submitted by accident by team member', '2026-11-17 12:10:00'),
(8, 22, 17, 'Department conference hall booked instead for presentation', '2026-11-18 11:00:00'),
(9, 23, 6, 'Component delivery delayed by logistics vendor; unable to solder PCB', '2026-11-19 13:50:00'),
(10, 24, 7, 'Student completed experiments earlier than scheduled timeline', '2026-11-20 15:25:00');

-- ----------------------------------------------------------------------------
-- 13. Seed AUDIT_LOG (30 records)
-- ----------------------------------------------------------------------------
INSERT INTO AUDIT_LOG (audit_id, booking_id, changed_by, action, old_status, new_status, change_details, ip_address, user_agent, changed_at) VALUES
(1, 1, 12, 'created', NULL, 'pending', '{"ip": "192.168.1.45", "method": "web_portal"}', '192.168.1.45', 'Mozilla/5.0 Chrome/118.0', '2026-11-01 09:15:00'),
(2, 1, 2, 'approval_granted', 'pending', 'confirmed', '{"approver": "Priya Nair", "clearance": "passed"}', '192.168.1.10', 'Mozilla/5.0 Firefox/119.0', '2026-11-01 12:00:00'),
(3, 1, 1, 'completed', 'confirmed', 'completed', '{"session": "normal_finish"}', '127.0.0.1', 'CronDaemon/1.0', '2026-11-01 18:00:00'),
(4, 2, 13, 'created', NULL, 'pending', '{"ip": "192.168.1.48", "method": "web_portal"}', '192.168.1.48', 'Mozilla/5.0 Safari/17.0', '2026-11-01 11:30:00'),
(5, 2, 2, 'approval_granted', 'pending', 'confirmed', '{"approver": "Priya Nair"}', '192.168.1.10', 'Mozilla/5.0 Firefox/119.0', '2026-11-01 13:45:00'),
(6, 2, 1, 'completed', 'confirmed', 'completed', '{"session": "normal_finish"}', '127.0.0.1', 'CronDaemon/1.0', '2026-11-01 19:00:00'),
(7, 3, 14, 'created', NULL, 'pending', '{"purpose": "DSP filtering"}', '192.168.1.52', 'Mozilla/5.0 Chrome/118.0', '2026-11-02 10:00:00'),
(8, 3, 3, 'approval_granted', 'pending', 'confirmed', '{"approver": "Vikram Aditya"}', '192.168.1.12', 'Mozilla/5.0 Chrome/118.0', '2026-11-02 12:15:00'),
(9, 4, 15, 'created', NULL, 'pending', '{"purpose": "FPGA Emulation"}', '192.168.1.55', 'Mozilla/5.0 Chrome/118.0', '2026-11-02 14:00:00'),
(10, 4, 3, 'approval_granted', 'pending', 'confirmed', '{"approver": "Vikram Aditya"}', '192.168.1.12', 'Mozilla/5.0 Chrome/118.0', '2026-11-02 16:00:00'),
(11, 48, 12, 'created', NULL, 'pending', '{"slot": "2026-11-21"}', '192.168.1.45', 'Mozilla/5.0 Chrome/118.0', '2026-11-21 09:00:00'),
(12, 48, 12, 'cancelled', 'pending', 'cancelled', '{"reason": "Emergency illness"}', '192.168.1.45', 'Mozilla/5.0 Chrome/118.0', '2026-11-21 10:15:00'),
(13, 49, 14, 'created', NULL, 'pending', '{"slot": "2026-11-21"}', '192.168.1.52', 'Mozilla/5.0 Chrome/118.0', '2026-11-21 11:00:00'),
(14, 49, 14, 'cancelled', 'pending', 'cancelled', '{"reason": "Advisor rescheduled"}', '192.168.1.52', 'Mozilla/5.0 Chrome/118.0', '2026-11-21 11:30:00'),
(15, 45, 13, 'created', NULL, 'pending', '{"purpose": "PCB trace print on Voltera"}', '192.168.1.48', 'Mozilla/5.0 Safari/17.0', '2026-11-20 11:00:00'),
(16, 45, 1, 'approval_denied', 'pending', 'rejected', '{"reason": "Equipment Voltera V-One is retired"}', '192.168.1.2', 'Mozilla/5.0 Edge/119.0', '2026-11-20 14:00:00'),
(17, 46, 15, 'created', NULL, 'pending', '{"purpose": "Flexible PCB printing on Voltera"}', '192.168.1.55', 'Mozilla/5.0 Chrome/118.0', '2026-11-20 15:00:00'),
(18, 46, 3, 'approval_denied', 'pending', 'rejected', '{"reason": "Equipment Voltera V-One is retired"}', '192.168.1.12', 'Mozilla/5.0 Chrome/118.0', '2026-11-20 17:30:00'),
(19, 47, 17, 'created', NULL, 'pending', '{"purpose": "Peak speed run"}', '192.168.1.60', 'Mozilla/5.0 Chrome/118.0', '2026-11-21 14:00:00'),
(20, 47, 2, 'approval_denied', 'pending', 'rejected', '{"reason": "Duration exceeds cap"}', '192.168.1.10', 'Mozilla/5.0 Firefox/119.0', '2026-11-21 16:00:00'),
(21, 26, 12, 'created', NULL, 'pending', '{"purpose": "Attention Profiling"}', '192.168.1.45', 'Mozilla/5.0 Chrome/118.0', '2026-11-15 09:00:00'),
(22, 26, 2, 'approval_granted', 'pending', 'confirmed', '{"approver": "Priya Nair"}', '192.168.1.10', 'Mozilla/5.0 Firefox/119.0', '2026-11-15 11:00:00'),
(23, 27, 13, 'created', NULL, 'pending', '{"purpose": "Convolutional Autoencoder"}', '192.168.1.48', 'Mozilla/5.0 Safari/17.0', '2026-11-15 13:30:00'),
(24, 27, 2, 'approval_granted', 'pending', 'confirmed', '{"approver": "Priya Nair"}', '192.168.1.10', 'Mozilla/5.0 Firefox/119.0', '2026-11-15 15:30:00'),
(25, 28, 14, 'created', NULL, 'pending', '{"purpose": "DSP Audio"}', '192.168.1.52', 'Mozilla/5.0 Chrome/118.0', '2026-11-16 10:15:00'),
(26, 28, 3, 'approval_granted', 'pending', 'confirmed', '{"approver": "Vikram Aditya"}', '192.168.1.12', 'Mozilla/5.0 Chrome/118.0', '2026-11-16 12:00:00'),
(27, 39, 13, 'created', NULL, 'pending', '{"purpose": "Competing Slot DGX-01"}', '192.168.1.48', 'Mozilla/5.0 Safari/17.0', '2026-11-15 11:30:00'),
(28, 40, 14, 'created', NULL, 'pending', '{"purpose": "Competing Slot Ultimaker"}', '192.168.1.52', 'Mozilla/5.0 Chrome/118.0', '2026-11-16 15:00:00'),
(29, 41, 16, 'created', NULL, 'pending', '{"purpose": "Competing Slot Barco Projection"}', '192.168.1.58', 'Mozilla/5.0 Chrome/118.0', '2026-11-22 10:00:00'),
(30, 42, 18, 'created', NULL, 'pending', '{"purpose": "Competing Slot Barco Projection 2"}', '192.168.1.62', 'Mozilla/5.0 Chrome/118.0', '2026-11-22 11:00:00');

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- VERIFICATION QUERY: Record Count Across All 13 Tables (Version 2.0)
-- ============================================================================

SELECT 'ROLE' AS Table_Name, COUNT(*) AS Total_Records FROM ROLE
UNION ALL SELECT 'DEPARTMENT', COUNT(*) FROM DEPARTMENT
UNION ALL SELECT 'USER', COUNT(*) FROM `USER`
UNION ALL SELECT 'LOCATION', COUNT(*) FROM LOCATION
UNION ALL SELECT 'RESOURCE_TYPE', COUNT(*) FROM RESOURCE_TYPE
UNION ALL SELECT 'RESOURCE', COUNT(*) FROM RESOURCE
UNION ALL SELECT 'BOOKING', COUNT(*) FROM BOOKING
UNION ALL SELECT 'BOOKING_ITEM', COUNT(*) FROM BOOKING_ITEM
UNION ALL SELECT 'APPROVAL', COUNT(*) FROM APPROVAL
UNION ALL SELECT 'MAINTENANCE', COUNT(*) FROM MAINTENANCE
UNION ALL SELECT 'USAGE_LOG', COUNT(*) FROM USAGE_LOG
UNION ALL SELECT 'CANCELLATION', COUNT(*) FROM CANCELLATION
UNION ALL SELECT 'AUDIT_LOG', COUNT(*) FROM AUDIT_LOG
UNION ALL SELECT 'TOTAL RECORDS (SUM)', (
    (SELECT COUNT(*) FROM ROLE) +
    (SELECT COUNT(*) FROM DEPARTMENT) +
    (SELECT COUNT(*) FROM `USER`) +
    (SELECT COUNT(*) FROM LOCATION) +
    (SELECT COUNT(*) FROM RESOURCE_TYPE) +
    (SELECT COUNT(*) FROM RESOURCE) +
    (SELECT COUNT(*) FROM BOOKING) +
    (SELECT COUNT(*) FROM BOOKING_ITEM) +
    (SELECT COUNT(*) FROM APPROVAL) +
    (SELECT COUNT(*) FROM MAINTENANCE) +
    (SELECT COUNT(*) FROM USAGE_LOG) +
    (SELECT COUNT(*) FROM CANCELLATION) +
    (SELECT COUNT(*) FROM AUDIT_LOG)
);
USE smart_campus_db;

SELECT * FROM ROLE;

SELECT * FROM DEPARTMENT;

SELECT * FROM `USER`;

SELECT * FROM LOCATION;

SELECT * FROM RESOURCE_TYPE;

SELECT * FROM RESOURCE;

SELECT * FROM BOOKING;

SELECT * FROM BOOKING_ITEM;

SELECT * FROM APPROVAL;

SELECT * FROM MAINTENANCE;

SELECT * FROM USAGE_LOG;

SELECT * FROM CANCELLATION;

SELECT * FROM AUDIT_LOG;
