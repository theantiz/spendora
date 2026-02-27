package com.spendora.category.service;

import com.spendora.category.dto.CategoryResponse;
import com.spendora.category.dto.CreateCategoryRequest;
import com.spendora.category.dto.UpdateCategoryRequest;
import com.spendora.category.model.Category;
import com.spendora.category.repository.CategoryRepository;
import com.spendora.common.exception.ConflictException;
import com.spendora.common.exception.NotFoundException;
import java.util.List;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

@Service
public class CategoryService {

    private final CategoryRepository categoryRepository;

    public CategoryService(CategoryRepository categoryRepository) {
        this.categoryRepository = categoryRepository;
    }

    public CategoryResponse create(CreateCategoryRequest request) {
        String normalizedName = request.name().trim();
        if (categoryRepository.existsByNameIgnoreCase(normalizedName)) {
            throw new ConflictException("Category already exists: " + normalizedName);
        }

        Category category = new Category();
        category.setName(normalizedName);
        category.setColor(request.color().trim().toUpperCase());
        Category saved = categoryRepository.save(category);
        return toResponse(saved);
    }

    public List<CategoryResponse> listAll() {
        return categoryRepository.findAll(Sort.by(Sort.Direction.ASC, "name")).stream()
                .map(this::toResponse)
                .toList();
    }

    public CategoryResponse getById(Long id) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Category not found: " + id));
        return toResponse(category);
    }

    public CategoryResponse update(Long id, UpdateCategoryRequest request) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Category not found: " + id));

        String normalizedName = request.name().trim();
        if (categoryRepository.existsByNameIgnoreCaseAndIdNot(normalizedName, id)) {
            throw new ConflictException("Category already exists: " + normalizedName);
        }

        category.setName(normalizedName);
        category.setColor(request.color().trim().toUpperCase());
        Category saved = categoryRepository.save(category);
        return toResponse(saved);
    }

    public void delete(Long id) {
        if (!categoryRepository.existsById(id)) {
            throw new NotFoundException("Category not found: " + id);
        }
        categoryRepository.deleteById(id);
    }

    private CategoryResponse toResponse(Category category) {
        return new CategoryResponse(category.getId(), category.getName(), category.getColor());
    }
}
