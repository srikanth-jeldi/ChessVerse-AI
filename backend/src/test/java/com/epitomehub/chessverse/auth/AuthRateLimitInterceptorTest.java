package com.epitomehub.chessverse.auth;

import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class AuthRateLimitInterceptorTest {
    @Test
    void limitsRepeatedLoginRequestsFromOneAddress() {
        AuthRateLimitInterceptor interceptor = new AuthRateLimitInterceptor(true);
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/auth/login");
        request.setRemoteAddr("203.0.113.7");
        MockHttpServletResponse response = new MockHttpServletResponse();

        for (int attempt = 0; attempt < 10; attempt++) {
            interceptor.preHandle(request, response, new Object());
        }

        assertThrows(
                AuthException.class,
                () -> interceptor.preHandle(request, response, new Object()));
    }
}
