with source as (
    select * from {{ ref('loan_products') }}
),

renamed as (
    select
        product_id,
        product_name,
        product_type,
        min_amount,
        max_amount,
        min_term_months,
        max_term_months,
        base_interest_rate,
        risk_category,
        max_amount - min_amount           as amount_range
    from source
)

select * from renamed