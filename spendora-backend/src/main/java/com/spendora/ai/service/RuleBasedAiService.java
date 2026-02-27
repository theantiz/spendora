package com.spendora.ai.service;

import com.spendora.ai.dto.AiFeedbackRequest;
import com.spendora.ai.dto.AiFeedbackResponse;
import com.spendora.ai.dto.InsightsResponse;
import com.spendora.ai.dto.SuggestCategoryRequest;
import com.spendora.ai.dto.SuggestCategoryResponse;
import com.spendora.ai.dto.TrainingDataResponse;
import com.spendora.ai.model.AiSuggestion;
import com.spendora.ai.repository.AiSuggestionRepository;
import com.spendora.common.exception.BadRequestException;
import com.spendora.common.exception.NotFoundException;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Service;

@Service
@Primary
public class RuleBasedAiService implements AiService {

    private static final Long ANONYMOUS_USER_ID = 0L;
    private static final String TRAINING_SYSTEM_PROMPT = """
            You are a personal-finance categorization assistant.
            Return exactly one category from this list:
            Transport, Food, Entertainment, Shopping, Bills, Health, Other, Uncategorized.
            Classify restaurant dishes, groceries, and beverages as Food.
            Classify movies, cinema, streaming subscriptions, and OTT platforms as Entertainment.
            Do not add explanations.
            """;

    private final AiSuggestionRepository suggestionRepository;
    private final GptAiService gptAiService;

    public RuleBasedAiService(
            AiSuggestionRepository suggestionRepository,
            GptAiService gptAiService) {
        this.suggestionRepository = suggestionRepository;
        this.gptAiService = gptAiService;
    }

    @Override
    public SuggestCategoryResponse suggestCategory(SuggestCategoryRequest request) {
        String input = request.description() == null ? "" : request.description().trim();
        if (input.isBlank()) {
            throw new BadRequestException("Description is required");
        }

        Long userId = request.userId() == null ? ANONYMOUS_USER_ID : request.userId();
        String normalized = normalize(input);

        AiSuggestion memoryHit = suggestionRepository
                .findTopByUserIdAndNormalizedInputAndValidatedTrueOrderByCreatedAtDesc(userId, normalized)
                .or(() -> suggestionRepository
                        .findTopByNormalizedInputAndValidatedTrueAndOverriddenTrueOrderByCreatedAtDesc(normalized))
                .orElse(null);

        if (memoryHit != null) {
            String learnedCategory = memoryHit.getFinalCategory() == null
                    ? memoryHit.getSuggestedCategory()
                    : memoryHit.getFinalCategory();
            AiSuggestion saved = saveSuggestion(userId, input, normalized, learnedCategory, 0.98, "MEMORY");
            return toResponse(saved, learnedCategory, 0.98, "MEMORY");
        }

        String category = "Uncategorized";
        double confidence = 0.35;
        String source = "LLM_FALLBACK";

        try {
            SuggestCategoryResponse gpt = gptAiService.suggestCategory(request);
            if (gpt.category() != null && !gpt.category().isBlank()) {
                category = gpt.category().trim();
                confidence = Math.max(gpt.confidence(), confidence);
                source = "GPT";
            }
        } catch (RuntimeException ignored) {
            // LLM unavailable or failed: return fallback category instead of failing request.
        }

        AiSuggestion saved = saveSuggestion(userId, input, normalized, category, confidence, source);
        return toResponse(saved, category, confidence, source);
    }

    @Override
    public AiFeedbackResponse submitFeedback(AiFeedbackRequest request) {
        if (request.suggestionId() == null) {
            throw new BadRequestException("suggestionId is required");
        }
        if (request.finalCategory() == null || request.finalCategory().isBlank()) {
            throw new BadRequestException("finalCategory is required");
        }

        AiSuggestion suggestion = suggestionRepository.findById(request.suggestionId())
                .orElseThrow(() -> new NotFoundException("Suggestion not found: " + request.suggestionId()));

        Long effectiveUserId = request.userId() == null ? suggestion.getUserId() : request.userId();
        suggestion.setUserId(effectiveUserId);
        suggestion.setValidated(Boolean.TRUE);
        suggestion.setFinalCategory(request.finalCategory().trim());
        suggestion.setOverridden(!request.finalCategory().trim().equalsIgnoreCase(suggestion.getSuggestedCategory()));
        suggestionRepository.save(suggestion);

        return new AiFeedbackResponse(
                suggestion.getId(),
                suggestion.getFinalCategory(),
                suggestion.getOverridden());
    }

    @Override
    public InsightsResponse insights() {
        try {
            return gptAiService.insights();
        } catch (RuntimeException ex) {
            return new InsightsResponse(List.of(
                    "AI insights are temporarily unavailable.",
                    "You can still record entries and use category suggestions.",
                    "Try again in a moment."));
        }
    }

    @Override
    public TrainingDataResponse trainingData() {
        List<String> lines = suggestionRepository.findByValidatedTrueOrderByCreatedAtAsc()
                .stream()
                .map(this::toTrainingJsonLine)
                .toList();

        String note = lines.isEmpty()
                ? "No validated feedback yet. Submit AI feedback first to build training data."
                : "Use these lines as a JSONL file for model fine-tuning.";

        return new TrainingDataResponse("jsonl", lines.size(), note, lines);
    }

    private AiSuggestion saveSuggestion(
            Long userId,
            String inputText,
            String normalizedInput,
            String category,
            double confidence,
            String source) {
        AiSuggestion suggestion = new AiSuggestion();
        suggestion.setUserId(userId);
        suggestion.setInputText(inputText);
        suggestion.setNormalizedInput(normalizedInput);
        suggestion.setSuggestedCategory(category);
        suggestion.setConfidence(confidence);
        suggestion.setSource(source);
        suggestion.setValidated(Boolean.FALSE);
        suggestion.setOverridden(Boolean.FALSE);
        suggestion.setFinalCategory(null);
        return suggestionRepository.save(suggestion);
    }

    private SuggestCategoryResponse toResponse(
            AiSuggestion saved,
            String category,
            double confidence,
            String source) {
        return new SuggestCategoryResponse(saved.getId(), category, confidence, source);
    }

    private String normalize(String input) {
        return Arrays.stream(input.toLowerCase(Locale.ROOT).split("\\s+"))
                .map(token -> token.replaceAll("[^a-z0-9]", ""))
                .filter(token -> !token.isBlank())
                .reduce((a, b) -> a + " " + b)
                .orElse("");
    }

    private String toTrainingJsonLine(AiSuggestion suggestion) {
        String userInput = suggestion.getInputText() == null ? "" : suggestion.getInputText().trim();
        String finalCategory = suggestion.getFinalCategory();
        if (finalCategory == null || finalCategory.isBlank()) {
            finalCategory = suggestion.getSuggestedCategory();
        }
        if (finalCategory == null || finalCategory.isBlank()) {
            finalCategory = "Uncategorized";
        }

        String createdAt = suggestion.getCreatedAt() == null ? "" : suggestion.getCreatedAt().toString();
        return "{"
                + "\"messages\":["
                + "{\"role\":\"system\",\"content\":\"" + escapeJson(TRAINING_SYSTEM_PROMPT) + "\"},"
                + "{\"role\":\"user\",\"content\":\"" + escapeJson("Transaction note: " + userInput) + "\"},"
                + "{\"role\":\"assistant\",\"content\":\"" + escapeJson(finalCategory.trim()) + "\"}"
                + "],"
                + "\"metadata\":{"
                + "\"suggestionId\":" + (suggestion.getId() == null ? "null" : suggestion.getId()) + ","
                + "\"userId\":" + (suggestion.getUserId() == null ? "null" : suggestion.getUserId()) + ","
                + "\"createdAt\":\"" + escapeJson(createdAt) + "\""
                + "}"
                + "}";
    }

    private String escapeJson(String raw) {
        String input = raw == null ? "" : raw;
        return input
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}
