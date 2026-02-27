package com.spendora.analytics.dto;

import java.math.BigDecimal;

public record SummaryResponse(BigDecimal totalSpent, long transactionCount) {
}
