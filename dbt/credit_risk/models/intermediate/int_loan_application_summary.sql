with applications as (
    select * from {{ ref('stg_loan_applications') }}
),

products as (
    select * from {{ ref('stg_loan_products') }}
),

joined as (
    select
        a.application_id,
        a.customer_id,
        a.loan_status,
        a.requested_amount,
        a.credit_score,
        a.debt_to_income_ratio,
        a.employment_status,
        a.applied_at,
        a.reviewed_at,
        p.product_name,
        p.product_type,
        p.base_interest_rate,
        p.risk_category,
        p.min_amount,
        p.max_amount,
        case
            when a.requested_amount < p.min_amount then 'below_minimum'
            when a.requested_amount > p.max_amount then 'above_maximum'
            else 'within_range'
        end                                         as amount_eligibility,
        round(
            (a.requested_amount * p.base_interest_rate / 100)::numeric, 2
        )                                           as estimated_annual_interest
    from applications a
    left join products p
        on a.product_id = p.product_id
)

select * from joined