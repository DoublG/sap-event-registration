import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// The CAP server (cds watch) runs on port 4004; in development Vite proxies
// the OData services to it, so the browser sees one origin.
const cap = 'http://localhost:4004'

export default defineConfig({
  base: './', // CAP also serves the built app from app/family/dist/
  plugins: [
    vue({
      template: {
        // <ui5-*> tags are SAP UI5 Web Components (custom elements), not Vue components.
        compilerOptions: { isCustomElement: tag => tag.startsWith('ui5-') },
      },
    }),
  ],
  server: {
    port: 5173,
    proxy: { '/public': cap, '/family': cap },
  },
  build: { outDir: 'dist', chunkSizeWarningLimit: 2000 },
})
