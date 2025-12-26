package com.example.budgeting_app.features.transactions;

import com.example.budgeting_app.exceptions.ResourceNotFoundException;
import com.example.budgeting_app.features.categories.Category;
import com.example.budgeting_app.features.categories.CategoryRepository;
import com.example.budgeting_app.features.plans.Plan;
import com.example.budgeting_app.features.plans.PlanRepository;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.List;

@Service
public class TransactionService {

    private static final Logger logger = LoggerFactory.getLogger(TransactionService.class);
    private final TransactionRepository transactionRepository;
    private final CategoryRepository categoryRepository;
    private final PlanRepository planRepository;

    public TransactionService(TransactionRepository transactionRepository,
            CategoryRepository categoryRepository,
            PlanRepository planRepository) {
        this.transactionRepository = transactionRepository;
        this.categoryRepository = categoryRepository;
        this.planRepository = planRepository;
    }

    public Transaction addTransaction(Transaction transaction) {
        return transactionRepository.save(transaction);
    }

    public List<Transaction> getAllTransactions() {
        return transactionRepository.findAll();
    }

    public Transaction getTransactionById(Long id) {
        return transactionRepository.findById(id)
                .orElseThrow(() -> {
                    logger.error("Transaction not found with id: {}", id);
                    return new ResourceNotFoundException("Transaction not found with id: " + id);
                });
    }

    public List<Transaction> getTransactionsByPlan(Long planId) {
        return transactionRepository.findByPlanId(planId);
    }

    public List<Transaction> getTransactionsByCategory(Long categoryId) {
        return transactionRepository.findByCategoryId(categoryId);
    }

    public void deleteTransaction(Long id) {
        logger.info("Attempting to delete transaction with id: {}", id);
        Transaction transaction = getTransactionById(id);
        transactionRepository.delete(transaction);
        logger.info("Successfully deleted transaction with id: {}", id);
    }

    public Transaction syncTransaction(Transaction transaction) {
        // Check for duplicate M-Pesa reference
        if (transaction.getMpesaReference() != null) {
            var existing = transactionRepository.findByMpesaReference(transaction.getMpesaReference());
            if (existing.isPresent()) {
                return existing.get(); // Already exists, don't duplicate
            }
        }

        if (transaction.getClientId() != null) {
            return transactionRepository.findByClientId(transaction.getClientId())
                    .map(existing -> {
                        updateFields(existing, transaction);
                        return transactionRepository.save(existing);
                    })
                    .orElseGet(() -> transactionRepository.save(transaction));
        }
        return transactionRepository.save(transaction);
    }

    private void updateFields(Transaction existing, Transaction updated) {
        existing.setAmount(updated.getAmount());
        existing.setDescription(updated.getDescription());
        existing.setDate(updated.getDate());
        existing.setType(updated.getType());
        existing.setVendor(updated.getVendor());
        existing.setMpesaReference(updated.getMpesaReference());
        existing.setBalance(updated.getBalance());
        existing.setRawSmsMessage(updated.getRawSmsMessage());
        existing.setPlan(updated.getPlan());
        existing.setCategory(updated.getCategory());
    }
}
