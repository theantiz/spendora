package com.spendora.ai.dto;

public record AiFeedbackResponse(
        Long suggestionId,
        String finalCategory,
        boolean overridden) {
}
