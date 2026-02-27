package com.spendora.ai.service;

import com.spendora.ai.dto.AiFeedbackRequest;
import com.spendora.ai.dto.AiFeedbackResponse;
import com.spendora.ai.dto.InsightsResponse;
import com.spendora.ai.dto.SuggestCategoryRequest;
import com.spendora.ai.dto.SuggestCategoryResponse;
import com.spendora.ai.dto.TrainingDataResponse;

public interface AiService {

    SuggestCategoryResponse suggestCategory(SuggestCategoryRequest request);

    AiFeedbackResponse submitFeedback(AiFeedbackRequest request);

    InsightsResponse insights();

    TrainingDataResponse trainingData();
}
