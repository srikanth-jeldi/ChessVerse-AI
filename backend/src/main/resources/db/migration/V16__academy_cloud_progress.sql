create table player_completed_academy_lesson (
    player_id uuid not null references player_cloud_progress(player_id) on delete cascade,
    lesson_id varchar(64) not null,
    primary key (player_id, lesson_id)
);
