package com.epitomehub.chessverse.academy;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

/** Spring's static welcome-page mapping covers the root, not nested directories. */
@Controller
class AcademyPortalController {
    @GetMapping({"/academy", "/academy/"})
    String index(@RequestParam(required=false) String demo) {
        return "redirect:/academy/index.html" + (demo == null ? "" : "?demo");
    }
}
