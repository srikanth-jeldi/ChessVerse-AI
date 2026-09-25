package com.epitomehub.chessverse.academy;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
class AcademyHeadersFilter extends OncePerRequestFilter {
    @Override protected void doFilterInternal(HttpServletRequest request,HttpServletResponse response,FilterChain chain) throws ServletException,IOException {
        String path=request.getRequestURI();
        if(path.startsWith("/api/v1/academy") || path.equals("/academy") || path.startsWith("/academy/")) {
            response.setHeader("Cache-Control","no-store");
            response.setHeader("X-Content-Type-Options","nosniff");
            response.setHeader("Referrer-Policy","no-referrer");
            response.setHeader("Content-Security-Policy","default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' https: data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'");
        }
        chain.doFilter(request,response);
    }
}
