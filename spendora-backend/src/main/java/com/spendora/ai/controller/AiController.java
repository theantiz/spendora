package com.spendora.ai.controller;

import com.spendora.ai.dto.AiFeedbackRequest;
import com.spendora.ai.dto.AiFeedbackResponse;
import com.spendora.ai.dto.InsightsResponse;
import com.spendora.ai.dto.SuggestCategoryRequest;
import com.spendora.ai.dto.SuggestCategoryResponse;
import com.spendora.ai.dto.TrainingDataResponse;
import com.spendora.ai.service.AiService;
import com.spendora.common.api.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/ai")
public class AiController {

    private final AiService aiService;

    public AiController(AiService aiService) {
        this.aiService = aiService;
    }

    @PostMapping("/suggest-category")
    public ApiResponse<SuggestCategoryResponse> suggestCategory(@RequestBody SuggestCategoryRequest request) {
        return ApiResponse.ok(aiService.suggestCategory(request));
    }

    @PostMapping("/feedback")
    public ApiResponse<AiFeedbackResponse> feedback(@RequestBody AiFeedbackRequest request) {
        return ApiResponse.ok(aiService.submitFeedback(request));
    }

    @GetMapping("/insights")
    public ApiResponse<InsightsResponse> insights() {
        return ApiResponse.ok(aiService.insights());
    }

    @GetMapping("/training-data")
    public ApiResponse<TrainingDataResponse> trainingData() {
        return ApiResponse.ok(aiService.trainingData());
    }
}
