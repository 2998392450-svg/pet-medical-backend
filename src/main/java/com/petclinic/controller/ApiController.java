package com.petclinic.controller;

import com.petclinic.dto.*;
import com.petclinic.entity.*;
import com.petclinic.service.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class ApiController {

    @Autowired private UserService userService;
    @Autowired private HospitalService hospitalService;
    @Autowired private DoctorService doctorService;
    @Autowired private PetService petService;
    @Autowired private AppointmentService appointmentService;
    @Autowired private FavoriteService favoriteService;
    @Autowired private com.petclinic.repository.VerificationCodeRepository verificationCodeRepository;

    @PostMapping("/register")
    public Result<?> register(@RequestBody User user) {
        return userService.register(user);
    }

    @PostMapping("/register/phone")
    public Result<?> registerWithPhone(@RequestBody RegisterDto dto) {
        return userService.registerWithPhone(dto);
    }

    /**
     * 发送短信验证码(开发环境:不接真实短信网关,直接把验证码返回给前端)
     * POST /api/sms/send  body: { phone, type }
     */
    @PostMapping("/sms/send")
    public Result<?> sendSmsCode(@RequestBody Map<String, String> body) {
        String phone = body.get("phone");
        String type = body.getOrDefault("type", "register");
        if (phone == null || !phone.matches("^1[3-9]\\d{9}$")) {
            return Result.error("手机号格式错误");
        }
        // 生成 6 位随机码
        String code = String.format("%06d", new java.util.Random().nextInt(1000000));
        com.petclinic.entity.VerificationCode vc = new com.petclinic.entity.VerificationCode();
        vc.setPhone(phone);
        vc.setCode(code);
        vc.setType(type);
        vc.setExpireTime(java.time.LocalDateTime.now().plusMinutes(5));
        vc.setUsed(false);
        verificationCodeRepository.save(vc);
        // 开发环境:把 code 放在 data 里返回(生产环境应该发短信,不返回)
        java.util.Map<String, String> data = new java.util.HashMap<>();
        data.put("code", code);
        data.put("expireMinutes", "5");
        return Result.success(data);
    }

    @PostMapping("/login")
    public Result<?> login(@RequestBody LoginDto dto) {
        return userService.login(dto);
    }

    @PostMapping("/login/phone")
    public Result<?> loginWithPhone(@RequestBody LoginDto dto) {
        return userService.loginWithPhone(dto);
    }

    @GetMapping("/user/{id}")
    public Result<?> getUser(@PathVariable Long id) {
        return userService.getUserById(id);
    }

    @PutMapping("/user/{id}")
    public Result<?> updateUser(@PathVariable Long id, @RequestBody User user) {
        return userService.updateUser(id, user);
    }

    @PostMapping("/user/{id}/password")
    public Result<?> changePassword(@PathVariable Long id, @RequestBody Map<String, String> body) {
        return userService.changePassword(id, body.get("oldPassword"), body.get("newPassword"));
    }

    @GetMapping("/hospitals")
    public Result<?> getHospitals(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Boolean nightService,
            @RequestParam(required = false) Boolean exoticAccept,
            @RequestParam(defaultValue = "rating") String sortBy,
            @RequestParam(required = false) Double lat,
            @RequestParam(required = false) Double lng) {
        if (keyword != null && !keyword.isEmpty()) {
            return hospitalService.search(keyword);
        }
        if (lat != null && lng != null) {
            return hospitalService.getWithDistance(lat, lng, nightService, exoticAccept, sortBy);
        }
        return hospitalService.filter(nightService, exoticAccept, sortBy);
    }

    @GetMapping("/hospitals/{id}")
    public Result<?> getHospital(@PathVariable Long id) {
        return hospitalService.getById(id);
    }

    @GetMapping("/hospitals/{id}/doctors")
    public Result<?> getHospitalDoctors(@PathVariable Long id) {
        return doctorService.getByHospitalId(id);
    }

    @GetMapping("/doctors/{id}")
    public Result<?> getDoctor(@PathVariable Long id) {
        return doctorService.getById(id);
    }

    @GetMapping("/pets")
    public Result<?> getPets(@RequestParam Long userId) {
        return petService.getByUserId(userId);
    }

    @GetMapping("/pets/{id}")
    public Result<?> getPet(@PathVariable Long id) {
        return petService.getById(id);
    }

    @PostMapping("/pets")
    public Result<?> addPet(@RequestBody Pet pet) {
        return petService.add(pet);
    }

    @PutMapping("/pets/{id}")
    public Result<?> updatePet(@PathVariable Long id, @RequestBody Pet pet) {
        return petService.update(id, pet);
    }

    @DeleteMapping("/pets/{id}")
    public Result<?> deletePet(@PathVariable Long id, @RequestParam Long userId) {
        return petService.delete(id, userId);
    }

    @GetMapping("/appointments")
    public Result<?> getAppointments(
            @RequestParam Long userId,
            @RequestParam(required = false) String status) {
        if (status != null && !status.isEmpty()) {
            return appointmentService.getByUserIdAndStatus(userId, status);
        }
        return appointmentService.getByUserId(userId);
    }

    @GetMapping("/appointments/{id}")
    public Result<?> getAppointment(@PathVariable Long id) {
        return appointmentService.getById(id);
    }

    @PostMapping("/appointments")
    public Result<?> createAppointment(@RequestBody AppointmentCreateDto dto) {
        return appointmentService.create(dto);
    }

    @DeleteMapping("/appointments/{id}")
    public Result<?> cancelAppointment(@PathVariable Long id, @RequestParam Long userId) {
        return appointmentService.cancel(id, userId);
    }

    @GetMapping("/appointments/time-slots")
    public Result<?> getAvailableTimeSlots(
            @RequestParam Long hospitalId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return appointmentService.getAvailableTimeSlots(hospitalId, date);
    }

    @PostMapping("/favorites")
    public Result<?> addFavorite(@RequestBody Map<String, Object> body) {
        Long userId = ((Number) body.get("userId")).longValue();
        String targetType = (String) body.get("targetType");
        Long targetId = ((Number) body.get("targetId")).longValue();
        return favoriteService.add(userId, targetType, targetId);
    }

    @DeleteMapping("/favorites")
    public Result<?> removeFavorite(
            @RequestParam Long userId,
            @RequestParam String targetType,
            @RequestParam Long targetId) {
        return favoriteService.remove(userId, targetType, targetId);
    }

    @GetMapping("/favorites")
    public Result<?> getFavorites(@RequestParam Long userId, @RequestParam String targetType) {
        return favoriteService.getByUserIdAndType(userId, targetType);
    }

    @GetMapping("/favorites/check")
    public Result<?> checkFavorite(
            @RequestParam Long userId,
            @RequestParam String targetType,
            @RequestParam Long targetId) {
        return favoriteService.check(userId, targetType, targetId);
    }
}
