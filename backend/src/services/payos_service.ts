import crypto from 'crypto';
import https from 'https';

export interface PayOSPaymentLinkResult {
  bin: string;
  accountNumber: string;
  accountName: string;
  amount: number;
  description: string;
  orderCode: number;
  paymentLinkId: string;
  checkoutUrl: string;
  qrCode?: string;
}

export class PayOSService {
  private static clientId = process.env.PAYOS_CLIENT_ID || '';
  private static apiKey = process.env.PAYOS_API_KEY || '';
  private static checksumKey = process.env.PAYMENT_WEBHOOK_SECRET || '';

  /**
   * Tạo Payment Link chính thức từ PayOS để nhận biến động số dư TỨC THÌ (1-2 giây)
   */
  static async createPaymentLink(params: {
    orderCode: number;
    amount: number;
    description: string;
    cancelUrl?: string;
    returnUrl?: string;
  }): Promise<PayOSPaymentLinkResult | null> {
    if (!this.clientId || !this.apiKey || !this.checksumKey) {
      console.warn('[PayOSService] Thiếu cấu hình PayOS trong .env, sử dụng mã QR tĩnh dự phòng');
      return null;
    }

    return new Promise((resolve) => {
      try {
        const orderCode = Number(params.orderCode);
        const amount = Math.round(Number(params.amount));
        // PayOS description tối đa 25 ký tự, chỉ chứa chữ và số
        const description = (params.description || `DH${orderCode}`).replace(/[^a-zA-Z0-9]/g, '').slice(0, 25);
        const cancelUrl = params.cancelUrl || 'http://localhost:3000/cancel';
        const returnUrl = params.returnUrl || 'http://localhost:3000/success';

        const data: Record<string, any> = {
          amount,
          cancelUrl,
          description,
          orderCode,
          returnUrl,
        };

        const sortedKeys = Object.keys(data).sort();
        const str = sortedKeys.map((k) => `${k}=${data[k]}`).join('&');
        const signature = crypto.createHmac('sha256', this.checksumKey).update(str).digest('hex');

        const payload = JSON.stringify({ ...data, signature });

        const req = https.request(
          'https://api-merchant.payos.vn/v2/payment-requests',
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'x-client-id': this.clientId,
              'x-api-key': this.apiKey,
              'Content-Length': Buffer.byteLength(payload),
            },
            timeout: 10000,
          },
          (res) => {
            let body = '';
            res.on('data', (chunk) => (body += chunk));
            res.on('end', () => {
              try {
                const json = JSON.parse(body);
                if (json.code === '00' && json.data) {
                  console.log(`[PayOSService] [Info] Tạo Payment Link thành công cho đơn #${orderCode}: STK Virtual ${json.data.accountNumber}`);
                  resolve(json.data as PayOSPaymentLinkResult);
                } else {
                  console.error(`[PayOSService] [Error] Lỗi từ PayOS:`, json);
                  resolve(null);
                }
              } catch (parseErr) {
                console.error(`[PayOSService] [Error] Parse error:`, parseErr);
                resolve(null);
              }
            });
          }
        );

        req.on('error', (err) => {
          console.error(`[PayOSService] [Error] Request error:`, err);
          resolve(null);
        });

        req.on('timeout', () => {
          req.destroy();
          console.error(`[PayOSService] [Error] Request timeout sau 10s`);
          resolve(null);
        });

        req.write(payload);
        req.end();
      } catch (err) {
        console.error(`[PayOSService] [Error] Unexpected exception:`, err);
        resolve(null);
      }
    });
  }
}
