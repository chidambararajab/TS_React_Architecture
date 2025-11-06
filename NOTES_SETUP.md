Notes App (React Query + Zustand) scaffolded.

Run:
  npm run dev

The app proxies /api to http://localhost:8080 (Vite config).
Ensure your backend runs at http://localhost:8080.

Files created:
 - src/features/notes/      (API, hooks, components)
 - src/stores/useNotesUIStore.ts (Zustand store)
 - src/app/providers.tsx    (QueryClient + Devtools)
 - vite.config.ts           (proxy /api)
