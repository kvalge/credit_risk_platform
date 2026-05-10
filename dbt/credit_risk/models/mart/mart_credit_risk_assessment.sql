with customer_risk as (
    select * from {{ ref('int_customer_risk_profile') }}
),

transactions as (
    select * from {{ ref('int_customer_transactions_summary') }}
),

final as (
    select
        cr.customer_id,
        cr.full_name,
        cr.age,
        cr.country,
        cr.city,
        cr.employment_status,
        cr.annual_income,
        cr.avg_credit_score,
        cr.avg_debt_to_income_ratio,
        cr.credit_band,
        cr.risk_level,
        cr.recommended_action,
        cr.default_probability,
        cr.total_applications,
        cr.total_defaults,
        cr.total_approved,
        t.total_transactions,
        t.total_deposits,
        t.total_withdrawals,
        t.total_payments,
        t.total_failed_transactions,
        t.last_transaction_at,
        case
            when cr.risk_level = 'very_high'                then 1
            when cr.risk_level = 'high'                     then 2
            when cr.risk_level = 'medium'                   then 3
            when cr.risk_level = 'low'                      then 4
            when cr.risk_level = 'very_low'                 then 5
            else 0
        end                                                 as risk_score,
        case
            when cr.total_defaults > 0                      then true
            else false
        end                                                 as has_defaults,
        case
            when cr.avg_debt_to_income_ratio > 0.5          then 'high_debt'
            when cr.avg_debt_to_income_ratio > 0.3          then 'medium_debt'
            else 'low_debt'
        end                                                 as debt_category
    from customer_risk cr
    left join transactions t
        on cr.customer_id = t.customer_id
)

select * from final