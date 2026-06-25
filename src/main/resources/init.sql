-- =============================================
-- 宠物医疗预约系统数据库初始化脚本
-- =============================================

-- 创建数据库（如果不存在）
CREATE DATABASE IF NOT EXISTS pet_clinic DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE pet_clinic;

-- =============================================
-- 1. 用户表
-- =============================================
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '用户ID',
    `username` VARCHAR(50) NOT NULL COMMENT '用户名',
    `password` VARCHAR(255) NOT NULL COMMENT '密码（BCrypt加密）',
    `phone` VARCHAR(20) DEFAULT NULL COMMENT '手机号',
    `email` VARCHAR(100) DEFAULT NULL COMMENT '邮箱',
    `nickname` VARCHAR(50) DEFAULT NULL COMMENT '昵称',
    `avatar` VARCHAR(500) DEFAULT NULL COMMENT '头像URL',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_username` (`username`),
    UNIQUE KEY `uk_phone` (`phone`),
    KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- =============================================
-- 2. 宠物表
-- =============================================
DROP TABLE IF EXISTS `pet`;
CREATE TABLE `pet` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '宠物ID',
    `user_id` BIGINT NOT NULL COMMENT '所属用户ID',
    `name` VARCHAR(50) NOT NULL COMMENT '宠物名称',
    `breed` VARCHAR(100) DEFAULT NULL COMMENT '品种',
    `gender` VARCHAR(20) DEFAULT NULL COMMENT '性别：公/母/未绝育',
    `weight` DOUBLE DEFAULT NULL COMMENT '体重(kg)',
    `blood_type` VARCHAR(20) DEFAULT NULL COMMENT '血型',
    `birthday` VARCHAR(20) DEFAULT NULL COMMENT '生日',
    `photo_url` VARCHAR(500) DEFAULT NULL COMMENT '照片URL',
    `is_exotic` TINYINT(1) DEFAULT 0 COMMENT '是否异宠：0-否，1-是',
    `allergy_history` TEXT DEFAULT NULL COMMENT '过敏史',
    `is_pinned` TINYINT(1) DEFAULT 0 COMMENT '是否置顶：0-否，1-是',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_create_time` (`create_time`),
    CONSTRAINT `fk_pet_user` FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='宠物表';

-- =============================================
-- 3. 医院表
-- =============================================
DROP TABLE IF EXISTS `hospital`;
CREATE TABLE `hospital` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '医院ID',
    `name` VARCHAR(100) NOT NULL COMMENT '医院名称',
    `address` VARCHAR(255) DEFAULT NULL COMMENT '医院地址',
    `longitude` DOUBLE DEFAULT NULL COMMENT '经度',
    `latitude` DOUBLE DEFAULT NULL COMMENT '纬度',
    `rating` DOUBLE DEFAULT 4.5 COMMENT '评分（0-5）',
    `phone` VARCHAR(50) DEFAULT NULL COMMENT '联系电话',
    `business_hours` VARCHAR(100) DEFAULT NULL COMMENT '营业时间',
    `night_service` TINYINT(1) DEFAULT 0 COMMENT '夜间服务：0-否，1-是',
    `exotic_accept` TINYINT(1) DEFAULT 0 COMMENT '接诊异宠：0-否，1-是',
    `emergency_support` TINYINT(1) DEFAULT 0 COMMENT '急诊支持：0-否，1-是',
    `description` TEXT DEFAULT NULL COMMENT '医院简介',
    `logo_url` VARCHAR(500) DEFAULT NULL COMMENT '医院Logo URL',
    `services` TEXT DEFAULT NULL COMMENT '服务项目（JSON格式）',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_location` (`longitude`, `latitude`),
    KEY `idx_rating` (`rating`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='医院表';

-- =============================================
-- 4. 医生表
-- =============================================
DROP TABLE IF EXISTS `doctor`;
CREATE TABLE `doctor` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '医生ID',
    `hospital_id` BIGINT NOT NULL COMMENT '所属医院ID',
    `name` VARCHAR(50) NOT NULL COMMENT '医生姓名',
    `title` VARCHAR(100) DEFAULT NULL COMMENT '职称/执业资质',
    `specialty` VARCHAR(255) DEFAULT NULL COMMENT '专业领域',
    `rating` DOUBLE DEFAULT 4.5 COMMENT '评分（0-5）',
    `schedule` VARCHAR(500) DEFAULT NULL COMMENT '接诊时间（JSON格式）',
    `avatar_url` VARCHAR(500) DEFAULT NULL COMMENT '头像URL',
    `license_number` VARCHAR(50) DEFAULT NULL COMMENT '执业证书编号',
    `experience_years` INT DEFAULT 5 COMMENT '从业年限',
    `description` TEXT DEFAULT NULL COMMENT '医生简介',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_hospital_id` (`hospital_id`),
    KEY `idx_rating` (`rating`),
    CONSTRAINT `fk_doctor_hospital` FOREIGN KEY (`hospital_id`) REFERENCES `hospital`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='医生表';

-- =============================================
-- 5. 预约表
-- =============================================
DROP TABLE IF EXISTS `appointment`;
CREATE TABLE `appointment` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '预约ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `pet_id` BIGINT NOT NULL COMMENT '宠物ID',
    `hospital_id` BIGINT NOT NULL COMMENT '医院ID',
    `doctor_id` BIGINT DEFAULT NULL COMMENT '医生ID',
    `date` VARCHAR(20) NOT NULL COMMENT '预约日期（yyyy-MM-dd）',
    `time_slot` VARCHAR(50) NOT NULL COMMENT '时段（如 10:00-10:30）',
    `reason` VARCHAR(500) DEFAULT NULL COMMENT '就诊原因',
    `remark` VARCHAR(500) DEFAULT NULL COMMENT '备注（性格/过敏等）',
    `status` VARCHAR(20) DEFAULT '待处理' COMMENT '状态：待处理/已确认/已完成/已取消/已拒绝',
    `hospital_feedback` TEXT DEFAULT NULL COMMENT '医院反馈',
    `appointment_number` VARCHAR(50) DEFAULT NULL COMMENT '预约编号',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_appointment_number` (`appointment_number`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_hospital_id` (`hospital_id`),
    KEY `idx_doctor_id` (`doctor_id`),
    KEY `idx_date` (`date`),
    KEY `idx_status` (`status`),
    CONSTRAINT `fk_appointment_user` FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_appointment_pet` FOREIGN KEY (`pet_id`) REFERENCES `pet`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_appointment_hospital` FOREIGN KEY (`hospital_id`) REFERENCES `hospital`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_appointment_doctor` FOREIGN KEY (`doctor_id`) REFERENCES `doctor`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='预约表';

-- =============================================
-- 6. 验证码表（用于短信验证码登录）
-- =============================================
DROP TABLE IF EXISTS `verification_code`;
CREATE TABLE `verification_code` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT 'ID',
    `phone` VARCHAR(20) NOT NULL COMMENT '手机号',
    `code` VARCHAR(10) NOT NULL COMMENT '验证码',
    `type` VARCHAR(20) DEFAULT 'login' COMMENT '类型：login-登录，register-注册，reset-重置密码',
    `expire_time` DATETIME NOT NULL COMMENT '过期时间',
    `used` TINYINT(1) DEFAULT 0 COMMENT '是否已使用：0-否，1-是',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`),
    KEY `idx_phone` (`phone`),
    KEY `idx_expire_time` (`expire_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='验证码表';

-- =============================================
-- 7. 收藏表（用户收藏医院/医生）
-- =============================================
DROP TABLE IF EXISTS `favorite`;
CREATE TABLE `favorite` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT 'ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `target_type` VARCHAR(20) NOT NULL COMMENT '目标类型：hospital/doctor',
    `target_id` BIGINT NOT NULL COMMENT '目标ID',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_target` (`user_id`, `target_type`, `target_id`),
    CONSTRAINT `fk_favorite_user` FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='收藏表';

-- =============================================
-- 插入测试数据
-- =============================================

-- 插入测试用户（密码都是 123456，经过 BCrypt 加密）
INSERT INTO `user` (`id`, `username`, `password`, `phone`, `email`, `nickname`, `avatar`) VALUES
(1, 'testuser', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5EH', '13800138001', 'test@example.com', '测试用户', 'https://randomuser.me/api/portraits/men/1.jpg'),
(2, 'petlover', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5EH', '13800138002', 'petlover@example.com', '爱宠人士', 'https://randomuser.me/api/portraits/women/1.jpg'),
(3, 'doctor_fan', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5EH', '13800138003', 'doctor@example.com', '医生粉丝', 'https://randomuser.me/api/portraits/men/2.jpg');

-- 插入测试医院（北京地区）
INSERT INTO `hospital` (`id`, `name`, `address`, `longitude`, `latitude`, `rating`, `phone`, `business_hours`, `night_service`, `exotic_accept`, `emergency_support`, `description`, `logo_url`, `services`) VALUES
(1, '北京爱宠动物医院', '北京市朝阳区建国路88号', 116.461, 39.909, 4.8, '010-12345678', '周一至周日 08:00-21:00', 1, 1, 1, 
 '北京爱宠动物医院成立于2010年，是一家集医疗、美容、寄养于一体的综合性宠物医院。医院拥有先进的医疗设备和专业的医疗团队，为您的爱宠提供最优质的医疗服务。',
 'https://img.icons8.com/color/96/hospital-3.png',
 '["内科", "外科", "骨科", "皮肤科", "眼科", "牙科", "疫苗接种", "绝育手术", "宠物美容", "宠物寄养"]'),

(2, '宠爱国际动物医院', '北京市海淀区中关村大街1号', 116.315, 39.984, 4.6, '010-87654321', '周一至周日 09:00-20:00', 1, 0, 1,
 '宠爱国际动物医院是一家高端宠物医疗机构，引进国际先进的诊疗设备和技术，提供专业的宠物医疗服务。医院环境优雅，服务周到。',
 'https://img.icons8.com/color/96/hospital-2.png',
 '["内科", "外科", "骨科", "影像诊断", "疫苗接种", "绝育手术", "宠物美容"]'),

(3, '萌宠之家宠物医院', '北京市西城区西单北大街100号', 116.374, 39.913, 4.5, '010-55556666', '周一至周六 08:30-18:30', 0, 1, 0,
 '萌宠之家宠物医院专注于小动物诊疗，特别擅长猫科疾病的治疗。医院设备齐全，医生经验丰富，价格实惠。',
 'https://img.icons8.com/color/96/hospital.png',
 '["内科", "外科", "皮肤科", "疫苗接种", "绝育手术", "宠物美容"]'),

(4, '阳光宠物诊所', '北京市东城区东直门内大街50号', 116.427, 39.944, 4.3, '010-77778888', '周一至周五 09:00-18:00', 0, 0, 0,
 '阳光宠物诊所是一家社区型宠物诊所，提供基础的宠物医疗服务，价格亲民，服务热情。',
 'https://img.icons8.com/color/96/stethoscope.png',
 '["内科", "疫苗接种", "绝育手术"]');

-- 插入测试医生
INSERT INTO `doctor` (`id`, `hospital_id`, `name`, `title`, `specialty`, `rating`, `schedule`, `avatar_url`, `license_number`, `experience_years`, `description`) VALUES
-- 北京爱宠动物医院的医生
(1, 1, '张伟', '主任医师', '犬猫内科、骨科', 4.9, 
 '{"monday": ["09:00-12:00", "14:00-17:00"], "tuesday": ["09:00-12:00"], "wednesday": ["14:00-17:00"], "thursday": ["09:00-12:00", "14:00-17:00"], "friday": ["09:00-12:00"]}',
 'https://randomuser.me/api/portraits/men/32.jpg', 'BJVET2010001', 15,
 '张伟医生毕业于中国农业大学动物医学专业，从医15年，擅长犬猫内科和骨科疾病的诊治，在业界享有很高声誉。'),

(2, 1, '李娜', '副主任医师', '猫科疾病、皮肤科', 4.8,
 '{"monday": ["14:00-17:00"], "tuesday": ["09:00-12:00", "14:00-17:00"], "wednesday": ["09:00-12:00"], "thursday": ["14:00-17:00"], "friday": ["09:00-12:00", "14:00-17:00"]}',
 'https://randomuser.me/api/portraits/women/44.jpg', 'BJVET2010002', 12,
 '李娜医生是国内知名的猫科疾病专家，对猫咪的各类疾病有深入研究，尤其擅长皮肤病的诊治。'),

(3, 1, '王强', '主治医师', '外科手术、急诊', 4.7,
 '{"monday": ["09:00-12:00"], "tuesday": ["14:00-17:00"], "wednesday": ["09:00-12:00", "14:00-17:00"], "thursday": ["09:00-12:00"], "friday": ["14:00-17:00"]}',
 'https://randomuser.me/api/portraits/men/52.jpg', 'BJVET2010003', 10,
 '王强医生擅长各类外科手术，尤其是绝育手术和骨科手术，手术技术精湛，深受宠物主人信赖。'),

-- 宠爱国际动物医院的医生
(4, 2, '陈明', '主任医师', '影像诊断、内科', 4.9,
 '{"monday": ["09:00-12:00", "14:00-17:00"], "tuesday": ["09:00-12:00"], "wednesday": ["14:00-17:00"], "thursday": ["09:00-12:00", "14:00-17:00"], "friday": ["09:00-12:00"]}',
 'https://randomuser.me/api/portraits/men/62.jpg', 'BJVET2011001', 18,
 '陈明医生是影像诊断专家，擅长使用B超、X光等设备进行疾病诊断，诊断准确率高。'),

(5, 2, '刘芳', '副主任医师', '异宠诊疗、小动物内科', 4.6,
 '{"monday": ["14:00-17:00"], "tuesday": ["09:00-12:00", "14:00-17:00"], "wednesday": ["09:00-12:00"], "thursday": ["14:00-17:00"], "friday": ["09:00-12:00", "14:00-17:00"]}',
 'https://randomuser.me/api/portraits/women/28.jpg', 'BJVET2011002', 8,
 '刘芳医生是国内少有的异宠诊疗专家，擅长兔子、仓鼠、鸟类等异宠的疾病诊治。'),

-- 萌宠之家宠物医院的医生
(6, 3, '赵敏', '主治医师', '猫科疾病、疫苗接种', 4.5,
 '{"monday": ["09:00-12:00", "14:00-17:00"], "tuesday": ["09:00-12:00", "14:00-17:00"], "wednesday": ["09:00-12:00", "14:00-17:00"], "thursday": ["09:00-12:00", "14:00-17:00"], "friday": ["09:00-12:00", "14:00-17:00"], "saturday": ["09:00-12:00"]}',
 'https://randomuser.me/api/portraits/women/65.jpg', 'BJVET2012001', 6,
 '赵敏医生对猫科疾病有深入研究，尤其擅长猫咪疫苗接种和日常保健。'),

(7, 3, '周杰', '主治医师', '犬科疾病、绝育手术', 4.4,
 '{"monday": ["09:00-12:00"], "tuesday": ["14:00-17:00"], "wednesday": ["09:00-12:00", "14:00-17:00"], "thursday": ["09:00-12:00"], "friday": ["14:00-17:00"], "saturday": ["09:00-12:00", "14:00-17:00"]}',
 'https://randomuser.me/api/portraits/men/75.jpg', 'BJVET2012002', 5,
 '周杰医生擅长犬类疾病的诊治和绝育手术，手术经验丰富，术后恢复快。'),

-- 阳光宠物诊所的医生
(8, 4, '孙丽', '执业医师', '基础诊疗、疫苗接种', 4.3,
 '{"monday": ["09:00-12:00", "14:00-17:00"], "tuesday": ["09:00-12:00", "14:00-17:00"], "wednesday": ["09:00-12:00", "14:00-17:00"], "thursday": ["09:00-12:00", "14:00-17:00"], "friday": ["09:00-12:00", "14:00-17:00"]}',
 'https://randomuser.me/api/portraits/women/85.jpg', 'BJVET2013001', 4,
 '孙丽医生提供基础的宠物诊疗服务，态度亲切，价格实惠。');

-- 插入测试宠物
INSERT INTO `pet` (`id`, `user_id`, `name`, `breed`, `gender`, `weight`, `blood_type`, `birthday`, `photo_url`, `is_exotic`, `allergy_history`, `is_pinned`) VALUES
(1, 1, '豆豆', '金毛寻回犬', '公', 28.5, NULL, '2020-03-15', 'https://images.unsplash.com/photo-1552053831-71594a27632d?w=400', 0, '对鸡肉过敏', 1),
(2, 1, '咪咪', '英国短毛猫', '母', 4.2, NULL, '2021-06-20', 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=400', 0, NULL, 0),
(3, 1, '小白', '荷兰垂耳兔', '母', 2.1, NULL, '2022-01-10', 'https://images.unsplash.com/photo-1585110396000-c9ffd4e4b308?w=400', 1, NULL, 0),
(4, 2, '旺财', '柴犬', '公', 12.3, NULL, '2019-11-08', 'https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=400', 0, NULL, 1),
(5, 2, '花花', '布偶猫', '母', 5.8, NULL, '2022-04-05', 'https://images.unsplash.com/photo-1495360010541-f48722b34f7d?w=400', 0, '对海鲜过敏', 0);

-- 插入测试预约
INSERT INTO `appointment` (`id`, `user_id`, `pet_id`, `hospital_id`, `doctor_id`, `date`, `time_slot`, `reason`, `remark`, `status`, `appointment_number`) VALUES
(1, 1, 1, 1, 1, '2024-01-15', '10:00-10:30', '年度体检', '狗狗性格温顺，无特殊情况', '已完成', 'APT20240115001'),
(2, 1, 2, 1, 2, '2024-01-20', '14:00-14:30', '疫苗接种', '猫咪比较胆小，请温柔对待', '已确认', 'APT20240120001'),
(3, 2, 4, 2, 4, '2024-01-18', '09:00-09:30', '皮肤问题咨询', '最近发现皮肤有红点', '待处理', 'APT20240118001');

-- 插入测试收藏
INSERT INTO `favorite` (`user_id`, `target_type`, `target_id`) VALUES
(1, 'hospital', 1),
(1, 'hospital', 2),
(1, 'doctor', 1),
(2, 'hospital', 2),
(2, 'doctor', 4);

-- =============================================
-- 创建索引优化查询性能
-- =============================================
CREATE INDEX idx_appointment_user_status ON appointment(user_id, status);
CREATE INDEX idx_appointment_hospital_date ON appointment(hospital_id, date);
CREATE INDEX idx_appointment_doctor_date ON appointment(doctor_id, date);

-- =============================================
-- 存储过程：根据经纬度查询附近医院
-- =============================================
DELIMITER //
CREATE PROCEDURE sp_find_nearby_hospitals(
    IN p_lat DOUBLE,
    IN p_lng DOUBLE,
    IN p_radius DOUBLE,
    IN p_night_service TINYINT,
    IN p_exotic_accept TINYINT
)
BEGIN
    SELECT h.*, 
           (6371 * ACOS(
               COS(RADIANS(p_lat)) * COS(RADIANS(h.latitude)) * 
               COS(RADIANS(h.longitude) - RADIANS(p_lng)) + 
               SIN(RADIANS(p_lat)) * SIN(RADIANS(h.latitude))
           )) AS distance
    FROM hospital h
    WHERE (p_night_service IS NULL OR h.night_service = p_night_service)
      AND (p_exotic_accept IS NULL OR h.exotic_accept = p_exotic_accept)
    HAVING distance <= p_radius
    ORDER BY distance;
END //
DELIMITER ;

-- =============================================
-- 触发器：预约创建时自动生成预约编号
-- =============================================
DELIMITER //
CREATE TRIGGER tr_generate_appointment_number
BEFORE INSERT ON appointment
FOR EACH ROW
BEGIN
    IF NEW.appointment_number IS NULL THEN
        SET NEW.appointment_number = CONCAT('APT', DATE_FORMAT(NOW(), '%Y%m%d'), LPAD(FLOOR(RAND() * 10000), 4, '0'));
    END IF;
END //
DELIMITER ;

-- =============================================
-- 完成
-- =============================================
SELECT '数据库初始化完成！' AS message;
SELECT COUNT(*) AS hospital_count FROM hospital;
SELECT COUNT(*) AS doctor_count FROM doctor;
SELECT COUNT(*) AS user_count FROM user;