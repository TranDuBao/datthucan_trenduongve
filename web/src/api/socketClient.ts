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

  if (!socket || !socket.connected) {
    socket = io(SOCKET_URL, {
      auth: { token },
      transports: ['websocket', 'polling'],
      autoConnect: true,
      reconnection: true,
      reconnectionAttempts: 5,
      reconnectionDelay: 2000,
    });

    socket.on('connect', () => {
      console.log('⚡ Web Socket connected:', socket?.id);
    });

    socket.on('connect_error', (err) => {
      console.warn('⚠️ Web Socket connect error:', err.message);
    });

    socket.on('disconnect', (reason) => {
      console.log('⚡ Web Socket disconnected:', reason);
    });
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

export const disconnectSocket = () => {
  if (socket) {
    socket.disconnect();
    socket = null;
  }
};
