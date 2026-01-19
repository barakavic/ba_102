package com.example.budgeting_app.features.goals;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Table(name = "goals")
public class Goal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name; // e.g., "PS5" or "Emergency Fund"

    private BigDecimal targetAmount; // What the user thinks it costs

    private BigDecimal currentAmount; // What they have saved

    private LocalDate deadline;

    // --- Market Intelligence Fields ---

    private BigDecimal marketPrice; // The real price from Hawkeye

    private String trackingUrl; // Link to the product

    private LocalDateTime lastChecked; // When we last scraped

    private String marketStatus; // "BUY_NOW", "WAIT", "UNAVAILABLE"

    private String currency; // "KES", "USD"

    private String rationale; // "Save 4k more..."
}
