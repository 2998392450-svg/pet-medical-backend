package com.petclinic.repository;

import com.petclinic.entity.VerificationCode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface VerificationCodeRepository extends JpaRepository<VerificationCode, Long> {
    
    Optional<VerificationCode> findByPhoneAndCodeAndTypeAndUsedFalse(
        String phone, String code, String type);
    
    Optional<VerificationCode> findTopByPhoneAndTypeAndUsedFalseOrderByCreateTimeDesc(
        String phone, String type);
    
    void deleteByExpireTimeBefore(LocalDateTime time);
}