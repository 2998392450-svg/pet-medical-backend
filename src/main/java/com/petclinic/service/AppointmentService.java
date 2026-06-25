package com.petclinic.service;

import com.petclinic.dto.AppointmentCreateDto;
import com.petclinic.dto.Result;
import com.petclinic.entity.Appointment;
import com.petclinic.entity.Hospital;
import com.petclinic.entity.Pet;
import com.petclinic.repository.AppointmentRepository;
import com.petclinic.repository.HospitalRepository;
import com.petclinic.repository.PetRepository;
import com.petclinic.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Service
public class AppointmentService {
    @Autowired
    private AppointmentRepository appointmentRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PetRepository petRepository;

    @Autowired
    private HospitalRepository hospitalRepository;

    @Transactional
    public Result<?> create(AppointmentCreateDto dto) {
        if (!userRepository.existsById(dto.getUserId())) {
            return Result.error("用户不存在");
        }

        Pet pet = petRepository.findById(dto.getPetId()).orElse(null);
        if (pet == null) {
            return Result.error("宠物不存在");
        }
        if (!pet.getUserId().equals(dto.getUserId())) {
            return Result.error("宠物不属于该用户");
        }

        Hospital hospital = hospitalRepository.findById(dto.getHospitalId()).orElse(null);
        if (hospital == null) {
            return Result.error("医院不存在");
        }

        boolean isOccupied = appointmentRepository.existsByDateAndTimeSlotAndHospitalIdAndStatusNot(
            dto.getDate(), dto.getTimeSlot(), dto.getHospitalId(), "cancelled");
        if (isOccupied) {
            return Result.error("该时段已被预约");
        }

        Appointment appointment = new Appointment();
        appointment.setUserId(dto.getUserId());
        appointment.setPetId(dto.getPetId());
        appointment.setHospitalId(dto.getHospitalId());
        appointment.setDoctorId(dto.getDoctorId());
        appointment.setDate(dto.getDate());
        appointment.setTimeSlot(dto.getTimeSlot());
        appointment.setReason(dto.getReason());
        appointment.setRemark(dto.getRemark());
        appointment.setStatus("pending");

        Appointment saved = appointmentRepository.save(appointment);
        return Result.success("预约成功", saved);
    }

    public Result<?> getByUserId(Long userId) {
        List<Appointment> appointments = appointmentRepository.findByUserIdOrderByCreateTimeDesc(userId);
        return Result.success(appointments);
    }

    public Result<?> getByUserIdAndStatus(Long userId, String status) {
        List<Appointment> appointments = appointmentRepository.findByUserIdAndStatusOrderByCreateTimeDesc(userId, status);
        return Result.success(appointments);
    }

    public Result<?> getById(Long id) {
        Appointment appointment = appointmentRepository.findById(id).orElse(null);
        if (appointment == null) {
            return Result.error("预约不存在");
        }
        return Result.success(appointment);
    }

    @Transactional
    public Result<?> cancel(Long id, Long userId) {
        Appointment appointment = appointmentRepository.findById(id).orElse(null);
        if (appointment == null) {
            return Result.error("预约不存在");
        }
        if (!appointment.getUserId().equals(userId)) {
            return Result.error("无权取消该预约");
        }
        if (!"pending".equals(appointment.getStatus()) && !"confirmed".equals(appointment.getStatus())) {
            return Result.error("只能取消待处理或已确认的预约");
        }
        appointment.setStatus("cancelled");
        appointmentRepository.save(appointment);
        return Result.success("取消成功");
    }

    public Result<?> getAvailableTimeSlots(Long hospitalId, LocalDate date) {
        Hospital hospital = hospitalRepository.findById(hospitalId).orElse(null);
        if (hospital == null) {
            return Result.error("医院不存在");
        }

        List<String> allSlots = generateTimeSlots(hospital.getNightService());
        List<Appointment> booked = appointmentRepository.findByDateAndHospitalId(date, hospitalId);
        
        List<String> bookedSlots = new ArrayList<>();
        for (Appointment a : booked) {
            if (!"cancelled".equals(a.getStatus())) {
                bookedSlots.add(a.getTimeSlot());
            }
        }

        allSlots.removeAll(bookedSlots);
        return Result.success(allSlots);
    }

    private List<String> generateTimeSlots(Boolean nightService) {
        List<String> slots = new ArrayList<>();
        
        if (nightService) {
            for (int hour = 8; hour < 24; hour++) {
                slots.add(String.format("%02d:00-%02d:30", hour, hour));
                slots.add(String.format("%02d:30-%02d:00", hour, hour + 1));
            }
            for (int hour = 0; hour < 8; hour++) {
                slots.add(String.format("%02d:00-%02d:30", hour, hour));
                slots.add(String.format("%02d:30-%02d:00", hour, hour + 1));
            }
        } else {
            for (int hour = 8; hour < 22; hour++) {
                slots.add(String.format("%02d:00-%02d:30", hour, hour));
                slots.add(String.format("%02d:30-%02d:00", hour, hour + 1));
            }
        }
        
        return slots;
    }
}
