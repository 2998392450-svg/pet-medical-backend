package com.petclinic.dto;

import lombok.Data;

@Data
public class JwtResponseDto {
    private String token;
    private Long userId;
    private String username;
    private String nickname;
    private String avatar;
    private Long expiresIn;
}