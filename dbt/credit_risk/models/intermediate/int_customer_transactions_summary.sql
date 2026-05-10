with transactions as (
    select * from {{ ref('stg_transactions') }}
),

summary as (
    select
        customer_id,
        count(*)                                        as total_transactions,
        sum(amount)                                     as total_amount,
        avg(amount)                                     as avg_transaction_amount,
        max(amount)                                     as max_transaction_amount,
        sum(case when transaction_type = 'deposit' 
            then amount else 0 end)                     as total_deposits,
        sum(case when transaction_type = 'withdrawal' 
            then amount else 0 end)                     as total_withdrawals,
        sum(case when transaction_type = 'payment' 
            then amount else 0 end)                     as total_payments,
        sum(case when status = 'failed' 
            then 1 else 0 end)                          as total_failed_transactions,
        max(created_at)                                 as last_transaction_at,
        min(created_at)                                 as first_transaction_at
    from transactions
    group by customer_id
)

select * from summary