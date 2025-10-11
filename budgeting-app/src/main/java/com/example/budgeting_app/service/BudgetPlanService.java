package com.example.budgeting_app.service;

import com.example.budgeting_app.repository.BudgetPlanRepository;
import com.example.budgeting_app.entity.BudgetPlan;
import com.example.budgeting_app.entity.PlanStatus;

import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;


@Service
public class BudgetPlanService {
    private BudgetPlanRepository planRepository;

    public BudgetPlanService (BudgetPlanRepository planRepository){
        this.planRepository = planRepository;
    }

    public BudgetPlan createPlan(String name, LocalDate startDate, LocalDate endDate){
        BudgetPlan plan = new BudgetPlan();
        plan.setName(name);
        plan.setStartDate(startDate);
        plan.setEndDate(endDate);
        return planRepository.save(plan);
    }


    // Save using full Object for JSON
    public BudgetPlan savePlan(BudgetPlan plan){
        return planRepository.save(plan);
    }

    // Fetching all
    public List<BudgetPlan> getAllPlans(){
        return planRepository.findAll();
    }

    // Fetching By Id
    public Optional<BudgetPlan> getPlanById(Long id){
        return planRepository.findById(id);
    }

    // Fetching By Status
    public List<BudgetPlan> getPlanByStatus(PlanStatus status){
        return planRepository.findByStatus(status);
        
    }

    // Updating budgetPlanStatus
    public Optional<BudgetPlan> updatePlanStatus(Long id, PlanStatus status){
        return planRepository.findById(id).map(plan -> {
            plan.setStatus(status);
            return planRepository.save(plan);
        });
    }
    
}
