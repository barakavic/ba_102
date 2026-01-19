package com.example.budgeting_app.features.goals;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class GoalService {

    private final GoalRepository goalRepository;
    private RestTemplate restTemplate = new RestTemplate();

    @Value("${hawkeye.service.url:http://localhost:8000/api/v1}")
    private String hawkeyeUrl;

    public Goal createGoal(Goal goal) {
        if (goal.getCurrentAmount() == null) {
            goal.setCurrentAmount(BigDecimal.ZERO);
        }
        return goalRepository.save(goal);
    }

    public List<Goal> getAllGoals() {
        return goalRepository.findAll();
    }

    public Goal analyzeGoal(Long goalId) {
        Goal goal = goalRepository.findById(goalId)
                .orElseThrow(() -> new RuntimeException("Goal not found"));

        try {
            // 1. Prepare Request for Hawkeye
            // We need to send { "product_name": "...", "user_context": { ... } }
            // For now, we mock the user context or fetch it from a UserProfile service if
            // it existed.
            // Let's assume a default context for this MVP step.

            HawkeyeRequest request = new HawkeyeRequest();
            request.setProduct_name(goal.getName());
            request.setUser_context(new UserFinancialContext(
                    new BigDecimal("50000"), // Mock Balance
                    new BigDecimal("5000"), // Mock Safe-to-spend
                    new BigDecimal("40000") // Mock Commitments
            ));

            // 2. Call Python API
            String url = hawkeyeUrl + "/analyze";
            log.info("Calling Hawkeye at: {}", url);

            HawkeyeResponse response = restTemplate.postForObject(url, request, HawkeyeResponse.class);

            // 3. Update Goal with Intelligence
            if (response != null) {
                goal.setMarketPrice(response.getConsensus_price());
                goal.setCurrency(response.getCurrency());
                goal.setMarketStatus(response.getWait_risk().equals("LOW") ? "BUY_NOW" : "WAIT");
                goal.setLastChecked(LocalDateTime.now());
                goal.setTrackingUrl(response.getBest_offer_url()); // Using specific URL

                // Join rationale list into a string
                String rationaleText = "";
                if (response.getBest_offer_source() != null) {
                    rationaleText += "Found at " + response.getBest_offer_source() + ". ";
                }
                if (response.getRationale() != null) {
                    rationaleText += String.join(". ", response.getRationale());
                }
                goal.setRationale(rationaleText);

                return goalRepository.save(goal);
            }

        } catch (Exception e) {
            log.error("Failed to analyze goal with Hawkeye", e);
            // Don't crash, just return the goal as is (maybe set status to ERROR)
        }

        return goal;
    }

    // DTOs for Hawkeye Communication (Inner classes for simplicity)
    @Data
    public static class HawkeyeRequest {
        private String product_name;
        private UserFinancialContext user_context;
    }

    @Data
    @AllArgsConstructor
    public static class UserFinancialContext {
        private BigDecimal liquid_balance;
        private BigDecimal safe_to_spend_monthly;
        private BigDecimal existing_commitments;
    }

    @Data
    public static class HawkeyeResponse {
        private String product_id;
        private BigDecimal consensus_price;
        private String currency;
        private String wait_risk;
        private List<String> rationale;
        private String best_offer_source;
        private String best_offer_url;
    }
}
