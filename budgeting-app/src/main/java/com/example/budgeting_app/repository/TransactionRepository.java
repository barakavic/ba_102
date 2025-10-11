package com.example.budgeting_app.repository;

import com.example.budgeting_app.entity.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    
    List<Transaction> findByPlanId(Long planId);

    List<Transaction> findByCategoryId(Long categoryId);

    // @Query("SELECT COALESCE(SUM(t.amount), 0) FROM Transaction t where t.category.id = ")
}
