with source as (
    select * from {{ source('credit_risk_raw', 'transactions') }}
),

renamed as (
    select
        transaction_id,
        customer_id,
        transaction_type,
        amount,
        balance_after,
        currency,
        status,
        merchant,
        description,
        created_at::timestamp             as created_at
    from source
)

select * from renamed