/**
 * Role Constants and Normalization Utilities for Web Portal
 * Ensures consistency between DB typo 'CUAN_HANG' and standard 'CUA_HANG'
 */

export const ROLES = {
  ADMIN: 'ADMIN',
  CUAN_HANG: 'CUAN_HANG',
  CUA_HANG: 'CUAN_HANG', // Alias
  KHACH_HANG: 'KHACH_HANG',
  NHAN_VIEN: 'NHAN_VIEN',
} as const;

export type UserRole = 'ADMIN' | 'CUAN_HANG' | 'KHACH_HANG' | 'NHAN_VIEN';

/**
 * Checks whether a given role is a merchant/store role (CUAN_HANG, CUA_HANG, etc.)
 */
export function isStoreRole(role?: string | null): boolean {
  if (!role) return false;
  const normalized = String(role).trim().toUpperCase();
  return (
    normalized === 'CUAN_HANG' ||
    normalized === 'CUA_HANG' ||
    normalized === 'STORE' ||
    normalized === 'RESTAURANT' ||
    normalized === 'MERCHANT' ||
    normalized === 'CHU_CUA_HANG'
  );
}

/**
 * Normalizes any role variation to canonical values ('ADMIN', 'CUAN_HANG', 'KHACH_HANG', 'NHAN_VIEN')
 */
export function normalizeRole(role?: string | null): UserRole {
  if (!role) return 'KHACH_HANG';
  const normalized = String(role).trim().toUpperCase();
  if (isStoreRole(normalized)) return 'CUAN_HANG';
  if (normalized === 'ADMIN' || normalized === 'QUAN_TRI') return 'ADMIN';
  if (normalized === 'NHAN_VIEN') return 'NHAN_VIEN';
  return 'KHACH_HANG';
}
