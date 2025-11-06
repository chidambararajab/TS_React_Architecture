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
