package com.example.budgeting_app.features.transactions;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    List<Transaction> findByPlanId(Long planId);

    List<Transaction> findByCategoryId(Long categoryId);

    Optional<Transaction> findByClientId(String clientId);

    Optional<Transaction> findByMpesaReference(String mpesaReference);
}
