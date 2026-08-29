import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  scenarios: {
    steady: { executor: 'ramping-vus', startVUs: 1, stages: [
      { duration: '20s', target: 25 }, { duration: '60s', target: 25 }, { duration: '20s', target: 0 },
    ]},
  },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<750', 'p(99)<1500'],
  },
};

const base = __ENV.BASE_URL || 'http://127.0.0.1:8080';
const token = __ENV.AUTH_TOKEN || '';

export default function () {
  const health = http.get(`${base}/actuator/health/liveness`);
  check(health, { 'liveness is up': (r) => r.status === 200 });
  if (token) {
    const headers = { Authorization: `Bearer ${token}` };
    const me = http.get(`${base}/api/auth/me`, { headers });
    check(me, { 'authenticated profile succeeds': (r) => r.status === 200 });
    if (__ENV.TEST_COMMUNITY === 'true') {
      const community = http.get(`${base}/api/v1/community`, { headers });
      check(community, { 'community succeeds or is throttled': (r) => r.status === 200 || r.status === 429 });
    }
  }
  sleep(0.25);
}
