package com.epitomehub.chessverse.api;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.web.server.ResponseStatusException;

class ApiExceptionHandlerTest {
    @Test
    void oversizedUploadReturnsActionablePayload() {
        var request = new org.springframework.mock.web.MockHttpServletRequest();
        request.setRequestURI("/api/auth/profile-photo");
        var response = new ApiExceptionHandler().uploadTooLarge(
                new MaxUploadSizeExceededException(5L * 1024 * 1024), request);
        org.junit.jupiter.api.Assertions.assertEquals(413, response.getStatusCode().value());
        org.junit.jupiter.api.Assertions.assertEquals(
                "Choose an image up to 5 MB.", response.getBody().get("message"));
    }
    private final ApiExceptionHandler handler = new ApiExceptionHandler();

    @Test
    void preservesSafeResponseStatusReasonForClients() {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/v1/online/queue");

        ResponseEntity<Map<String, Object>> response = handler.responseStatus(
                new ResponseStatusException(HttpStatus.CONFLICT, "Insufficient coins."), request);

        assertEquals(HttpStatus.CONFLICT, response.getStatusCode());
        assertEquals("Insufficient coins.", response.getBody().get("message"));
        assertEquals("/api/v1/online/queue", response.getBody().get("path"));
    }
}
