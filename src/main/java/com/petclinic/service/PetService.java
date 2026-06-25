package com.petclinic.service;

import com.petclinic.dto.Result;
import com.petclinic.entity.Pet;
import com.petclinic.repository.PetRepository;
import com.petclinic.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
public class PetService {
    @Autowired
    private PetRepository petRepository;

    @Autowired
    private UserRepository userRepository;

    public Result<?> add(Pet pet) {
        if (!userRepository.existsById(pet.getUserId())) {
            return Result.error("用户不存在");
        }
        Pet saved = petRepository.save(pet);
        return Result.success("添加成功", saved);
    }

    public Result<?> update(Long id, Pet pet) {
        Pet existing = petRepository.findById(id).orElse(null);
        if (existing == null) {
            return Result.error("宠物不存在");
        }
        if (!existing.getUserId().equals(pet.getUserId())) {
            return Result.error("无权修改该宠物信息");
        }
        existing.setName(pet.getName() != null ? pet.getName() : existing.getName());
        existing.setBreed(pet.getBreed() != null ? pet.getBreed() : existing.getBreed());
        existing.setIsExotic(pet.getIsExotic() != null ? pet.getIsExotic() : existing.getIsExotic());
        existing.setGender(pet.getGender() != null ? pet.getGender() : existing.getGender());
        existing.setBirthday(pet.getBirthday() != null ? pet.getBirthday() : existing.getBirthday());
        existing.setWeight(pet.getWeight() != null ? pet.getWeight() : existing.getWeight());
        existing.setBloodType(pet.getBloodType() != null ? pet.getBloodType() : existing.getBloodType());
        existing.setAllergyHistory(pet.getAllergyHistory() != null ? pet.getAllergyHistory() : existing.getAllergyHistory());
        existing.setPhotoUrl(pet.getPhotoUrl() != null ? pet.getPhotoUrl() : existing.getPhotoUrl());
        existing.setIsPinned(pet.getIsPinned() != null ? pet.getIsPinned() : existing.getIsPinned());
        Pet saved = petRepository.save(existing);
        return Result.success("更新成功", saved);
    }

    public Result<?> delete(Long id, Long userId) {
        Pet pet = petRepository.findById(id).orElse(null);
        if (pet == null) {
            return Result.error("宠物不存在");
        }
        if (!pet.getUserId().equals(userId)) {
            return Result.error("无权删除该宠物");
        }
        petRepository.delete(pet);
        return Result.success("删除成功");
    }

    public Result<?> getById(Long id) {
        Pet pet = petRepository.findById(id).orElse(null);
        if (pet == null) {
            return Result.error("宠物不存在");
        }
        return Result.success(pet);
    }

    public Result<?> getByUserId(Long userId) {
        List<Pet> pets = petRepository.findByUserIdOrderByIsPinnedDescCreateTimeDesc(userId);
        return Result.success(pets);
    }
}
