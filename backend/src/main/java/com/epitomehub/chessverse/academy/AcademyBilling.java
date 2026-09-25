package com.epitomehub.chessverse.academy;

import java.util.*;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.server.ResponseStatusException;
import tools.jackson.databind.ObjectMapper;

/** Immutable order billing snapshots; tax setup must be approved before checkout. */
final class AcademyBilling {
    static Map<String,Object> snapshot(JdbcTemplate db,ObjectMapper json,Map<String,Object> enrollment,long subtotal,long discount) {
        var c=db.queryForMap("SELECT * FROM academy_billing_config WHERE id=1");
        if(!Boolean.TRUE.equals(c.get("approved"))||c.get("legal_name").toString().isBlank()||c.get("address").toString().isBlank()||c.get("sac").toString().isBlank())throw new ResponseStatusException(HttpStatus.CONFLICT,"Seller invoice and tax setup is awaiting confirmation. No payment has been started.");
        // USD currency alone does not establish export eligibility or LUT compliance.
        if(!"IN".equals(enrollment.get("country")))throw new ResponseStatusException(HttpStatus.CONFLICT,"International billing needs an export tax review. Contact EpitomeHub for a USD invoice.");
        if(enrollment.get("billing_details")==null)throw new ResponseStatusException(HttpStatus.CONFLICT,"Add billing details before checkout.");
        var buyer=json.readTree(enrollment.get("billing_details").toString());
        long taxable=subtotal-discount;int rate=((Number)c.get("india_rate_bps")).intValue();
        boolean intra=buyer.path("stateCode").asText().equals(c.get("gstin").toString().substring(0,2));
        long cgst=intra?Math.round(taxable*rate/20000.0):0,sgst=cgst,igst=intra?0:Math.round(taxable*rate/10000.0);
        Map<String,Object> s=new LinkedHashMap<>();s.put("sellerName",c.get("legal_name"));s.put("sellerAddress",c.get("address"));s.put("sellerGstin",c.get("gstin"));s.put("sac",c.get("sac"));s.put("buyer",buyer);s.put("country",enrollment.get("country"));s.put("currency","INR");s.put("subtotal",subtotal);s.put("discount",discount);s.put("taxable",taxable);s.put("gstRate",rate/100.0);s.put("cgst",cgst);s.put("sgst",sgst);s.put("igst",igst);s.put("tax",cgst+sgst+igst);s.put("total",taxable+cgst+sgst+igst);s.put("reverseCharge",false);return s;
    }
}
