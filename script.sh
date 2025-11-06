#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Starting React Notes App frontend scaffolding..."

# ------------------------------
# 1️⃣  Dependencies installation
# ------------------------------
echo "📦 Installing dependencies..."
npm install react react-dom react-router-dom@^6 \
  @tanstack/react-query@^5 @tanstack/react-query-devtools \
  @reduxjs/toolkit react-redux axios zod

echo "🧪 Installing dev dependencies..."
npm install -D typescript vite @vitejs/plugin-react vitest jsdom \
  @testing-library/react @testing-library/jest-dom @testing-library/user-event \
  eslint prettier eslint-config-prettier eslint-plugin-react eslint-plugin-react-hooks \
  msw playwright husky lint-staged

# ------------------------------
# 2️⃣  Folder structure
# ------------------------------
echo "📁 Creating folders..."
mkdir -p src/{app,features,shared,routes,tests}
mkdir -p src/features/notes/{api,components,hooks,types}
mkdir -p src/shared/{api,components,hooks,types,ui,utils}
mkdir -p src/tests/{unit,integration,e2e}

# ------------------------------
# 3️⃣  App setup files
# ------------------------------
echo "🧱 Creating app setup..."
cat > src/app/store.ts <<'TS'
import { configureStore } from '@reduxjs/toolkit';
import { combineReducers } from 'redux';
import uiReducer from '../shared/ui/uiSlice';
import selectionReducer from '../features/notes/selectionSlice';

const rootReducer = combineReducers({
  ui: uiReducer,
  selection: selectionReducer,
});

export const store = configureStore({
  reducer: rootReducer,
  devTools: import.meta.env.DEV,
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
TS

cat > src/app/queryClient.ts <<'TS'
import { QueryClient } from '@tanstack/react-query';

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,
      retry: 2,
      refetchOnWindowFocus: false,
    },
    mutations: { retry: 0 },
  },
});
TS

cat > src/app/providers.tsx <<'TSX'
import React from 'react';
import { Provider } from 'react-redux';
import { QueryClientProvider } from '@tanstack/react-query';
import { queryClient } from './queryClient';
import { store } from './store';

export const AppProviders: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <Provider store={store}>
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  </Provider>
);
TSX

# ------------------------------
# 4️⃣  Shared logic (API, UI, utils)
# ------------------------------
echo "🧩 Creating shared files..."
cat > src/shared/api/http.ts <<'TS'
import axios, { AxiosError } from 'axios';
import { z } from 'zod';

export const api = axios.create({
  baseURL: '/api',
  headers: { 'Content-Type': 'application/json' },
});

export type ApiError = { status: number; message: string };

export function parseAxiosError(err: unknown): ApiError {
  if (axios.isAxiosError(err)) {
    const e = err as AxiosError;
    return { status: e.response?.status ?? 0, message: e.message };
  }
  return { status: 0, message: (err as Error)?.message ?? 'Unknown Error' };
}
TS

cat > src/shared/ui/uiSlice.ts <<'TS'
import { createSlice, PayloadAction } from '@reduxjs/toolkit';

interface Toast { id: string; type: 'info' | 'success' | 'error'; message: string; }
interface UIState { toasts: Toast[] }

const initialState: UIState = { toasts: [] };

const uiSlice = createSlice({
  name: 'ui',
  initialState,
  reducers: {
    addToast: (state, action: PayloadAction<Toast>) => { state.toasts.push(action.payload); },
    removeToast: (state, action: PayloadAction<string>) => {
      state.toasts = state.toasts.filter(t => t.id !== action.payload);
    },
  },
});

export const uiActions = uiSlice.actions;
export default uiSlice.reducer;
TS

cat > src/shared/utils/date.ts <<'TS'
export function formatDateTime(date: string) {
  return new Date(date).toLocaleString();
}
TS

# ------------------------------
# 5️⃣  Notes feature (CRUD)
# ------------------------------
echo "📝 Creating Notes feature..."

# Types
cat > src/features/notes/types/index.ts <<'TS'
export interface Note {
  id: string;
  title: string;
  content: string;
  createdAt: string;
  updatedAt?: string;
}

export type CreateNoteDTO = Pick<Note, 'title' | 'content'>;
export type UpdateNoteDTO = Partial<CreateNoteDTO>;
TS

# API
cat > src/features/notes/api/index.ts <<'TS'
import { api, parseAxiosError } from '../../../shared/api/http';
import type { Note, CreateNoteDTO, UpdateNoteDTO } from '../types';

export async function getNotes(): Promise<Note[]> {
  try { const res = await api.get('/notes'); return res.data; }
  catch (e) { throw parseAxiosError(e); }
}

export async function createNote(payload: CreateNoteDTO): Promise<Note> {
  try { const res = await api.post('/notes', payload); return res.data; }
  catch (e) { throw parseAxiosError(e); }
}

export async function updateNote(id: string, payload: UpdateNoteDTO): Promise<Note> {
  try { const res = await api.put(`/notes/${id}`, payload); return res.data; }
  catch (e) { throw parseAxiosError(e); }
}

export async function deleteNote(id: string): Promise<void> {
  try { await api.delete(`/notes/${id}`); }
  catch (e) { throw parseAxiosError(e); }
}
TS

# Hooks
cat > src/features/notes/hooks/useNotes.ts <<'TS'
import { useQuery } from '@tanstack/react-query';
import { getNotes } from '../api';
import type { Note } from '../types';

export function useNotes() {
  return useQuery<Note[]>({
    queryKey: ['notes'],
    queryFn: getNotes,
  });
}
TS

cat > src/features/notes/hooks/useCreateNote.ts <<'TS'
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { createNote } from '../api';
import type { CreateNoteDTO, Note } from '../types';

export function useCreateNote() {
  const qc = useQueryClient();
  return useMutation<Note, Error, CreateNoteDTO>({
    mutationFn: createNote,
    onSuccess: () => qc.invalidateQueries({ queryKey: ['notes'] }),
  });
}
TS

cat > src/features/notes/hooks/useUpdateNote.ts <<'TS'
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { updateNote } from '../api';
import type { Note, UpdateNoteDTO } from '../types';

export function useUpdateNote() {
  const qc = useQueryClient();
  return useMutation<Note, Error, { id: string; payload: UpdateNoteDTO }>({
    mutationFn: ({ id, payload }) => updateNote(id, payload),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['notes'] }),
  });
}
TS

cat > src/features/notes/hooks/useDeleteNote.ts <<'TS'
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { deleteNote } from '../api';

export function useDeleteNote() {
  const qc = useQueryClient();
  return useMutation<void, Error, string>({
    mutationFn: deleteNote,
    onSuccess: () => qc.invalidateQueries({ queryKey: ['notes'] }),
  });
}
TS

# Redux slice for selection
cat > src/features/notes/selectionSlice.ts <<'TS'
import { createSlice, PayloadAction } from '@reduxjs/toolkit';

interface SelectionState { selectedNoteId?: string | null; }
const initialState: SelectionState = { selectedNoteId: null };

const selectionSlice = createSlice({
  name: 'selection',
  initialState,
  reducers: {
    setSelectedNote: (s, a: PayloadAction<string | null>) => { s.selectedNoteId = a.payload; },
    clearSelectedNote: (s) => { s.selectedNoteId = null; },
  },
});

export const selectionActions = selectionSlice.actions;
export default selectionSlice.reducer;
TS

# Components
cat > src/features/notes/components/NoteCard.tsx <<'TSX'
import React from 'react';
import { formatDateTime } from '../../../shared/utils/date';
import type { Note } from '../types';
import { useDeleteNote } from '../hooks/useDeleteNote';

const NoteCard: React.FC<{ note: Note }> = ({ note }) => {
  const { mutate: remove } = useDeleteNote();
  return (
    <div className="note-card">
      <h3>{note.title}</h3>
      <p>{note.content}</p>
      <small>{formatDateTime(note.createdAt)}</small>
      <button onClick={() => remove(note.id)}>🗑️ Delete</button>
    </div>
  );
};
export default NoteCard;
TSX

cat > src/features/notes/components/NotesList.tsx <<'TSX'
import React from 'react';
import { useNotes } from '../hooks/useNotes';
import NoteCard from './NoteCard';

const NotesList: React.FC = () => {
  const { data, isLoading, isError } = useNotes();
  if (isLoading) return <p>Loading notes...</p>;
  if (isError) return <p>Error loading notes</p>;
  if (!data?.length) return <p>No notes yet.</p>;
  return (
    <div className="notes-list">
      {data.map(note => <NoteCard key={note.id} note={note} />)}
    </div>
  );
};
export default NotesList;
TSX

cat > src/features/notes/components/NoteEditor.tsx <<'TSX'
import React, { useState } from 'react';
import { useCreateNote } from '../hooks/useCreateNote';

const NoteEditor: React.FC = () => {
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const { mutateAsync: create } = useCreateNote();

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;
    await create({ title, content });
    setTitle(''); setContent('');
  };

  return (
    <form onSubmit={onSubmit}>
      <input placeholder="Title" value={title} onChange={e => setTitle(e.target.value)} />
      <textarea placeholder="Content" value={content} onChange={e => setContent(e.target.value)} />
      <button type="submit">Add Note</button>
    </form>
  );
};
export default NoteEditor;
TSX

# ------------------------------
# 6️⃣  Routing + App entry
# ------------------------------
echo "🧭 Creating routes and main app..."
cat > src/routes/NotesPage.tsx <<'TSX'
import React from 'react';
import NoteEditor from '../features/notes/components/NoteEditor';
import NotesList from '../features/notes/components/NotesList';

const NotesPage: React.FC = () => (
  <main>
    <h1>📝 Notes</h1>
    <NoteEditor />
    <hr />
    <NotesList />
  </main>
);
export default NotesPage;
TSX

cat > src/App.tsx <<'TSX'
import React, { Suspense } from 'react';
import { BrowserRouter, Routes, Route, Link } from 'react-router-dom';
import { AppProviders } from './app/providers';
import NotesPage from './routes/NotesPage';

const App: React.FC = () => (
  <AppProviders>
    <BrowserRouter>
      <nav style={{ padding: 8 }}>
        <Link to="/">Home</Link> | <Link to="/notes">Notes</Link>
      </nav>
      <Suspense fallback={<div>Loading...</div>}>
        <Routes>
          <Route path="/" element={<div>Welcome to Notes App</div>} />
          <Route path="/notes" element={<NotesPage />} />
        </Routes>
      </Suspense>
    </BrowserRouter>
  </AppProviders>
);
export default App;
TSX

cat > src/main.tsx <<'TSX'
import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';

createRoot(document.getElementById('root')!).render(<App />);
TSX

# ------------------------------
# 7️⃣  Vite config & scripts
# ------------------------------
cat > vite.config.ts <<'TS'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: { '/api': 'http://localhost:8080' },
  },
});
TS

node <<'NODE'
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.scripts = pkg.scripts || {};
pkg.scripts.dev = "vite";
pkg.scripts.build = "vite build";
pkg.scripts.preview = "vite preview";
pkg.scripts.test = "vitest";
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
console.log("✅ Updated package.json scripts");
NODE

# ------------------------------
# 8️⃣  End message
# ------------------------------
echo "✅ All files created successfully!"
echo "🎉 Run: npm run dev  →  then open http://localhost:5173/notes"
