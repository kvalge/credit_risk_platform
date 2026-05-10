with customer_risk as (
    select * from {{ ref('int_customer_risk_profile') }}
),

transactions as (
    select * from {{ ref('int_customer_transactions_summary') }}
),

loan_applications as (
    select * from {{ ref('int_loan_application_summary') }}
),

latest_application as (
    select distinct on (customer_id)
        customer_id,
        product_name,
        product_type,
        loan_status                                         as latest_loan_status,
        requested_amount                                    as latest_requested_amount,
        applied_at                                          as latest_applied_at
    from loan_applications
    order by customer_id, applied_at desc
),

final as (
    select
        cr.customer_id,
        cr.full_name,
        cr.age,
        cr.employment_status,
        cr.annual_income,
        cr.city,
        cr.country,
        cr.credit_band,
        cr.risk_level,
        cr.recommended_action,
        cr.avg_credit_score,
        cr.avg_debt_to_income_ratio,
        cr.total_applications,
        cr.total_approved,
        cr.total_defaults,
        t.total_transactions,
        t.total_deposits,
        t.total_withdrawals,
        t.total_failed_transactions,
        t.avg_transaction_amount,
        t.last_transaction_at,
        la.product_name                                     as latest_product,
        la.product_type                                     as latest_product_type,
        la.latest_loan_status,
        la.latest_requested_amount,
        la.latest_applied_at
    from customer_risk cr
    left join transactions t
        on cr.customer_id = t.customer_id
    left join latest_application la
        on cr.customer_id = la.customer_id
)

select * from final