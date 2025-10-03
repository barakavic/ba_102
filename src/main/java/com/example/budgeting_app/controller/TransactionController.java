package com.example.budgeting_app.controller;

import com.example.budgeting_app.service.TransactionService;
import com.example.budgeting_app.entity.Transaction;

import org.springframework.web.bind.annotation.*;

/* import java.math.BigDecimal;
import java.time.LocalDate; */
import java.util.List;

@RestController
@RequestMapping("/transactions")
public class TransactionController {

    private TransactionService transactionService;

    public TransactionController(TransactionService transactionService){
        this.transactionService = transactionService;
    }

    @PostMapping
    public Transaction createTransaction(@RequestBody Transaction transaction) {
        return transactionService.saveTransaction(transaction);
    }

    @GetMapping
    public List<Transaction> getAllTransactions(){
        return transactionService.getAllTransactions();

    }
    
    @GetMapping("/by-id")
    public Transaction geTransactionById(@RequestParam Long id){
        return transactionService.getTransactionById(id).orElseThrow(() -> new RuntimeException("Transaction not found for id:"+ id));
    }

    @GetMapping("/by-plan")
    public List<Transaction> getTransactionsByPlan(@RequestParam Long planId){
        return transactionService.getTransactionsByPlan(planId);
    }

    @GetMapping("/by-category")
    public List<Transaction> geTransactionsByCategory(@RequestParam Long categoryId ){
        return transactionService.geTransactionsByCategory(categoryId);
    }

    
    
}
