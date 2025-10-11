package com.example.budgeting_app.service;

import com.example.budgeting_app.repository.BudgetCategoryRepository;
import com.example.budgeting_app.repository.TransactionRepository;
import com.example.budgeting_app.entity.BudgetCategory;
import com.example.budgeting_app.entity.BudgetPlan;
import com.example.budgeting_app.entity.Transaction;

import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.time.LocalDateTime;


@Service
public class TransactionService {

    private TransactionRepository transactionRepository;
    private BudgetCategoryRepository categoryRepository;

    public TransactionService(TransactionRepository transactionRepository, BudgetCategoryRepository categoryRepository){
        this.transactionRepository = transactionRepository;
        this.categoryRepository = categoryRepository;
    }

    public Transaction addTransaction(BudgetPlan plan, BudgetCategory category, Double amount, String description ){
        Transaction transaction = new Transaction();

        transaction.setPlan(plan);
        transaction.setCategory(category);
        transaction.setAmount(amount);
        transaction.setDescription(description);

        Transaction saved = transactionRepository.save(transaction);

        //Summation trigger logic that increments spent amount
        category.setSpentAmount(category.getSpentAmount()+amount);
        categoryRepository.save(category);

        return saved;


    }

    public Transaction saveTransaction(Transaction transaction){
        return transactionRepository.save(transaction);
    }

    public List<Transaction> getTransactionsByPlan(Long planId){
        return transactionRepository.findByPlanId(planId);

    }

    public List<Transaction> geTransactionsByCategory(Long categoryId){

        return transactionRepository.findByCategoryId(categoryId);

    }

    public List<Transaction> getAllTransactions(){
        return transactionRepository.findAll();
    }

    public Optional<Transaction> getTransactionById(Long id){

        return transactionRepository.findById(id);
    }


    
}
