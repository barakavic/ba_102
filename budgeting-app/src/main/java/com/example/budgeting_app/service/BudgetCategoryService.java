package com.example.budgeting_app.service;

import com.example.budgeting_app.repository.BudgetCategoryRepository;
import com.example.budgeting_app.entity.BudgetCategory;

import org.springframework.stereotype.Service;
import java.util.List;


@Service
public class BudgetCategoryService {

    private final BudgetCategoryRepository categoryRepository;

    public BudgetCategoryService(BudgetCategoryRepository categoryRepository){
        this.categoryRepository = categoryRepository;
    }

    public BudgetCategory createCategory(String name){
        BudgetCategory category = new BudgetCategory();
        category.setName(name);
        return categoryRepository.save(category);




    }

    public BudgetCategory saveCategory(BudgetCategory category){
        return categoryRepository.save(category);
    }

    public List<BudgetCategory> getAllCategories(){
        return categoryRepository.findAll();
    }

    public BudgetCategory getCategoryByName(String name){
        return categoryRepository.findByName(name);
    }

    public BudgetCategory updateCategoryLimit(String name, Double limit){
        BudgetCategory category = categoryRepository.findByName(name);

        if(category == null){
           throw new IllegalArgumentException("category with name"+name+"doesnt exist");

        }

        category.setLimitAmount(limit);
        return categoryRepository.save(category);
    }
    

    

    
    
}
