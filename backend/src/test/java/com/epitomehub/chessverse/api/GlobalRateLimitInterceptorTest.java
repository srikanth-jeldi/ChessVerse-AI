package com.epitomehub.chessverse.api;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import java.sql.Timestamp;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class GlobalRateLimitInterceptorTest {
    @Test
    void enforcesSharedIpAndSessionCounters() throws Exception {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        when(jdbc.queryForObject(anyString(), eq(Integer.class), any(), any(), any()))
                .thenReturn(1, 1);
        var interceptor = new GlobalRateLimitInterceptor(jdbc, true);
        var request = new MockHttpServletRequest("POST", "/api/v1/community/messages");
        request.setRemoteAddr("172.18.0.3");
        request.addHeader("X-Forwarded-For", "203.0.113.8");
        request.addHeader("Authorization", "Bearer secret-session-token");
        var response = new MockHttpServletResponse();

        assertTrue(interceptor.preHandle(request, response, new Object()));
        verify(jdbc, times(2)).queryForObject(anyString(), eq(Integer.class), any(), any(), any());
        verify(jdbc, times(2)).queryForObject(anyString(), eq(Integer.class), any(), any(), isA(Timestamp.class));
        assertEquals("45", response.getHeader("X-RateLimit-Limit"));
        assertEquals("44", response.getHeader("X-RateLimit-Remaining"));
    }

    @Test
    void returns429WithRetryAfterWhenUploadLimitIsExceeded() throws Exception {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        when(jdbc.queryForObject(anyString(), eq(Integer.class), any(), any(), any())).thenReturn(13);
        var interceptor = new GlobalRateLimitInterceptor(jdbc, true);
        var request = new MockHttpServletRequest("POST", "/api/v1/community/messages/attachments");
        request.setRemoteAddr("198.51.100.7");
        var response = new MockHttpServletResponse();

        assertFalse(interceptor.preHandle(request, response, new Object()));
        assertEquals(429, response.getStatus());
        assertNotNull(response.getHeader("Retry-After"));
        assertEquals("0", response.getHeader("X-RateLimit-Remaining"));
        assertTrue(response.getContentAsString().contains("Too many requests"));
    }

    @Test
    void assignsSpecificHighRiskPolicies() {
        assertEquals(GlobalRateLimitInterceptor.Policy.AUTH_LOGIN,
                GlobalRateLimitInterceptor.policyFor("POST", "/api/auth/login"));
        assertEquals(GlobalRateLimitInterceptor.Policy.UPLOAD,
                GlobalRateLimitInterceptor.policyFor("POST", "/api/v1/community/messages/attachments"));
        assertEquals(GlobalRateLimitInterceptor.Policy.GAME_MOVE,
                GlobalRateLimitInterceptor.policyFor("POST", "/api/v1/online/matches/abc/moves"));
        assertEquals(GlobalRateLimitInterceptor.Policy.TOURNAMENT,
                GlobalRateLimitInterceptor.policyFor("PUT", "/api/v1/community/tournaments/abc"));
        assertEquals(GlobalRateLimitInterceptor.Policy.MATCHMAKING,
                GlobalRateLimitInterceptor.policyFor("POST", "/api/v1/online/queue"));
    }

    @Test
    void optionsAndHealthAreExempt() throws Exception {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        var interceptor = new GlobalRateLimitInterceptor(jdbc, true);
        assertTrue(interceptor.preHandle(new MockHttpServletRequest("OPTIONS", "/api/v1/community"),
                new MockHttpServletResponse(), new Object()));
        assertTrue(interceptor.preHandle(new MockHttpServletRequest("GET", "/api/v1/health"),
                new MockHttpServletResponse(), new Object()));
        verifyNoInteractions(jdbc);
    }
}
