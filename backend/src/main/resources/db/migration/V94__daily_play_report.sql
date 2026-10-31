create table daily_play_report_delivery (
    report_date date primary key,
    sent_at timestamp with time zone
);
create index if not exists idx_product_activity_report_time on product_analytics_event(occurred_at,player_id);
