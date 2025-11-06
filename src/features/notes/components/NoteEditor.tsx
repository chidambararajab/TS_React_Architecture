import React, { useState } from 'react';
import { useCreateNote } from '../hooks/useCreateNote';

const NoteEditor: React.FC = () => {
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const { mutateAsync: create, isLoading } = useCreateNote();

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;
    await create({ title, content });
    setTitle('');
    setContent('');
  };

  return (
    <form onSubmit={onSubmit} style={{ marginBottom: 12 }}>
      <input placeholder="Title" value={title} onChange={(e) => setTitle(e.target.value)} />
      <br />
      <textarea placeholder="Content" value={content} onChange={(e) => setContent(e.target.value)} />
      <br />
      <button type="submit" disabled={isLoading}>Add</button>
    </form>
  );
};

export default NoteEditor;
