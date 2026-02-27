package com.spendora.ai.dto;

public record AiFeedbackRequest(
        Long suggestionId,
        Long userId,
        String finalCategory) {
}
