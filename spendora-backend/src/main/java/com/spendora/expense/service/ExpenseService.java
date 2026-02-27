package com.spendora.expense.service;

import com.spendora.category.repository.CategoryRepository;
import com.spendora.common.exception.BadRequestException;
import com.spendora.common.exception.NotFoundException;
import com.spendora.common.util.MoneyUtil;
import com.spendora.expense.dto.CreateExpenseRequest;
import com.spendora.expense.dto.ExpenseResponse;
import com.spendora.expense.dto.UpdateExpenseRequest;
import com.spendora.expense.model.Expense;
import com.spendora.expense.repository.ExpenseRepository;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

@Service
public class ExpenseService {

    private final ExpenseRepository expenseRepository;
    private final CategoryRepository categoryRepository;

    public ExpenseService(
            ExpenseRepository expenseRepository,
            CategoryRepository categoryRepository) {
        this.expenseRepository = expenseRepository;
        this.categoryRepository = categoryRepository;
    }

    public ExpenseResponse create(CreateExpenseRequest request) {
        validateCreateRequest(request);
        Expense expense = new Expense();
        expense.setCategoryId(request.categoryId());
        expense.setAmount(MoneyUtil.normalize(request.amount()));
        expense.setDescription(request.description().trim());
        expense.setSpentAt(request.spentAt());
        Expense saved = expenseRepository.save(expense);
        return toResponse(saved);
    }

    public ExpenseResponse update(Long id, UpdateExpenseRequest request) {
        validateUpdateRequest(request);
        Expense expense = expenseRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Expense not found: " + id));
        expense.setAmount(MoneyUtil.normalize(request.amount()));
        expense.setDescription(request.description().trim());
        expense.setSpentAt(request.spentAt());
        Expense saved = expenseRepository.save(expense);
        return toResponse(saved);
    }

    public ExpenseResponse getById(Long id) {
        Expense expense = expenseRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Expense not found: " + id));
        return toResponse(expense);
    }

    public List<ExpenseResponse> listAll() {
        return expenseRepository.findAll(Sort.by(Sort.Direction.DESC, "spentAt", "id")).stream()
                .map(this::toResponse)
                .toList();
    }

    public void delete(Long id) {
        if (!expenseRepository.existsById(id)) {
            throw new NotFoundException("Expense not found: " + id);
        }
        expenseRepository.deleteById(id);
    }

    private void validateCreateRequest(CreateExpenseRequest request) {
        if (request.categoryId() == null) {
            throw new BadRequestException("categoryId is required");
        }
        if (!categoryRepository.existsById(request.categoryId())) {
            throw new BadRequestException("Invalid categoryId: " + request.categoryId());
        }
        validateAmountDescriptionAndDate(request.amount(), request.description(), request.spentAt());
    }

    private void validateUpdateRequest(UpdateExpenseRequest request) {
        validateAmountDescriptionAndDate(request.amount(), request.description(), request.spentAt());
    }

    private void validateAmountDescriptionAndDate(BigDecimal amount, String description, LocalDate spentAt) {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new BadRequestException("amount must be greater than zero");
        }
        if (description == null || description.isBlank()) {
            throw new BadRequestException("description is required");
        }
        if (spentAt == null) {
            throw new BadRequestException("spentAt is required");
        }
    }

    private ExpenseResponse toResponse(Expense expense) {
        return new ExpenseResponse(
                expense.getId(),
                expense.getCategoryId(),
                expense.getAmount(),
                expense.getDescription(),
                expense.getSpentAt());
    }
}
