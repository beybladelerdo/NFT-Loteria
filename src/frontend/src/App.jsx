import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';

// Authentication & Context
import { AuthProvider, useAuth } from './context/AuthContext';
import { GameProvider } from './context/GameContext';

// Components
import LandingPage from './pages/LandingPage';
import Dashboard from './pages/Dashboard';
import JoinGamePage from './pages/JoinGamePage';
import HostGamePage from './pages/HostGamePage';
import TablaRentalPage from './pages/TablaRentalPage';
import PlayerGamePage from './pages/PlayerGamePage';
import HostGamePanel from './pages/HostGamePanel';
import WalletPage from './pages/WalletPage';
import CkBTCMinter from './pages/CkBTCMinter';
import ProfileSettings from './pages/ProfileSettings';
import NotFound from './pages/NotFound';

// Protected route component
const ProtectedRoute = ({ children }) => {
  const { isAuthenticated, isLoading } = useAuth();
  
  if (isLoading) {
    return <div className="min-h-screen bg-gradient-to-br from-purple-900 via-fuchsia-800 to-orange-600 flex items-center justify-center">
      <div className="text-white text-xl">Loading...</div>
    </div>;
  }
  
  return isAuthenticated ? children : <Navigate to="/" />;
};

function App() {
  return (
    <Router>
      <AuthProvider>
        <GameProvider>
          <Routes>
            {/* Public routes */}
            <Route path="/" element={<LandingPage />} />
            
            {/* Protected routes */}
            <Route path="/dashboard" element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
            <Route path="/join-game" element={<ProtectedRoute><JoinGamePage /></ProtectedRoute>} />
            <Route path="/host-game" element={<ProtectedRoute><HostGamePage /></ProtectedRoute>} />
            <Route path="/tabla-rental/:gameId" element={<ProtectedRoute><TablaRentalPage /></ProtectedRoute>} />
            <Route path="/game/play/:gameId" element={<ProtectedRoute><PlayerGamePage /></ProtectedRoute>} />
            <Route path="/game/host/:gameId" element={<ProtectedRoute><HostGamePanel /></ProtectedRoute>} />
            <Route path="/wallet" element={<ProtectedRoute><WalletPage /></ProtectedRoute>} />
            <Route path="/ckbtc-minter" element={<ProtectedRoute><CkBTCMinter /></ProtectedRoute>} />
            <Route path="/profile" element={<ProtectedRoute><ProfileSettings /></ProtectedRoute>} />
            
            {/* 404 route */}
            <Route path="*" element={<NotFound />} />
          </Routes>
        </GameProvider>
      </AuthProvider>
    </Router>
  );
}

export default App;