package com.example.budgeting_app.features.plans;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import com.example.budgeting_app.features.transactions.Transaction;
import com.fasterxml.jackson.annotation.JsonManagedReference;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
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
@Table(name = "plans")
public class Plan {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    private LocalDate startDate;

    private LocalDate endDate;

    @Enumerated(EnumType.STRING)
    private PlanStatus status;

    @Builder.Default
    private Double limitAmount = 0.0;

    @Builder.Default
    private String planType = "monthly";

    private String clientId; // For sync-safety

    @OneToMany(mappedBy = "plan", cascade = CascadeType.ALL)
    @JsonManagedReference("plan-transaction")
    @Builder.Default
    private List<Transaction> transactions = new ArrayList<>();

    @PrePersist
    public void prePersist() {
        if (status == null) {
            status = PlanStatus.ACTIVE;
        }
    }
}
