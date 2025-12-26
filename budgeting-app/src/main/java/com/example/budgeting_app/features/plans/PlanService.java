package com.example.budgeting_app.features.plans;

import com.example.budgeting_app.exceptions.ResourceNotFoundException;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.List;

@Service
public class PlanService {

    private static final Logger logger = LoggerFactory.getLogger(PlanService.class);
    private final PlanRepository planRepository;

    public PlanService(PlanRepository planRepository) {
        this.planRepository = planRepository;
    }

    public Plan createPlan(Plan plan) {
        return planRepository.save(plan);
    }

    public Plan savePlan(Plan plan) {
        return planRepository.save(plan);
    }

    public List<Plan> getAllPlans() {
        return planRepository.findAll();
    }

    public Plan getPlanById(Long id) {
        return planRepository.findById(id)
                .orElseThrow(() -> {
                    logger.error("Plan not found with id: {}", id);
                    return new ResourceNotFoundException("Plan not found with id: " + id);
                });
    }

    public List<Plan> getPlansByStatus(PlanStatus status) {
        return planRepository.findByStatus(status);
    }

    public Plan updatePlanStatus(Long id, PlanStatus status) {
        Plan plan = getPlanById(id);
        plan.setStatus(status);
        return planRepository.save(plan);
    }

    public void deletePlan(Long id) {
        logger.info("Attempting to delete plan with id: {}", id);
        Plan plan = getPlanById(id);
        planRepository.delete(plan);
        logger.info("Successfully deleted plan with id: {}", id);
    }

    public Plan syncPlan(Plan plan) {
        if (plan.getClientId() != null) {
            return planRepository.findByClientId(plan.getClientId())
                    .map(existing -> {
                        existing.setName(plan.getName());
                        existing.setStartDate(plan.getStartDate());
                        existing.setEndDate(plan.getEndDate());
                        existing.setStatus(plan.getStatus());
                        existing.setLimitAmount(plan.getLimitAmount());
                        existing.setPlanType(plan.getPlanType());
                        return planRepository.save(existing);
                    })
                    .orElseGet(() -> planRepository.save(plan));
        }
        return planRepository.save(plan);
    }
}
