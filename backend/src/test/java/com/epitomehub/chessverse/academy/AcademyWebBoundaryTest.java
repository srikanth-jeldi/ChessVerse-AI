package com.epitomehub.chessverse.academy;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.mockito.Mockito.*;
import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import org.springframework.web.server.ResponseStatusException;
import com.epitomehub.chessverse.api.ApiExceptionHandler;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import tools.jackson.databind.ObjectMapper;

class AcademyWebBoundaryTest {
    @Test void directoryRoutesReachStaticEntryAndPreserveDemoMode() throws Exception {
        var mvc=MockMvcBuilders.standaloneSetup(new AcademyPortalController()).addFilters(new AcademyHeadersFilter()).build();
        mvc.perform(get("/academy/").param("demo",""))
            .andExpect(status().is3xxRedirection()).andExpect(redirectedUrl("/academy?demo"))
            .andExpect(header().string("Cache-Control","no-store"));
        mvc.perform(get("/academy")).andExpect(status().isOk())
            .andExpect(content().contentTypeCompatibleWith(MediaType.TEXT_HTML))
            .andExpect(content().string(org.hamcrest.Matchers.containsString("<base href=\"/academy/\">")))
            .andExpect(header().string("Cache-Control","no-store"));
        mvc.perform(get("/academy/index.html").param("demo",""))
            .andExpect(redirectedUrl("/academy?demo"));
    }
    @Test void invalidRolesAndNestedImportAreRejectedBeforeWrites() throws Exception {
        var auth=mock(PlayerAuthenticationService.class);var db=mock(JdbcTemplate.class);
        var controller=new AcademyController(db,auth,new ObjectMapper(),mock(AcademyGuidanceService.class));
        var mvc=MockMvcBuilders.standaloneSetup(controller).setControllerAdvice(new ApiExceptionHandler()).build();
        String org="11111111-1111-1111-1111-111111111111";
        mvc.perform(post("/api/v1/academy/"+org+"/members").header("Authorization","Bearer token").contentType(MediaType.APPLICATION_JSON)
            .content("{\"email\":\"a@example.com\",\"name\":\"Escalation\",\"role\":\"SUPER_ADMIN\",\"active\":true}"))
            .andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/academy/"+org+"/students/import").header("Authorization","Bearer token").contentType(MediaType.APPLICATION_JSON)
            .content("{\"students\":[{\"name\":\"\",\"email\":\"not-an-email\",\"active\":true}]}"))
            .andExpect(status().isBadRequest());
        verifyNoInteractions(db,auth);
    }
    @Test void unauthenticatedRequestCannotReachTenantDatabase() throws Exception {
        var auth=mock(PlayerAuthenticationService.class);var db=mock(JdbcTemplate.class);
        when(auth.requireBearer("Bearer invalid")).thenThrow(new ResponseStatusException(HttpStatus.UNAUTHORIZED,"Sign in"));
        var mvc=MockMvcBuilders.standaloneSetup(new AcademyController(db,auth,new ObjectMapper(),mock(AcademyGuidanceService.class)))
            .setControllerAdvice(new ApiExceptionHandler()).addFilters(new AcademyHeadersFilter()).build();
        mvc.perform(get("/api/v1/academy/me").header("Authorization","Bearer invalid"))
            .andExpect(status().isUnauthorized()).andExpect(header().string("Cache-Control","no-store"));
        verifyNoInteractions(db);
    }
}
