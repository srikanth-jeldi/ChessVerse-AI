package com.epitomehub.chessverse.auth;

import java.util.UUID;

public record AuthenticatedPlayer(
        UUID id,
        String username,
        String displayName,
        String photoUrl) {
}
