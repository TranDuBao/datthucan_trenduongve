import React from 'react';
import { BrowserRouter, Routes, Route, Navigate, Outlet } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import { Sidebar } from './components/Sidebar';
import { Header } from './components/Header';
import { Login } from './pages/Login';
import { isTokenExpired, getUserRoleFromToken } from './utils/jwtUtils';

// Admin Pages
import { AdminDashboard } from './pages/admin/AdminDashboard';
import { AdminUsers } from './pages/admin/AdminUsers';
import { AdminRestaurants } from './pages/admin/AdminRestaurants';
import { AdminOrders } from './pages/admin/AdminOrders';
import { AdminActivityLogs } from './pages/admin/AdminActivityLogs';
import { AdminReviews } from './pages/admin/AdminReviews';

// Restaurant Pages
import { RestaurantDashboard } from './pages/restaurant/RestaurantDashboard';
import { RestaurantRevenue } from './pages/restaurant/RestaurantRevenue';
import { RestaurantOrders } from './pages/restaurant/RestaurantOrders';
import { RestaurantMenu } from './pages/restaurant/RestaurantMenu';
import { RestaurantVouchers } from './pages/restaurant/RestaurantVouchers';
import { RestaurantProfile } from './pages/restaurant/RestaurantProfile';
import { RestaurantReservations } from './pages/restaurant/RestaurantReservations';
import { RestaurantReviews } from './pages/restaurant/RestaurantReviews';


const ProtectedLayout: React.FC<{ allowedRoles: string[] }> = ({ allowedRoles }) => {
  const { user, token } = useAuth();

  if (!token || !user || isTokenExpired(token)) {
    return <Navigate to="/login" replace />;
  }

  // Derive role strictly from JWT token claim
  const jwtRole = getUserRoleFromToken(token);
  const effectiveRole = (jwtRole || user.role || '').toUpperCase();
  const normalizedUserRole = effectiveRole === 'CUA_HANG' ? 'CUAN_HANG' : effectiveRole;

  const hasAccess = allowedRoles.some((r) => {
    const normalizedR = r.toUpperCase() === 'CUA_HANG' ? 'CUAN_HANG' : r.toUpperCase();
    return normalizedR === normalizedUserRole;
  });

  if (!hasAccess) {
    if (normalizedUserRole === 'ADMIN') {
      return <Navigate to="/admin/dashboard" replace />;
    }
    if (normalizedUserRole === 'CUAN_HANG') {
      return <Navigate to="/restaurant/dashboard" replace />;
    }
    return <Navigate to="/login" replace />;
  }

  return (
    <div className="app-layout">
      <Sidebar />
      <div className="main-content">
        <Header />
        <main className="page-container">
          <Outlet />
        </main>
      </div>
    </div>
  );
};

export const App: React.FC = () => {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />

          {/* Admin Routes */}
          <Route element={<ProtectedLayout allowedRoles={['ADMIN']} />}>
            <Route path="/admin/dashboard" element={<AdminDashboard />} />
            <Route path="/admin/users" element={<AdminUsers />} />
            <Route path="/admin/restaurants" element={<AdminRestaurants />} />
            <Route path="/admin/categories" element={<Navigate to="/admin/restaurants?tab=categories" replace />} />
            <Route path="/admin/orders" element={<AdminOrders />} />
            <Route path="/admin/reviews" element={<AdminReviews />} />
            <Route path="/admin/logs" element={<AdminActivityLogs />} />
          </Route>

          {/* Restaurant Routes - only CUAN_HANG (ADMIN is forbidden) */}
          <Route element={<ProtectedLayout allowedRoles={['CUAN_HANG']} />}>
            <Route path="/restaurant/dashboard" element={<RestaurantDashboard />} />
            <Route path="/restaurant/revenue" element={<RestaurantRevenue />} />
            <Route path="/restaurant/orders" element={<RestaurantOrders />} />
            <Route path="/restaurant/menu" element={<RestaurantMenu />} />
            <Route path="/restaurant/reservations" element={<RestaurantReservations />} />
            <Route path="/restaurant/vouchers" element={<RestaurantVouchers />} />
            <Route path="/restaurant/reviews" element={<RestaurantReviews />} />
            <Route path="/restaurant/profile" element={<RestaurantProfile />} />
          </Route>


          {/* Fallback */}
          <Route path="*" element={<Navigate to="/login" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
};

export default App;
