package com.spendora.analytics.dto;

import java.util.List;

public record AiKpiResponse(
        long totalSuggestions,
        long feedbackCount,
        double acceptanceRate,
        double overrideRate,
        double gptFallbackRate,
        List<AiSourceKpiResponse> sourceBreakdown,
        List<AiCategoryPrecisionResponse> categoryPrecision) {
}
