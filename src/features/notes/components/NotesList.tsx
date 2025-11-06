import React from 'react';
import { useNotes } from '../hooks/useNotes';
import NoteCard from './NoteCard';

const NotesList: React.FC = () => {
  const { data, isLoading, isError } = useNotes();
  if (isLoading) return <p>Loading notes...</p>;
  if (isError) return <p>Error loading notes</p>;
  if (!data?.length) return <p>No notes yet.</p>;
  return (
    <div className="notes-list">
      {data.map(note => <NoteCard key={note.id} note={note} />)}
    </div>
  );
};
export default NotesList;
