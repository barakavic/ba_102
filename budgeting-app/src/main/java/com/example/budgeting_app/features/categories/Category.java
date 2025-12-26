package com.example.budgeting_app.features.categories;

import java.util.ArrayList;
import java.util.List;

import com.example.budgeting_app.features.transactions.Transaction;
import com.fasterxml.jackson.annotation.JsonManagedReference;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Table(name = "categories")
public class Category {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String name;

    @Builder.Default
    private Double limitAmount = 0.0;

    private String icon;

    private String color;

    private Long parentId;

    private String clientId; // For sync-safety

    @OneToMany(mappedBy = "category", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonManagedReference("category-transaction")
    @Builder.Default
    private List<Transaction> transactions = new ArrayList<>();

    public Double getSpentAmount() {
        if (transactions == null || transactions.isEmpty())
            return 0.0;
        return transactions.stream()
                .mapToDouble(t -> t.getAmount() != null ? t.getAmount() : 0.0)
                .sum();
    }

    public CategoryStatus getStatus() {
        if (limitAmount == null || limitAmount == 0) {
            return CategoryStatus.NORMAL;
        }

        double spent = getSpentAmount();
        double ratio = spent / limitAmount;

        if (ratio > 1)
            return CategoryStatus.OVERSPENT;
        else if (ratio > 0.8)
            return CategoryStatus.WARNING;
        else
            return CategoryStatus.NORMAL;
    }
}
