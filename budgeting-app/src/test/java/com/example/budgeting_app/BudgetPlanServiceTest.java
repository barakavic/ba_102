package com.example.budgeting_app;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.time.LocalDate;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import com.example.budgeting_app.entity.BudgetPlan;
import com.example.budgeting_app.service.BudgetPlanService;

public class BudgetPlanServiceTest {

    private BudgetPlanService service;
    

    @BeforeEach
    void setUp(){
        service = new BudgetPlanService(null);

    }
    @Test
    void testCreatePlan(){
        BudgetPlan plan = service.createPlan("Test", LocalDate.now(), LocalDate.now().plusDays(30));
        assertEquals("Test", plan.getName());
    }

    
}
