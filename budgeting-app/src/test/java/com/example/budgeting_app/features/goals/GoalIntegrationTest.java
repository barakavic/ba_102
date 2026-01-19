package com.example.budgeting_app.features.goals;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import java.math.BigDecimal;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
public class GoalIntegrationTest {

    @Autowired
    private GoalService goalService;

    @Test
    public void testGoalAnalysisFlow() {
        // 1. Create a Goal
        Goal goal = Goal.builder()
                .name("3D Printer")
                .targetAmount(new BigDecimal("60000"))
                .currentAmount(new BigDecimal("5000"))
                .build();

        Goal savedGoal = goalService.createGoal(goal);
        assertNotNull(savedGoal.getId());

        // 2. Analyze Goal (Calls Python Hawkeye)
        // Note: Python Hawkeye must be running on port 8000 for this to pass
        Goal analyzedGoal = goalService.analyzeGoal(savedGoal.getId());

        // 3. Verify Intelligence
        System.out.println("--- Analysis Result ---");
        System.out.println("Product Found (URL/ID): " + analyzedGoal.getTrackingUrl());
        System.out.println("Market Price: " + analyzedGoal.getMarketPrice());
        System.out.println("Status: " + analyzedGoal.getMarketStatus());
        System.out.println("Rationale: " + analyzedGoal.getRationale());

        assertNotNull(analyzedGoal.getMarketPrice(), "Market price should be populated");
        assertNotNull(analyzedGoal.getMarketStatus(), "Market status should be populated");

        // We expect "WAIT" or "BUY_NOW"
        // And a price around 14k-15k
    }
}
