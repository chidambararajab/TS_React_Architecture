import { useMutation, useQueryClient } from '@tanstack/react-query';
import { deleteNote } from '../api';

export function useDeleteNote() {
  const qc = useQueryClient();
  return useMutation<void, Error, string>({
    mutationFn: deleteNote,
    onSuccess: () => qc.invalidateQueries({ queryKey: ['notes'] }),
  });
}
