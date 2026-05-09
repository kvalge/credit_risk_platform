with source as (
    select * from {{ ref('customers') }}
),

renamed as (
    select
        customer_id,
        first_name,
        last_name,
        first_name || ' ' || last_name   as full_name,
        lower(email)                      as email,
        phone,
        date_of_birth::date               as date_of_birth,
        date_part('year', age(date_of_birth::date)) as age,
        country,
        city,
        employment_status,
        annual_income,
        created_at::timestamp             as created_at
    from source
)

select * from renamed