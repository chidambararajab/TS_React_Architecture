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
