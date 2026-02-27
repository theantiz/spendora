package com.spendora.ai.dto;

import java.util.List;

public record TrainingDataResponse(
        String format,
        int count,
        String note,
        List<String> lines) {
}
