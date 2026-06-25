package com.petclinic.service;

import com.petclinic.dto.Result;
import com.petclinic.entity.Favorite;
import com.petclinic.repository.FavoriteRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
public class FavoriteService {
    @Autowired
    private FavoriteRepository favoriteRepository;

    @Transactional
    public Result<?> add(Long userId, String targetType, Long targetId) {
        if (favoriteRepository.existsByUserIdAndTargetTypeAndTargetId(userId, targetType, targetId)) {
            return Result.error("已收藏");
        }
        Favorite favorite = new Favorite();
        favorite.setUserId(userId);
        favorite.setTargetType(targetType);
        favorite.setTargetId(targetId);
        favoriteRepository.save(favorite);
        return Result.success("收藏成功");
    }

    @Transactional
    public Result<?> remove(Long userId, String targetType, Long targetId) {
        if (!favoriteRepository.existsByUserIdAndTargetTypeAndTargetId(userId, targetType, targetId)) {
            return Result.error("未收藏");
        }
        favoriteRepository.deleteByUserIdAndTargetTypeAndTargetId(userId, targetType, targetId);
        return Result.success("取消收藏");
    }

    public Result<?> getByUserIdAndType(Long userId, String targetType) {
        List<Favorite> favorites = favoriteRepository.findByUserIdAndTargetType(userId, targetType);
        return Result.success(favorites);
    }

    public Result<?> check(Long userId, String targetType, Long targetId) {
        boolean exists = favoriteRepository.existsByUserIdAndTargetTypeAndTargetId(userId, targetType, targetId);
        return Result.success(exists);
    }
}
