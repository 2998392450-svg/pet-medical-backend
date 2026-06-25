package com.petclinic.service;

import com.auth0.jwt.JWT;
import com.auth0.jwt.algorithms.Algorithm;
import com.petclinic.dto.LoginDto;
import com.petclinic.dto.RegisterDto;
import com.petclinic.dto.Result;
import com.petclinic.entity.User;
import com.petclinic.repository.UserRepository;
import com.petclinic.repository.VerificationCodeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

@Service
public class UserService {
    @Autowired
    private UserRepository userRepository;

    @Autowired
    private VerificationCodeRepository verificationCodeRepository;

    @Value("${jwt.secret}")
    private String jwtSecret;

    @Value("${jwt.expiration}")
    private Long jwtExpiration;

    private BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    public Result<?> register(User user) {
        if (userRepository.existsByUsername(user.getUsername())) {
            return Result.error("用户名已存在");
        }
        if (user.getPhone() != null && userRepository.existsByPhone(user.getPhone())) {
            return Result.error("手机号已注册");
        }
        user.setPassword(passwordEncoder.encode(user.getPassword()));
        User savedUser = userRepository.save(user);
        savedUser.setPassword(null);
        return Result.success("注册成功", savedUser);
    }

    public Result<?> registerWithPhone(RegisterDto dto) {
        if (dto.getPhone() == null) {
            return Result.error("手机号不能为空");
        }
        // 校验验证码(开发环境:不校验,生产环境要打开)
        if (dto.getCode() != null && !dto.getCode().isEmpty()) {
            var codeOpt = verificationCodeRepository
                .findByPhoneAndCodeAndTypeAndUsedFalse(dto.getPhone(), dto.getCode(), "register");
            if (codeOpt.isEmpty()) {
                return Result.error("验证码错误或已使用");
            }
            var vc = codeOpt.get();
            if (vc.getExpireTime().isBefore(java.time.LocalDateTime.now())) {
                return Result.error("验证码已过期");
            }
            vc.setUsed(true);
            verificationCodeRepository.save(vc);
        }
        if (userRepository.existsByPhone(dto.getPhone())) {
            return Result.error("手机号已注册");
        }
        User user = new User();
        user.setPhone(dto.getPhone());
        user.setUsername(dto.getUsername() != null ? dto.getUsername() : "user_" + dto.getPhone().substring(7));
        user.setPassword(passwordEncoder.encode(dto.getPassword() != null ? dto.getPassword() : "123456"));
        user.setNickname(dto.getNickname());
        user.setEmail(dto.getEmail());
        User savedUser = userRepository.save(user);
        savedUser.setPassword(null);
        return Result.success("注册成功", savedUser);
    }

    public Result<?> login(LoginDto dto) {
        User user = userRepository.findByUsername(dto.getUsername()).orElse(null);
        if (user == null) {
            user = userRepository.findByPhone(dto.getUsername()).orElse(null);
        }
        if (user == null || !passwordEncoder.matches(dto.getPassword(), user.getPassword())) {
            return Result.error("用户名或密码错误");
        }
        String token = generateToken(user);
        Map<String, Object> data = new HashMap<>();
        data.put("token", token);
        user.setPassword(null);
        data.put("user", user);
        return Result.success("登录成功", data);
    }

    public Result<?> loginWithPhone(LoginDto dto) {
        User user = userRepository.findByPhone(dto.getPhone()).orElse(null);
        if (user == null) {
            return Result.error("用户不存在");
        }
        String token = generateToken(user);
        Map<String, Object> data = new HashMap<>();
        data.put("token", token);
        user.setPassword(null);
        data.put("user", user);
        return Result.success("登录成功", data);
    }

    public Result<?> getUserById(Long id) {
        User user = userRepository.findById(id).orElse(null);
        if (user == null) {
            return Result.error("用户不存在");
        }
        user.setPassword(null);
        return Result.success(user);
    }

    public Result<?> updateUser(Long id, User user) {
        User existing = userRepository.findById(id).orElse(null);
        if (existing == null) {
            return Result.error("用户不存在");
        }
        if (user.getNickname() != null) existing.setNickname(user.getNickname());
        if (user.getEmail() != null) existing.setEmail(user.getEmail());
        if (user.getAvatar() != null) existing.setAvatar(user.getAvatar());
        if (user.getPhone() != null && !user.getPhone().equals(existing.getPhone())) {
            if (userRepository.existsByPhone(user.getPhone())) {
                return Result.error("手机号已被使用");
            }
            existing.setPhone(user.getPhone());
        }
        User saved = userRepository.save(existing);
        saved.setPassword(null);
        return Result.success("更新成功", saved);
    }

    public Result<?> changePassword(Long id, String oldPassword, String newPassword) {
        User user = userRepository.findById(id).orElse(null);
        if (user == null) {
            return Result.error("用户不存在");
        }
        if (!passwordEncoder.matches(oldPassword, user.getPassword())) {
            return Result.error("原密码错误");
        }
        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);
        return Result.success("密码修改成功");
    }

    private String generateToken(User user) {
        return JWT.create()
                .withSubject(user.getId().toString())
                .withExpiresAt(new Date(System.currentTimeMillis() + jwtExpiration))
                .sign(Algorithm.HMAC256(jwtSecret));
    }
}
