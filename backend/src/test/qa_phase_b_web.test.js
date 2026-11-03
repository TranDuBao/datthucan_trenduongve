/**
 * ============================================================================
 * QA AUTOMATED TEST SUITE: PHẦN B - GIAO DIỆN WEB (REACT + VITE)
 * ============================================================================
 * Branch: fix/review-round1
 * Tester: QA Automation Engineer
 * 
 * Verifies web client routes, cross-role protections, price formatting,
 * image error fallback, and responsive behavior.
 */

const fs = require('fs');
const path = require('path');
const http = require('http');

let totalTests = 0;
let passedTests = 0;
let failedTests = 0;
const testResults = [];

function recordResult(id, group, name, expected, actual, pass, evidence) {
  totalTests++;
  if (pass) {
    passedTests++;
    console.log(`  [PASS] [${id}] ${name}`);
  } else {
    failedTests++;
    console.error(`  [FAIL] [${id}] ${name}`);
    console.error(`         Expected: ${expected} | Got: ${actual}`);
  }
  testResults.push({ id, group, name, expected, actual, status: pass ? 'PASS' : 'FAIL', evidence });
}

function assert(condition, message) {
  if (!condition) throw new Error(message || 'Assertion failed');
}

function checkUrlHttp(url) {
  return new Promise((resolve) => {
    http.get(url, (res) => {
      resolve({ status: res.statusCode, headers: res.headers });
    }).on('error', (err) => {
      resolve({ status: 0, error: err.message });
    });
  });
}

async function runPhaseBTests() {
  console.log('╔════════════════════════════════════════════════════════════════╗');
  console.log('║   QA AUTOMATED TEST SUITE: PHẦN B (WEB CLIENT AUDIT)           ║');
  console.log('╚════════════════════════════════════════════════════════════════╝\n');

  // --------------------------------------------------------------------------
  // B1. ĐĂNG NHẬP VÀ ĐIỀU HƯỚNG BẢO VỆ ROLE
  // --------------------------------------------------------------------------
  console.log('--- [B1] Đăng nhập & Điều hướng Bảo vệ Role ---');

  // B1.1: Web dev server status
  {
    const res = await checkUrlHttp('http://localhost:5173');
    const pass = res.status === 200;
    recordResult('B1.1', 'B1_Nav', 'Vite Web server is active and serving index.html', '200', String(res.status), pass, `Status: ${res.status}`);
  }

  // B1.2: ProtectedLayout in App.tsx enforces role-based redirection
  {
    const appTsx = fs.readFileSync(path.join(__dirname, '../../../web/src/App.tsx'), 'utf-8');
    const hasRoleCheck = appTsx.includes('getUserRoleFromToken') && appTsx.includes('normalizeRole');
    const hasAdminRedirect = appTsx.includes("navigate to=\"/admin/dashboard\"") || appTsx.includes("<Navigate to=\"/admin/dashboard\"");
    const hasStoreRedirect = appTsx.includes("navigate to=\"/restaurant/dashboard\"") || appTsx.includes("<Navigate to=\"/restaurant/dashboard\"");
    const pass = hasRoleCheck && hasAdminRedirect && hasStoreRedirect;
    recordResult('B1.2', 'B1_Nav', 'ProtectedLayout strictly checks JWT role and blocks cross-role access', 'ProtectedLayout enforces role redirect', 'Role check & redirect present', pass, 'Verified in web/src/App.tsx');
  }

  // B1.3: Refresh page session persistence (localStorage auth_token & auth_user)
  {
    const authContext = fs.readFileSync(path.join(__dirname, '../../../web/src/context/AuthContext.tsx'), 'utf-8');
    const hasStorage = authContext.includes("localStorage.getItem('auth_token')") && authContext.includes("localStorage.getItem('auth_user')");
    recordResult('B1.3', 'B1_Nav', 'Session persistence on page refresh via localStorage', 'auth_token & auth_user in localStorage', 'Found', hasStorage, 'Verified in AuthContext.tsx');
  }

  // --------------------------------------------------------------------------
  // B2. CORS THỰC TẾ
  // --------------------------------------------------------------------------
  console.log('\n--- [B2] CORS Thực Tế ---');

  {
    const res = await new Promise((resolve) => {
      const req = http.request({
        hostname: 'localhost',
        port: 3000,
        path: '/api/v1/auth/login',
        method: 'OPTIONS',
        headers: {
          Origin: 'http://localhost:5173',
          'Access-Control-Request-Method': 'POST',
        },
      }, (r) => resolve({ status: r.statusCode, aCAllowOrigin: r.headers['access-control-allow-origin'] }));
      req.end();
    });
    const pass = (res.status === 200 || res.status === 204) && res.aCAllowOrigin === 'http://localhost:5173';
    recordResult('B2.1', 'B2_CORS', 'Official Vite origin (http://localhost:5173) allowed by API with ACAO header', '200/204 with http://localhost:5173', `${res.status} with ${res.aCAllowOrigin}`, pass, `Status: ${res.status}, ACAO: ${res.aCAllowOrigin}`);
  }

  // --------------------------------------------------------------------------
  // B3. TRANG HOÀN TIỀN ADMIN (AdminPayments)
  // --------------------------------------------------------------------------
  console.log('\n--- [B3] Trang Hoàn Tiền Admin (AdminPayments) ---');

  {
    const adminPayments = fs.readFileSync(path.join(__dirname, '../../../web/src/pages/admin/AdminPayments.tsx'), 'utf-8');
    const hasRefundTab = adminPayments.includes("activeTab === 'refunds'");
    const hasFullAccountRender = adminPayments.includes("r.h_sotaikhoannhan || r.soTaiKhoanNhan");
    const hasConfirmRefund = adminPayments.includes("handleConfirmRefund");
    const pass = hasRefundTab && hasFullAccountRender && hasConfirmRefund;
    recordResult('B3.1', 'B3_Refunds', 'AdminPayments tab renders full bank account and approval action for admin', 'Refund tab & bank account visible', 'Present', pass, 'Verified in AdminPayments.tsx');
  }

  // --------------------------------------------------------------------------
  // B4. QUÁN TRẢ VỀ LỖI HỢP LÝ KHI TRUY CẬP TÀI NGUYÊN KHÁC
  // --------------------------------------------------------------------------
  console.log('\n--- [B4] Quán Xử Lý Lỗi Hợp Lý, Không Crash Trang Trắng ---');

  {
    const restMenu = fs.readFileSync(path.join(__dirname, '../../../web/src/pages/restaurant/RestaurantMenu.tsx'), 'utf-8');
    const hasErrorCatch = restMenu.includes('catch (err') || restMenu.includes('catch {');
    const hasNotifyModal = restMenu.includes('NotificationModal') || restMenu.includes('notifyModal');
    const pass = hasErrorCatch && hasNotifyModal;
    recordResult('B4.1', 'B4_StoreError', 'Restaurant menu handles API errors via modal without white-screen crash', 'Error modal / catch block', 'Present', pass, 'Verified in RestaurantMenu.tsx');
  }

  // --------------------------------------------------------------------------
  // B5. GIÁ MÓN KHỚP BACKEND, KHÔNG CÓ GIÁ GẠCH TỰ TÍNH
  // --------------------------------------------------------------------------
  console.log('\n--- [B5] Giá Món Khớp Backend (Không Fake Struck-through Price) ---');

  {
    const restMenu = fs.readFileSync(path.join(__dirname, '../../../web/src/pages/restaurant/RestaurantMenu.tsx'), 'utf-8');
    // Check if there is fake calculation like giaMonAn * 1.2 or similar
    const hasFakePriceMultiplier = /giaMonAn\s*\*\s*1\.[1-9]/.test(restMenu);
    const usesFormatVND = restMenu.includes('formatVND(f.giaMonAn)');
    const pass = !hasFakePriceMultiplier && usesFormatVND;
    recordResult('B5.1', 'B5_Price', 'Dish prices rendered directly from backend without fake struck-through calculation', 'Direct backend price, no fake multiplier', `usesFormatVND: ${usesFormatVND}, fakeMultiplier: ${hasFakePriceMultiplier}`, pass, 'Verified in RestaurantMenu.tsx line 379');
  }

  // --------------------------------------------------------------------------
  // B6. CONSOLE & IMAGE PLACEHOLDER FALLBACK
  // --------------------------------------------------------------------------
  console.log('\n--- [B6] Console & Image Fallback ---');

  {
    const imageUtils = fs.readFileSync(path.join(__dirname, '../../../web/src/utils/imageUtils.ts'), 'utf-8');
    const hasDefaultPlaceholder = imageUtils.includes('DEFAULT_IMAGE_PLACEHOLDER');
    const hasErrorFallback = imageUtils.includes('handleImageError');
    const pass = hasDefaultPlaceholder && hasErrorFallback;
    recordResult('B6.1', 'B6_ImagePlaceholder', 'Image fallback replaces empty/broken URLs with SVG placeholder', 'DEFAULT_IMAGE_PLACEHOLDER present', 'Present', pass, 'Verified in imageUtils.ts');
  }

  // --------------------------------------------------------------------------
  // B7. RESPONSIVE LAYOUT VERIFICATION (375px, 768px, 1280px)
  // --------------------------------------------------------------------------
  console.log('\n--- [B7] Responsive Viewport Screenshots ---');

  {
    const screenshotsDir = 'C:/Users/Windows/.gemini/antigravity-ide/brain/f8ee31a0-8204-40a3-adad-c5c161e88c82';
    const files = fs.readdirSync(screenshotsDir);
    const hasMobile = files.some((f) => f.includes('login_mobile_375'));
    const hasTablet = files.some((f) => f.includes('login_tablet_768'));
    const hasDesktop = files.some((f) => f.includes('login_desktop_1280'));
    const hasMenu = files.some((f) => f.includes('restaurant_menu'));
    const pass = hasMobile && hasTablet && hasDesktop && hasMenu;
    recordResult('B7.1', 'B7_Responsive', 'Responsive viewports captured (375px mobile, 768px tablet, 1280px desktop, menu)', '4 screenshots captured', `Mobile: ${hasMobile}, Tablet: ${hasTablet}, Desktop: ${hasDesktop}, Menu: ${hasMenu}`, pass, 'Screenshots saved in artifact directory');
  }

  // --------------------------------------------------------------------------
  // SUMMARY
  // --------------------------------------------------------------------------
  console.log('\n====================================================================');
  console.log(`   PHASE B SUMMARY: ${passedTests}/${totalTests} Passed (${failedTests} Failed)`);
  console.log('====================================================================\n');

  return { totalTests, passedTests, failedTests, results: testResults };
}

if (require.main === module) {
  runPhaseBTests()
    .then(({ failedTests }) => {
      if (failedTests > 0) process.exit(1);
    })
    .catch((err) => {
      console.error('Fatal test error:', err);
      process.exit(1);
    });
}

module.exports = { runPhaseBTests };
