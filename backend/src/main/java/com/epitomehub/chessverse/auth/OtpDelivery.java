package com.epitomehub.chessverse.auth;

interface OtpDelivery {
    void sendVerificationCode(String email, String displayName, String code);

    void sendPasswordResetCode(String email, String displayName, String code);

    default void sendSecurityNotice(
            String email, String displayName, String subject, String message) {
        // Optional for local/test delivery implementations.
    }
}
