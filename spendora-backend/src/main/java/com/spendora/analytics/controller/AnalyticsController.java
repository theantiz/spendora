package com.spendora.analytics.controller;

import com.spendora.analytics.dto.AiKpiResponse;
import com.spendora.analytics.dto.CategoryBreakdownResponse;
import com.spendora.analytics.dto.SummaryResponse;
import com.spendora.analytics.dto.TopCategoryResponse;
import com.spendora.analytics.service.AnalyticsService;
import com.spendora.common.api.ApiResponse;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/analytics")
public class AnalyticsController {

    private final AnalyticsService analyticsService;

    public AnalyticsController(AnalyticsService analyticsService) {
        this.analyticsService = analyticsService;
    }

    @GetMapping("/summary")
    public ApiResponse<SummaryResponse> summary() {
        return ApiResponse.ok(analyticsService.getSummary());
    }

    @GetMapping("/breakdown")
    public ApiResponse<List<CategoryBreakdownResponse>> breakdown() {
        return ApiResponse.ok(analyticsService.getCategoryBreakdown());
    }

    @GetMapping("/top-categories")
    public ApiResponse<List<TopCategoryResponse>> topCategories() {
        return ApiResponse.ok(analyticsService.getTopCategories());
    }

    @GetMapping("/ai/kpis")
    public ApiResponse<AiKpiResponse> aiKpis() {
        return ApiResponse.ok(analyticsService.getAiKpis());
    }
}
