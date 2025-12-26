package com.example.budgeting_app.features.plans;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.List;

@Repository
public interface PlanRepository extends JpaRepository<Plan, Long> {
    Optional<Plan> findByClientId(String clientId);

    List<Plan> findByStatus(PlanStatus status);
}
