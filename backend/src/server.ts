import http from 'http';
import app from './app';
import { connectDatabase, AppDataSource } from './config/database';
import { RealtimeService } from './services/realtime_service';
import { LegalDocumentService } from './services/legal_document_service';

const PORT = process.env.PORT || 3000;

async function startServer() {
  await connectDatabase();
  await LegalDocumentService.getInstance().seedInitialDraftDocuments();

  const server = http.createServer(app);
  RealtimeService.getInstance().initialize(server);

  server.listen(PORT, () => {
    console.log(`[Server] [Info] Server đang lắng nghe tại cổng ${PORT}`);
    console.log(`[Server] [Info] Healthcheck: http://localhost:${PORT}/health`);
    console.log(`[Server] [Info] Auth API: http://localhost:${PORT}/api/v1/auth`);
  });

  const gracefulShutdown = async (signal: string) => {
    console.log(`[Server] [Info] Nhận tín hiệu ${signal}. Đang đóng các kết nối an toàn...`);
    server.close(async () => {
      try {
        if (AppDataSource.isInitialized) {
          await AppDataSource.destroy();
          console.log('[Server] [Info] Đã đóng kết nối Database an toàn.');
        }
      } catch (e) {
        console.error('[Server] [Error] Lỗi khi đóng database:', e);
      }
      process.exit(0);
    });

    // Timeout buộc tắt sau 10 giây nếu các kết nối chưa thoát
    const forceExitTimer = setTimeout(() => {
      console.error('[Server] [Warn] Quá thời gian chờ shutdown 10s. Buộc dừng tiến trình.');
      process.exit(1);
    }, 10000) as any;
    if (forceExitTimer && typeof forceExitTimer.unref === 'function') {
      forceExitTimer.unref();
    }
  };

  process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
  process.on('SIGINT', () => gracefulShutdown('SIGINT'));

  process.on('unhandledRejection', (reason, promise) => {
    console.error('[Server] [UnhandledRejection]:', reason);
  });

  process.on('uncaughtException', (error) => {
    console.error('[Server] [UncaughtException]:', error);
  });
}

startServer();
