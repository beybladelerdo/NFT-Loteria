<div class="widget">
  <div class="widget-content">
    <div class="widget-spinner"></div>
  </div>
</div>

<style>
  .widget {
    position: fixed;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background-color: black;
  }
  
  .widget-content {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 1rem;
  }
  
  .widget-spinner {
    border: 5px solid rgba(139, 92, 246, 0.3); /* violet-500 with opacity */
    border-top: 5px solid #8b5cf6; /* violet-500 */
    border-radius: 50%;
    width: 50px;
    height: 50px;
    animation: spin 1s linear infinite;
  }
  
  @keyframes spin {
    0% {
      transform: rotate(0deg);
    }
    100% {
      transform: rotate(360deg);
    }
  }
</style>