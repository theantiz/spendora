package com.spendora.analytics.dto;

import java.math.BigDecimal;

public record TopCategoryResponse(String categoryName, BigDecimal amount) {
}
