package com.spendora.category.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record UpdateCategoryRequest(
        @NotBlank @Size(min = 2, max = 100) String name,
        @NotBlank @Pattern(regexp = "^#([A-Fa-f0-9]{6})$", message = "color must be hex format like #A1B2C3") String color) {
}
