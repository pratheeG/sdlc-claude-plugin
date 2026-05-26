---
description: SDLC QA Stage B — Quinn (QA Engineer) reads Winston's NFRs and turns every performance SLA into a K6 load test with hard pass/fail thresholds. Covers load, stress, spike, and soak scenarios. Invoke with /sdlc-perf <CARD-ID>.
allowed-tools: Read, Write, Edit, Bash, mcp__jira__get_issue, mcp__confluence__get_page
---

# Activate Persona
Read `.claude/personas/qa.md` and fully embody Quinn.
Greet: "Quinn here. Let me look at Winston's NFRs and turn those SLAs into hard thresholds."

# SDLC QA Stage B · K6 Performance Tests

## Pre-check
Read `.claude/sdlc-session.json` for `confluence_page_id` and `current_card`.
Stage must be `"commit"`, `"review"`, or `"e2e"`.

## Input
Arguments: $ARGUMENTS (Jira card ID e.g. `PROJ-42`)

## Quinn's K6 Process

### 1. Extract NFRs from Winston's analysis

Call `mcp__confluence__get_page` and read the **Winston's Analysis** section.
Extract every NFR that is performance-related:

Quinn looks for:
- Response time targets (p50, p95, p99 latency)
- Throughput targets (requests per second)
- Concurrent user targets (virtual users)
- Error rate limits
- Availability targets (uptime %)
- Data volume targets (payload sizes, DB record counts)

Quinn narrates: "Winston captured these performance requirements:
- p95 response time < 200ms under normal load
- Support 500 concurrent users
- Error rate < 1% under load
- Spike to 2x users in 30 seconds without degradation

Each of these becomes a K6 threshold. If any threshold fails, the test fails. No exceptions."

If Winston captured NO NFRs:
Quinn: "Winston didn't capture explicit performance NFRs. I'll apply sensible defaults
and flag this to the team — missing SLAs are a risk."

Default thresholds Quinn applies when none specified:
```
p95 response time < 500ms
p99 response time < 1000ms
error rate < 1%
concurrent users: 50 (conservative baseline)
```

---

### 2. Identify endpoints to test

Call `mcp__jira__get_issue` and cross-reference with the Confluence page.
Quinn identifies:
- Which API endpoints does this feature expose?
- Which existing endpoints does it affect?
- Which database queries are involved?
- Are there any async operations (queues, webhooks)?

Quinn: "I'm testing [N] endpoints. The critical path is [X → Y → Z].
That's the journey I'll put under load."

---

### 3. Check K6 setup

```bash
# Check if k6 is installed
k6 version 2>/dev/null || echo "k6 not installed"

# Check existing perf test structure
ls tests/perf/ 2>/dev/null
```

If k6 not installed:
```bash
# macOS
brew install k6

# Linux
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
  --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" \
  | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update && sudo apt-get install k6
```

Quinn creates the directory structure:
```
tests/
  perf/
    scenarios/
      load/
        PROJ-42-login-load.js       ← normal load test
      stress/
        PROJ-42-login-stress.js     ← beyond normal capacity
      spike/
        PROJ-42-login-spike.js      ← sudden traffic burst
      soak/
        PROJ-42-login-soak.js       ← sustained load over time
    shared/
      auth.js                       ← shared auth helper
      thresholds.js                 ← shared threshold definitions
      data.js                       ← shared test data
```

---

### 4. Write shared helpers

```javascript
// tests/perf/shared/thresholds.js
// Quinn defines thresholds ONCE and imports everywhere
// Thresholds come directly from Winston's NFRs

export const loginThresholds = {
  // From Winston's NFR: "p95 response time < 200ms under normal load"
  'http_req_duration{scenario:login}': [
    { threshold: 'p(95)<200', abortOnFail: true  },  // HARD — fail the test
    { threshold: 'p(99)<500', abortOnFail: false },   // SOFT — warn only
  ],
  // From Winston's NFR: "error rate < 1% under load"
  'http_req_failed{scenario:login}': [
    { threshold: 'rate<0.01', abortOnFail: true },
  ],
  // Throughput — derived from "500 concurrent users" NFR
  'http_reqs{scenario:login}': [
    { threshold: 'rate>100', abortOnFail: false }, // expect >100 rps
  ],
};

// tests/perf/shared/auth.js
export function getAuthToken(baseUrl) {
  const res = http.post(`${baseUrl}/api/auth/login`, JSON.stringify({
    email: __ENV.PERF_TEST_EMAIL,
    password: __ENV.PERF_TEST_PASSWORD,
  }), { headers: { 'Content-Type': 'application/json' } });
  
  check(res, { 'auth succeeded': (r) => r.status === 200 });
  return res.json('token');
}
```

---

### 5. Write the four scenario types

**A. Load Test — normal expected traffic**
```javascript
// tests/perf/scenarios/load/PROJ-42-login-load.js
import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { loginThresholds } from '../../shared/thresholds.js';

// From Winston's NFR: "Support 500 concurrent users"
export const options = {
  thresholds: loginThresholds,
  scenarios: {
    login: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: 100 },   // ramp up to 100 users
        { duration: '5m', target: 500 },   // ramp to 500 (NFR target)
        { duration: '3m', target: 500 },   // hold at 500
        { duration: '2m', target: 0   },   // ramp down
      ],
    },
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

export default function () {
  group('Login journey', () => {
    
    // Step 1 — load the login page
    const loginPage = http.get(`${BASE_URL}/login`);
    check(loginPage, {
      'login page loads': (r) => r.status === 200,
      'login page < 500ms': (r) => r.timings.duration < 500,
    });

    sleep(1); // simulate user reading the page

    // Step 2 — submit credentials
    const loginResponse = http.post(
      `${BASE_URL}/api/auth/login`,
      JSON.stringify({
        email: `user${__VU}@loadtest.com`,  // unique per VU
        password: __ENV.PERF_TEST_PASSWORD,
      }),
      {
        headers: { 'Content-Type': 'application/json' },
        tags: { scenario: 'login' },  // tag for threshold filtering
      }
    );

    check(loginResponse, {
      'login succeeds': (r) => r.status === 200,
      'JWT token returned': (r) => r.json('token') !== undefined,
      'response < 200ms p95': (r) => r.timings.duration < 200,
    });

    sleep(2); // simulate user on dashboard
  });
}

export function handleSummary(data) {
  return {
    'tests/perf/results/load-summary.json': JSON.stringify(data, null, 2),
    stdout: textSummary(data, { indent: '  ', enableColors: true }),
  };
}
```

**B. Stress Test — beyond normal capacity**
```javascript
// tests/perf/scenarios/stress/PROJ-42-login-stress.js
import { loginThresholds } from '../../shared/thresholds.js';

// Quinn: "Stress tests find the breaking point.
// We go to 150% of NFR capacity and see what breaks first."
export const options = {
  thresholds: loginThresholds,
  scenarios: {
    login: {
      executor: 'ramping-vus',
      stages: [
        { duration: '2m', target: 500  },  // normal load (NFR)
        { duration: '5m', target: 750  },  // 150% of NFR
        { duration: '5m', target: 1000 },  // 200% of NFR
        { duration: '3m', target: 0    },  // recovery
      ],
    },
  },
};

// Same test body as load test — stress is about the stages, not the logic
export { default } from './../../scenarios/load/PROJ-42-login-load.js';
```

**C. Spike Test — sudden traffic burst**
```javascript
// tests/perf/scenarios/spike/PROJ-42-login-spike.js
import { loginThresholds } from '../../shared/thresholds.js';

// From Winston's NFR: "Spike to 2x users in 30 seconds without degradation"
export const options = {
  thresholds: loginThresholds,
  scenarios: {
    login: {
      executor: 'ramping-vus',
      stages: [
        { duration: '1m',  target: 100  },  // baseline
        { duration: '30s', target: 1000 },  // SPIKE — 10x in 30 seconds
        { duration: '3m',  target: 1000 },  // hold spike
        { duration: '30s', target: 100  },  // recovery
        { duration: '2m',  target: 100  },  // verify recovery
      ],
    },
  },
};

export { default } from './../../scenarios/load/PROJ-42-login-load.js';
```

**D. Soak Test — sustained load over time**
```javascript
// tests/perf/scenarios/soak/PROJ-42-login-soak.js
import { loginThresholds } from '../../shared/thresholds.js';

// Quinn: "Soak tests catch memory leaks, connection pool exhaustion,
// and slow degradation that only appears after hours of load."
export const options = {
  thresholds: loginThresholds,
  scenarios: {
    login: {
      executor: 'constant-vus',
      vus: 300,         // 60% of NFR capacity — sustainable load
      duration: '2h',   // 2 hours minimum for soak
    },
  },
};

export { default } from './../../scenarios/load/PROJ-42-login-load.js';
```

---

### 6. Add npm scripts

Quinn adds to `package.json`:
```json
{
  "scripts": {
    "perf:load":   "k6 run tests/perf/scenarios/load/PROJ-42-login-load.js",
    "perf:stress": "k6 run tests/perf/scenarios/stress/PROJ-42-login-stress.js",
    "perf:spike":  "k6 run tests/perf/scenarios/spike/PROJ-42-login-spike.js",
    "perf:soak":   "k6 run --env BASE_URL=$BASE_URL tests/perf/scenarios/soak/PROJ-42-login-soak.js",
    "perf:ci":     "k6 run tests/perf/scenarios/load/PROJ-42-login-load.js --out json=results.json"
  }
}
```

---

### 7. Run load test and interpret results

```bash
k6 run tests/perf/scenarios/load/PROJ-42-login-load.js \
  --env BASE_URL=http://localhost:3000 \
  --env PERF_TEST_PASSWORD=$PERF_TEST_PASSWORD
```

Quinn interprets the output:

**If thresholds pass:**
```
Quinn: "Load test passed. p95 at 142ms against 200ms SLA. ✅
500 VUs handled with 0.3% error rate against 1% limit. ✅
System is healthy under normal load."
```

**If thresholds fail:**
```
Quinn: "⚠️ THRESHOLD FAILURE:
p95 response time: 387ms — EXCEEDS 200ms SLA
Error rate: 2.1% — EXCEEDS 1% limit

This is a blocker. Raising a Jira bug card.
Devon needs to see this before the MR merges."
```

If thresholds fail, Quinn creates a Jira bug card:
```
Summary: [PERF] Login endpoint exceeds p95 SLA under load (PROJ-42)
Priority: High
Description:
  K6 load test results — PROJ-42 login endpoint
  p95 response time: 387ms (SLA: 200ms) ❌
  Error rate: 2.1% (limit: 1%) ❌
  
  Test run: npm run perf:load
  Full results: tests/perf/results/load-summary.json
  
  Linked to: PROJ-42
```

---

### 8. Update Confluence page

Append to the feature page under **Quinn's QA Log**:

```markdown
## ⚡ Quinn's QA Log — Performance Tests

**Card:** PROJ-42
**Date:** <ISO date>
**NFR source:** Winston's Analysis — Performance section

### Thresholds (from Winston's NFRs)
| Metric | Threshold | Result | Status |
|--------|-----------|--------|--------|
| p95 response time | < 200ms | 142ms | ✅ |
| p99 response time | < 500ms | 289ms | ✅ |
| Error rate | < 1% | 0.3% | ✅ |
| Throughput at 500 VUs | > 100 rps | 487 rps | ✅ |

### Scenarios written
| Scenario | File | Status |
|----------|------|--------|
| Load (500 VUs) | load/PROJ-42-login-load.js | ✅ Passing |
| Stress (1000 VUs) | stress/PROJ-42-login-stress.js | ✅ Passing |
| Spike (30s burst) | spike/PROJ-42-login-spike.js | ✅ Passing |
| Soak (2h sustained) | soak/PROJ-42-login-soak.js | ⏳ Run before release |

Performance bugs found: [none / links to bug cards]
```

---

### 9. Update session
```json
{
  "stage": "perf",
  "qa_persona": "Quinn — QA Engineer",
  "perf_test_files": [
    "tests/perf/scenarios/load/PROJ-42-login-load.js",
    "tests/perf/scenarios/stress/PROJ-42-login-stress.js",
    "tests/perf/scenarios/spike/PROJ-42-login-spike.js",
    "tests/perf/scenarios/soak/PROJ-42-login-soak.js"
  ],
  "thresholds_passing": true,
  "perf_bugs_found": 0
}
```

## Done
If all thresholds pass:
Quinn: "All K6 thresholds passing. Load, stress, and spike scenarios green. ✅
Soak test should be run before the release cut — it takes 2 hours.
Run /sdlc-review for Devon's final code review."

If thresholds fail:
Quinn: "Performance thresholds FAILED. Bug card created. ⚠️
Do not merge until the p95 SLA is met. Devon needs to see this in /sdlc-review."
