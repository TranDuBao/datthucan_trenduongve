import React from 'react';
import { API_HOST } from '../api/apiClient';

export { API_HOST };

export const DEFAULT_IMAGE_PLACEHOLDER = `data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyMDAiIGhlaWdodD0iMjAwIiB2aWV3Qm94PSIwIDAgMjAwIDIwMCIgZmlsbD0ibm9uZSI+PHJlY3Qgd2lkdGg9IjIwMCIgaGVpZ2h0PSIyMDAiIHJ4PSIyNCIgZmlsbD0iI2UyZThmMCIvPjxwYXRoIGQ9Ik01MCA2MEM1MCA1MS4xNjM0IDU3LjE2MzQgNDQgNjYgNDRIMTM0QzE0Mi44MzcgNDQgMTUwIDUxLjE2MzQgMTUwIDYwVjE0MEMxNTAgMTQ4LjgzNyAxNDIuODM3IDE1NiAxMzQgMTU2SDY2QzU3LjE2MzQgMTU2IDUwIDE0OC44MzcgNTAgMTQwVjYwWiIgc3Ryb2tlPSIjNjQ3NDhiIiBzdHJva2Utd2lkdGg9IjciIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIgc3Ryb2tlLWxpbmVqb2luPSJyb3VuZCIvPjxjaXJjbGUgY3g9Ijc4IiBjeT0iODAiIHI9IjEwIiBmaWxsPSIjNjQ3NDhiIi8+PHBhdGggZD0iTTU0IDEzOEw4NiAxMDJMMTEyIDEyOEwxMzIgMTA4TDE0NiAxMjIiIHN0cm9rZT0iIzY0NzQ4YiIgc3Ryb2tlLXdpZHRoPSI3IiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiLz48cGF0aCBkPSJNMTI4IDMyTDEzMiA0MEwxNDAgNDRMMTMyIDQ4TDEyOCA1NkwxMjQgNDhMMTE2IDQ0TDEyNCA0MEwxMjggMzJaIiBmaWxsPSIjNjQ3NDhiIi8+PC9zdmc+`;

export function isValidImageUrl(url?: string | null): boolean {
  if (!url || typeof url !== 'string') return false;
  const trimmed = url.trim();
  if (!trimmed) return false;

  // Base64 image data
  if (trimmed.startsWith('data:image/')) return true;

  // Standard http/https URL
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return true;

  // Relative upload path
  if (trimmed.startsWith('/uploads/') || trimmed.startsWith('uploads/')) return true;

  // Common image extensions if path like /images/foo.png
  if (/\.(png|jpe?g|gif|webp|svg|bmp)(\?.*)?$/i.test(trimmed)) return true;

  return false;
}

export function getImageUrl(
  url?: string | null,
  fallback: string = DEFAULT_IMAGE_PLACEHOLDER
): string {
  if (!url || typeof url !== 'string' || !url.trim()) return fallback;
  const trimmed = url.trim();

  if (!isValidImageUrl(trimmed)) {
    return fallback;
  }

  // Handle uploaded images containing /uploads/
  if (trimmed.includes('/uploads/')) {
    const fileName = trimmed.split('/uploads/').pop();
    if (fileName) {
      return `${API_HOST}/uploads/${fileName}`;
    }
  }

  // Return base64 or complete external URLs directly (e.g. Unsplash, CDN)
  if (
    trimmed.startsWith('data:image/') ||
    trimmed.startsWith('http://') ||
    trimmed.startsWith('https://')
  ) {
    return trimmed;
  }

  return trimmed;
}

export function handleImageError(
  e: React.SyntheticEvent<HTMLImageElement, Event>,
  fallback: string = DEFAULT_IMAGE_PLACEHOLDER
) {
  const target = e.currentTarget;
  if (target.getAttribute('data-error-handled') === 'true') return;
  target.setAttribute('data-error-handled', 'true');
  target.src = fallback;
}
