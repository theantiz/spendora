package com.spendora.expense.controller;

import com.spendora.common.api.ApiResponse;
import com.spendora.expense.dto.CreateExpenseRequest;
import com.spendora.expense.dto.ExpenseResponse;
import com.spendora.expense.dto.UpdateExpenseRequest;
import com.spendora.expense.service.ExpenseService;
import java.util.List;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/expenses")
public class ExpenseController {

    private final ExpenseService expenseService;

    public ExpenseController(ExpenseService expenseService) {
        this.expenseService = expenseService;
    }

    @PostMapping
    public ApiResponse<ExpenseResponse> create(@RequestBody CreateExpenseRequest request) {
        return ApiResponse.ok(expenseService.create(request));
    }

    @GetMapping
    public ApiResponse<List<ExpenseResponse>> listAll() {
        return ApiResponse.ok(expenseService.listAll());
    }

    @GetMapping("/{id}")
    public ApiResponse<ExpenseResponse> getById(@PathVariable Long id) {
        return ApiResponse.ok(expenseService.getById(id));
    }

    @PutMapping("/{id}")
    public ApiResponse<ExpenseResponse> update(
            @PathVariable Long id,
            @RequestBody UpdateExpenseRequest request) {
        return ApiResponse.ok(expenseService.update(id, request));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<String> delete(@PathVariable Long id) {
        expenseService.delete(id);
        return ApiResponse.ok("Expense deleted");
    }
}
