/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'loteria-primary': '#6D28D9',
        'loteria-secondary': '#EC4899',
        'loteria-accent': '#F97316',
      },
      animation: {
        'card-draw': 'cardDraw 0.5s ease-out',
        'win-pulse': 'winPulse 2s infinite',
      },
      keyframes: {
        cardDraw: {
          '0%': { transform: 'scale(0.5)', opacity: '0' },
          '100%': { transform: 'scale(1)', opacity: '1' },
        },
        winPulse: {
          '0%': { boxShadow: '0 0 0 0 rgba(255, 215, 0, 0.7)' },
          '70%': { boxShadow: '0 0 0 15px rgba(255, 215, 0, 0)' },
          '100%': { boxShadow: '0 0 0 0 rgba(255, 215, 0, 0)' },
        },
      },
    },
  },
  plugins: [],
}