import http from 'http';
import app from './app';
import { connectDatabase } from './config/database';
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
}

startServer();
