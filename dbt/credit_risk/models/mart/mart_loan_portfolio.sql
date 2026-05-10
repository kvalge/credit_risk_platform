with loan_summary as (
    select * from {{ ref('int_loan_application_summary') }}
),

final as (
    select
        product_type,
        risk_category,
        count(*)                                            as total_applications,
        sum(case when loan_status = 'approved' 
            then 1 else 0 end)                              as total_approved,
        sum(case when loan_status = 'rejected' 
            then 1 else 0 end)                              as total_rejected,
        sum(case when loan_status = 'defaulted' 
            then 1 else 0 end)                              as total_defaulted,
        sum(case when loan_status = 'disbursed' 
            then 1 else 0 end)                              as total_disbursed,
        round(avg(requested_amount)::numeric, 2)            as avg_requested_amount,
        round(sum(requested_amount)::numeric, 2)            as total_requested_amount,
        round(avg(credit_score)::numeric, 2)                as avg_credit_score,
        round(avg(debt_to_income_ratio)::numeric, 4)        as avg_debt_to_income_ratio,
        round(avg(base_interest_rate)::numeric, 2)          as avg_interest_rate,
        round(sum(estimated_annual_interest)::numeric, 2)   as total_estimated_interest
    from loan_summary
    group by product_type, risk_category
)

select * from final