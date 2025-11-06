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
