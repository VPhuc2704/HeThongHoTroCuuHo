// // nuxt.config.ts
export default defineNuxtConfig({
  compatibilityDate: '2024-04-03',
  devtools: { enabled: false },

  modules: [
    '@nuxtjs/tailwindcss',
    '@pinia/nuxt',
    '@vueuse/nuxt',
    '@element-plus/nuxt'
  ],
  app: {
    head: {
      link: [
        { rel: 'stylesheet', href: 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css' }
      ]
    }
  },
  ssr: false,
  
  elementPlus: {
    icon: 'ElIcon',
  },
  
  css: [
    '~/assets/css/main.css'
  ],

  runtimeConfig: {
    public: {
      apiBase: process.env.NUXT_PUBLIC_API_BASE || 'http://127.0.0.1:8000/api',
      wsBase: process.env.NUXT_PUBLIC_WS_BASE || 'ws://127.0.0.1:8000',
      env: process.env.NODE_ENV || 'development',
    }
  },
  
  routeRules: {
    '/api/**': { 
      proxy: 'http://127.0.0.1:8000/api/**' 
    }
  },

})