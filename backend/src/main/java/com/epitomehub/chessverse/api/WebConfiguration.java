package com.epitomehub.chessverse.api;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
class WebConfiguration implements WebMvcConfigurer {
    private final String[] allowedOrigins;
    private final GlobalRateLimitInterceptor rateLimit;

    WebConfiguration(
            @Value("${chessverse.web.allowed-origin-patterns:http://localhost:*,http://127.0.0.1:*}")
            String allowedOriginPatterns,
            GlobalRateLimitInterceptor rateLimit) {
        this.allowedOrigins = allowedOriginPatterns.split(",");
        this.rateLimit = rateLimit;
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOriginPatterns(allowedOrigins)
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*");
    }

    @Override
    public void addInterceptors(org.springframework.web.servlet.config.annotation.InterceptorRegistry registry) {
        registry.addInterceptor(rateLimit).addPathPatterns("/api/**");
    }
}
