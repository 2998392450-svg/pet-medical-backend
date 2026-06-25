-- ============================================================
-- H2 兼容版 schema + data (从原 schema.sql 改造)
-- 改动:
--   1. 去掉 CREATE DATABASE / USE
--   2. 去掉所有 COMMENT '...' (H2 MySQL mode 支持,但为安全去掉)
--   3. 去掉 ENGINE=... DEFAULT CHARSET=... COLLATE=...
--   4. ON UPDATE CURRENT_TIMESTAMP -> 用 trigger 模拟
--   5. TINYINT(1) -> BOOLEAN
--   6. DECIMAL(...) 改 DOUBLE (entity 用的是 Double)
--   7. 保留 AUTO_INCREMENT (H2 MySQL 模式支持)
-- ============================================================

-- 用户表
CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    phone VARCHAR(20) UNIQUE,
    email VARCHAR(100) UNIQUE,
    nickname VARCHAR(50),
    avatar VARCHAR(255),
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_phone ON users(phone);

-- 宠物表
CREATE TABLE pets (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    name VARCHAR(50) NOT NULL,
    breed VARCHAR(100),
    is_exotic BOOLEAN DEFAULT FALSE,
    gender VARCHAR(10),
    birthday DATE,
    weight DOUBLE,
    blood_type VARCHAR(20),
    allergy_history TEXT,
    photo_url VARCHAR(255),
    is_pinned BOOLEAN DEFAULT FALSE,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_pets_user_id ON pets(user_id);

-- 医院表
CREATE TABLE hospitals (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(255),
    phone VARCHAR(20),
    description TEXT,
    logo_url VARCHAR(255),
    business_hours VARCHAR(100),
    night_service BOOLEAN DEFAULT FALSE,
    exotic_accept BOOLEAN DEFAULT FALSE,
    emergency_support BOOLEAN DEFAULT FALSE,
    services VARCHAR(500),
    rating DOUBLE DEFAULT 0,
    latitude DOUBLE,
    longitude DOUBLE,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_hospitals_location ON hospitals(latitude, longitude);
CREATE INDEX idx_hospitals_rating ON hospitals(rating);

-- 医生表
CREATE TABLE doctors (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    hospital_id BIGINT NOT NULL,
    name VARCHAR(50) NOT NULL,
    title VARCHAR(50),
    specialty VARCHAR(100),
    license_number VARCHAR(50),
    experience_years INT,
    rating DOUBLE DEFAULT 0,
    schedule VARCHAR(500),
    avatar_url VARCHAR(255),
    description TEXT,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (hospital_id) REFERENCES hospitals(id) ON DELETE CASCADE
);

CREATE INDEX idx_doctors_hospital_id ON doctors(hospital_id);

-- 预约记录表
CREATE TABLE appointments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    pet_id BIGINT NOT NULL,
    hospital_id BIGINT NOT NULL,
    doctor_id BIGINT,
    appointment_number VARCHAR(50) UNIQUE,
    date DATE NOT NULL,
    time_slot VARCHAR(20) NOT NULL,
    reason VARCHAR(500),
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    remark VARCHAR(500),
    hospital_feedback TEXT,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (pet_id) REFERENCES pets(id) ON DELETE CASCADE,
    FOREIGN KEY (hospital_id) REFERENCES hospitals(id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE SET NULL
);

CREATE INDEX idx_appointments_user_id ON appointments(user_id);
CREATE INDEX idx_appointments_status ON appointments(status);
CREATE INDEX idx_appointments_date ON appointments(date);

-- 收藏表
CREATE TABLE favorites (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    target_type VARCHAR(20) NOT NULL,
    target_id BIGINT NOT NULL,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT uk_favorites UNIQUE (user_id, target_type, target_id)
);

-- ============================================================
-- 初始数据
-- ============================================================

INSERT INTO hospitals (name, address, phone, description, business_hours, night_service, exotic_accept, emergency_support, services, rating, latitude, longitude) VALUES
('阳光宠物医院', '北京市朝阳区建国路88号', '010-12345678', '专业宠物医疗服务机构，提供全方位诊疗', '08:00-22:00', FALSE, FALSE, TRUE, '["普通门诊","疫苗接种","体检","手术"]', 4.8, 39.9042, 116.4074),
('爱心宠物诊所', '北京市海淀区中关村大街1号', '010-87654321', '温馨舒适的诊疗环境，关爱每一只宠物', '08:00-22:00', TRUE, TRUE, TRUE, '["普通门诊","疫苗接种","美容","寄养"]', 4.6, 39.9842, 116.3074),
('康宠动物医院', '北京市西城区西直门外大街12号', '010-23456789', '24小时营业，急诊服务随时待命', '08:00-次日08:00', TRUE, FALSE, TRUE, '["急诊","手术","住院","重症监护"]', 4.9, 39.9342, 116.3674),
('萌宠乐园', '北京市东城区王府井大街25号', '010-34567890', '专注小动物护理，提供优质服务', '08:00-22:00', FALSE, TRUE, FALSE, '["普通门诊","疫苗接种","驱虫","营养咨询"]', 4.5, 39.9142, 116.4174);

INSERT INTO doctors (hospital_id, name, title, specialty, license_number, experience_years, rating, description) VALUES
(1, '张医生', '主任医师', '犬猫内科', 'DC123456', 15, 4.9, '擅长犬猫内科疾病诊治，经验丰富'),
(1, '李医生', '副主任医师', '外科手术', 'DC654321', 12, 4.8, '精通各类宠物外科手术'),
(2, '王医生', '主治医师', '异宠专科', 'DC112233', 8, 4.7, '专注爬行动物、鸟类等异宠诊疗'),
(3, '赵医生', '主任医师', '急诊医学', 'DC445566', 20, 4.9, '24小时急诊值班，处理各类紧急情况'),
(4, '孙医生', '主治医师', '小动物保健', 'DC778899', 6, 4.6, '宠物营养与日常保健专家');

-- 默认管理员: admin / 123456 (BCrypt 加密)
INSERT INTO users (username, password, phone, nickname) VALUES
('admin', '$2a$10$N9qo8uLOickgx2ZMRZoMye.IjzqAKL9xL5jvMFVdNJHvGCgTq/VEq', '13800138000', '管理员');
