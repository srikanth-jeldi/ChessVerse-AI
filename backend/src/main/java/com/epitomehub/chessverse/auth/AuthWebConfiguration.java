package com.epitomehub.chessverse.auth;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
class AuthWebConfiguration implements WebMvcConfigurer {
    private final AuthRateLimitInterceptor rateLimitInterceptor;

    AuthWebConfiguration(AuthRateLimitInterceptor rateLimitInterceptor) {
        this.rateLimitInterceptor = rateLimitInterceptor;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(rateLimitInterceptor).addPathPatterns("/api/auth/**");
    }
}
