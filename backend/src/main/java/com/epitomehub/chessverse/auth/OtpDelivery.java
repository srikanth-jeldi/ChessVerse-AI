package com.epitomehub.chessverse.auth;

interface OtpDelivery {
    void sendVerificationCode(String email, String displayName, String code);

    void sendPasswordResetCode(String email, String displayName, String code);
}
