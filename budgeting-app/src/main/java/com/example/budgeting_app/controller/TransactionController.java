package com.example.budgeting_app.controller;

import com.example.budgeting_app.service.BudgetCategoryService;
import com.example.budgeting_app.service.BudgetPlanService;
import com.example.budgeting_app.service.TransactionService;
import com.example.budgeting_app.entity.BudgetCategory;
import com.example.budgeting_app.entity.BudgetPlan;
import com.example.budgeting_app.entity.Transaction;
import com.example.budgeting_app.exceptions.ResourceNotFoundException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/transactions")
public class TransactionController {

    private final TransactionService transactionService;
    private final BudgetCategoryService categoryService;
    private final BudgetPlanService planService;

    private static final Logger logger = LoggerFactory.getLogger(TransactionController.class);

    public TransactionController(TransactionService transactionService, BudgetCategoryService categoryService, BudgetPlanService planService){
        this.transactionService = transactionService;
        this.planService = planService;
        this.categoryService = categoryService;
    }

    @PostMapping
    public ResponseEntity<Transaction> createTransaction(
    @RequestParam Long planId, 
    @RequestParam Long categoryId,
    @RequestParam Double amount,
    @RequestParam(required = false) String description) {
        BudgetPlan plan = planService.getPlanById(planId)
        .orElseThrow(()-> new ResourceNotFoundException("Plan not found with id: "+planId));

        BudgetCategory category = categoryService.getCategoryById(categoryId);
        
        Transaction saved = transactionService.addTransaction(plan, category, amount, description);

        logger.info("Transaction created: planId{}, categoryId{}, amount{}", planId, category, amount);

        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        
    }

    @GetMapping
    public ResponseEntity<List<Transaction>> getAllTransactions(){
        return ResponseEntity.ok( transactionService.getAllTransactions());

    }
    
    @GetMapping("/by-id")
    public ResponseEntity<Transaction> getTransactionById(@RequestParam Long id){
        return transactionService.getTransactionById(id)
        .map(ResponseEntity::ok)
        .orElse(ResponseEntity.status(HttpStatus.NOT_FOUND).build());
    }

    @GetMapping("/by-plan")
    public ResponseEntity<List<Transaction>> getTransactionsByPlan(@RequestParam Long planId){
        return ResponseEntity.ok(transactionService.getTransactionsByPlan(planId));
    }

    @GetMapping("/by-category")
    public ResponseEntity<List<Transaction>> getTransactionsByCategory(@RequestParam Long categoryId ){
        return ResponseEntity.ok(transactionService.getTransactionsByCategory(categoryId));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTransaction(@PathVariable Long id){
        transactionService.deleteTransaction(id);
        logger.info("Transaction with id {} was deleted by user", id);
        return ResponseEntity.noContent().build();
        

    }

    
    
}
