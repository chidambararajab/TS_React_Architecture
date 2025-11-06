import React, { useState } from 'react';
import { useCreateNote } from '../hooks/useCreateNote';

const NoteEditor: React.FC = () => {
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const { mutateAsync: create } = useCreateNote();

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;
    await create({ title, content });
    setTitle(''); setContent('');
  };

  return (
    <form onSubmit={onSubmit}>
      <input placeholder="Title" value={title} onChange={e => setTitle(e.target.value)} />
      <textarea placeholder="Content" value={content} onChange={e => setContent(e.target.value)} />
      <button type="submit">Add Note</button>
    </form>
  );
};
export default NoteEditor;
