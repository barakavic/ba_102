package com.example.budgeting_app.service;

import com.example.budgeting_app.repository.BudgetCategoryRepository;
import com.example.budgeting_app.repository.TransactionRepository;
import com.example.budgeting_app.entity.BudgetCategory;
import com.example.budgeting_app.entity.BudgetPlan;
import com.example.budgeting_app.entity.Transaction;
import com.example.budgeting_app.exceptions.ResourceNotFoundException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;


@Service
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final BudgetCategoryRepository categoryRepository;

    private static final Logger logger = LoggerFactory.getLogger(TransactionService.class);

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

        double currentSpent = category.getSpentAmount() !=null ? category.getSpentAmount() : 0.0;
        category.setSpentAmount(currentSpent+amount);
        categoryRepository.save(category);

        return saved;


    }


    public List<Transaction> getTransactionsByPlan(Long planId){
        return transactionRepository.findByPlanId(planId);

    }

    public List<Transaction> getTransactionsByCategory(Long categoryId){

        return transactionRepository.findByCategoryId(categoryId);

    }

    public List<Transaction> getAllTransactions(){
        return transactionRepository.findAll();
    }

    public Optional<Transaction> getTransactionById(Long id){

        return transactionRepository.findById(id);
    }

    public void deleteTransaction(Long id){
        Optional<Transaction> optionalTransaction = transactionRepository.findById(id);

        if(optionalTransaction.isPresent()){
            Transaction transaction = optionalTransaction.get();
            BudgetCategory category = transaction.getCategory();

            if (category != null){
                double currentSpent = category.getSpentAmount() != null ? category.getSpentAmount(): 0.0;
                category.setSpentAmount(Math.max(0, currentSpent - transaction.getAmount()));
                categoryRepository.save(category);

            }


            transactionRepository.delete(transaction);
            logger.info("Transaction with id {} has been deleted", id);


        }
        else{
            logger.error("Transaction with id {} doesnt exist", id);
            throw new ResourceNotFoundException("Transaction not found with id: "+ id);
        }

    }


    
}
