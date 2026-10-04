const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,html}'
  ],
  theme: {
    extend: {
      colors: {
        ink: {
          950: '#0a0a0a',
          900: '#111111',
          850: '#161616',
          800: '#1c1c1c',
          700: '#262626',
          600: '#3a3a3a',
          500: '#5c5c5c',
          400: '#8a8a8a',
          300: '#b5b5b5',
          100: '#f2f2f2'
        },
        champagne: {
          DEFAULT: '#c9b38a',
          600: '#a89067',
          200: '#e7ddc8'
        }
      },
      fontFamily: {
        sans: ['Inter', '"Helvetica Neue"', 'Helvetica', 'Arial', ...defaultTheme.fontFamily.sans]
      },
      letterSpacing: {
        eyebrow: '0.24em',
        wordmark: '0.55em'
      }
    }
  },
  plugins: []
}
