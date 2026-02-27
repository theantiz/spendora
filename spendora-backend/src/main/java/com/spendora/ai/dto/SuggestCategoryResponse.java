package com.spendora.ai.dto;

public record SuggestCategoryResponse(
        Long suggestionId,
        String category,
        double confidence,
        String source) {
}
