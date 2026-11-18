import nodemailer, { Transporter } from 'nodemailer';
import https from 'https';

export class EmailService {
  private static instance: EmailService;
  private transporter: Transporter | null = null;

  private constructor() {
    this.initTransporter();
  }

  static getInstance(): EmailService {
    if (!EmailService.instance) {
      EmailService.instance = new EmailService();
    }
    return EmailService.instance;
  }

  private initTransporter() {
    const user = process.env.SMTP_USER;
    const rawPass = process.env.SMTP_PASS;

    if (!user || !rawPass) {
      console.warn('[EmailService] [Notice] Chưa cấu hình SMTP_USER hoặc SMTP_PASS trong .env');
      return;
    }

    const cleanPass = rawPass.replace(/\s+/g, '');
    const isGmail = (process.env.SMTP_HOST || '').includes('gmail') || user.includes('@gmail.com');

    if (isGmail) {
      this.transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
          user: user.trim(),
          pass: cleanPass,
        },
        tls: {
          rejectUnauthorized: false,
        },
        connectionTimeout: 8000,
        greetingTimeout: 8000,
        socketTimeout: 10000,
      });
      console.log(`[EmailService] [Info] Đã khởi tạo SMTP Transporter (service: gmail)`);
    } else {
      const port = Number(process.env.SMTP_PORT) || 465;
      const secure = process.env.SMTP_SECURE === 'true' || port === 465;
      this.transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST || 'localhost',
        port,
        secure,
        auth: {
          user: user.trim(),
          pass: cleanPass,
        },
        tls: {
          rejectUnauthorized: false,
        },
        connectionTimeout: 8000,
        greetingTimeout: 8000,
        socketTimeout: 10000,
      });
      console.log(`[EmailService] [Info] Đã khởi tạo SMTP Transporter (${process.env.SMTP_HOST || 'custom'}:${port})`);
    }
  }

  private async sendViaBrevo(params: {
    apiKey: string;
    fromEmail: string;
    fromName: string;
    toEmail: string;
    toName?: string;
    subject: string;
    htmlContent: string;
  }): Promise<{ success: boolean; message?: string }> {
    return new Promise((resolve) => {
      const postData = JSON.stringify({
        sender: { name: params.fromName, email: params.fromEmail },
        to: [{ email: params.toEmail, name: params.toName || params.toEmail }],
        subject: params.subject,
        htmlContent: params.htmlContent,
      });

      const options = {
        hostname: 'api.brevo.com',
        port: 443,
        path: '/v3/smtp/email',
        method: 'POST',
        headers: {
          'api-key': params.apiKey.trim(),
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(postData),
        },
        timeout: 12000,
      };

      const req = https.request(options, (res) => {
        let body = '';
        res.on('data', (chunk) => (body += chunk));
        res.on('end', () => {
          if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
            resolve({ success: true });
          } else {
            console.error('[EmailService] [Brevo Error]', body);
            resolve({ success: false, message: `Brevo API error: ${res.statusCode}` });
          }
        });
      });

      req.on('error', (e) => {
        console.error('[EmailService] [Brevo Network Error]', e.message);
        resolve({ success: false, message: e.message });
      });

      req.on('timeout', () => {
        req.destroy();
        resolve({ success: false, message: 'Brevo API timeout' });
      });

      req.write(postData);
      req.end();
    });
  }

  private async sendViaResend(params: {
    apiKey: string;
    fromEmail: string;
    toEmail: string;
    subject: string;
    htmlContent: string;
  }): Promise<{ success: boolean; message?: string }> {
    return new Promise((resolve) => {
      const postData = JSON.stringify({
        from: params.fromEmail.includes('<') ? params.fromEmail : `FoodRoute <${params.fromEmail}>`,
        to: [params.toEmail],
        subject: params.subject,
        html: params.htmlContent,
      });

      const options = {
        hostname: 'api.resend.com',
        port: 443,
        path: '/emails',
        method: 'POST',
        headers: {
          Authorization: `Bearer ${params.apiKey.trim()}`,
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(postData),
        },
        timeout: 12000,
      };

      const req = https.request(options, (res) => {
        let body = '';
        res.on('data', (chunk) => (body += chunk));
        res.on('end', () => {
          if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
            resolve({ success: true });
          } else {
            console.error('[EmailService] [Resend Error]', body);
            resolve({ success: false, message: `Resend API error: ${res.statusCode}` });
          }
        });
      });

      req.on('error', (e) => {
        console.error('[EmailService] [Resend Network Error]', e.message);
        resolve({ success: false, message: e.message });
      });

      req.on('timeout', () => {
        req.destroy();
        resolve({ success: false, message: 'Resend API timeout' });
      });

      req.write(postData);
      req.end();
    });
  }

  async sendOtpEmail(params: {
    toEmail: string;
    otpCode: string;
    recipientName?: string;
    type?: 'FORGOT_PASSWORD' | 'REGISTER';
  }): Promise<{ success: boolean; message?: string; isCloudBlocked?: boolean }> {
    const { toEmail, otpCode, recipientName, type = 'FORGOT_PASSWORD' } = params;

    const fromName = process.env.SMTP_FROM_NAME || 'FoodRoute';
    const fromEmail = process.env.BREVO_SENDER_EMAIL || process.env.SMTP_FROM_EMAIL || process.env.SMTP_USER || 'no-reply@foodroute.vn';
    const displayName = recipientName ? ` ${recipientName}` : '';

    const isRegister = type === 'REGISTER';
    const emailTitle = isRegister ? 'Xác thực tài khoản mới' : 'Yêu cầu đặt lại mật khẩu';
    const emailSubject = isRegister
      ? `[FoodRoute] Mã xác thực đăng ký tài khoản: ${otpCode}`
      : `[FoodRoute] Mã xác thực đặt lại mật khẩu: ${otpCode}`;

    const greetingText = isRegister
      ? `Xin chào<strong>${displayName}</strong>,<br>Chào mừng bạn đến với FoodRoute! Để hoàn tất đăng ký tài khoản, vui lòng sử dụng mã xác thực (OTP) dưới đây để xác thực địa chỉ email của bạn:`
      : `Xin chào<strong>${displayName}</strong>,<br>Bạn vừa gửi yêu cầu đặt lại mật khẩu cho tài khoản FoodRoute liên kết với địa chỉ email này. Vui lòng sử dụng mã xác thực (OTP) dưới đây:`;

    const subWarningText = isRegister
      ? `Nếu bạn không thực hiện đăng ký tài khoản trên ứng dụng FoodRoute, vui lòng bỏ qua email này.`
      : `Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua email. Mật khẩu của bạn vẫn an toàn và không thay đổi.`;

    const htmlContent = `
      <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 560px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; border: 1px solid #e2e8f0; box-shadow: 0 10px 25px rgba(0,0,0,0.05);">
        <div style="background: linear-gradient(135deg, #FF4200 0%, #FF5714 50%, #FF6D22 100%); padding: 26px 24px; color: #ffffff;">
          <table width="100%" border="0" cellpadding="0" cellspacing="0" style="border-collapse: collapse;">
            <tr>
              <td align="left" valign="middle">
                <div style="font-size: 28px; font-weight: 900; letter-spacing: -0.5px; line-height: 1.1; margin: 0; color: #ffffff;">
                  FoodRoute<span style="color: #FFD54F;">.</span>
                </div>
                <div style="margin-top: 6px; font-size: 13px; font-weight: 500; opacity: 0.95; line-height: 1.4; color: #ffffff;">
                  Món ngon dọc đường đi,<br>Đặt món trước, ghé là có.
                </div>
              </td>
              <td align="right" valign="middle" width="130" style="width: 130px;">
                <div style="display: inline-block; background: rgba(255, 255, 255, 0.18); border-radius: 50%; padding: 8px;">
                  <img src="https://res.cloudinary.com/qla1kfvo/image/upload/v1794970961/foodroute/branding/commuter_scooter_email.png" alt="FoodRoute Commuter" width="105" style="display: block; width: 105px; max-width: 105px; height: auto;" />
                </div>
              </td>
            </tr>
          </table>
        </div>

        <div style="padding: 32px 28px;">
          <h2 style="margin: 0 0 12px; font-size: 18px; color: #0f172a; font-weight: 700;">${emailTitle}</h2>
          <p style="margin: 0 0 20px; font-size: 14px; color: #475569; line-height: 1.6;">
            ${greetingText}
          </p>

          <div style="background: #fff7ed; border: 2px dashed #fdba74; border-radius: 12px; padding: 20px; text-align: center; margin: 24px 0;">
            <div style="font-size: 12px; font-weight: 700; color: #c2410c; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 6px;">MÃ XÁC THỰC CỦA BẠN</div>
            <div style="font-size: 34px; font-weight: 900; color: #ea580c; letter-spacing: 8px; font-family: monospace;">${otpCode}</div>
            <div style="font-size: 12px; color: #9a3412; margin-top: 8px;">Mã có hiệu lực trong vòng <strong>5 phút</strong></div>
          </div>

          <p style="margin: 0 0 16px; font-size: 13px; color: #64748b; line-height: 1.5;">
            ${subWarningText}
          </p>

          <div style="border-top: 1px solid #f1f5f9; padding-top: 18px; margin-top: 24px; font-size: 12px; color: #94a3b8; text-align: center;">
            Đây là email tự động từ FoodRoute. Vui lòng không trả lời thư này.<br>
            Cần trợ giúp? Liên hệ hotline: <strong>1900 6868</strong> hoặc email: <strong>support@foodroute.vn</strong>
          </div>
        </div>
      </div>
    `;

    // 1. Kiểm tra Brevo API HTTPS (Cổng 443 - không bao giờ bị Cloud chặn)
    const brevoApiKey = process.env.BREVO_API_KEY || process.env.SENDINBLUE_API_KEY;
    if (brevoApiKey) {
      console.log(`[EmailService] [Info] Đang gửi qua Brevo HTTPS API đến: ${toEmail}`);
      const brevoRes = await this.sendViaBrevo({
        apiKey: brevoApiKey,
        fromEmail,
        fromName,
        toEmail,
        toName: recipientName,
        subject: emailSubject,
        htmlContent,
      });
      if (brevoRes.success) {
        console.log(`[EmailService] [Success] Brevo đã gửi mail OTP (${type}) thành công đến: ${toEmail}`);
        return { success: true };
      }
    }

    // 2. Kiểm tra Resend API HTTPS (Cổng 443)
    const resendApiKey = process.env.RESEND_API_KEY;
    if (resendApiKey) {
      console.log(`[EmailService] [Info] Đang gửi qua Resend HTTPS API đến: ${toEmail}`);
      const resendRes = await this.sendViaResend({
        apiKey: resendApiKey,
        fromEmail: process.env.RESEND_FROM_EMAIL || 'onboarding@resend.dev',
        toEmail,
        subject: emailSubject,
        htmlContent,
      });
      if (resendRes.success) {
        console.log(`[EmailService] [Success] Resend đã gửi mail OTP (${type}) thành công đến: ${toEmail}`);
        return { success: true };
      }
    }

    // 3. Fallback qua SMTP Nodemailer
    if (!this.transporter) {
      this.initTransporter();
      if (!this.transporter) {
        return { success: false, message: 'Dịch vụ gửi email chưa được cấu hình trên máy chủ', isCloudBlocked: true };
      }
    }

    try {
      const sendPromise = this.transporter.sendMail({
        from: `"${fromName}" <${fromEmail}>`,
        to: toEmail,
        subject: emailSubject,
        html: htmlContent,
      });

      const timeoutPromise = new Promise<never>((_, reject) => {
        setTimeout(() => reject(new Error('Hết thời gian chờ kết nối máy chủ gửi mail (Timeout 10s)')), 10000);
      });

      await Promise.race([sendPromise, timeoutPromise]);

      console.log(`[EmailService] [Success] Đã gửi mã OTP (${type}) qua SMTP thành công đến email: ${toEmail}`);
      return { success: true };
    } catch (error: any) {
      console.error(`[EmailService] [Error] Gửi mail OTP (${type}) thất bại đến ${toEmail}:`, error.message);
      return {
        success: false,
        message: error.message || 'Lỗi gửi email qua máy chủ SMTP',
        isCloudBlocked: true,
      };
    }
  }
}
