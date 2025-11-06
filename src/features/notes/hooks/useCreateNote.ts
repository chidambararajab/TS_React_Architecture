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
