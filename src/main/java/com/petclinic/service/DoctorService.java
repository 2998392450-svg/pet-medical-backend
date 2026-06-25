package com.petclinic.service;

import com.petclinic.dto.Result;
import com.petclinic.entity.Doctor;
import com.petclinic.repository.DoctorRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class DoctorService {
    @Autowired
    private DoctorRepository doctorRepository;

    public Result<?> getByHospitalId(Long hospitalId) {
        List<Doctor> doctors = doctorRepository.findByHospitalIdOrderByRatingDesc(hospitalId);
        return Result.success(doctors);
    }

    public Result<?> getById(Long id) {
        Doctor doctor = doctorRepository.findById(id).orElse(null);
        if (doctor == null) {
            return Result.error("医生不存在");
        }
        return Result.success(doctor);
    }
}
