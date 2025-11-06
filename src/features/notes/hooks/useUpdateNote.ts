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
