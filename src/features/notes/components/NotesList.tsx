import React from 'react';
import { useNotes } from '../hooks/useNotes';
import NoteCard from './NoteCard';

const NotesList: React.FC = () => {
  const { data, isLoading, isError } = useNotes();

  if (isLoading) return <div>Loading notes...</div>;
  if (isError) return <div>Error loading notes</div>;
  if (!data || data.length === 0) return <div>No notes yet</div>;

  return (
    <div>
      {data.map(n => <NoteCard key={n.id} note={n} />)}
    </div>
  );
};

export default NotesList;
