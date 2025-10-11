package com.example.budgeting_app.controller;

import com.example.budgeting_app.entity.BudgetCategory;
import com.example.budgeting_app.service.BudgetCategoryService;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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
    public ResponseEntity<BudgetCategory> createCategory(@RequestBody BudgetCategory category){
        BudgetCategory saved = categoryService.saveCategory(category);

        return ResponseEntity.status(HttpStatus.CREATED).body(saved);

    }

    @GetMapping
    public ResponseEntity<List<BudgetCategory>> getAllCategories(){
        List<BudgetCategory> categories = categoryService.getAllCategories();
        return ResponseEntity.ok(categories);
    }

    @GetMapping("/by-name")
    public ResponseEntity<BudgetCategory> getCategoryByName(@RequestParam String name){
        BudgetCategory category = categoryService.getCategoryByName(name);
        if (category == null){
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
        return ResponseEntity.ok(category);
    }

    @GetMapping("/{name}/spent")
    public ResponseEntity<Double> getSpentamount(
        @PathVariable String name 
    ){
        BudgetCategory category = categoryService.getCategoryByName(name);
        if (category == null){
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();


        }
        return ResponseEntity.ok(category.getSpentAmount());
    }
    
    
}
