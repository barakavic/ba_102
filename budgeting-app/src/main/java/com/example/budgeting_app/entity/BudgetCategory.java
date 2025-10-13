package com.example.budgeting_app.entity;

import java.util.ArrayList;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonBackReference;
import com.fasterxml.jackson.annotation.JsonManagedReference;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import lombok.Data;

@Entity
@Data
@Table
public class BudgetCategory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Double spentAmount = 0.0;

    private Double limitAmount;

    @Column (unique =true)
    private String name;

    @OneToMany(mappedBy = "category", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonManagedReference("category-transaction")
    private List<Transaction> transactions = new ArrayList<>();

    @ManyToOne
    @JoinColumn(name = "plan_id")
    @JsonBackReference("plan-category")
    private BudgetPlan plan;

  

    public Double getSpentAmount(){
        if(transactions == null || transactions.isEmpty()) return 0.0;
        return transactions.stream()
        .mapToDouble(Transaction::getAmount)
        .sum();
    }

    public CategoryStatus getStatus(){
        if (limitAmount == null || limitAmount == 0)  {
            return CategoryStatus.NORMAL;
            
        }

        double ratio = spentAmount/limitAmount;

        if (ratio>1) return CategoryStatus.OVERSPENT;
        else if (ratio>0.8) return CategoryStatus.WARNING;
        else return CategoryStatus.NORMAL;


    }



}
