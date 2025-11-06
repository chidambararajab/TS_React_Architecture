import React from 'react';
import NoteEditor from '../features/notes/components/NoteEditor';
import NotesList from '../features/notes/components/NotesList';

const NotesPage: React.FC = () => (
  <main>
    <h1>📝 Notes</h1>
    <NoteEditor />
    <hr />
    <NotesList />
  </main>
);
export default NotesPage;
