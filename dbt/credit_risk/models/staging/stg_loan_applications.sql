with source as (
    select * from {{ source('credit_risk_raw', 'loan_applications') }}
),

renamed as (
    select
        application_id,
        customer_id,
        product_id,
        requested_amount,
        credit_score,
        annual_income,
        debt_to_income_ratio,
        employment_status,
        loan_status,
        applied_at::timestamp             as applied_at,
        reviewed_at::timestamp            as reviewed_at
    from source
)

select * from renamed