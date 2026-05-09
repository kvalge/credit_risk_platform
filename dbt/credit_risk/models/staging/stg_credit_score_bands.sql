with source as (
    select * from {{ ref('credit_score_bands') }}
),

renamed as (
    select
        band_id,
        band_name,
        score_min,
        score_max,
        score_max - score_min             as score_range,
        risk_level,
        description,
        default_probability,
        recommended_action
    from source
)

select * from renamed