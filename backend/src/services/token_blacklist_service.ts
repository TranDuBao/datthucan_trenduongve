import crypto from 'crypto';

interface RevokedTokenEntry {
  expiresAt: number; // in milliseconds
  revokedAt: number;
  reason?: string;
}

export class TokenBlacklistService {
  private static instance: TokenBlacklistService;
  // Map of token hash -> revocation entry
  private revokedTokens = new Map<string, RevokedTokenEntry>();
  // Map of userId -> timestamp of latest full logout (all tokens issued before this are invalid)
  private userRevocationTimestamps = new Map<number, number>();

  private constructor() {
    // Periodically prune expired entries every 15 minutes
    const timer = setInterval(() => this.cleanupExpired(), 15 * 60 * 1000);
    if (typeof (timer as any)?.unref === 'function') {
      (timer as any).unref();
    }
  }

  public static getInstance(): TokenBlacklistService {
    if (!TokenBlacklistService.instance) {
      TokenBlacklistService.instance = new TokenBlacklistService();
    }
    return TokenBlacklistService.instance;
  }

  private hashToken(token: string): string {
    return crypto.createHash('sha256').update(token.trim()).digest('hex');
  }

  /**
   * Revoke a specific token (Access Token or Refresh Token)
   */
  public revokeToken(token: string, expInSeconds?: number, reason: string = 'logout'): void {
    if (!token) return;
    const tokenHash = this.hashToken(token);
    // If exp is provided, use it; otherwise default to 30 days retention
    const expiresAt = expInSeconds
      ? expInSeconds * 1000
      : Date.now() + 30 * 24 * 60 * 60 * 1000;

    this.revokedTokens.set(tokenHash, {
      expiresAt,
      revokedAt: Date.now(),
      reason,
    });
  }

  /**
   * Invalidate all current tokens for a user (e.g. password change, account lock, global logout)
   */
  public revokeAllUserTokens(userId: number): void {
    if (!userId) return;
    this.userRevocationTimestamps.set(userId, Math.floor(Date.now() / 1000));
  }

  /**
   * Check if a token has been revoked
   */
  public isRevoked(token: string, decodedPayload?: any): boolean {
    if (!token) return true;
    const tokenHash = this.hashToken(token);
    const entry = this.revokedTokens.get(tokenHash);

    if (entry) {
      if (entry.expiresAt > Date.now()) {
        return true;
      }
      // Expired from blacklist, can remove
      this.revokedTokens.delete(tokenHash);
    }

    // Check if user was globally logged out after this token was issued
    if (decodedPayload && decodedPayload.sub) {
      const userLogoutTime = this.userRevocationTimestamps.get(Number(decodedPayload.sub));
      if (userLogoutTime && decodedPayload.iat && decodedPayload.iat < userLogoutTime) {
        return true;
      }
    }

    return false;
  }

  private cleanupExpired(): void {
    const now = Date.now();
    for (const [hash, entry] of this.revokedTokens.entries()) {
      if (entry.expiresAt <= now) {
        this.revokedTokens.delete(hash);
      }
    }
  }

  /**
   * Clear all blacklist data (useful in testing)
   */
  public resetForTesting(): void {
    this.revokedTokens.clear();
    this.userRevocationTimestamps.clear();
  }
}
