package com.epitomehub.chessverse.academy;

import com.epitomehub.chessverse.auth.PlayerAuthenticationService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
import java.util.*;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import tools.jackson.databind.ObjectMapper;

/** Self-service enrollment does not grant tenant access until captured payment is verified. */
@RestController @RequestMapping("/api/v1/academy/onboarding") @Transactional
public class AcademyOnboardingController {
    private final JdbcTemplate db;
    private final PlayerAuthenticationService auth;
    private final AcademyPaymentGateway gateway;
    private final ObjectMapper json;
    public AcademyOnboardingController(JdbcTemplate db, PlayerAuthenticationService auth, AcademyPaymentGateway gateway, ObjectMapper json) {
        this.db=db; this.auth=auth; this.gateway=gateway; this.json=json;
    }
    public record Enrollment(@NotBlank @Size(max=100) String name,
        @NotNull @Pattern(regexp="ACADEMY|SCHOOL") String kind,
        @NotNull @Pattern(regexp="[A-Z]{2}") String country) {}
    public record Plan(@NotNull @Pattern(regexp="STARTER|GROWTH|SCHOOL") String planCode,
        @Size(max=30) @Pattern(regexp="[A-Za-z0-9_-]*") String coupon, @Min(1) Long expectedTotal) {
        public Plan(String planCode,String coupon) {this(planCode,coupon,null);}
    }
    public record Verification(@NotNull UUID checkoutId,
        @NotBlank @Pattern(regexp="pay_[A-Za-z0-9]+") String paymentId,
        @NotBlank @Pattern(regexp="[a-fA-F0-9]{64}") String signature) {}
    public record BillingDetails(@NotBlank @Size(max=150) String legalName,
        @NotBlank @Email @Size(max=254) String email,@NotBlank @Size(max=500) String address,
        @NotBlank @Size(max=100) String city,@NotBlank @Size(max=100) String state,
        @NotBlank @Size(max=12) String postalCode,@Size(max=2) String stateCode,
        @Size(max=15) String gstin) {}
    @PutMapping("/billing") public Object billing(@RequestHeader("Authorization") String bearer,@Valid @RequestBody BillingDetails b) {
        var e=enrollment(account(bearer));
        check(db.queryForObject("SELECT COUNT(*) FROM academy_checkout WHERE enrollment_id=? AND status='PENDING'",Integer.class,e.get("id"))==0,HttpStatus.CONFLICT,"A payment order is pending; contact support to correct its billing details.");
        if("IN".equals(e.get("country"))) {
            check(b.postalCode.matches("[1-9][0-9]{5}")&&b.stateCode!=null&&b.stateCode.matches("0[1-9]|[12][0-9]|3[0-8]"),HttpStatus.BAD_REQUEST,"Enter a valid Indian pincode and GST state code.");
            check(b.gstin==null||b.gstin.isBlank()||(b.gstin.matches("[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]")&&b.gstin.startsWith(b.stateCode)),HttpStatus.BAD_REQUEST,"GSTIN must match the billing state.");
        } else check(b.gstin==null||b.gstin.isBlank(),HttpStatus.BAD_REQUEST,"Indian GSTIN requires an Indian billing country.");
        db.update("UPDATE academy_enrollment SET billing_details=? WHERE id=?",json.writeValueAsString(b),e.get("id"));return Map.of("saved",true);
    }
    private UUID account(String bearer) {
        UUID id=auth.requireBearer(bearer).id();
        check(db.queryForObject("SELECT COUNT(*) FROM player_account WHERE id=? AND verified=TRUE",Integer.class,id)==1,
            HttpStatus.FORBIDDEN,"Verify your account email before registering an academy.");
        // Serialize enrollment/order creation for this account, including the first request.
        db.queryForObject("SELECT id FROM player_account WHERE id=? FOR UPDATE",UUID.class,id);
        return id;
    }
    private void check(boolean ok,HttpStatus status,String message) { if(!ok) throw new ResponseStatusException(status,message); }
    private UUID id(Object value) { return UUID.fromString(value.toString()); }
    private List<Map<String,Object>> rows(String sql,Object... args) {
        return db.query(sql,(rs,n)->{Map<String,Object> r=new LinkedHashMap<>();
            for(int i=1;i<=rs.getMetaData().getColumnCount();i++) {Object v=rs.getObject(i);r.put(rs.getMetaData().getColumnLabel(i).toLowerCase(Locale.ROOT),v==null?null:v instanceof UUID||v instanceof Number||v instanceof Boolean?v:v.toString());}return r;},args);
    }
    private Map<String,Object> enrollment(UUID account) {
        var result=rows("SELECT * FROM academy_enrollment WHERE account_id=?",account);
        check(!result.isEmpty(),HttpStatus.NOT_FOUND,"Register your academy first.");return result.getFirst();
    }
    @GetMapping("/plans") public Object plans(@RequestParam String country) {
        check(Set.of(Locale.getISOCountries()).contains(country),HttpStatus.BAD_REQUEST,"Select a valid billing country.");
        String currency=country.equals("IN")?"INR":"USD";
        boolean taxReady=Boolean.TRUE.equals(db.queryForObject("SELECT approved FROM academy_billing_config WHERE id=1",Boolean.class));
        return Map.of("currency",currency,"checkoutAvailable",gateway.available()&&taxReady&&country.equals("IN"),"plans",
            rows("SELECT plan_code,name,seats,amount_minor,currency,enabled FROM academy_plan_price WHERE currency=? ORDER BY CASE plan_code WHEN 'STARTER' THEN 1 WHEN 'GROWTH' THEN 2 ELSE 3 END",currency));
    }
    @GetMapping("/countries") public Object countries() {
        return Arrays.stream(Locale.getISOCountries()).map(c->Map.of("code",c,"name",new Locale.Builder().setRegion(c).build().getDisplayCountry(Locale.ENGLISH))).sorted(Comparator.comparing(c->c.get("name"))).toList();
    }
    @GetMapping public Object status(@RequestHeader("Authorization") String bearer) {
        UUID account=account(bearer);var result=rows("SELECT * FROM academy_enrollment WHERE account_id=?",account);
        if(result.isEmpty())return Map.of("registered",false);
        var e=result.getFirst();
        return Map.of("registered",true,"enrollment",e,"orders",rows("SELECT id,plan_name,amount_minor,currency,status,created_at FROM academy_checkout WHERE enrollment_id=? ORDER BY created_at DESC",e.get("id")));
    }
    @PostMapping public Object enroll(@RequestHeader("Authorization") String bearer,@Valid @RequestBody Enrollment input) {
        UUID account=account(bearer);
        check(Set.of(Locale.getISOCountries()).contains(input.country),HttpStatus.BAD_REQUEST,"Invalid billing country.");
        var existing=rows("SELECT * FROM academy_enrollment WHERE account_id=?",account);
        if(!existing.isEmpty()) return existing.getFirst();
        UUID enrollment=UUID.randomUUID();
        db.update("INSERT INTO academy_enrollment(id,account_id,name,kind,country) VALUES(?,?,?,?,?)",enrollment,account,input.name.trim(),input.kind,input.country);
        return enrollment(account);
    }
    @PostMapping("/orders") public Object order(@RequestHeader("Authorization") String bearer,@Valid @RequestBody Plan input) {
        var e=enrollment(account(bearer));
        check(gateway.available(),HttpStatus.SERVICE_UNAVAILABLE,"Online checkout is not yet enabled. Contact EpitomeHub for pricing.");
        if(e.get("organization_id")!=null) {
            var org=rows("SELECT status,renewal_date FROM academy_organization WHERE id=?",e.get("organization_id")).getFirst();
            check(!"SUSPENDED".equals(org.get("status")),HttpStatus.FORBIDDEN,"Contact support about this suspended academy.");
            check(org.get("renewal_date")!=null&&!LocalDate.parse(org.get("renewal_date").toString()).isAfter(LocalDate.now()),HttpStatus.CONFLICT,"Your academy plan is already active.");
        }
        // Resume a pending checkout instead of producing duplicate payable orders.
        var pending=rows("SELECT * FROM academy_checkout WHERE enrollment_id=? AND status='PENDING' ORDER BY created_at DESC",e.get("id"));
        if(!pending.isEmpty()){samePending(pending.getFirst(),input);check(Objects.equals(input.expectedTotal,((Number)pending.getFirst().get("amount_minor")).longValue()),HttpStatus.CONFLICT,"Review the payment total again.");return checkoutView(pending.getFirst());}
        String currency="IN".equals(e.get("country"))?"INR":"USD";
        var prices=rows("SELECT * FROM academy_plan_price WHERE plan_code=? AND currency=? AND enabled=TRUE AND seats IS NOT NULL AND amount_minor IS NOT NULL",input.planCode,currency);
        check(!prices.isEmpty(),HttpStatus.CONFLICT,"Pricing is not yet available for this plan.");
        var p=prices.getFirst();
        var quote=quote(e,p,input);
        var billing=AcademyBilling.snapshot(db,json,e,((Number)quote.get("subtotal")).longValue(),((Number)quote.get("discount")).longValue());
        check(Objects.equals(input.expectedTotal,billing.get("total")),HttpStatus.CONFLICT,"The price or tax changed. Review your total again before paying.");
        if(e.get("organization_id")!=null) check(db.queryForObject("SELECT COUNT(*) FROM academy_student WHERE organization_id=? AND active=TRUE",Integer.class,e.get("organization_id"))<=((Number)p.get("seats")).intValue(),HttpStatus.CONFLICT,"Choose a plan that covers your active students.");
        UUID order=UUID.randomUUID();
        var provider=gateway.createOrder(order.toString(),((Number)billing.get("total")).longValue(),currency);
        db.update("INSERT INTO academy_checkout(id,enrollment_id,provider_order,plan_code,plan_name,seats,amount_minor,currency,coupon_code,subtotal_minor,discount_minor,billing_snapshot,tax_minor) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)",order,e.get("id"),provider.id(),input.planCode,p.get("name"),p.get("seats"),billing.get("total"),currency,quote.get("coupon"),p.get("amount_minor"),quote.get("discount"),json.writeValueAsString(billing),billing.get("tax"));
        return checkoutView(rows("SELECT * FROM academy_checkout WHERE id=?",order).getFirst());
    }
    private Object checkoutView(Map<String,Object> o) {
        return Map.of("id",o.get("id"),"orderId",o.get("provider_order"),"keyId",gateway.publicKey(),"amount",o.get("amount_minor"),"currency",o.get("currency"),"plan",o.get("plan_name"));
    }
    @PostMapping("/quote") public Object quote(@RequestHeader("Authorization") String bearer,@Valid @RequestBody Plan input) {
        var e=enrollment(account(bearer));String currency="IN".equals(e.get("country"))?"INR":"USD";
        var pending=rows("SELECT * FROM academy_checkout WHERE enrollment_id=? AND status='PENDING'",e.get("id"));
        if(!pending.isEmpty()) {var o=pending.getFirst();samePending(o,input);return json.readTree(o.get("billing_snapshot").toString());}
        var prices=rows("SELECT * FROM academy_plan_price WHERE plan_code=? AND currency=? AND enabled=TRUE AND seats IS NOT NULL AND amount_minor IS NOT NULL",input.planCode,currency);
        check(!prices.isEmpty(),HttpStatus.CONFLICT,"This plan is awaiting pricing confirmation.");
        var result=quote(e,prices.getFirst(),input);return AcademyBilling.snapshot(db,json,e,((Number)result.get("subtotal")).longValue(),((Number)result.get("discount")).longValue());
    }
    private void samePending(Map<String,Object> o,Plan input) {
        String code=input.coupon==null||input.coupon.isBlank()?null:input.coupon.toUpperCase(Locale.ROOT);
        check(o.get("plan_code").equals(input.planCode)&&Objects.equals(o.get("coupon_code"),code),HttpStatus.CONFLICT,"A checkout already exists for "+o.get("plan_name")+". Resume the same plan and coupon, or contact support before changing it.");
    }
    private Map<String,Object> quote(Map<String,Object> enrollment,Map<String,Object> price,Plan input) {
        long subtotal=((Number)price.get("amount_minor")).longValue(),discount=0;
        String code=input.coupon==null||input.coupon.isBlank()?null:input.coupon.toUpperCase(Locale.ROOT);
        if(code!=null) {
            check(db.queryForObject("SELECT COUNT(*) FROM academy_checkout WHERE enrollment_id=? AND status='PAID'",Integer.class,enrollment.get("id"))==0,HttpStatus.CONFLICT,"Launch coupons apply to the first month only.");
            var coupons=rows("SELECT * FROM academy_coupon WHERE code=? FOR UPDATE",code);
            check(!coupons.isEmpty(),HttpStatus.BAD_REQUEST,"Coupon is invalid or unavailable.");var c=coupons.getFirst();
            check(Boolean.TRUE.equals(c.get("enabled"))&&!LocalDate.parse(c.get("expires_on").toString()).isBefore(LocalDate.now())&&(c.get("plan_code")==null||c.get("plan_code").equals(input.planCode)),HttpStatus.BAD_REQUEST,"Coupon is expired or does not apply to this plan.");
            check(db.queryForObject("SELECT COUNT(*) FROM academy_checkout WHERE coupon_code=?",Integer.class,code)<((Number)c.get("max_orders")).intValue(),HttpStatus.CONFLICT,"Coupon redemption limit reached.");
            check(db.queryForObject("SELECT COUNT(*) FROM academy_checkout WHERE enrollment_id=? AND coupon_code=?",Integer.class,enrollment.get("id"),code)==0,HttpStatus.CONFLICT,"This academy has already used this coupon.");
            discount=subtotal*((Number)c.get("percent_off")).intValue()/100;
        }
        Map<String,Object> result=new LinkedHashMap<>();result.put("subtotal",subtotal);result.put("discount",discount);result.put("total",subtotal-discount);result.put("coupon",code);return result;
    }
    private Map<String,Object> owned(String bearer,UUID checkout) {
        UUID account=account(bearer);
        var orders=rows("SELECT c.* FROM academy_checkout c JOIN academy_enrollment e ON e.id=c.enrollment_id WHERE c.id=? AND e.account_id=?",checkout,account);
        check(!orders.isEmpty(),HttpStatus.NOT_FOUND,"Checkout not found.");return orders.getFirst();
    }
    @PostMapping("/verify") public Object verify(@RequestHeader("Authorization") String bearer,@Valid @RequestBody Verification v) {
        var o=owned(bearer,v.checkoutId);
        check(gateway.validPaymentSignature(o.get("provider_order").toString(),v.paymentId,v.signature),HttpStatus.BAD_REQUEST,"Payment signature could not be verified.");
        return activate(v.checkoutId,v.paymentId);
    }
    @PostMapping("/orders/{checkout}/reconcile") public Object reconcile(@RequestHeader("Authorization") String bearer,@PathVariable UUID checkout) {
        var o=owned(bearer,checkout);
        if("PAID".equals(o.get("status")))return Map.of("active",true);
        String payment=gateway.findCapturedPayment(o.get("provider_order").toString(),((Number)o.get("amount_minor")).longValue(),o.get("currency").toString());
        return payment==null?Map.of("active",false):activate(checkout,payment);
    }
    @PostMapping("/webhook") public Object webhook(@RequestBody String raw,@RequestHeader(value="X-Razorpay-Signature",required=false) String signature) {
        check(gateway.validWebhookSignature(raw,signature),HttpStatus.BAD_REQUEST,"Invalid webhook signature.");
        var payload=json.readTree(raw);
        if(!"payment.captured".equals(payload.path("event").asText()))return Map.of("received",true);
        var payment=payload.path("payload").path("payment").path("entity");
        var orders=rows("SELECT id FROM academy_checkout WHERE provider_order=?",payment.path("order_id").asText());
        if(!orders.isEmpty())activate(id(orders.getFirst().get("id")),payment.path("id").asText());
        return Map.of("received",true);
    }
    private Object activate(UUID checkout,String payment) {
        var o=rows("SELECT * FROM academy_checkout WHERE id=? FOR UPDATE",checkout).getFirst();
        if("PAID".equals(o.get("status")))return Map.of("active",true);
        check(payment.matches("pay_[A-Za-z0-9]+"),HttpStatus.BAD_REQUEST,"Invalid payment identifier.");
        gateway.verifyCapturedPayment(payment,o.get("provider_order").toString(),((Number)o.get("amount_minor")).longValue(),o.get("currency").toString());
        var e=rows("SELECT * FROM academy_enrollment WHERE id=? FOR UPDATE",o.get("enrollment_id")).getFirst();
        UUID org=e.get("organization_id")==null?UUID.randomUUID():id(e.get("organization_id"));
        if(e.get("organization_id")==null) {
            db.update("INSERT INTO academy_organization(id,name,kind,plan,seats,status,renewal_date) VALUES(?,?,?,?,?,'ACTIVE',?)",org,e.get("name"),e.get("kind"),o.get("plan_name"),o.get("seats"),LocalDate.now().plusMonths(1));
            String name=db.queryForObject("SELECT display_name FROM player_account WHERE id=?",String.class,e.get("account_id"));
            db.update("INSERT INTO academy_member(id,organization_id,account_id,name,role) VALUES(?,?,?,?,'ORGANIZATION_ADMIN')",UUID.randomUUID(),org,e.get("account_id"),name);
            db.update("UPDATE academy_enrollment SET organization_id=? WHERE id=?",org,e.get("id"));
        } else {
            db.queryForObject("SELECT id FROM academy_organization WHERE id=? FOR UPDATE",UUID.class,org);
            check(!"SUSPENDED".equals(db.queryForObject("SELECT status FROM academy_organization WHERE id=?",String.class,org)),HttpStatus.CONFLICT,"Payment received; contact support about suspended academy activation.");
            db.update("UPDATE academy_organization SET plan=?,seats=?,renewal_date=?,status='ACTIVE' WHERE id=?",o.get("plan_name"),o.get("seats"),LocalDate.now().plusMonths(1),org);
        }
        db.update("INSERT INTO academy_invoice(id,organization_id,label,amount_minor,currency,status,issued_on) VALUES(?,?,?,?,?,'PAID',?)",checkout,org,"Academy license · "+o.get("plan_name"),o.get("amount_minor"),o.get("currency"),LocalDate.now());
        long sequence=db.queryForObject("SELECT next_number FROM academy_invoice_counter WHERE id=1 FOR UPDATE",Long.class);
        check(sequence<1000000000,HttpStatus.CONFLICT,"Invoice sequence exhausted; contact support.");
        db.update("UPDATE academy_invoice_counter SET next_number=next_number+1 WHERE id=1");
        String number="CV"+String.format("%02d",(LocalDate.now().getMonthValue()<4?LocalDate.now().getYear()-1:LocalDate.now().getYear())%100)+"/"+String.format("%09d",sequence);
        db.update("INSERT INTO academy_invoice_document(invoice_id,invoice_number,snapshot) VALUES(?,?,?)",checkout,number,o.get("billing_snapshot"));
        db.update("UPDATE academy_checkout SET status='PAID',payment_id=?,paid_at=CURRENT_TIMESTAMP WHERE id=?",payment,checkout);
        return Map.of("active",true,"organizationId",org);
    }
    @GetMapping("/invoices/{checkout}") public Object invoice(@RequestHeader("Authorization") String bearer,@PathVariable UUID checkout) {
        var o=owned(bearer,checkout);check("PAID".equals(o.get("status")),HttpStatus.NOT_FOUND,"Paid invoice not available.");
        var d=rows("SELECT d.*,i.issued_on FROM academy_invoice_document d JOIN academy_invoice i ON i.id=d.invoice_id WHERE invoice_id=?",checkout).getFirst();
        return Map.of("number",d.get("invoice_number"),"date",d.get("issued_on"),"plan",o.get("plan_name"),"paymentId",o.get("payment_id"),"billing",json.readTree(d.get("snapshot").toString()));
    }
}
