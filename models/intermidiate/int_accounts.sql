with accounts as (
    select * from {{ ref('stg_accounts') }}
    -- Bu anchor. Hamma narsa shunga bog'lanadi.
),

product as (
    select * from {{ ref('stg_product_companies') }}
    -- accounts.id = product.account_id
    -- To'g'ri bog'lanadi, agregatsiya shart emas (1-to-1)
),

billing as (
    select * from {{ ref('stg_subscriptions') }}
    -- accounts.id = subscriptions.account_id
    -- 1-to-1 deb hisoblaymiz (bir accountda bir subscription)
),

ticket_summary as (
    --  Bu yerda avval agregat, keyin JOIN
    -- Chunki bir accountda ko'p ticket bo'ladi (1-to-many)
    select
        account_id,
        count(*)                                    as total_tickets,
        count(*) filter (where status = 'open')     as open_tickets,
        count(*) filter (where priority = 'urgent') as urgent_tickets
    from {{ ref('stg_tickets') }}
    group by account_id
)

select
    -- Anchor dan
    a.id                as account_id,
    a.name              as account_name,
    a.domain,
    a.industry,
    a.country,
    a.owner_id,

    -- Product dan (1-to-1, to'g'ri JOIN)
    p.plan              as product_plan,
    p.seat_count,

    -- Billing dan (1-to-1, to'g'ri JOIN)
    s.mrr,
    s.status            as subscription_status,
    s.is_past_due,

    -- Support dan (agregatlangan, xavfsiz)
    coalesce(t.total_tickets, 0)   as total_tickets,
    coalesce(t.open_tickets, 0)    as open_tickets,
    coalesce(t.urgent_tickets, 0)  as urgent_tickets

from accounts a
left join product        p on p.account_id = a.id
left join billing        s on s.account_id = a.id
left join ticket_summary t on t.account_id = a.id
