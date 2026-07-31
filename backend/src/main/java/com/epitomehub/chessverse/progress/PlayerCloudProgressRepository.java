package com.epitomehub.chessverse.progress;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface PlayerCloudProgressRepository extends JpaRepository<PlayerCloudProgress, UUID> {
}
