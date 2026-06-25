package com.petclinic.service;

import com.petclinic.dto.Result;
import com.petclinic.entity.Hospital;
import com.petclinic.repository.HospitalRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Service
public class HospitalService {
    @Autowired
    private HospitalRepository hospitalRepository;

    public Result<?> getAll() {
        List<Hospital> hospitals = hospitalRepository.findAll();
        return Result.success(hospitals);
    }

    public Result<?> getById(Long id) {
        Hospital hospital = hospitalRepository.findById(id).orElse(null);
        if (hospital == null) {
            return Result.error("医院不存在");
        }
        return Result.success(hospital);
    }

    public Result<?> search(String keyword) {
        List<Hospital> hospitals = hospitalRepository.findAll();
        List<Hospital> result = new ArrayList<>();
        for (Hospital h : hospitals) {
            if (h.getName().contains(keyword) || 
                (h.getAddress() != null && h.getAddress().contains(keyword)) ||
                (h.getDescription() != null && h.getDescription().contains(keyword))) {
                result.add(h);
            }
        }
        return Result.success(result);
    }

    public Result<?> filter(Boolean nightService, Boolean exoticAccept, String sortBy) {
        List<Hospital> hospitals = hospitalRepository.findByFilters(nightService, exoticAccept);
        
        if ("rating".equals(sortBy)) {
            hospitals.sort(Comparator.comparing(Hospital::getRating).reversed());
        } else if ("distance".equals(sortBy)) {
        }
        
        return Result.success(hospitals);
    }

    public Result<?> getWithDistance(Double userLat, Double userLng, Boolean nightService, Boolean exoticAccept, String sortBy) {
        List<Hospital> hospitals = hospitalRepository.findByFilters(nightService, exoticAccept);
        
        for (Hospital h : hospitals) {
            double distance = calculateDistance(userLat, userLng, h.getLatitude(), h.getLongitude());
            h.setServices(String.valueOf(distance));
        }
        
        if ("distance".equals(sortBy)) {
            hospitals.sort(Comparator.comparingDouble(h -> {
                return calculateDistance(userLat, userLng, h.getLatitude(), h.getLongitude());
            }));
        } else if ("rating".equals(sortBy)) {
            hospitals.sort(Comparator.comparing(Hospital::getRating).reversed());
        }
        
        return Result.success(hospitals);
    }

    private double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
        // 基本类型 double 不能与 null 比较;0/0 视为坐标缺失
        if (lat1 == 0 || lng1 == 0 || lat2 == 0 || lng2 == 0) {
            return Double.MAX_VALUE;
        }
        final int R = 6371;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                   Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                   Math.sin(dLng/2) * Math.sin(dLng/2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        return R * c;
    }
}
