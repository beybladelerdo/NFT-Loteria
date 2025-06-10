<div class="widget">
  <div class="widget-content">
    <div class="widget-spinner"></div>
  </div>
</div>

<style>
  .widget {
    position: relative;
    width: 100%;
    height: 200px;
    margin-top: 25px;
    margin-bottom: 25px;
  }

  .widget-content {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 1rem;
  }

  .widget-spinner {
    border: 5px solid rgba(255, 255, 255, 0.3);
    border-top: 5px solid white;
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
