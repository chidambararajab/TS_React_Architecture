#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Scaffolding React + TypeScript app with React Query + Zustand..."

# Ensure package.json exists
if [ ! -f package.json ]; then
  echo "ERROR: package.json not found. Run this in your project root (existing React project)."
  exit 1
fi

# 1) Install dependencies
echo "📦 Installing runtime dependencies..."
npm install react-router-dom @tanstack/react-query @tanstack/react-query-devtools axios zustand zod

echo "🧰 Installing dev dependencies..."
npm install -D typescript vite @vitejs/plugin-react vitest jsdom @testing-library/react @testing-library/jest-dom @testing-library/user-event msw eslint prettier husky lint-staged

# 2) Create folder structure
echo "📁 Creating folders..."
mkdir -p src/{app,features,stores,shared/hooks,shared/ui,shared/utils,routes,styles,tests}
mkdir -p src/features/notes/{api,components,hooks,types}
mkdir -p src/tests/{unit,integration,e2e}

# 3) Create QueryClient and providers
echo "🧱 Creating app/provider files..."
cat > src/app/queryClient.ts <<'TS'
import { QueryClient } from '@tanstack/react-query';

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30_000,
      cacheTime: 1000 * 60 * 5,
      retry: 2,
      refetchOnWindowFocus: false,
    },
    mutations: {
      retry: 0,
    },
  },
});
TS

cat > src/app/providers.tsx <<'TSX'
import React from 'react';
import { QueryClientProvider } from '@tanstack/react-query';
import { queryClient } from './queryClient';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';

export const AppProviders: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <QueryClientProvider client={queryClient}>
    {children}
    {/* Devtools only in development */}
    {import.meta.env.DEV ? <ReactQueryDevtools initialIsOpen={false} /> : null}
  </QueryClientProvider>
);
TSX

# 4) Create shared utils
cat > src/shared/utils/date.ts <<'TS'
export const formatDateTime = (iso?: string) => {
  if (!iso) return '';
  const d = new Date(iso);
  return d.toLocaleString();
};
export default formatDateTime;
TS

# 5) Zustand store for UI concerns (filters, modal, selection)
echo "🧠 Creating Zustand store..."
cat > src/stores/useNotesUIStore.ts <<'TS'
import create from 'zustand';

type Filter = { q?: string; sort?: 'newest' | 'oldest' };
type State = {
  filter: Filter;
  selectedNoteId?: string | null;
  isEditModalOpen: boolean;
  setFilter: (f: Partial<Filter>) => void;
  setSelectedNote: (id?: string | null) => void;
  openEditModal: (id?: string) => void;
  closeEditModal: () => void;
};

export const useNotesUIStore = create<State>((set) => ({
  filter: {},
  selectedNoteId: null,
  isEditModalOpen: false,
  setFilter: (f) => set((s) => ({ filter: { ...s.filter, ...f } })),
  setSelectedNote: (id) => set(() => ({ selectedNoteId: id ?? null })),
  openEditModal: (id) => set(() => ({ isEditModalOpen: true, selectedNoteId: id ?? null })),
  closeEditModal: () => set(() => ({ isEditModalOpen: false })),
}));
TS

# 6) Notes feature types & API
echo "🔌 Creating notes API & types..."
cat > src/features/notes/types/index.ts <<'TS'
export interface Note {
  id: string;
  title: string;
  content?: string;
  createdAt: string;
  updatedAt?: string;
}

export type CreateNoteDTO = Pick<Note, 'title' | 'content'>;
export type UpdateNoteDTO = Partial<CreateNoteDTO>;
TS

cat > src/features/notes/api/index.ts <<'TS'
import axios from 'axios';
import type { Note, CreateNoteDTO, UpdateNoteDTO } from '../types';

const client = axios.create({
  baseURL: '/api',
  headers: { 'Content-Type': 'application/json' },
  timeout: 10_000,
});

export const getNotes = async (): Promise<Note[]> => {
  const r = await client.get('/notes');
  return r.data;
};

export const getNote = async (id: string): Promise<Note> => {
  const r = await client.get(`/notes/${id}`);
  return r.data;
};

export const createNote = async (payload: CreateNoteDTO): Promise<Note> => {
  const r = await client.post('/notes', payload);
  return r.data;
};

export const updateNote = async (id: string, payload: UpdateNoteDTO): Promise<Note> => {
  const r = await client.put(`/notes/${id}`, payload);
  return r.data;
};

export const deleteNote = async (id: string): Promise<void> => {
  await client.delete(`/notes/${id}`);
};
TS

# 7) Query keys helper
cat > src/features/notes/queryKeys.ts <<'TS'
export const NOTES = ['notes'] as const;
export const notesListKey = (filters: Record<string, any> = {}) => [...NOTES, 'list', filters] as const;
export const noteKey = (id: string) => [...NOTES, 'byId', id] as const;
TS

# 8) React Query hooks (useNotes, useNote, useCreateNote, useUpdateNote, useDeleteNote)
echo "🪝 Creating React Query hooks for notes..."
cat > src/features/notes/hooks/useNotes.ts <<'TS'
import { useQuery } from '@tanstack/react-query';
import { getNotes } from '../api';
import { notesListKey } from '../queryKeys';
import type { Note } from '../types';

export const useNotes = (filters?: Record<string, any>) =>
  useQuery<Note[], Error>({
    queryKey: notesListKey(filters),
    queryFn: () => getNotes(),
    keepPreviousData: true,
  });
TS

cat > src/features/notes/hooks/useNote.ts <<'TS'
import { useQuery } from '@tanstack/react-query';
import { getNote } from '../api';
import { noteKey } from '../queryKeys';
import type { Note } from '../types';

export const useNote = (id?: string) =>
  useQuery<Note, Error>({
    queryKey: id ? noteKey(id) : ['note', 'disabled'],
    enabled: Boolean(id),
    queryFn: () => getNote(id as string),
  });
TS

cat > src/features/notes/hooks/useCreateNote.ts <<'TS'
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { createNote } from '../api';
import { notesListKey } from '../queryKeys';
import type { CreateNoteDTO, Note } from '../types';

export const useCreateNote = () => {
  const qc = useQueryClient();
  return useMutation<Note, Error, CreateNoteDTO>({
    mutationFn: createNote,
    onMutate: async (newNote) => {
      await qc.cancelQueries(notesListKey());
      const prev = qc.getQueryData<Note[]>(notesListKey());
      const optimistic: Note = { id: `tmp-${Date.now()}`, ...newNote, createdAt: new Date().toISOString() };
      qc.setQueryData(notesListKey(), (old = []) => [optimistic, ...old]);
      return { prev };
    },
    onError: (_err, _vars, ctx: any) => qc.setQueryData(notesListKey(), ctx?.prev ?? []),
    onSettled: () => qc.invalidateQueries(notesListKey()),
  });
};
TS

cat > src/features/notes/hooks/useUpdateNote.ts <<'TS'
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { updateNote } from '../api';
import { noteKey, notesListKey } from '../queryKeys';
import type { UpdateNoteDTO, Note } from '../types';

export const useUpdateNote = () => {
  const qc = useQueryClient();
  return useMutation<Note, Error, { id: string; payload: UpdateNoteDTO }>({
    mutationFn: ({ id, payload }) => updateNote(id, payload),
    onMutate: async ({ id, payload }) => {
      await qc.cancelQueries(noteKey(id));
      const prevNote = qc.getQueryData(noteKey(id));
      const prevList = qc.getQueryData(notesListKey());
      qc.setQueryData(noteKey(id), (old: any) => ({ ...(old ?? {}), ...payload }));
      qc.setQueryData(notesListKey(), (list: Note[] = []) =>
        list.map((n) => (n.id === id ? ({ ...n, ...payload }) : n))
      );
      return { prevNote, prevList };
    },
    onError: (_err, vars, ctx: any) => {
      qc.setQueryData(noteKey(vars.id), ctx?.prevNote);
      qc.setQueryData(notesListKey(), ctx?.prevList);
    },
    onSettled: (_data, _err, vars) => {
      qc.invalidateQueries(notesListKey());
      qc.invalidateQueries(noteKey(vars.id));
    },
  });
};
TS

cat > src/features/notes/hooks/useDeleteNote.ts <<'TS'
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { deleteNote } from '../api';
import { notesListKey } from '../queryKeys';
import type { Note } from '../types';

export const useDeleteNote = () => {
  const qc = useQueryClient();
  return useMutation<void, Error, string>({
    mutationFn: (id) => deleteNote(id),
    onMutate: async (id) => {
      await qc.cancelQueries(notesListKey());
      const prev = qc.getQueryData<Note[]>(notesListKey());
      qc.setQueryData(notesListKey(), (list = []) => list.filter((n) => n.id !== id));
      return { prev };
    },
    onError: (_err, _id, ctx: any) => qc.setQueryData(notesListKey(), ctx?.prev ?? []),
    onSettled: () => qc.invalidateQueries(notesListKey()),
  });
};
TS

# 9) Feature components (NotesPage, List, Card, Editor, EditModal)
echo "🧩 Creating Notes components..."
cat > src/features/notes/components/NoteEditor.tsx <<'TSX'
import React, { useState } from 'react';
import { useCreateNote } from '../hooks/useCreateNote';

const NoteEditor: React.FC = () => {
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const { mutateAsync: create, isLoading } = useCreateNote();

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;
    await create({ title, content });
    setTitle('');
    setContent('');
  };

  return (
    <form onSubmit={onSubmit} style={{ marginBottom: 12 }}>
      <input placeholder="Title" value={title} onChange={(e) => setTitle(e.target.value)} />
      <br />
      <textarea placeholder="Content" value={content} onChange={(e) => setContent(e.target.value)} />
      <br />
      <button type="submit" disabled={isLoading}>Add</button>
    </form>
  );
};

export default NoteEditor;
TSX

cat > src/features/notes/components/NoteEditModal.tsx <<'TSX'
import React, { useEffect, useState } from 'react';
import { useNotesUIStore } from '../../../stores/alias';
import { useNote } from '../hooks/useNote';
import { useUpdateNote } from '../hooks/useUpdateNote';

// Use small alias exporter to avoid circular import issues in single-file script
// The alias will be created below. This file expects useNotesUIStore to be imported from alias.

const NoteEditModal: React.FC = () => {
  const selectedId = (useNotesUIStore as any)((s: any) => s.selectedNoteId);
  const isOpen = (useNotesUIStore as any)((s: any) => s.isEditModalOpen);
  const close = (useNotesUIStore as any)((s: any) => s.closeEditModal);
  const { data: note, isLoading } = useNote(selectedId);
  const update = useUpdateNote();

  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');

  useEffect(() => {
    if (note) {
      setTitle(note.title || '');
      setContent(note.content || '');
    }
  }, [note]);

  if (!isOpen) return null;

  const onSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedId) return;
    await update.mutateAsync({ id: selectedId, payload: { title, content } });
    close();
  };

  return (
    <div style={{
      position:'fixed', inset:0, display:'flex', alignItems:'center', justifyContent:'center',
      background: 'rgba(0,0,0,0.4)'
    }}>
      <div style={{ background:'white', padding:16, borderRadius:8, width:480 }}>
        <h3>Edit Note</h3>
        {isLoading && <div>Loading...</div>}
        <form onSubmit={onSave}>
          <input value={title} onChange={e => setTitle(e.target.value)} />
          <br />
          <textarea value={content} onChange={e => setContent(e.target.value)} />
          <br />
          <div style={{ display:'flex', gap:8, justifyContent:'flex-end' }}>
            <button type="button" onClick={close}>Cancel</button>
            <button type="submit">Save</button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default NoteEditModal;
TSX

cat > src/features/notes/components/NoteCard.tsx <<'TSX'
import React from 'react';
import type { Note } from '../types';
import { useDeleteNote } from '../hooks/useDeleteNote';
import { useNotesUIStore } from '../../../stores/alias';
import formatDateTime from '../../../shared/utils/date';

const NoteCard: React.FC<{ note: Note }> = ({ note }) => {
  const remove = useDeleteNote();
  const openEdit = (useNotesUIStore as any)((s: any) => s.openEditModal);

  return (
    <div style={{ border: '1px solid #ddd', padding: 12, marginBottom: 8 }}>
      <h4>{note.title}</h4>
      <p>{note.content}</p>
      <small>{formatDateTime(note.createdAt)}</small>
      <div style={{ marginTop: 8 }}>
        <button onClick={() => openEdit(note.id)}>Edit</button>
        <button onClick={() => remove.mutate(note.id)} style={{ marginLeft: 8 }}>Delete</button>
      </div>
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

  if (isLoading) return <div>Loading notes...</div>;
  if (isError) return <div>Error loading notes</div>;
  if (!data || data.length === 0) return <div>No notes yet</div>;

  return (
    <div>
      {data.map(n => <NoteCard key={n.id} note={n} />)}
    </div>
  );
};

export default NotesList;
TSX

cat > src/features/notes/components/NotesPage.tsx <<'TSX'
import React from 'react';
import NoteEditor from './NoteEditor';
import NotesList from './NotesList';
import NoteEditModal from './NoteEditModal';

const NotesPage: React.FC = () => {
  return (
    <main style={{ padding: 16 }}>
      <h1>Notes</h1>
      <NoteEditor />
      <hr />
      <NotesList />
      <NoteEditModal />
    </main>
  );
};

export default NotesPage;
TSX

# 10) Simple alias file to export Zustand store to components (avoid import cycles)
cat > src/stores/alias.ts <<'TS'
export { useNotesUIStore } from './useNotesUIStore';
TS

# 11) App + routes + main entry
echo "🌐 Creating app entry and routes..."
cat > src/App.tsx <<'TSX'
import React, { Suspense, lazy } from 'react';
import { BrowserRouter, Routes, Route, Link } from 'react-router-dom';
import { AppProviders } from './app/providers';

const NotesPage = lazy(() => import('./features/notes/components/NotesPage'));

export const App: React.FC = () => (
  <AppProviders>
    <BrowserRouter>
      <nav style={{ padding: 8 }}>
        <Link to="/">Home</Link> | <Link to="/notes">Notes</Link>
      </nav>
      <Suspense fallback={<div>Loading...</div>}>
        <Routes>
          <Route path="/" element={<div style={{ padding:16 }}>Welcome</div>} />
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

# 12) Vite config with proxy to backend
cat > vite.config.ts <<'JS'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': 'http://localhost:8080'
    }
  }
});
JS

# 13) Update package.json scripts using CommonJS inline node
echo "🔧 Updating package.json scripts..."
node - <<'NODE'
const fs = require('fs');
const pkgPath = 'package.json';
const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
pkg.scripts = pkg.scripts || {};
pkg.scripts.dev = pkg.scripts.dev || 'vite';
pkg.scripts.build = pkg.scripts.build || 'vite build';
pkg.scripts.preview = pkg.scripts.preview || 'vite preview';
pkg.scripts['test:unit'] = pkg.scripts['test:unit'] || 'vitest';
pkg.scripts['lint'] = pkg.scripts['lint'] || 'eslint --ext .ts,.tsx src';
pkg.type = pkg.type || 'module'; // enable ESM (safe if project expects ESM)
fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2));
console.log('✅ package.json scripts updated.');
NODE

# 14) Basic tsconfig.json if missing
if [ ! -f tsconfig.json ]; then
  cat > tsconfig.json <<'TS'
{
  "compilerOptions": {
    "target": "ES2021",
    "lib": ["DOM", "ES2021"],
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "jsx": "react-jsx",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "isolatedModules": true
  },
  "include": ["src"]
}
TS
  echo "✅ tsconfig.json created"
fi

# 15) Create a basic MSW handler for tests
cat > src/tests/msw-handlers.ts <<'TS'
import { rest } from 'msw';

export const handlers = [
  rest.get('/api/notes', (req, res, ctx) => {
    return res(ctx.json([]));
  }),
];
TS

# 16) Small README snippet and final notes
cat > NOTES_SETUP.md <<'MD'
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
MD

echo "🎉 Done. Run 'npm run dev' and open http://localhost:5173/notes"
