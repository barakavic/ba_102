package com.example.budgeting_app.features.plans;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.time.LocalDate;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

public class PlanServiceTest {

    private PlanRepository planRepository;
    private PlanService planService;

    @BeforeEach
    void setUp() {
        planRepository = mock(PlanRepository.class);
        planService = new PlanService(planRepository);
    }

    @Test
    void testCreatePlan() {
        Plan plan = Plan.builder()
                .name("Test")
                .startDate(LocalDate.now())
                .endDate(LocalDate.now().plusDays(30))
                .build();
        when(planRepository.save(any(Plan.class))).thenReturn(plan);

        Plan result = planService.createPlan(plan);
        assertEquals("Test", result.getName());
    }
}
