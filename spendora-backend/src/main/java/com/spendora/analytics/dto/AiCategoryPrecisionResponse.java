package com.spendora.analytics.dto;

public record AiCategoryPrecisionResponse(String category, long validatedCount, long acceptedCount, double precision) {
}
