package com.example.budgeting_app.repository;

import com.example.budgeting_app.entity.BudgetCategory;
import org.springframework.data.jpa.repository.JpaRepository;


public interface BudgetCategoryRepository extends JpaRepository<BudgetCategory, Long>{

    BudgetCategory findByName(String name);
    
    
}
