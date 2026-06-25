package com.petclinic.repository;

import com.petclinic.entity.Pet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface PetRepository extends JpaRepository<Pet, Long> {
    List<Pet> findByUserIdOrderByIsPinnedDescCreateTimeDesc(Long userId);
    List<Pet> findByUserIdAndIsExotic(Long userId, Boolean isExotic);
}
