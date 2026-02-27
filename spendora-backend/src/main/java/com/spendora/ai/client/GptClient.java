package com.spendora.ai.client;

import java.util.Arrays;
import java.util.List;
import java.util.regex.Pattern;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Component;

@Component
public class GptClient {

    private static final List<String> ALLOWED_CATEGORIES =
            List.of(
                    "Transport",
                    "Food",
                    "Entertainment",
                    "Shopping",
                    "Bills",
                    "Health",
                    "Other",
                    "Uncategorized");

    private final ChatClient chatClient;

    public GptClient(ObjectProvider<ChatClient> chatClientProvider) {
        this.chatClient = chatClientProvider.getIfAvailable();
    }

    public String classify(String description) {
        String input = description == null ? "" : description.trim();

        if (chatClient == null) {
            return "Uncategorized";
        }

        String raw = chatClient.prompt()
                .system("""
                        You are a personal-finance categorization assistant.
                        Return exactly one category from this list:
                        Transport, Food, Entertainment, Shopping, Bills, Health, Other, Uncategorized.
                        Classify restaurant dishes, groceries, and beverages as Food.
                        Classify movies, cinema, streaming subscriptions, and OTT platforms as Entertainment.
                        Do not add explanations.
                        """)
                .user("Transaction note: " + input)
                .call()
                .content();

        return normalizeCategory(raw);
    }

    public String generateInsights() {
        if (chatClient == null) {
            return "No insights available yet.";
        }

        return chatClient.prompt()
                .system("You are a personal finance analyst.")
                .user("""
                        Provide exactly 3 short actionable spending insights.
                        Keep the response under 60 words.
                        """)
                .call()
                .content();
    }

    private String normalizeCategory(String raw) {
        if (raw == null || raw.isBlank()) {
            return "Uncategorized";
        }

        String normalized = raw.trim();
        String single = Arrays.stream(normalized.split("[\\r\\n]"))
                .findFirst()
                .orElse(normalized)
                .replace("-", "")
                .trim();
        String compact = single.replaceFirst("(?i)^category\\s*[:\\-]\\s*", "").trim();

        for (String category : ALLOWED_CATEGORIES) {
            if (category.equalsIgnoreCase(compact)) {
                return category;
            }
        }

        for (String category : ALLOWED_CATEGORIES) {
            Pattern pattern = Pattern.compile("\\b" + Pattern.quote(category) + "\\b", Pattern.CASE_INSENSITIVE);
            if (pattern.matcher(compact).find()) {
                return category;
            }
        }

        return "Uncategorized";
    }
}
