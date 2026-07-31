package com.epitomehub.chessverse;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class ChessVerseApplication {

    public static void main(String[] args) {
        SpringApplication.run(ChessVerseApplication.class, args);
    }
}

