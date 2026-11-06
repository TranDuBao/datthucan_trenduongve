import { io, Socket } from 'socket.io-client';
import { API_HOST } from './apiClient';

const envSocketUrl = (import.meta as any).env?.VITE_SOCKET_URL;
const SOCKET_URL = envSocketUrl ? envSocketUrl.replace(/\/+$/, '') : API_HOST;
let socket: Socket | null = null;

export const getSocket = (): Socket | null => {
  const token = localStorage.getItem('auth_token');
  if (!token) {
    if (socket) {
      socket.disconnect();
      socket = null;
    }
    return null;
  }

  if (!socket) {
    socket = io(SOCKET_URL, {
      auth: { token },
      transports: ['websocket', 'polling'],
      autoConnect: true,
      reconnection: true,
      reconnectionAttempts: 10,
      reconnectionDelay: 1500,
    });

    socket.on('connect', () => {
      console.log('[SocketClient] [Info] Web Socket connected:', socket?.id);
    });

    socket.on('connect_error', (err) => {
      console.warn('[SocketClient] [Warn] Web Socket connect error:', err.message);
    });

    socket.on('disconnect', (reason) => {
      console.log('[SocketClient] [Info] Web Socket disconnected:', reason);
    });
  } else if (!socket.connected) {
    socket.connect();
  }

  return socket;
};

export const joinRestaurantRoom = (maQuan: number) => {
  const s = getSocket();
  if (s && maQuan) {
    s.emit('room:join', { roomType: 'restaurant', id: maQuan });
  }
};

export const leaveRestaurantRoom = (maQuan: number) => {
  if (socket && maQuan) {
    socket.emit('room:leave', { roomType: 'restaurant', id: maQuan });
  }
};

export const joinAdminRoom = () => {
  const s = getSocket();
  if (s) {
    s.emit('room:join', { roomType: 'admin' });
  }
};

export const leaveAdminRoom = () => {
  if (socket) {
    socket.emit('room:leave', { roomType: 'admin' });
  }
};

export const joinTicketRoom = (ticketId: number) => {
  const s = getSocket();
  if (s && ticketId) {
    s.emit('room:join', { roomType: 'ticket', id: ticketId });
  }
};

export const leaveTicketRoom = (ticketId: number) => {
  if (socket && ticketId) {
    socket.emit('room:leave', { roomType: 'ticket', id: ticketId });
  }
};

export const disconnectSocket = () => {
  if (socket) {
    socket.disconnect();
    socket = null;
  }
};
