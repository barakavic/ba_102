package com.example.budgeting_app.features.goals;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/goals")
@RequiredArgsConstructor
public class GoalController {

    private final GoalService goalService;

    @PostMapping
    public ResponseEntity<Goal> createGoal(@RequestBody Goal goal) {
        return ResponseEntity.ok(goalService.createGoal(goal));
    }

    @GetMapping
    public ResponseEntity<List<Goal>> getAllGoals() {
        return ResponseEntity.ok(goalService.getAllGoals());
    }

    @PostMapping("/{id}/analyze")
    public ResponseEntity<Goal> analyzeGoal(@PathVariable Long id) {
        return ResponseEntity.ok(goalService.analyzeGoal(id));
    }
}
