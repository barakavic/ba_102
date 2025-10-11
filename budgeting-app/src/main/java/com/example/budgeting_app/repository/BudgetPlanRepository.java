package com.example.budgeting_app.repository;

import com.example.budgeting_app.entity.BudgetPlan;
import com.example.budgeting_app.entity.PlanStatus;

import java.time.LocalDate;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

public interface BudgetPlanRepository extends JpaRepository<BudgetPlan, Long>{

    // List<BudgetPlan> findByStartdateBeforeAndEndDateAfter(LocalDate start, LocalDate end);
    List<BudgetPlan> findByStatus(PlanStatus status);

    
}
