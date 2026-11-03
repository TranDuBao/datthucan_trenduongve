/**
 * Master Test Runner for Smart City Food Route
 * Runs all unit, integration, and security test suites.
 * Exits with non-zero exit code if any test suite fails.
 */

const { fork } = require('child_process');
const path = require('path');

const suites = [
  { name: '1. Phase 4 Architecture & Logic Suite', file: path.join(__dirname, 'phase4_regression.test.js') },
  { name: '2. Payment Flow & Lifecycle Suite', file: path.join(__dirname, 'payment_order_flow.test.js') },
  { name: '3. BOLA Refund Authorization & Masking Suite', file: path.join(__dirname, 'refund_bola.test.js') },
  { name: '4. PayOS Webhook & Idempotency Suite', file: path.join(__dirname, 'payos_webhook.test.js') },
  { name: '5. QA Phase A API & Security Audit Suite', file: path.join(__dirname, 'qa_phase_a_api.test.js') },
  { name: '6. QA Phase B Web Client Audit Suite', file: path.join(__dirname, 'qa_phase_b_web.test.js') },
];

console.log('╔════════════════════════════════════════════════════════════════╗');
console.log('║       SMART CITY FOOD ROUTE - AUTOMATED TEST RUNNER            ║');
console.log('╚════════════════════════════════════════════════════════════════╝\n');

let currentSuiteIndex = 0;
let passedSuites = 0;
let failedSuites = 0;

function runNextSuite() {
  if (currentSuiteIndex >= suites.length) {
    console.log('\n================================================================');
    console.log(`[Test Runner Summary] COMPLETED: ${passedSuites}/${suites.length} SUITES PASSED`);
    if (failedSuites > 0) {
      console.error(`[Test Runner Summary] FAILED: ${failedSuites} SUITES FAILED!`);
      process.exit(1);
    } else {
      console.log('[Test Runner Summary] ALL TEST SUITES PASSED CLEANLY (EXIT CODE 0)!');
      process.exit(0);
    }
    return;
  }

  const suite = suites[currentSuiteIndex];
  console.log(`\n>>> STARTING SUITE [${currentSuiteIndex + 1}/${suites.length}]: ${suite.name}`);
  
  const child = fork(suite.file, [], { stdio: 'inherit' });

  child.on('exit', (code) => {
    if (code === 0) {
      passedSuites++;
      console.log(`>>> SUITE [${suite.name}] FINISHED: SUCCESS (code 0)`);
    } else {
      failedSuites++;
      console.error(`>>> SUITE [${suite.name}] FINISHED: FAILED (code ${code})`);
    }
    currentSuiteIndex++;
    runNextSuite();
  });

  child.on('error', (err) => {
    failedSuites++;
    console.error(`>>> SUITE [${suite.name}] ERROR: ${err.message}`);
    currentSuiteIndex++;
    runNextSuite();
  });
}

runNextSuite();
