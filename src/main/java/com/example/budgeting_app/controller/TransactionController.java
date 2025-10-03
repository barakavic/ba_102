package com.example.budgeting_app.controller;

import com.example.budgeting_app.service.TransactionService;
import com.example.budgeting_app.entity.Transaction;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
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
    public ResponseEntity<Transaction> createTransaction(@RequestBody Transaction transaction) {
        Transaction save = transactionService.saveTransaction(transaction);
        return ResponseEntity.status(HttpStatus.CREATED).body(save);
    }

    @GetMapping
    public ResponseEntity<List<Transaction>> getAllTransactions(){
        return ResponseEntity.ok( transactionService.getAllTransactions());

    }
    
    @GetMapping("/by-id")
    public ResponseEntity<Transaction> geTransactionById(@RequestParam Long id){
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
        return ResponseEntity.ok(transactionService.geTransactionsByCategory(categoryId));
    }

    
    
}
