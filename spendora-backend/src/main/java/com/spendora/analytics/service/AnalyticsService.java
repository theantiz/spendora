package com.spendora.analytics.service;

import com.spendora.analytics.dto.AiCategoryPrecisionResponse;
import com.spendora.analytics.dto.AiKpiResponse;
import com.spendora.analytics.dto.AiSourceKpiResponse;
import com.spendora.analytics.dto.CategoryBreakdownResponse;
import com.spendora.analytics.dto.SummaryResponse;
import com.spendora.analytics.dto.TopCategoryResponse;
import com.spendora.analytics.repository.AnalyticsRepository;
import java.math.BigDecimal;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class AnalyticsService {

    private final AnalyticsRepository analyticsRepository;

    public AnalyticsService(AnalyticsRepository analyticsRepository) {
        this.analyticsRepository = analyticsRepository;
    }

    public SummaryResponse getSummary() {
        return new SummaryResponse(BigDecimal.ZERO, 0L);
    }

    public List<CategoryBreakdownResponse> getCategoryBreakdown() {
        return List.of();
    }

    public List<TopCategoryResponse> getTopCategories() {
        return List.of();
    }

    public AiKpiResponse getAiKpis() {
        long total = analyticsRepository.countSuggestions();
        long feedback = analyticsRepository.countFeedback();
        long accepted = analyticsRepository.countAccepted();
        long overridden = analyticsRepository.countOverridden();
        long gpt = analyticsRepository.countGpt();

        double acceptanceRate = ratio(accepted, feedback);
        double overrideRate = ratio(overridden, feedback);
        double gptFallbackRate = ratio(gpt, total);

        List<AiSourceKpiResponse> sourceBreakdown = analyticsRepository.countBySource().stream()
                .map(row -> new AiSourceKpiResponse(
                        asString(row[0]),
                        asLong(row[1]),
                        ratio(asLong(row[1]), total)))
                .toList();

        List<AiCategoryPrecisionResponse> categoryPrecision = analyticsRepository.categoryPrecision().stream()
                .map(row -> {
                    long validated = asLong(row[1]);
                    long acceptedInCategory = asLong(row[2]);
                    return new AiCategoryPrecisionResponse(
                            asString(row[0]),
                            validated,
                            acceptedInCategory,
                            ratio(acceptedInCategory, validated));
                })
                .toList();

        return new AiKpiResponse(
                total,
                feedback,
                acceptanceRate,
                overrideRate,
                gptFallbackRate,
                sourceBreakdown,
                categoryPrecision);
    }

    private long asLong(Object value) {
        return value == null ? 0L : ((Number) value).longValue();
    }

    private String asString(Object value) {
        return value == null ? "UNKNOWN" : value.toString();
    }

    private double ratio(long numerator, long denominator) {
        if (denominator == 0L) {
            return 0.0;
        }
        return (double) numerator / denominator;
    }
}
