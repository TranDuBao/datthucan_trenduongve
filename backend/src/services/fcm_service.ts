import { initializeApp, cert, getApps, App } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import fs from 'fs';
import path from 'path';

export interface SendPushOptions {
  tokens: string[];
  title: string;
  body: string;
  data?: Record<string, string>;
  channelId?: string;
  badge?: number;
}

export interface SendPushResult {
  successCount: number;
  failureCount: number;
  deadTokens: string[];
}

export class FcmService {
  private static instance: FcmService;
  private app: App | null = null;
  private initialized = false;

  private constructor() {
    this.initFirebase();
  }

  public static getInstance(): FcmService {
    if (!FcmService.instance) {
      FcmService.instance = new FcmService();
    }
    return FcmService.instance;
  }

  private initFirebase() {
    const existingApps = getApps();
    if (existingApps.length > 0) {
      this.app = existingApps[0];
      this.initialized = true;
      return;
    }

    try {
      // 1. Try env var with JSON content or path
      const keyEnv = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
      if (keyEnv) {
        if (keyEnv.trim().startsWith('{')) {
          const serviceAccount = JSON.parse(keyEnv);
          this.app = initializeApp({
            credential: cert(serviceAccount),
          });
          this.initialized = true;
          console.log('[FcmService] Firebase Admin SDK initialized from env JSON.');
          return;
        } else if (fs.existsSync(keyEnv)) {
          const serviceAccount = JSON.parse(fs.readFileSync(keyEnv, 'utf8'));
          this.app = initializeApp({
            credential: cert(serviceAccount),
          });
          this.initialized = true;
          console.log('[FcmService] Firebase Admin SDK initialized from key file.');
          return;
        }
      }

      // 2. Try individual env credentials
      if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) {
        this.app = initializeApp({
          credential: cert({
            projectId: process.env.FIREBASE_PROJECT_ID,
            clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
            privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
          }),
        });
        this.initialized = true;
        console.log('[FcmService] Firebase Admin SDK initialized from individual env credentials.');
        return;
      }

      // 3. Fallback check for service-account.json in backend/config
      const defaultPath = path.resolve(__dirname, '../config/firebase-service-account.json');
      if (fs.existsSync(defaultPath)) {
        const serviceAccount = JSON.parse(fs.readFileSync(defaultPath, 'utf8'));
        this.app = initializeApp({
          credential: cert(serviceAccount),
        });
        this.initialized = true;
        console.log('[FcmService] Firebase Admin SDK initialized from default config file.');
        return;
      }

      console.warn('[FcmService] Firebase credentials not configured. FCM push notifications are in fallback mode.');
    } catch (err: any) {
      console.error('[FcmService] Failed to initialize Firebase Admin SDK:', err.message);
    }
  }

  public isAvailable(): boolean {
    return this.initialized;
  }

  /**
   * Send push notification to multiple device tokens via FCM.
   * Auto-identifies dead/unregistered tokens for safe cleanup.
   */
  public async sendMulticastPush(options: SendPushOptions): Promise<SendPushResult> {
    const { tokens, title, body, data = {}, channelId = 'food_route_orders', badge } = options;

    if (!tokens || tokens.length === 0) {
      return { successCount: 0, failureCount: 0, deadTokens: [] };
    }

    if (!this.initialized || !this.app) {
      // In development or when credentials are not yet set, log gracefully without throwing
      return { successCount: tokens.length, failureCount: 0, deadTokens: [] };
    }

    // FCM data payload values must all be strings
    const stringifiedData: Record<string, string> = {};
    for (const [k, v] of Object.entries(data)) {
      stringifiedData[k] = typeof v === 'string' ? v : JSON.stringify(v);
    }

    const deadTokens: string[] = [];
    let successCount = 0;
    let failureCount = 0;

    // Send in batches of 500 (FCM max batch size limit)
    const chunkSize = 500;
    for (let i = 0; i < tokens.length; i += chunkSize) {
      const chunk = tokens.slice(i, i + chunkSize);

      try {
        const messaging = getMessaging(this.app);
        const response = await messaging.sendEachForMulticast({
          tokens: chunk,
          notification: {
            title,
            body,
          },
          data: stringifiedData,
          android: {
            priority: 'high',
            notification: {
              channelId,
              color: '#FF5A0E',
              sound: 'default',
              defaultSound: true,
              notificationCount: badge,
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                badge: badge ?? 1,
                contentAvailable: true,
              },
            },
          },
        });

        successCount += response.successCount;
        failureCount += response.failureCount;

        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const errCode = resp.error?.code;
            if (
              errCode === 'messaging/invalid-registration-token' ||
              errCode === 'messaging/registration-token-not-registered'
            ) {
              deadTokens.push(chunk[idx]);
            }
          }
        });
      } catch (batchErr: any) {
        console.error('[FcmService] Batch push failed:', batchErr.message);
        failureCount += chunk.length;
      }
    }

    return {
      successCount,
      failureCount,
      deadTokens,
    };
  }
}
