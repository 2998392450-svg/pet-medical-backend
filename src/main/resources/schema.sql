-- 创建数据库
CREATE DATABASE IF NOT EXISTS pet_clinic DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE pet_clinic;

-- 用户表
DROP TABLE IF EXISTS users;
CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '用户ID',
    username VARCHAR(50) NOT NULL UNIQUE COMMENT '用户名',
    password VARCHAR(255) NOT NULL COMMENT '密码(BCrypt加密)',
    phone VARCHAR(20) UNIQUE COMMENT '手机号',
    email VARCHAR(100) UNIQUE COMMENT '邮箱',
    nickname VARCHAR(50) COMMENT '昵称',
    avatar VARCHAR(255) COMMENT '头像URL',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_users_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- 宠物表
DROP TABLE IF EXISTS pets;
CREATE TABLE pets (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '宠物ID',
    user_id BIGINT NOT NULL COMMENT '所属用户ID',
    name VARCHAR(50) NOT NULL COMMENT '宠物名字',
    breed VARCHAR(100) COMMENT '品种(预设或自定义)',
    is_exotic TINYINT(1) DEFAULT 0 COMMENT '是否异宠(0-否,1-是)',
    gender VARCHAR(10) COMMENT '性别(公/母)',
    birthday DATE COMMENT '出生日期',
    weight DECIMAL(5,2) COMMENT '体重(kg)',
    blood_type VARCHAR(20) COMMENT '血型',
    allergy_history TEXT COMMENT '过敏史',
    photo_url VARCHAR(255) COMMENT '照片URL',
    is_pinned TINYINT(1) DEFAULT 0 COMMENT '是否置顶',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_pets_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='宠物表';

-- 医院表
DROP TABLE IF EXISTS hospitals;
CREATE TABLE hospitals (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '医院ID',
    name VARCHAR(100) NOT NULL COMMENT '医院名称',
    address VARCHAR(255) COMMENT '地址',
    phone VARCHAR(20) COMMENT '联系电话',
    description TEXT COMMENT '医院简介',
    logo_url VARCHAR(255) COMMENT 'logoURL',
    business_hours VARCHAR(100) COMMENT '营业时间描述',
    night_service TINYINT(1) DEFAULT 0 COMMENT '是否夜间服务(0-否,1-是)',
    exotic_accept TINYINT(1) DEFAULT 0 COMMENT '是否接诊异宠(0-否,1-是)',
    emergency_support TINYINT(1) DEFAULT 0 COMMENT '是否支持急诊(0-否,1-是)',
    services VARCHAR(500) COMMENT '服务项目(JSON数组)',
    rating DECIMAL(3,1) DEFAULT 0 COMMENT '评分',
    latitude DECIMAL(10,6) COMMENT '纬度',
    longitude DECIMAL(10,6) COMMENT '经度',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_hospitals_location (latitude, longitude),
    INDEX idx_hospitals_rating (rating)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='医院表';

-- 医生表
DROP TABLE IF EXISTS doctors;
CREATE TABLE doctors (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '医生ID',
    hospital_id BIGINT NOT NULL COMMENT '所属医院ID',
    name VARCHAR(50) NOT NULL COMMENT '医生姓名',
    title VARCHAR(50) COMMENT '职称',
    specialty VARCHAR(100) COMMENT '专业特长',
    license_number VARCHAR(50) COMMENT '执业证书号',
    experience_years INT COMMENT '从业年限',
    rating DECIMAL(3,1) DEFAULT 0 COMMENT '评分',
    schedule VARCHAR(500) COMMENT '排班信息(JSON)',
    avatar_url VARCHAR(255) COMMENT '头像URL',
    description TEXT COMMENT '医生简介',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (hospital_id) REFERENCES hospitals(id) ON DELETE CASCADE,
    INDEX idx_doctors_hospital_id (hospital_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='医生表';

-- 预约记录表
DROP TABLE IF EXISTS appointments;
CREATE TABLE appointments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '预约ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    pet_id BIGINT NOT NULL COMMENT '宠物ID',
    hospital_id BIGINT NOT NULL COMMENT '医院ID',
    doctor_id BIGINT COMMENT '医生ID(可选)',
    appointment_number VARCHAR(50) UNIQUE COMMENT '预约单号',
    date DATE NOT NULL COMMENT '预约日期',
    time_slot VARCHAR(20) NOT NULL COMMENT '预约时段(如08:00-08:30)',
    reason VARCHAR(500) COMMENT '就诊原因',
    status VARCHAR(20) NOT NULL DEFAULT 'pending' COMMENT '状态(pending-待处理,confirmed-已确认,completed-已完成,cancelled-已取消)',
    remark VARCHAR(500) COMMENT '备注',
    hospital_feedback TEXT COMMENT '医院反馈',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (pet_id) REFERENCES pets(id) ON DELETE CASCADE,
    FOREIGN KEY (hospital_id) REFERENCES hospitals(id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE SET NULL,
    INDEX idx_appointments_user_id (user_id),
    INDEX idx_appointments_status (status),
    INDEX idx_appointments_date (date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='预约记录表';

-- 收藏表
DROP TABLE IF EXISTS favorites;
CREATE TABLE favorites (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '收藏ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    target_type VARCHAR(20) NOT NULL COMMENT '收藏类型(hospital/doctor)',
    target_id BIGINT NOT NULL COMMENT '目标ID',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uk_favorites (user_id, target_type, target_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='收藏表';

-- 插入测试数据
INSERT INTO hospitals (name, address, phone, description, business_hours, night_service, exotic_accept, emergency_support, services, rating, latitude, longitude) VALUES
('阳光宠物医院', '北京市朝阳区建国路88号', '010-12345678', '专业宠物医疗服务机构，提供全方位诊疗', '08:00-22:00', 0, 0, 1, '["普通门诊","疫苗接种","体检","手术"]', 4.8, 39.9042, 116.4074),
('爱心宠物诊所', '北京市海淀区中关村大街1号', '010-87654321', '温馨舒适的诊疗环境，关爱每一只宠物', '08:00-22:00', 1, 1, 1, '["普通门诊","疫苗接种","美容","寄养"]', 4.6, 39.9842, 116.3074),
('康宠动物医院', '北京市西城区西直门外大街12号', '010-23456789', '24小时营业，急诊服务随时待命', '08:00-次日08:00', 1, 0, 1, '["急诊","手术","住院","重症监护"]', 4.9, 39.9342, 116.3674),
('萌宠乐园', '北京市东城区王府井大街25号', '010-34567890', '专注小动物护理，提供优质服务', '08:00-22:00', 0, 1, 0, '["普通门诊","疫苗接种","驱虫","营养咨询"]', 4.5, 39.9142, 116.4174);

INSERT INTO doctors (hospital_id, name, title, specialty, license_number, experience_years, rating, description) VALUES
(1, '张医生', '主任医师', '犬猫内科', 'DC123456', 15, 4.9, '擅长犬猫内科疾病诊治，经验丰富'),
(1, '李医生', '副主任医师', '外科手术', 'DC654321', 12, 4.8, '精通各类宠物外科手术'),
(2, '王医生', '主治医师', '异宠专科', 'DC112233', 8, 4.7, '专注爬行动物、鸟类等异宠诊疗'),
(3, '赵医生', '主任医师', '急诊医学', 'DC445566', 20, 4.9, '24小时急诊值班，处理各类紧急情况'),
(4, '孙医生', '主治医师', '小动物保健', 'DC778899', 6, 4.6, '宠物营养与日常保健专家');

INSERT INTO users (username, password, phone, nickname) VALUES
('admin', '$2a$10$N9qo8uLOickgx2ZMRZoMye.IjzqAKL9xL5jvMFVdNJHvGCgTq/VEq', '13800138000', '管理员');
