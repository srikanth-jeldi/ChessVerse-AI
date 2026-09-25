package com.epitomehub.chessverse.academy;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;

/** Spring's static welcome-page mapping covers the root, not nested directories. */
@Controller
class AcademyPortalController {
    @GetMapping(value="/academy", produces="text/html")
    @ResponseBody
    Resource index() {
        return new ClassPathResource("static/academy/index.html");
    }

    @GetMapping({"/academy/", "/academy/index.html"})
    String canonical(@RequestParam(required=false) String demo) {
        return "redirect:/academy" + (demo == null ? "" : "?demo");
    }
}
