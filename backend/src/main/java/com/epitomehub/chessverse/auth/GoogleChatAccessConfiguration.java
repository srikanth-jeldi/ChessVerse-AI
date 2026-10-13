package com.epitomehub.chessverse.auth;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.servlet.HandlerInterceptor;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/** Require a server-verified Google identity for all chat operations. */
@Configuration
class GoogleChatAccessConfiguration implements WebMvcConfigurer {
    private final PlayerAuthenticationService authentication;

    GoogleChatAccessConfiguration(PlayerAuthenticationService authentication) {
        this.authentication = authentication;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(new HandlerInterceptor() {
            @Override
            public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
                if (!"OPTIONS".equals(request.getMethod())) {
                    authentication.requireGoogleBearer(request.getHeader("Authorization"));
                }
                return true;
            }
        }).addPathPatterns("/api/v1/coach/ask", "/api/v1/community/messages",
                "/api/v1/community/messages/**", "/api/v1/community/e2ee/**", "/api/v1/community/media/**");
    }
}
