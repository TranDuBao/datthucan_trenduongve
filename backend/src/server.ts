import app from './app';
import { connectDatabase } from './config/database';

const PORT = process.env.PORT || 3000;

async function startServer() {
  await connectDatabase();

  app.listen(PORT, () => {
    console.log(`🚀 Server đang lắng nghe tại cổng ${PORT}`);
    console.log(`🔗 Healthcheck: http://localhost:${PORT}/health`);
    console.log(`🔑 Auth API: http://localhost:${PORT}/api/v1/auth`);
  });
}

startServer();
