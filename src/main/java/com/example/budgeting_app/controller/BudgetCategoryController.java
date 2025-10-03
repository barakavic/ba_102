package com.example.budgeting_app.controller;

import com.example.budgeting_app.entity.BudgetCategory;
import com.example.budgeting_app.service.BudgetCategoryService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/categories")
public class BudgetCategoryController {
    
    private final BudgetCategoryService categoryService;

    public BudgetCategoryController(BudgetCategoryService categoryService){
        this.categoryService = categoryService;
    }

    @PostMapping
    public BudgetCategory createCategory(@RequestBody BudgetCategory category){
        return categoryService.saveCategory(category);

    }

    @GetMapping
    public List<BudgetCategory> getAllCategories(){
        return categoryService.getAllCategories();
    }

    @GetMapping("/by-name")
    public BudgetCategory getCategoryByName(@RequestParam String name){
        return categoryService.getCategoryByName(name);
    }

    
}
