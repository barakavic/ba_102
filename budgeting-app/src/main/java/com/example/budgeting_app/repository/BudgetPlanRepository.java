package com.example.budgeting_app.repository;

import com.example.budgeting_app.entity.BudgetPlan;
import com.example.budgeting_app.entity.PlanStatus;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface BudgetPlanRepository extends JpaRepository<BudgetPlan, Long>{

    
    List<BudgetPlan> findByStatus(PlanStatus status);

    
}
