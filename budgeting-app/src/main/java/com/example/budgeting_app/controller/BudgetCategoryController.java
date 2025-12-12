package com.example.budgeting_app.controller;

import com.example.budgeting_app.entity.BudgetCategory;
import com.example.budgeting_app.service.BudgetCategoryService;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

@RestController
@RequestMapping("/categories")
public class BudgetCategoryController {

    private final BudgetCategoryService categoryService;

    private static final Logger logger = LoggerFactory.getLogger(BudgetCategoryController.class);

    public BudgetCategoryController(BudgetCategoryService categoryService) {
        this.categoryService = categoryService;
    }

    @PostMapping
    public ResponseEntity<BudgetCategory> createCategory(@RequestBody BudgetCategory category,
            @RequestParam(required = false) Long planId) {
        BudgetCategory saved = categoryService.createCategoryWithPlan(category, planId);

        return ResponseEntity.status(HttpStatus.CREATED).body(saved);

    }

    @GetMapping
    public ResponseEntity<List<BudgetCategory>> getAllCategories() {
        List<BudgetCategory> categories = categoryService.getAllCategories();
        return ResponseEntity.ok(categories);
    }

    @GetMapping("/by-name")
    public ResponseEntity<BudgetCategory> getCategoryByName(@RequestParam String name) {
        BudgetCategory category = categoryService.getCategoryByName(name);
        if (category == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
        return ResponseEntity.ok(category);
    }

    @GetMapping("/{name}/spent")
    public ResponseEntity<Double> getSpentamount(
            @PathVariable String name) {
        BudgetCategory category = categoryService.getCategoryByName(name);
        if (category == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();

        }
        return ResponseEntity.ok(category.getSpentAmount());
    }

    @DeleteMapping
    public ResponseEntity<Void> deleteCategory(Long id) {

        categoryService.deleteCategory(id);
        logger.info("category with ID {} deleted by user", id);
        return ResponseEntity.noContent().build();

    }

}
