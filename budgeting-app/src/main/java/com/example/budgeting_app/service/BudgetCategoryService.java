package com.example.budgeting_app.service;

import com.example.budgeting_app.repository.BudgetCategoryRepository;
import com.example.budgeting_app.repository.BudgetPlanRepository;
import com.example.budgeting_app.entity.BudgetCategory;
import com.example.budgeting_app.exceptions.ResourceNotFoundException;

import org.springframework.stereotype.Service;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class BudgetCategoryService {

    private final BudgetCategoryRepository categoryRepository;

    private static final Logger logger = LoggerFactory.getLogger(BudgetCategoryService.class);

    private final BudgetPlanRepository planRepository;

    public BudgetCategoryService(BudgetCategoryRepository categoryRepository, BudgetPlanRepository planRepository) {
        this.categoryRepository = categoryRepository;
        this.planRepository = planRepository;
    }

    public BudgetCategory createCategory(String name) {
        BudgetCategory category = new BudgetCategory();
        category.setName(name);
        return categoryRepository.save(category);
    }

    public BudgetCategory createCategoryWithPlan(BudgetCategory category, Long planId) {
        if (planId != null) {
            com.example.budgeting_app.entity.BudgetPlan plan = planRepository.findById(planId)
                    .orElseThrow(() -> new ResourceNotFoundException("Plan not found with id: " + planId));
            category.setPlan(plan);
        }
        return categoryRepository.save(category);
    }

    public BudgetCategory saveCategory(BudgetCategory category) {
        return categoryRepository.save(category);
    }

    public List<BudgetCategory> getAllCategories() {
        return categoryRepository.findAll();
    }

    public BudgetCategory getCategoryByName(String name) {
        BudgetCategory category = categoryRepository.findByName(name);
        if (category == null) {
            logger.error("Category not found with name{}", name);
            throw new ResourceNotFoundException("Category not found with name" + name);

        }

        return category;
    }

    public BudgetCategory getCategoryById(Long id) {
        if (id == null) {
            logger.error("category with id {} not found", id);
            throw new ResourceNotFoundException("Category not found for id: " + id);

        }
        return categoryRepository.findById(id)
                .orElseThrow(() -> {
                    logger.error("Category not found with id {}", id);
                    return new ResourceNotFoundException("Category not found with id: " + id);
                });

    }

    public BudgetCategory updateCategoryLimit(String name, Double limit) {
        BudgetCategory category = categoryRepository.findByName(name);

        if (category == null) {

            throw new ResourceNotFoundException("Can't set limit - category not found" + name);

        }

        category.setLimitAmount(limit);
        return categoryRepository.save(category);
    }

    public void deleteCategory(Long id) {

        logger.info("Attempting to delete category with id {}", id);

        BudgetCategory category = categoryRepository.findById(id)
                .orElseThrow(() -> {
                    logger.error("Category not found with id {}", id);
                    return new ResourceNotFoundException("Category not found with id" + id);
                });

        categoryRepository.delete(category);
        logger.info("Successfully deleted category with id {} ", id);
    }

}
