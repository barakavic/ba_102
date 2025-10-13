package com.example.budgeting_app.controller;

import com.example.budgeting_app.entity.BudgetCategory;
import com.example.budgeting_app.entity.BudgetPlan;
import com.example.budgeting_app.entity.PlanStatus;
import com.example.budgeting_app.service.BudgetPlanService;

import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;


@RestController
@RequestMapping("/plans")
public class BudgetPlanController {

    private static final Logger logger = LoggerFactory.getLogger(BudgetPlanController.class);
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

    @GetMapping("/status")
    public ResponseEntity<List<BudgetPlan>> findByStatus(@RequestParam(value = "status", required = false) PlanStatus status ){
        List<BudgetPlan> plans;

        if(status != null){
            plans = budgetPlanService.getPlanByStatus(status);
            
        }else{
            plans = budgetPlanService.getPlanByStatus(PlanStatus.ACTIVE);
        }

        return ResponseEntity.ok(plans);
    }

    // Changing status of a plan
    @PatchMapping("/{id}/status")
    public ResponseEntity<BudgetPlan> updatePlanStatus(
        @PathVariable Long id,
        @RequestParam PlanStatus status
    ){
        return budgetPlanService.updatePlanStatus(id, status)
        .map(ResponseEntity::ok)
        .orElse(ResponseEntity.status(HttpStatus.NOT_FOUND).build());

    }

    @PostMapping("/{planId}/category")
    public ResponseEntity<BudgetPlan> addCategoryToplan(@PathVariable Long planId, @RequestBody BudgetCategory category){
        BudgetPlan updatedPlan = budgetPlanService.addCategoryToPlan(planId, category);
        return ResponseEntity.ok(updatedPlan);
    }

    @GetMapping("/{planId}/total-spent")
    public ResponseEntity<Double> getTotalSpent(@PathVariable Long planId){
        double totalSpent = budgetPlanService.calculateTotalSpent(planId);
        return ResponseEntity.ok(totalSpent);
    }

    @DeleteMapping
    public ResponseEntity<Void> deletePlan(Long planId){
        budgetPlanService.deletePlan(planId);
        logger.warn("Plan with ID {} deleted by user request", planId);
        return ResponseEntity.noContent().build();
    
    }

    
    
}
