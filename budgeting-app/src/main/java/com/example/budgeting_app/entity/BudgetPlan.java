package com.example.budgeting_app.entity;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonManagedReference;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

@Entity
@Table(name = "budget_plans")
public class BudgetPlan {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)

    private Long id;

    private String name;

    private LocalDate startDate;

    private LocalDate endDate;

    @Enumerated(EnumType.STRING)
    private PlanStatus status;

    @OneToMany(mappedBy = "plan", cascade = CascadeType.ALL)
    @JsonManagedReference("plan-transaction")
    private List<Transaction> transactions = new ArrayList<>();

    public Long getId(){return id;}
    public void setId(Long id){this.id = id;}

    public String getName(){return name;}
    public void setName(String name){this.name = name;}

    public LocalDate getStartDate(){return startDate;}
    public void setStartDate(LocalDate startDate){this.startDate=startDate;}

    public LocalDate getEndDate(){return endDate;}
    public void setEndDate(LocalDate endDate){this.endDate=endDate;}

    public List<Transaction> getTransactions(){return transactions;}
    public void setTransactions(List<Transaction> transactions){this.transactions=transactions;}

    public PlanStatus getStatus(){return status;}
    public void setStatus(PlanStatus status){this.status = status;}

    // Ensures the status is set to active by default
    @PrePersist
    public void prePersist(){
        if (status == null){
            status = PlanStatus.ACTIVE;
        }
    }



    


  


}
