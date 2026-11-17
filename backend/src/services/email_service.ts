import nodemailer, { Transporter } from 'nodemailer';

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

    // Tự động loại bỏ mọi khoảng trắng trong mật khẩu ứng dụng Gmail (dạng "abcd efgh ijkl mnop")
    const cleanPass = rawPass.replace(/\s+/g, '');

    this.transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST || 'smtp.gmail.com',
      port: Number(process.env.SMTP_PORT) || 587,
      secure: process.env.SMTP_SECURE === 'true',
      auth: {
        user: user.trim(),
        pass: cleanPass,
      },
      tls: {
        rejectUnauthorized: false,
      },
    });

    console.log(`[EmailService] [Info] Đã khởi tạo SMTP Transporter cho tài khoản: ${user}`);
  }

  async sendOtpEmail(params: {
    toEmail: string;
    otpCode: string;
    recipientName?: string;
  }): Promise<{ success: boolean; message?: string }> {
    const { toEmail, otpCode, recipientName } = params;

    if (!this.transporter) {
      this.initTransporter();
      if (!this.transporter) {
        return { success: false, message: 'Dịch vụ gửi email chưa được cấu hình trên máy chủ' };
      }
    }

    const fromName = process.env.SMTP_FROM_NAME || 'FoodRoute System';
    const fromEmail = process.env.SMTP_FROM_EMAIL || process.env.SMTP_USER;
    const displayName = recipientName ? ` ${recipientName}` : '';

    const htmlContent = `
      <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 560px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; border: 1px solid #e2e8f0; box-shadow: 0 10px 25px rgba(0,0,0,0.05);">
        <div style="background: linear-gradient(135deg, #FF4800 0%, #FF6011 100%); padding: 32px 24px; text-align: center; color: #ffffff;">
          <h1 style="margin: 0; font-size: 26px; font-weight: 800; letter-spacing: -0.5px;">FoodRoute</h1>
          <p style="margin: 6px 0 0; font-size: 13.5px; opacity: 0.95;">Hệ Thống Đặt Thức Ăn Tiện Đường Ghé Lấy</p>
        </div>

        <div style="padding: 32px 28px;">
          <h2 style="margin: 0 0 12px; font-size: 18px; color: #0f172a; font-weight: 700;">Yêu cầu đặt lại mật khẩu</h2>
          <p style="margin: 0 0 20px; font-size: 14px; color: #475569; line-height: 1.6;">
            Xin chào<strong>${displayName}</strong>,<br>
            Bạn vừa gửi yêu cầu đặt lại mật khẩu cho tài khoản FoodRoute liên kết với địa chỉ email này. Vui lòng sử dụng mã xác thực (OTP) dưới đây:
          </p>

          <div style="background: #fff7ed; border: 2px dashed #fdba74; border-radius: 12px; padding: 20px; text-align: center; margin: 24px 0;">
            <div style="font-size: 12px; font-weight: 700; color: #c2410c; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 6px;">MÃ XÁC THỰC CỦA BẠN</div>
            <div style="font-size: 34px; font-weight: 900; color: #ea580c; letter-spacing: 8px; font-family: monospace;">${otpCode}</div>
            <div style="font-size: 12px; color: #9a3412; margin-top: 8px;">Mã có hiệu lực trong vòng <strong>5 phút</strong></div>
          </div>

          <p style="margin: 0 0 16px; font-size: 13px; color: #64748b; line-height: 1.5;">
            Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua email. Mật khẩu của bạn vẫn an toàn và không thay đổi.
          </p>

          <div style="border-top: 1px solid #f1f5f9; padding-top: 18px; margin-top: 24px; font-size: 12px; color: #94a3b8; text-align: center;">
            Đây là email tự động từ FoodRoute. Vui lòng không trả lời thư này.<br>
            Cần trợ giúp? Liên hệ hotline: <strong>1900 6868</strong> hoặc email: <strong>support@foodroute.vn</strong>
          </div>
        </div>
      </div>
    `;

    try {
      await this.transporter.sendMail({
        from: `"${fromName}" <${fromEmail}>`,
        to: toEmail,
        subject: `[FoodRoute] Mã xác thực đặt lại mật khẩu: ${otpCode}`,
        html: htmlContent,
      });

      console.log(`[EmailService] [Success] Đã gửi mã OTP thành công đến email: ${toEmail}`);
      return { success: true };
    } catch (error: any) {
      console.error(`[EmailService] [Error] Gửi mail OTP thất bại đến ${toEmail}:`, error);
      return { success: false, message: error.message || 'Lỗi gửi email qua máy chủ SMTP' };
    }
  }
}
