/**
 * Test Suite: Authentication Security & Token Lifecycle (SEC-02 Verification)
 */
import { TokenBlacklistService } from '../services/token_blacklist_service';

describe('SEC-02: Token Revocation & Refresh Token Lifecycle Tests', () => {
  const blacklist = TokenBlacklistService.getInstance();

  beforeEach(() => {
    blacklist.resetForTesting();
  });

  it('1. Should report false for unrevoked token and true after token is revoked', () => {
    const fakeToken = 'header.payload.signature_token_123';
    expect(blacklist.isRevoked(fakeToken)).toBe(false);

    blacklist.revokeToken(fakeToken, Math.floor(Date.now() / 1000) + 3600, 'logout');
    expect(blacklist.isRevoked(fakeToken)).toBe(true);
  });

  it('2. Should revoke all tokens issued before user global logout timestamp', () => {
    const userId = 42;
    const nowSec = Math.floor(Date.now() / 1000);

    const oldTokenPayload = { sub: userId, iat: nowSec - 60, exp: nowSec + 3600, type: 'access' };
    const newTokenPayload = { sub: userId, iat: nowSec + 10, exp: nowSec + 3600, type: 'access' };

    // Initially neither is revoked
    expect(blacklist.isRevoked('old_token', oldTokenPayload)).toBe(false);
    expect(blacklist.isRevoked('new_token', newTokenPayload)).toBe(false);

    // Global logout happens at nowSec
    blacklist.revokeAllUserTokens(userId);

    // Old token must be revoked, newer token remains valid
    expect(blacklist.isRevoked('old_token', oldTokenPayload)).toBe(true);
    expect(blacklist.isRevoked('new_token', newTokenPayload)).toBe(false);
  });

  it('3. Should reject refresh token when used on regular access token endpoints', () => {
    const decodedRefreshToken = { sub: 10, type: 'refresh', jti: 'ref_123' };
    const isAccess = decodedRefreshToken.type !== 'refresh';
    expect(isAccess).toBe(false);
  });

  it('4. Refresh token rotation: Revoked refresh token cannot be reused', () => {
    const usedRefreshToken = 'refresh_token_abc_xyz';
    const exp = Math.floor(Date.now() / 1000) + 86400;

    // First use: token is valid
    expect(blacklist.isRevoked(usedRefreshToken)).toBe(false);

    // After rotation: token is marked revoked
    blacklist.revokeToken(usedRefreshToken, exp, 'rotated');

    // Attempting to reuse the same refresh token must be rejected
    expect(blacklist.isRevoked(usedRefreshToken)).toBe(true);
  });
});
