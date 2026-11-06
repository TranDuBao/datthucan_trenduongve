import { Request, Response, NextFunction } from 'express';

interface RateLimitRecord {
  count: number;
  resetTime: number;
}

/**
 * Lightweight, isolated Rate Limiting Middleware
 * Each limiter instance maintains its own dedicated memory store to prevent quota bleed between different endpoints.
 * @param windowMs Time window in milliseconds (default 15 minutes)
 * @param maxMax Maximum requests per window (default 1000 requests)
 */
export const createRateLimiter = (windowMs = 15 * 60 * 1000, maxMax = 1000) => {
  // Dedicated storage bucket per limiter instance (isolates e.g. authLimiter from uploadLimiter)
  const store = new Map<string, RateLimitRecord>();

  // Periodic cleanup of expired records every 5 minutes to prevent memory leaks
  const cleanupTimer = setInterval(() => {
    const now = Date.now();
    for (const [key, record] of store.entries()) {
      if (now > record.resetTime) {
        store.delete(key);
      }
    }
  }, 5 * 60 * 1000);

  if (typeof (cleanupTimer as any)?.unref === 'function') {
    (cleanupTimer as any).unref();
  }

  return (req: Request, res: Response, next: NextFunction) => {
    // Bypass rate limiting if explicitly disabled via environment variable (e.g., local load testing)
    if (process.env.NODE_ENV !== 'production' && process.env.DISABLE_RATE_LIMIT === 'true') {
      return next();
    }

    // Read IP securely resolved via Express trust proxy configuration
    const clientIp = req.ip || req.socket.remoteAddress || 'unknown';

    const now = Date.now();
    const record = store.get(clientIp);

    if (!record || now > record.resetTime) {
      store.set(clientIp, {
        count: 1,
        resetTime: now + windowMs,
      });
      return next();
    }

    if (record.count >= maxMax) {
      const retryAfterSeconds = Math.ceil((record.resetTime - now) / 1000);
      res.setHeader('Retry-After', retryAfterSeconds);
      return res.status(429).json({
        statusCode: 429,
        status: 'error',
        message: 'Bạn đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau ít phút!',
      });
    }

    record.count += 1;
    next();
  };
};
