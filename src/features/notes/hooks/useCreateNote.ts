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
