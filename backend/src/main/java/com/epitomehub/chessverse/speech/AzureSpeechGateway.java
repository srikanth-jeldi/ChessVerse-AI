package com.epitomehub.chessverse.speech;

interface AzureSpeechGateway {
    byte[] synthesize(String ssml);
}
