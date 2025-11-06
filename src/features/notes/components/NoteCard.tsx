import React from 'react';
import type { Note } from '../types';
import { useDeleteNote } from '../hooks/useDeleteNote';
import { useNotesUIStore } from '../../../stores/alias';
import formatDateTime from '../../../shared/utils/date';

const NoteCard: React.FC<{ note: Note }> = ({ note }) => {
  const remove = useDeleteNote();
  const openEdit = (useNotesUIStore as any)((s: any) => s.openEditModal);

  return (
    <div style={{ border: '1px solid #ddd', padding: 12, marginBottom: 8 }}>
      <h4>{note.title}</h4>
      <p>{note.content}</p>
      <small>{formatDateTime(note.createdAt)}</small>
      <div style={{ marginTop: 8 }}>
        <button onClick={() => openEdit(note.id)}>Edit</button>
        <button onClick={() => remove.mutate(note.id)} style={{ marginLeft: 8 }}>Delete</button>
      </div>
    </div>
  );
};

export default NoteCard;
