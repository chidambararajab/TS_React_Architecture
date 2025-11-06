import React from 'react';
import NoteEditor from './NoteEditor';
import NotesList from './NotesList';
import NoteEditModal from './NoteEditModal';

const NotesPage: React.FC = () => {
  return (
    <main style={{ padding: 16 }}>
      <h1>Notes</h1>
      <NoteEditor />
      <hr />
      <NotesList />
      <NoteEditModal />
    </main>
  );
};

export default NotesPage;
