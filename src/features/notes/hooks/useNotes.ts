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
