package com.example.budgeting_app.service;

import com.example.budgeting_app.repository.BudgetPlanRepository;
import com.example.budgeting_app.entity.BudgetPlan;

import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;


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

    public List<BudgetPlan> getAllPlans(){
        return planRepository.findAll();
    }

    public BudgetPlan getPlan(Long id){
        return planRepository.findById(id).orElse(null);
    }
    
}
