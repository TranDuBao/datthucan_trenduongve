import { Request, Response, NextFunction } from 'express';

interface RateLimitRecord {
  count: number;
  resetTime: number;
}

const ipStore = new Map<string, RateLimitRecord>();

// Periodic cleanup of expired rate limit IP records every 5 minutes to prevent memory leak
const cleanupInterval = setInterval(() => {
  const now = Date.now();
  for (const [ip, record] of ipStore.entries()) {
    if (now > record.resetTime) {
      ipStore.delete(ip);
    }
  }
}, 5 * 60 * 1000);

if (cleanupInterval.unref) {
  cleanupInterval.unref();
}

/**
 * Lightweight in-memory Rate Limiting Middleware
 * @param windowMs Time window in milliseconds (default 15 minutes)
 * @param maxMax Maximum requests per window (default 1000 requests)
 */
export const createRateLimiter = (windowMs = 15 * 60 * 1000, maxMax = 1000) => {
  return (req: Request, res: Response, next: NextFunction) => {
    // Bypass rate limiting if explicitly disabled via environment variable (e.g., local load testing)
    if (process.env.NODE_ENV !== 'production' && process.env.DISABLE_RATE_LIMIT === 'true') {
      return next();
    }

    // Read IP securely resolved via Express trust proxy configuration
    const clientIp = req.ip || req.socket.remoteAddress || 'unknown';

    const now = Date.now();
    const record = ipStore.get(clientIp);

    if (!record || now > record.resetTime) {
      ipStore.set(clientIp, {
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
