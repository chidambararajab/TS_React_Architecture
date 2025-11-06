import React from 'react';
import { formatDateTime } from '../../../shared/utils/date';
import type { Note } from '../types';
import { useDeleteNote } from '../hooks/useDeleteNote';

const NoteCard: React.FC<{ note: Note }> = ({ note }) => {
  const { mutate: remove } = useDeleteNote();
  return (
    <div className="note-card">
      <h3>{note.title}</h3>
      <p>{note.content}</p>
      <small>{formatDateTime(note.createdAt)}</small>
      <button onClick={() => remove(note.id)}>🗑️ Delete</button>
    </div>
  );
};
export default NoteCard;
