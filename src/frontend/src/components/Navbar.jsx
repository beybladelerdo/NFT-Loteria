import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { LogIn, User, Wallet, Menu, X } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

const Navbar = () => {
  const { isAuthenticated, login, logout, principal, userBalance } = useAuth();
  const [mobileMenuOpen, setMobileMenuOpen] = React.useState(false);
  const navigate = useNavigate();

  const handleLogin = async () => {
    await login();
    navigate('/dashboard');
  };

  const handleLogout = async () => {
    await logout();
    navigate('/');
  };

  const toggleMobileMenu = () => {
    setMobileMenuOpen(!mobileMenuOpen);
  };

  const formatPrincipal = (principal) => {
    if (!principal) return '';
    const text = principal.toString();
    return text.substring(0, 5) + '...' + text.substring(text.length - 5);
  };

  return (
    <header className="flex justify-between items-center p-4 bg-black bg-opacity-30">
      <div className="flex items-center">
        <Link to="/" className="flex items-center">
          <div className="w-10 h-10 rounded-full bg-white flex items-center justify-center text-purple-900 font-bold">LC</div>
          <h1 className="text-2xl font-bold text-white ml-2">Crypto Lotería</h1>
        </Link>
      </div>
      
      {/* Mobile menu button */}
      <div className="md:hidden">
        <button 
          onClick={toggleMobileMenu}
          className="text-white p-2"
        >
          {mobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
        </button>
      </div>
      
      {/* Desktop navigation */}
      <div className="hidden md:flex items-center space-x-4">
        {isAuthenticated ? (
          <>
            <Link to="/dashboard" className="text-white hover:text-purple-300 transition">
              Dashboard
            </Link>
            <Link to="/join-game" className="text-white hover:text-purple-300 transition">
              Join Game
            </Link>
            <Link to="/host-game" className="text-white hover:text-purple-300 transition">
              Host Game
            </Link>
            <div className="flex items-center ml-2">
              <div className="text-white bg-white bg-opacity-20 rounded-full px-3 py-1 mr-2 flex items-center">
                <User size={16} className="mr-1" />
                {formatPrincipal(principal)}
              </div>
              <Link to="/wallet" className="bg-white bg-opacity-20 hover:bg-opacity-30 text-white rounded-full px-4 py-2 transition flex items-center">
                <Wallet size={18} className="mr-2" />
                My Wallet
              </Link>
              <button 
                onClick={handleLogout}
                className="ml-2 bg-red-500 hover:bg-red-600 text-white rounded-full px-3 py-2 transition flex items-center"
              >
                <LogIn size={18} className="transform rotate-180" />
              </button>
            </div>
          </>
        ) : (
          <button 
            onClick={handleLogin}
            className="bg-blue-600 hover:bg-blue-700 text-white rounded-full px-4 py-2 transition flex items-center"
          >
            <LogIn size={18} className="mr-2" />
            Connect with Internet Identity
          </button>
        )}
      </div>
      
      {/* Mobile menu */}
      {mobileMenuOpen && (
        <div className="absolute top-16 left-0 right-0 bg-gradient-to-b from-purple-900 to-fuchsia-800 p-4 z-50 md:hidden">
          {isAuthenticated ? (
            <div className="flex flex-col space-y-4">
              <Link to="/dashboard" 
                className="text-white py-2 px-4 rounded bg-white bg-opacity-10 hover:bg-opacity-20 transition"
                onClick={() => setMobileMenuOpen(false)}
              >
                Dashboard
              </Link>
              <Link to="/join-game" 
                className="text-white py-2 px-4 rounded bg-white bg-opacity-10 hover:bg-opacity-20 transition"
                onClick={() => setMobileMenuOpen(false)}
              >
                Join Game
              </Link>
              <Link to="/host-game" 
                className="text-white py-2 px-4 rounded bg-white bg-opacity-10 hover:bg-opacity-20 transition"
                onClick={() => setMobileMenuOpen(false)}
              >
                Host Game
              </Link>
              <Link to="/wallet" 
                className="text-white py-2 px-4 rounded bg-white bg-opacity-10 hover:bg-opacity-20 transition flex items-center"
                onClick={() => setMobileMenuOpen(false)}
              >
                <Wallet size={18} className="mr-2" />
                My Wallet ({userBalance.ICP.toFixed(2)} ICP)
              </Link>
              <button 
                onClick={handleLogout}
                className="bg-red-500 hover:bg-red-600 text-white py-2 px-4 rounded transition flex items-center justify-center"
              >
                <LogIn size={18} className="mr-2 transform rotate-180" />
                Sign Out
              </button>
            </div>
          ) : (
            <button 
              onClick={handleLogin}
              className="w-full bg-blue-600 hover:bg-blue-700 text-white py-2 px-4 rounded transition flex items-center justify-center"
            >
              <LogIn size={18} className="mr-2" />
              Connect with Internet Identity
            </button>
          )}
        </div>
      )}
    </header>
  );
};

export default Navbar;