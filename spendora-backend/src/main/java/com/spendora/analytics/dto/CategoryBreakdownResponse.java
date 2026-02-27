package com.spendora.analytics.dto;

import java.math.BigDecimal;

public record CategoryBreakdownResponse(String categoryName, BigDecimal amount) {
}
