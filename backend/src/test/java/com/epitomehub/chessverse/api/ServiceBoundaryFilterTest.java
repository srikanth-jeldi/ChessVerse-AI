package com.epitomehub.chessverse.api;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class ServiceBoundaryFilterTest {
    @Test
    void playRoleAllowsOnlineButHidesEconomyEndpoints() throws Exception {
        ServiceBoundaryFilter filter = new ServiceBoundaryFilter("play");

        MockHttpServletResponse onlineResponse = run(filter, "/api/v1/online/queue");
        MockHttpServletResponse economyResponse = run(filter, "/api/v1/economy/wallet");

        assertThat(onlineResponse.getStatus()).isEqualTo(200);
        assertThat(economyResponse.getStatus()).isEqualTo(404);
    }

    @Test
    void everyRoleKeepsReadinessEndpointAvailable() throws Exception {
        ServiceBoundaryFilter filter = new ServiceBoundaryFilter("learning");

        assertThat(run(filter, "/actuator/health/readiness").getStatus()).isEqualTo(200);
        assertThat(run(filter, "/api/v1/speech/synthesize").getStatus()).isEqualTo(200);
    }

    @Test
    void allRolePreservesLegacyDeployment() throws Exception {
        ServiceBoundaryFilter filter = new ServiceBoundaryFilter("all");

        assertThat(run(filter, "/api/v1/economy/wallet").getStatus()).isEqualTo(200);
        assertThat(run(filter, "/api/v1/online/queue").getStatus()).isEqualTo(200);
    }

    private MockHttpServletResponse run(ServiceBoundaryFilter filter, String path) throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", path);
        MockHttpServletResponse response = new MockHttpServletResponse();
        filter.doFilter(request, response, new MockFilterChain());
        return response;
    }
}
