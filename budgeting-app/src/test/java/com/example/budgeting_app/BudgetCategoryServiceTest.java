package com.example.budgeting_app;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import com.example.budgeting_app.entity.BudgetCategory;
import com.example.budgeting_app.repository.BudgetCategoryRepository;
import com.example.budgeting_app.repository.BudgetPlanRepository;
import com.example.budgeting_app.service.BudgetCategoryService;

public class BudgetCategoryServiceTest {

    private BudgetCategoryRepository categoryRepository;
    private BudgetCategoryService categoryService;

    @BeforeEach
    void setUp() {
        categoryRepository = mock(BudgetCategoryRepository.class);
        BudgetPlanRepository planRepository = mock(com.example.budgeting_app.repository.BudgetPlanRepository.class);
        categoryService = new BudgetCategoryService(categoryRepository, planRepository);

    }

    @Test
    void testCreateCategory() {

        BudgetCategory category = new BudgetCategory();
        category.setName("Food");
        when(categoryRepository.save(any(BudgetCategory.class))).thenReturn(category);

        BudgetCategory result = categoryService.createCategory("Food");

        assertEquals("Food", result.getName());
        verify(categoryRepository, times(1)).save(any(BudgetCategory.class));
    }

}
