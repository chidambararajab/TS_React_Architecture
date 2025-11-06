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
