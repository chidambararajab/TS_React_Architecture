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
