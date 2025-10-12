package com.example.budgeting_app.entity;

import java.time.LocalDateTime;

import com.fasterxml.jackson.annotation.JsonBackReference;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Data;


@Entity
@Table(name = "transactions")
@Data
public class Transaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)

    private Long id;

    private Double amount;

    private String description;

    private LocalDateTime date;

    

    // Changed to persistence @PrePersist to ensure date is set right before saving to DB
    @PrePersist
    protected void onCreate(){
        date = LocalDateTime.now();
    }

    @ManyToOne
    @JoinColumn(name = "plan_id")
    @JsonBackReference("plan-transaction")
    private BudgetPlan plan;

    @ManyToOne
    @JoinColumn(name = "category_id")
    @JsonBackReference("category-transaction")
    private BudgetCategory category;




    
}
