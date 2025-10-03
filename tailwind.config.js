/** @type {import('tailwindcss').Config} */
export default {
  content: ["./src/**/*.{html,js,svelte,ts}"],
  theme: {
    extend: {
      colors: {
        // Existing palette
        "loteria-primary": "#6D28D9",
        "loteria-secondary": "#EC4899",
        "loteria-accent": "#F97316",

        // Aurora HSL vars (defined in app.css :root)
        "color-1": "hsl(var(--color-1))",
        "color-2": "hsl(var(--color-2))",
        "color-3": "hsl(var(--color-3))",
        "color-4": "hsl(var(--color-4))",
        "color-5": "hsl(var(--color-5))",
      },
      fontFamily: {
        freigeist: ["FreigeistXCon"],
      },
      animation: {
        "card-draw": "cardDraw 0.5s ease-out",
        "win-pulse": "winPulse 2s infinite",

        // Convenient animation shortcuts for the aurora effects
        "aurora-border": "aurora-border 10s ease-in-out infinite",
        "aurora-1": "aurora-1 12s ease-in-out infinite",
        "aurora-2": "aurora-2 12s ease-in-out infinite",
        "aurora-3": "aurora-3 12s ease-in-out infinite",
        "aurora-4": "aurora-4 12s ease-in-out infinite",
      },
      keyframes: {
        cardDraw: {
          "0%": { transform: "scale(0.5)", opacity: "0" },
          "100%": { transform: "scale(1)", opacity: "1" },
        },
        winPulse: {
          "0%": { boxShadow: "0 0 0 0 rgba(255, 215, 0, 0.7)" },
          "70%": { boxShadow: "0 0 0 15px rgba(255, 215, 0, 0)" },
          "100%": { boxShadow: "0 0 0 0 rgba(255, 215, 0, 0)" },
        },

        // Aurora blob & mover keyframes
        "aurora-border": {
          "0%, 100%": { borderRadius: "37% 29% 27% 27% / 28% 25% 41% 37%" },
          "25%": { borderRadius: "47% 29% 39% 49% / 61% 19% 66% 26%" },
          "50%": { borderRadius: "57% 23% 47% 72% / 63% 17% 66% 33%" },
          "75%": { borderRadius: "28% 49% 29% 100% / 93% 20% 64% 25%" },
        },
        "aurora-1": {
          "0%, 100%": { top: "0", right: "0" },
          "50%": { top: "50%", right: "25%" },
          "75%": { top: "25%", right: "50%" },
        },
        "aurora-2": {
          "0%, 100%": { top: "0", left: "0" },
          "60%": { top: "75%", left: "25%" },
          "85%": { top: "50%", left: "50%" },
        },
        "aurora-3": {
          "0%, 100%": { bottom: "0", left: "0" },
          "40%": { bottom: "50%", left: "25%" },
          "65%": { bottom: "25%", left: "50%" },
        },
        "aurora-4": {
          "0%, 100%": { bottom: "0", right: "0" },
          "50%": { bottom: "25%", right: "40%" },
          "90%": { bottom: "50%", right: "25%" },
        },
      },
    },
  },
  plugins: [],
};
