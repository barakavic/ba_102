package com.example.budgeting_app.controller;

import com.example.budgeting_app.entity.BudgetPlan;
import com.example.budgeting_app.service.BudgetPlanService;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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
    public ResponseEntity<BudgetPlan> createPlan(@RequestBody BudgetPlan plan){
        BudgetPlan save = budgetPlanService.savePlan(plan);

        return ResponseEntity.status(HttpStatus.CREATED).body(save);
    }

    @GetMapping
    public ResponseEntity<List<BudgetPlan>> getAllPlans(){
        List<BudgetPlan> planService =  budgetPlanService.getAllPlans();
        return ResponseEntity.ok(planService);

    }

    @GetMapping("/id")
    public ResponseEntity<BudgetPlan> getPlanById(@RequestParam Long id){
        return budgetPlanService.getPlanById(id)
        .map(ResponseEntity::ok)
        .orElse(ResponseEntity.status(HttpStatus.NOT_FOUND).build());

        
    }
    
}
