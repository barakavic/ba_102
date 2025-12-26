package com.example.budgeting_app.features.transactions;

import java.time.LocalDateTime;

import com.example.budgeting_app.features.categories.Category;
import com.example.budgeting_app.features.plans.Plan;
import com.fasterxml.jackson.annotation.JsonBackReference;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
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
@Table(name = "transactions")
public class Transaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Double amount;

    private String description;

    private LocalDateTime date;

    @Builder.Default
    private String type = "outbound";

    private String vendor;

    @Column(unique = true)
    private String mpesaReference;

    private Double balance;

    @Column(columnDefinition = "TEXT")
    private String rawSmsMessage;

    private String clientId; // For sync-safety

    @ManyToOne
    @JoinColumn(name = "plan_id")
    @JsonBackReference("plan-transaction")
    private Plan plan;

    @ManyToOne
    @JoinColumn(name = "category_id")
    @JsonBackReference("category-transaction")
    private Category category;

    @PrePersist
    protected void onCreate() {
        if (date == null) {
            date = LocalDateTime.now();
        }
    }
}
