package com.example.budgeting_app.controller;

import com.example.budgeting_app.entity.BudgetPlan;
import com.example.budgeting_app.service.BudgetPlanService;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;


@RestController
@RequestMapping("/plans")
public class BudgetPlanController {

    private final BudgetPlanService budgetPlanService;

    public BudgetPlanController(BudgetPlanService budgetPlanService){
        this.budgetPlanService = budgetPlanService;
    }

    @PostMapping
    public BudgetPlan createPlan(@RequestBody BudgetPlan plan){
        return budgetPlanService.savePlan(plan);
    }

    @GetMapping
    public List<BudgetPlan> getAllPlans(){
        return budgetPlanService.getAllPlans();

    }

    @GetMapping("/id")
    public BudgetPlan getPlanById(@RequestParam Long id){
        return budgetPlanService.getPlanById(id)
        .orElseThrow(()-> new RuntimeException("Plan not found with id:" +id));
    }
    
}
