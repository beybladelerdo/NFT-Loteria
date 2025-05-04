import React from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowRight, Award, Users, Wallet } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import Navbar from '../components/Navbar';

const LandingPage = () => {
  const { isAuthenticated, login } = useAuth();
  const navigate = useNavigate();

  const handleGetStarted = async () => {
    if (isAuthenticated) {
      navigate('/dashboard');
    } else {
      await login();
      navigate('/dashboard');
    }
  };

  return (
    <div className="flex flex-col min-h-screen bg-gradient-to-br from-purple-900 via-fuchsia-800 to-orange-600">
      <Navbar />
      
      <main className="flex-1 flex flex-col items-center justify-center p-6 text-center">
        <div className="max-w-3xl">
          <h2 className="text-5xl font-bold text-white mb-6">
            Lotería on the Internet Computer
          </h2>
          <p className="text-xl text-white mb-8">
            Play the traditional Lotería game with crypto-themed NFT tablas, win tokens, and have fun on the blockchain!
          </p>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-12">
            <div className="bg-white bg-opacity-10 p-6 rounded-xl backdrop-blur-sm">
              <Users size={48} className="text-white mx-auto mb-4" />
              <h3 className="text-2xl font-bold text-white mb-2">Host a Game</h3>
              <p className="text-white mb-4">
                Create your own Lotería game, set entry fees, and invite friends to play.
              </p>
              <button 
                onClick={handleGetStarted}
                className="bg-gradient-to-r from-orange-500 to-pink-500 hover:from-orange-600 hover:to-pink-600 text-white font-bold py-3 px-6 rounded-full flex items-center justify-center mx-auto transition"
              >
                Host Game <ArrowRight size={18} className="ml-2" />
              </button>
            </div>
            
            <div className="bg-white bg-opacity-10 p-6 rounded-xl backdrop-blur-sm">
              <Award size={48} className="text-white mx-auto mb-4" />
              <h3 className="text-2xl font-bold text-white mb-2">Join a Game</h3>
              <p className="text-white mb-4">
                Browse open games, rent an NFT tabla, and try your luck at winning prizes.
              </p>
              <button 
                onClick={handleGetStarted}
                className="bg-gradient-to-r from-blue-500 to-purple-500 hover:from-blue-600 hover:to-purple-600 text-white font-bold py-3 px-6 rounded-full flex items-center justify-center mx-auto transition"
              >
                Join Game <ArrowRight size={18} className="ml-2" />
              </button>
            </div>
          </div>
          
          <div className="flex justify-center gap-6 mb-8">
            <div className="text-center">
              <div className="text-3xl font-bold text-white">54</div>
              <div className="text-white text-opacity-80">Cards</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-white">363</div>
              <div className="text-white text-opacity-80">NFT Tablas</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-white">2</div>
              <div className="text-white text-opacity-80">Token Types</div>
            </div>
          </div>
        </div>
      </main>
      
      <footer className="bg-black bg-opacity-50 text-white text-center py-4">
        <p>&copy; 2023 Crypto Lotería. Built on the Internet Computer Protocol.</p>
      </footer>
    </div>
  );
};

export default LandingPage;