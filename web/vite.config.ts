import { defineConfig } from 'vite';

export default defineConfig({
  server: {
    proxy: {
      '/brouter': {
        target: 'http://localhost:17777',
        changeOrigin: true,
      },
    },
  },
});
