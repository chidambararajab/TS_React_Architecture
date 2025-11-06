import { useQuery } from '@tanstack/react-query';
import { getNotes } from '../api';
import type { Note } from '../types';

export function useNotes() {
  return useQuery<Note[]>({
    queryKey: ['notes'],
    queryFn: getNotes,
  });
}
