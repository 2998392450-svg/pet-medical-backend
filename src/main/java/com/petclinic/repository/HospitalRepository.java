package com.petclinic.repository;

import com.petclinic.entity.Hospital;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface HospitalRepository extends JpaRepository<Hospital, Long> {
    List<Hospital> findByNightServiceTrue();
    List<Hospital> findByExoticAcceptTrue();
    List<Hospital> findByNightServiceAndExoticAccept(Boolean nightService, Boolean exoticAccept);
    List<Hospital> findAllByOrderByRatingDesc();
    
    @Query("SELECT h FROM Hospital h WHERE (:nightService IS NULL OR h.nightService = :nightService) " +
           "AND (:exoticAccept IS NULL OR h.exoticAccept = :exoticAccept)")
    List<Hospital> findByFilters(@Param("nightService") Boolean nightService, @Param("exoticAccept") Boolean exoticAccept);
}
