package com.spendora.common.api;

import java.util.List;
import java.time.Instant;

public record ErrorResponse(
        String code,
        String message,
        List<String> details,
        String path,
        Instant timestamp) {
}
