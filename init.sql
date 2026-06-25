-- ============================================
-- 宠物医疗预约系统 数据库初始化脚本
-- 使用前请确保已创建 pet_medical 数据库
-- 执行：mysql -u root -p123456 < init.sql
-- ============================================

CREATE DATABASE IF NOT EXISTS pet_medical DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pet_medical;

-- ========== 1. 用户表 ==========
DROP TABLE IF EXISTS `appointment`;
DROP TABLE IF EXISTS `doctor`;
DROP TABLE IF EXISTS `merchant_application`;
DROP TABLE IF EXISTS `hospital`;
DROP TABLE IF EXISTS `pet`;
DROP TABLE IF EXISTS `user`;

CREATE TABLE `user` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `username` VARCHAR(50) NOT NULL UNIQUE,
  `password` VARCHAR(255) NOT NULL COMMENT 'bcrypt加密',
  `phone` VARCHAR(20) UNIQUE,
  `email` VARCHAR(100),
  `nickname` VARCHAR(50),
  `avatar` VARCHAR(500),
  `role` VARCHAR(20) NOT NULL DEFAULT 'user' COMMENT 'user/merchant/admin',
  `hospital_id` INT DEFAULT NULL COMMENT '商家关联的医院ID',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========== 2. 医院表 ==========
CREATE TABLE `hospital` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `address` VARCHAR(255) NOT NULL,
  `phone` VARCHAR(30),
  `city` VARCHAR(20) DEFAULT '上海',
  `lng` DECIMAL(10,6) COMMENT '经度',
  `lat` DECIMAL(10,6) COMMENT '纬度',
  `rating` DECIMAL(2,1) DEFAULT 4.5,
  `business_hours` VARCHAR(50) DEFAULT '09:00-21:00',
  `night_service` TINYINT(1) DEFAULT 0 COMMENT '是否夜间服务',
  `exotic_accept` TINYINT(1) DEFAULT 0 COMMENT '是否接诊异宠',
  `emergency_support` TINYINT(1) DEFAULT 0 COMMENT '是否支持急诊',
  `description` TEXT,
  `services` VARCHAR(500),
  `license_url` VARCHAR(2000) COMMENT '营业执照图片(base64或URL)',
  `logo_url` VARCHAR(2000) COMMENT '医院logo图片',
  `verified` TINYINT(1) DEFAULT 1 COMMENT '是否已认证(预置数据为1)',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========== 3. 医生表 ==========
CREATE TABLE `doctor` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `hospital_id` INT NOT NULL,
  `name` VARCHAR(50) NOT NULL,
  `title` VARCHAR(50) COMMENT '职称：主任医师/副主任医师/主治医师',
  `specialty` VARCHAR(200) COMMENT '专业领域',
  `rating` DECIMAL(2,1) DEFAULT 4.5,
  `work_hours` VARCHAR(100) DEFAULT '09:00-18:00' COMMENT '接诊时间',
  `work_days` VARCHAR(50) DEFAULT '1,2,3,4,5' COMMENT '接诊日（1-7周一到周日）',
  `description` TEXT,
  `license_url` VARCHAR(2000) COMMENT '医生执照图片(base64或URL)',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`hospital_id`) REFERENCES `hospital`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========== 4. 宠物表 ==========
CREATE TABLE `pet` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `name` VARCHAR(50) NOT NULL,
  `species` VARCHAR(20) NOT NULL COMMENT 'dog/cat/rabbit/hamster/bird/fish/exotic',
  `breed` VARCHAR(50),
  `age` DECIMAL(4,1),
  `weight` DECIMAL(5,2),
  `gender` VARCHAR(10) COMMENT 'male/female/空',
  `neutered` TINYINT(1) DEFAULT NULL,
  `notes` TEXT,
  `avatar` VARCHAR(500),
  `is_exotic` TINYINT(1) DEFAULT 0,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========== 5. 预约表 ==========
CREATE TABLE `appointment` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `hospital_id` INT NOT NULL,
  `doctor_id` INT,
  `pet_id` INT,
  `pet_name` VARCHAR(50),
  `pet_breed` VARCHAR(50),
  `pet_weight` DECIMAL(5,2),
  `user_name` VARCHAR(50) COMMENT '联系人姓名',
  `appointment_date` DATE NOT NULL,
  `time_slot` VARCHAR(20) NOT NULL COMMENT '如 09:00-09:30',
  `reason` VARCHAR(200) COMMENT '就诊原因',
  `notes` TEXT,
  `contact_phone` VARCHAR(20),
  `status` VARCHAR(20) DEFAULT 'pending' COMMENT 'pending/confirmed/cancelled/completed',
  `hospital_feedback` TEXT,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `user`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`hospital_id`) REFERENCES `hospital`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========== 6. 商家入驻申请表 ==========
CREATE TABLE `merchant_application` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `hospital_name` VARCHAR(100) NOT NULL COMMENT '医院名称',
  `address` VARCHAR(255) NOT NULL,
  `phone` VARCHAR(30) NOT NULL,
  `city` VARCHAR(20) DEFAULT '上海',
  `description` TEXT,
  `license_url` VARCHAR(2000) COMMENT '营业执照图片(base64)',
  `contact_name` VARCHAR(50) COMMENT '联系人',
  `contact_phone` VARCHAR(20) COMMENT '联系电话',
  `username` VARCHAR(50) NOT NULL COMMENT '商家登录账号',
  `password` VARCHAR(255) NOT NULL COMMENT 'bcrypt加密密码',
  `hospital_id` INT DEFAULT NULL COMMENT '自动认证匹配到的医院ID(可空)',
  `auto_matched` TINYINT(1) DEFAULT 0 COMMENT '是否自动认证成功',
  `status` VARCHAR(20) DEFAULT 'pending' COMMENT 'pending/approved/rejected',
  `reject_reason` VARCHAR(500) COMMENT '拒绝原因',
  `reviewer_id` INT COMMENT '审核管理员ID',
  `reviewed_at` DATETIME,
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- 预置数据：上海真实宠物医院
-- ============================================

-- ========== 医院（5家真实连锁品牌） ==========
INSERT INTO `hospital` (`id`,`name`,`address`,`phone`,`city`,`lng`,`lat`,`rating`,`business_hours`,`night_service`,`exotic_accept`,`emergency_support`,`description`,`services`,`verified`) VALUES
(1, '上海宠颐生动物医院(静安店)', '上海市静安区南京西路1788号', '021-62880001', '上海', 121.458000, 31.224000, 4.8, '09:00-21:00', 0, 1, 1, '宠颐生动物医院静安旗舰店，设备先进，资深兽医团队坐诊，提供全方位宠物医疗服务', '疫苗接种,内外科,口腔,影像,住院,异宠诊疗', 1),
(2, '上海安安宠物医院(徐汇店)', '上海市徐汇区漕溪北路100号', '021-64830002', '上海', 121.437000, 31.195000, 4.6, '09:00-20:00', 0, 1, 0, '安安宠物医院徐汇分院，社区便民宠物诊所，服务热情周到', '疫苗接种,常规体检,绝育,美容,异宠诊疗', 1),
(3, '上海芭比堂动物医院(长宁店)', '上海市长宁区延安西路2000号', '021-62310003', '上海', 121.422000, 31.218000, 4.9, '24小时', 1, 0, 1, '芭比堂动物医院，24小时急诊服务，随时为爱宠保驾护航，设备先进', '急诊,外科,内科,ICU,影像,24小时', 1),
(4, '上海瑞鹏宠物医院(浦东店)', '上海市浦东新区张杨路500号', '021-58880004', '上海', 121.524000, 31.230000, 4.7, '09:00-22:00', 1, 1, 0, '瑞鹏宠物医院浦东分院，专注异宠诊疗，夜间急诊服务', '异宠诊疗,疫苗接种,体检,夜间急诊,外科', 1),
(5, '上海萌兽医馆(黄浦店)', '上海市黄浦区人民大道100号', '021-63220005', '上海', 121.474000, 31.231000, 4.5, '08:30-20:30', 0, 0, 0, '萌兽医馆黄浦店，温馨社区宠物诊所，价格亲民', '疫苗接种,常规体检,绝育,美容', 1);

-- ========== 医生（specialty 全部改为宠物类，去掉"牙科"字样） ==========
-- 宠颐生静安店
INSERT INTO `doctor` (`hospital_id`,`name`,`title`,`specialty`,`rating`,`work_hours`,`work_days`,`description`) VALUES
(1, '张明华', '主任医师', '犬猫外科/骨科', 4.9, '09:00-17:00', '1,2,3,4,5', '从业20年，擅长骨科手术和复杂外伤处理'),
(1, '李婷婷', '副主任医师', '犬猫内科/心脏病', 4.8, '13:00-21:00', '1,2,3,4,5,6', '内科专家，擅长心脏病和慢性病管理'),
(1, '王浩', '主治医师', '异宠诊疗', 4.7, '10:00-18:00', '2,3,4,5,6,7', '异宠专科医生，擅长爬行类、鸟类诊疗');

-- 安安徐汇店
INSERT INTO `doctor` (`hospital_id`,`name`,`title`,`specialty`,`rating`,`work_hours`,`work_days`,`description`) VALUES
(2, '陈丽萍', '主治医师', '疫苗保健/体检', 4.6, '09:00-17:00', '1,2,3,4,5', '社区兽医，擅长常规体检和疫苗接种'),
(2, '刘强', '副主任医师', '外科/绝育手术', 4.7, '13:00-20:00', '2,3,4,5,6', '绝育手术专家，手术经验丰富');

-- 芭比堂长宁店
INSERT INTO `doctor` (`hospital_id`,`name`,`title`,`specialty`,`rating`,`work_hours`,`work_days`,`description`) VALUES
(3, '赵雅芝', '主任医师', '急诊/ICU', 5.0, '08:00-20:00', '1,2,3,4,5,6,7', '24小时急诊专家，危重症抢救经验丰富'),
(3, '孙伟', '副主任医师', '外科/软组织', 4.8, '20:00-08:00', '1,2,3,4,5,6,7', '夜间值班医生，擅长夜间急诊手术'),
(3, '周慧', '主治医师', '内科/肾脏病', 4.7, '09:00-17:00', '1,2,3,4,5', '肾脏病专科，慢性病管理专家');

-- 瑞鹏浦东店
INSERT INTO `doctor` (`hospital_id`,`name`,`title`,`specialty`,`rating`,`work_hours`,`work_days`,`description`) VALUES
(4, '吴敏', '主任医师', '异宠诊疗/爬行类', 4.9, '10:00-18:00', '2,3,4,5,6', '异宠诊疗权威，擅长蜥蜴、蛇、龟类'),
(4, '黄涛', '副主任医师', '外科/口腔护理', 4.6, '14:00-22:00', '1,2,3,4,5,6', '夜间值班，擅长口腔护理及外科手术');

-- 萌兽医馆黄浦店
INSERT INTO `doctor` (`hospital_id`,`name`,`title`,`specialty`,`rating`,`work_hours`,`work_days`,`description`) VALUES
(5, '林晓', '主治医师', '疫苗保健/宠物美容', 4.5, '09:00-17:00', '1,2,3,4,5', '社区兽医，擅长基础医疗和宠物美容'),
(5, '郑佳', '主治医师', '内科/老年病', 4.6, '13:00-20:00', '2,3,4,5,6', '老年宠物护理专家');

-- ========== 商家账号（每家医院一个商家账号） ==========
-- 密码统一 123456（bcrypt hash）
-- 123456 的 bcrypt hash（10轮，已验证）: $2a$10$m0Ukp7QOglCZn6y6MKiV6eTV/AlUsktFtmJjDSpgkJLdRoyI4Qjn6
INSERT INTO `user` (`id`,`username`,`password`,`phone`,`email`,`nickname`,`role`,`hospital_id`) VALUES
(1, 'merchant_cys', '$2a$10$m0Ukp7QOglCZn6y6MKiV6eTV/AlUsktFtmJjDSpgkJLdRoyI4Qjn6', '13800000001', 'cys@merchant.com', '宠颐生静安店管理员', 'merchant', 1),
(2, 'merchant_aa', '$2a$10$m0Ukp7QOglCZn6y6MKiV6eTV/AlUsktFtmJjDSpgkJLdRoyI4Qjn6', '13800000002', 'aa@merchant.com', '安安徐汇店管理员', 'merchant', 2),
(3, 'merchant_bbt', '$2a$10$m0Ukp7QOglCZn6y6MKiV6eTV/AlUsktFtmJjDSpgkJLdRoyI4Qjn6', '13800000003', 'bbt@merchant.com', '芭比堂长宁店管理员', 'merchant', 3),
(4, 'merchant_rp', '$2a$10$m0Ukp7QOglCZn6y6MKiV6eTV/AlUsktFtmJjDSpgkJLdRoyI4Qjn6', '13800000004', 'rp@merchant.com', '瑞鹏浦东店管理员', 'merchant', 4),
(5, 'merchant_mn', '$2a$10$m0Ukp7QOglCZn6y6MKiV6eTV/AlUsktFtmJjDSpgkJLdRoyI4Qjn6', '13800000005', 'mn@merchant.com', '萌兽医馆黄浦店管理员', 'merchant', 5);

-- ========== 管理员账号（用于后台审核商家入驻） ==========
INSERT INTO `user` (`id`,`username`,`password`,`phone`,`email`,`nickname`,`role`) VALUES
(7, 'admin', '$2a$10$m0Ukp7QOglCZn6y6MKiV6eTV/AlUsktFtmJjDSpgkJLdRoyI4Qjn6', '13800000000', 'admin@system.com', '系统管理员', 'admin');

-- ========== 测试用户账号 ==========
INSERT INTO `user` (`id`,`username`,`password`,`phone`,`email`,`nickname`,`role`) VALUES
(6, 'demo', '$2a$10$m0Ukp7QOglCZn6y6MKiV6eTV/AlUsktFtmJjDSpgkJLdRoyI4Qjn6', '13900000000', 'demo@user.com', '演示用户', 'user');

-- ========== 测试宠物 ==========
INSERT INTO `pet` (`id`,`user_id`,`name`,`species`,`breed`,`age`,`weight`,`gender`,`neutered`,`notes`) VALUES
(1, 6, '小白', 'cat', '英国短毛猫', 2.0, 4.5, 'male', 1, '健康，定期体检'),
(2, 6, '大黄', 'dog', '金毛', 3.0, 25.0, 'male', 1, '活泼好动');

-- ========== 测试预约 ==========
INSERT INTO `appointment` (`id`,`user_id`,`hospital_id`,`doctor_id`,`pet_id`,`pet_name`,`pet_breed`,`user_name`,`appointment_date`,`time_slot`,`reason`,`notes`,`contact_phone`,`status`) VALUES
(1, 6, 1, 1, 1, '小白', '英国短毛猫', '演示用户', CURDATE(), '14:00-14:30', '疫苗接种', '首次接种', '13900000000', 'pending'),
(2, 6, 3, 7, 2, '大黄', '金毛', '演示用户', DATE_ADD(CURDATE(), INTERVAL 1 DAY), '10:00-10:30', '常规体检', '年度体检', '13900000000', 'confirmed');

-- ============================================
-- 完成提示
-- ============================================
SELECT '数据库初始化完成！' AS message;
SELECT CONCAT('医院数量: ', COUNT(*)) AS info FROM hospital;
SELECT CONCAT('医生数量: ', COUNT(*)) AS info FROM doctor;
SELECT CONCAT('用户数量: ', COUNT(*)) AS info FROM user;
SELECT CONCAT('商家账号: ', COUNT(*)) AS info FROM user WHERE role='merchant';
SELECT CONCAT('管理员账号: ', COUNT(*)) AS info FROM user WHERE role='admin';
