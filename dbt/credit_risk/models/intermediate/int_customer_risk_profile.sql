with customers as (
    select * from {{ ref('stg_customers') }}
),

credit_bands as (
    select * from {{ ref('stg_credit_score_bands') }}
),

loan_applications as (
    select
        customer_id,
        avg(credit_score)                           as avg_credit_score,
        max(credit_score)                           as max_credit_score,
        min(credit_score)                           as min_credit_score,
        avg(debt_to_income_ratio)                   as avg_debt_to_income_ratio,
        count(*)                                    as total_applications,
        sum(case when loan_status = 'defaulted' 
            then 1 else 0 end)                      as total_defaults,
        sum(case when loan_status = 'approved' 
            then 1 else 0 end)                      as total_approved
    from {{ ref('stg_loan_applications') }}
    group by customer_id
),

joined as (
    select
        c.customer_id,
        c.full_name,
        c.age,
        c.country,
        c.city,
        c.employment_status,
        c.annual_income,
        la.avg_credit_score,
        la.avg_debt_to_income_ratio,
        la.total_applications,
        la.total_defaults,
        la.total_approved,
        cb.band_name                                as credit_band,
        cb.risk_level,
        cb.recommended_action,
        cb.default_probability
    from customers c
    left join loan_applications la
        on c.customer_id = la.customer_id
    left join credit_bands cb
        on la.avg_credit_score between cb.score_min and cb.score_max
)

select * from joined