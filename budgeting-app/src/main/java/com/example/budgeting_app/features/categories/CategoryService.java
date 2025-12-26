package com.example.budgeting_app.features.categories;

import com.example.budgeting_app.exceptions.ResourceNotFoundException;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.List;

@Service
public class CategoryService {

    private static final Logger logger = LoggerFactory.getLogger(CategoryService.class);
    private final CategoryRepository categoryRepository;

    public CategoryService(CategoryRepository categoryRepository) {
        this.categoryRepository = categoryRepository;
    }

    public Category createCategory(Category category) {
        return categoryRepository.save(category);
    }

    public Category saveCategory(Category category) {
        return categoryRepository.save(category);
    }

    public List<Category> getAllCategories() {
        return categoryRepository.findAll();
    }

    public Category getCategoryByName(String name) {
        return categoryRepository.findByName(name)
                .orElseThrow(() -> {
                    logger.error("Category not found with name: {}", name);
                    return new ResourceNotFoundException("Category not found with name: " + name);
                });
    }

    public Category getCategoryById(Long id) {
        return categoryRepository.findById(id)
                .orElseThrow(() -> {
                    logger.error("Category not found with id: {}", id);
                    return new ResourceNotFoundException("Category not found with id: " + id);
                });
    }

    public Category updateCategoryLimit(String name, Double limit) {
        Category category = getCategoryByName(name);
        category.setLimitAmount(limit);
        return categoryRepository.save(category);
    }

    public void deleteCategory(Long id) {
        logger.info("Attempting to delete category with id: {}", id);
        Category category = getCategoryById(id);
        categoryRepository.delete(category);
        logger.info("Successfully deleted category with id: {}", id);
    }

    public Category syncCategory(Category category) {
        if (category.getClientId() != null) {
            return categoryRepository.findByClientId(category.getClientId())
                    .map(existing -> {
                        existing.setName(category.getName());
                        existing.setLimitAmount(category.getLimitAmount());
                        existing.setIcon(category.getIcon());
                        existing.setColor(category.getColor());
                        existing.setParentId(category.getParentId());
                        return categoryRepository.save(existing);
                    })
                    .orElseGet(() -> categoryRepository.save(category));
        }
        return categoryRepository.save(category);
    }
}
