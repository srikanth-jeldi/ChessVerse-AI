package com.epitomehub.chessverse.api;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
class WebConfiguration implements WebMvcConfigurer {
    private final String[] allowedOrigins;

    WebConfiguration(
            @Value("${chessverse.web.allowed-origin-patterns:http://localhost:*,http://127.0.0.1:*}")
            String allowedOriginPatterns) {
        this.allowedOrigins = allowedOriginPatterns.split(",");
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOriginPatterns(allowedOrigins)
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*");
    }
}
