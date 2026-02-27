package com.spendora.expense.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

public record ExpenseResponse(Long id, Long categoryId, BigDecimal amount, String description, LocalDate spentAt) {
}
