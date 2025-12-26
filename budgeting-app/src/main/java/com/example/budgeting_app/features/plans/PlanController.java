package com.example.budgeting_app.features.plans;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

@RestController
@RequestMapping("/api/plans")
public class PlanController {

    private static final Logger logger = LoggerFactory.getLogger(PlanController.class);
    private final PlanService planService;

    public PlanController(PlanService planService) {
        this.planService = planService;
    }

    @PostMapping
    public ResponseEntity<Plan> createPlan(@RequestBody Plan plan) {
        Plan saved = planService.savePlan(plan);
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    @GetMapping
    public ResponseEntity<List<Plan>> getAllPlans() {
        return ResponseEntity.ok(planService.getAllPlans());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Plan> getPlanById(@PathVariable Long id) {
        return ResponseEntity.ok(planService.getPlanById(id));
    }

    @GetMapping("/status")
    public ResponseEntity<List<Plan>> getPlansByStatus(@RequestParam(required = false) PlanStatus status) {
        if (status == null) {
            status = PlanStatus.ACTIVE;
        }
        return ResponseEntity.ok(planService.getPlansByStatus(status));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<Plan> updatePlanStatus(@PathVariable Long id, @RequestParam PlanStatus status) {
        return ResponseEntity.ok(planService.updatePlanStatus(id, status));
    }

    @PostMapping("/sync")
    public ResponseEntity<Plan> syncPlan(@RequestBody Plan plan) {
        return ResponseEntity.ok(planService.syncPlan(plan));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePlan(@PathVariable Long id) {
        planService.deletePlan(id);
        logger.info("Plan with ID {} deleted", id);
        return ResponseEntity.noContent().build();
    }
}
