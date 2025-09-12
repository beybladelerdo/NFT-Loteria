<script lang="ts">
  import { goto } from '$app/navigation';
  import { authStore } from '$lib/stores/auth-store';
  

  const hostGame = () => goto('/host-game');
  const joinGame = () => goto('/join-game');

  const currentYear = new Date().getFullYear();

</script>

<div class="flex flex-col min-h-screen bg-gradient-to-br from-purple-900 via-fuchsia-800 to-orange-600">
  <!--<Navbar />-->
  
  <main class="flex-1 flex flex-col items-center justify-center p-6 text-center">
    <div class="max-w-3xl">
      <h2 class="text-5xl font-bold text-white mb-6">
        Lotería on the Internet Computer
      </h2>
      <p class="text-xl text-white mb-8">
        Play the traditional Lotería game with crypto-themed NFT tablas, win tokens, and have fun on the blockchain!
      </p>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-12">
        <div class="bg-white bg-opacity-10 p-6 rounded-xl backdrop-blur-sm">
          <!--<Users size={48} class="text-white mx-auto mb-4" />-->
          <h3 class="text-2xl font-bold text-white mb-2">Host a Game</h3>
          <p class="text-white mb-4">
            Create your own Lotería game, set entry fees, and invite friends to play.
          </p>
          <button 
            onclick={hostGame}
            class="bg-gradient-to-r from-orange-500 to-pink-500 hover:from-orange-600 hover:to-pink-600 text-white font-bold py-3 px-6 rounded-full flex items-center justify-center mx-auto transition"
          >
            Host Game <!--<ArrowRight size={18} class="ml-2" />-->
          </button>
        </div>
        
        <div class="bg-white bg-opacity-10 p-6 rounded-xl backdrop-blur-sm">
          <!--<Award size={48} class="text-white mx-auto mb-4" />-->
          <h3 class="text-2xl font-bold text-white mb-2">Join a Game</h3>
          <p class="text-white mb-4">
            Browse open games, rent an NFT tabla, and try your luck at winning prizes.
          </p>
          <button 
            onclick={joinGame}
            class="bg-gradient-to-r from-blue-500 to-purple-500 hover:from-blue-600 hover:to-purple-600 text-white font-bold py-3 px-6 rounded-full flex items-center justify-center mx-auto transition"
          >
            Join Game <!--<ArrowRight size={18} class="ml-2" />-->
          </button>
        </div>
      </div>
      
      <div class="flex justify-center gap-6 mb-8">
        <div class="text-center">
          <div class="text-3xl font-bold text-white">54</div>
          <div class="text-white text-opacity-80">Cards</div>
        </div>
        <div class="text-center">
          <div class="text-3xl font-bold text-white">363</div>
          <div class="text-white text-opacity-80">NFT Tablas</div>
        </div>
        <div class="text-center">
          <div class="text-3xl font-bold text-white">2</div>
          <div class="text-white text-opacity-80">Token Types</div>
        </div>
      </div>
    </div>
  </main>
  
  <footer class="text-white text-center py-4">
    <p>© {currentYear} NFT Lotería. Built on the Internet Computer Protocol.</p>
  </footer>
</div>