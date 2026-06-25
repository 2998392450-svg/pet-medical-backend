package com.petclinic;

import com.petclinic.entity.Hospital;
import com.petclinic.entity.Doctor;
import com.petclinic.entity.User;
import com.petclinic.repository.HospitalRepository;
import com.petclinic.repository.DoctorRepository;
import com.petclinic.repository.UserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

@SpringBootApplication
public class PetClinicApplication {
    public static void main(String[] args) {
        SpringApplication.run(PetClinicApplication.class, args);
    }

    /**
     * 启动时用 Java 字符串注入测试数据(绕开 schema-h2.sql 的编码问题,保证中文正确)
     */
    @Bean
    public CommandLineRunner initData(HospitalRepository hospitalRepo, DoctorRepository doctorRepo, UserRepository userRepo) {
        return args -> {
            // 只在表为空时才插入(避免 H2 重启时重复)
            if (hospitalRepo.count() > 0) return;

            // 默认管理员 admin / 123456 (BCrypt 哈希对应密码 123456)
            if (userRepo.count() == 0) {
                User admin = new User();
                admin.setUsername("admin");
                admin.setPassword(new BCryptPasswordEncoder().encode("123456"));
                admin.setNickname("管理员");
                admin.setPhone("13800138000");
                userRepo.save(admin);
            }

            Hospital h1 = new Hospital();
            h1.setName("阳光宠物医院");
            h1.setAddress("北京市朝阳区建国路88号");
            h1.setPhone("010-12345678");
            h1.setDescription("专业宠物医疗服务机构，提供全方位诊疗");
            h1.setBusinessHours("08:00-22:00");
            h1.setNightService(false);
            h1.setExoticAccept(false);
            h1.setEmergencySupport(true);
            h1.setRating(4.8);
            h1.setLatitude(39.9042);
            h1.setLongitude(116.4074);
            hospitalRepo.save(h1);

            Hospital h2 = new Hospital();
            h2.setName("爱心宠物诊所");
            h2.setAddress("北京市海淀区中关村大街1号");
            h2.setPhone("010-87654321");
            h2.setDescription("温馨舒适的诊疗环境，关爱每一只宠物");
            h2.setBusinessHours("08:00-22:00");
            h2.setNightService(true);
            h2.setExoticAccept(true);
            h2.setEmergencySupport(true);
            h2.setRating(4.6);
            h2.setLatitude(39.9842);
            h2.setLongitude(116.3074);
            hospitalRepo.save(h2);

            Hospital h3 = new Hospital();
            h3.setName("康宠动物医院");
            h3.setAddress("北京市西城区西直门外大街12号");
            h3.setPhone("010-23456789");
            h3.setDescription("24小时营业，急诊服务随时待命");
            h3.setBusinessHours("08:00-次日08:00");
            h3.setNightService(true);
            h3.setExoticAccept(false);
            h3.setEmergencySupport(true);
            h3.setRating(4.9);
            h3.setLatitude(39.9342);
            h3.setLongitude(116.3674);
            hospitalRepo.save(h3);

            Hospital h4 = new Hospital();
            h4.setName("萌宠乐园");
            h4.setAddress("北京市东城区王府井大街25号");
            h4.setPhone("010-34567890");
            h4.setDescription("专注小动物护理，提供优质服务");
            h4.setBusinessHours("08:00-22:00");
            h4.setNightService(false);
            h4.setExoticAccept(true);
            h4.setEmergencySupport(false);
            h4.setRating(4.5);
            h4.setLatitude(39.9142);
            h4.setLongitude(116.4174);
            hospitalRepo.save(h4);

            // 医生
            Doctor d1 = new Doctor();
            d1.setHospitalId(1L);
            d1.setName("张医生");
            d1.setTitle("主任医师");
            d1.setSpecialty("犬猫内科");
            d1.setLicenseNumber("DC123456");
            d1.setExperienceYears(15);
            d1.setRating(4.9);
            d1.setDescription("擅长犬猫内科疾病诊治，经验丰富");
            doctorRepo.save(d1);

            Doctor d2 = new Doctor();
            d2.setHospitalId(1L);
            d2.setName("李医生");
            d2.setTitle("副主任医师");
            d2.setSpecialty("外科手术");
            d2.setLicenseNumber("DC654321");
            d2.setExperienceYears(12);
            d2.setRating(4.8);
            d2.setDescription("精通各类宠物外科手术");
            doctorRepo.save(d2);

            Doctor d3 = new Doctor();
            d3.setHospitalId(2L);
            d3.setName("王医生");
            d3.setTitle("主治医师");
            d3.setSpecialty("异宠专科");
            d3.setLicenseNumber("DC112233");
            d3.setExperienceYears(8);
            d3.setRating(4.7);
            d3.setDescription("专注爬行动物、鸟类等异宠诊疗");
            doctorRepo.save(d3);

            Doctor d4 = new Doctor();
            d4.setHospitalId(3L);
            d4.setName("赵医生");
            d4.setTitle("主任医师");
            d4.setSpecialty("急诊医学");
            d4.setLicenseNumber("DC445566");
            d4.setExperienceYears(20);
            d4.setRating(4.9);
            d4.setDescription("24小时急诊值班，处理各类紧急情况");
            doctorRepo.save(d4);

            Doctor d5 = new Doctor();
            d5.setHospitalId(4L);
            d5.setName("孙医生");
            d5.setTitle("主治医师");
            d5.setSpecialty("小动物保健");
            d5.setLicenseNumber("DC778899");
            d5.setExperienceYears(6);
            d5.setRating(4.6);
            d5.setDescription("宠物营养与日常保健专家");
            doctorRepo.save(d5);

            System.out.println("[InitData] 已注入 4 家医院 + 5 位医生");
        };
    }
}