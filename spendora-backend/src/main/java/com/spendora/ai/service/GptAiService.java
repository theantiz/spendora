package com.spendora.ai.service;

import com.spendora.ai.client.GptClient;
import com.spendora.ai.dto.AiFeedbackRequest;
import com.spendora.ai.dto.AiFeedbackResponse;
import com.spendora.ai.dto.InsightsResponse;
import com.spendora.ai.dto.SuggestCategoryRequest;
import com.spendora.ai.dto.SuggestCategoryResponse;
import com.spendora.ai.dto.TrainingDataResponse;
import java.util.Arrays;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class GptAiService implements AiService {

    private final GptClient gptClient;

    public GptAiService(GptClient gptClient) {
        this.gptClient = gptClient;
    }

    @Override
    public SuggestCategoryResponse suggestCategory(SuggestCategoryRequest request) {
        String category = gptClient.classify(request.description());
        double confidence = "Uncategorized".equalsIgnoreCase(category) ? 0.45 : 0.85;
        return new SuggestCategoryResponse(null, category, confidence, "GPT");
    }

    @Override
    public AiFeedbackResponse submitFeedback(AiFeedbackRequest request) {
        return new AiFeedbackResponse(request.suggestionId(), request.finalCategory(), false);
    }

    @Override
    public InsightsResponse insights() {
        String raw = gptClient.generateInsights();
        List<String> insights = Arrays.stream(raw.split("\\r?\\n"))
                .map(String::trim)
                .map(line -> line.replaceFirst("^[-*•]\\s*", ""))
                .filter(line -> !line.isBlank())
                .limit(3)
                .toList();

        if (insights.isEmpty()) {
            return new InsightsResponse(List.of("No insights available yet."));
        }

        return new InsightsResponse(insights);
    }

    @Override
    public TrainingDataResponse trainingData() {
        return new TrainingDataResponse(
                "jsonl",
                0,
                "Training data export is provided by RuleBasedAiService (primary AI service).",
                List.of());
    }
}
