package com.epitomehub.chessverse.auth;

interface SmsOtpDelivery {
    void sendVerificationCode(String phone, String displayName, String code);
}
