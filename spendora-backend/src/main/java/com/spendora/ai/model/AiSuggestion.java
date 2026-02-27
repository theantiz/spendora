package com.spendora.ai.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "ai_suggestions")
public class AiSuggestion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String inputText;

    @Column(nullable = false)
    private String normalizedInput;

    @Column(nullable = false)
    private Long userId;

    @Column(nullable = false)
    private String suggestedCategory;

    @Column
    private String finalCategory;

    @Column(nullable = false)
    private Double confidence;

    @Column(nullable = false)
    private String source;

    @Column(nullable = false)
    private Boolean validated = Boolean.FALSE;

    @Column(nullable = false)
    private Boolean overridden = Boolean.FALSE;

    @Column(nullable = false)
    private Instant createdAt = Instant.now();

    public Long getId() {
        return id;
    }

    public String getInputText() {
        return inputText;
    }

    public void setInputText(String inputText) {
        this.inputText = inputText;
    }

    public String getNormalizedInput() {
        return normalizedInput;
    }

    public void setNormalizedInput(String normalizedInput) {
        this.normalizedInput = normalizedInput;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getSuggestedCategory() {
        return suggestedCategory;
    }

    public void setSuggestedCategory(String suggestedCategory) {
        this.suggestedCategory = suggestedCategory;
    }

    public String getFinalCategory() {
        return finalCategory;
    }

    public void setFinalCategory(String finalCategory) {
        this.finalCategory = finalCategory;
    }

    public Double getConfidence() {
        return confidence;
    }

    public void setConfidence(Double confidence) {
        this.confidence = confidence;
    }

    public String getSource() {
        return source;
    }

    public void setSource(String source) {
        this.source = source;
    }

    public Boolean getValidated() {
        return validated;
    }

    public void setValidated(Boolean validated) {
        this.validated = validated;
    }

    public Boolean getOverridden() {
        return overridden;
    }

    public void setOverridden(Boolean overridden) {
        this.overridden = overridden;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
