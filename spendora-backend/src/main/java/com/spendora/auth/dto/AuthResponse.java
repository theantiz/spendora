package com.spendora.auth.dto;

public record AuthResponse(String token, Long userId, String email) {
}
