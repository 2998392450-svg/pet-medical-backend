package com.petclinic.repository;

import com.petclinic.entity.Appointment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDate;
import java.util.List;

@Repository
public interface AppointmentRepository extends JpaRepository<Appointment, Long> {
    List<Appointment> findByUserIdOrderByCreateTimeDesc(Long userId);
    List<Appointment> findByUserIdAndStatusOrderByCreateTimeDesc(Long userId, String status);
    List<Appointment> findByHospitalId(Long hospitalId);
    List<Appointment> findByDateAndHospitalId(LocalDate date, Long hospitalId);
    boolean existsByDateAndTimeSlotAndHospitalIdAndStatusNot(LocalDate date, String timeSlot, Long hospitalId, String status);
}
