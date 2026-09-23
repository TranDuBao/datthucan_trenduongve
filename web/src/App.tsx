import React from 'react';
import { BrowserRouter, Routes, Route, Navigate, Outlet } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import { Sidebar } from './components/Sidebar';
import { Header } from './components/Header';
import { Login } from './pages/Login';

// Admin Pages
import { AdminDashboard } from './pages/admin/AdminDashboard';
import { AdminUsers } from './pages/admin/AdminUsers';
import { AdminRestaurants } from './pages/admin/AdminRestaurants';
import { AdminCategories } from './pages/admin/AdminCategories';
import { AdminFoods } from './pages/admin/AdminFoods';
import { AdminOrders } from './pages/admin/AdminOrders';
import { AdminPayments } from './pages/admin/AdminPayments';

// Restaurant Pages
import { RestaurantDashboard } from './pages/restaurant/RestaurantDashboard';
import { RestaurantOrders } from './pages/restaurant/RestaurantOrders';
import { RestaurantMenu } from './pages/restaurant/RestaurantMenu';
import { RestaurantProfile } from './pages/restaurant/RestaurantProfile';

const ProtectedLayout: React.FC<{ allowedRoles: string[] }> = ({ allowedRoles }) => {
  const { user, token } = useAuth();

  if (!token || !user) {
    return <Navigate to="/login" replace />;
  }

  const userRole = (user.role || '').toUpperCase();
  const normalizedUserRole = userRole === 'CUA_HANG' ? 'CUAN_HANG' : userRole;

  const hasAccess = allowedRoles.some((r) => {
    const normalizedR = r.toUpperCase() === 'CUA_HANG' ? 'CUAN_HANG' : r.toUpperCase();
    return normalizedR === normalizedUserRole;
  }) || userRole === 'ADMIN';

  if (!hasAccess) {
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
            <Route path="/admin/categories" element={<AdminCategories />} />
            <Route path="/admin/foods" element={<AdminFoods />} />
            <Route path="/admin/orders" element={<AdminOrders />} />
            <Route path="/admin/payments" element={<AdminPayments />} />
          </Route>

          {/* Restaurant Routes */}
          <Route element={<ProtectedLayout allowedRoles={['CUAN_HANG', 'ADMIN']} />}>
            <Route path="/restaurant/dashboard" element={<RestaurantDashboard />} />
            <Route path="/restaurant/orders" element={<RestaurantOrders />} />
            <Route path="/restaurant/menu" element={<RestaurantMenu />} />
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
