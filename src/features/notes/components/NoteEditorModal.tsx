import React, { useEffect, useState } from "react";
import { useUpdateNote } from "../hooks/useUpdateNote";
import type { Note } from "../types";

interface Props {
  note: Note;
  onClose: () => void;
}

const NoteEditorModal: React.FC<Props> = ({ note, onClose }) => {
  const [title, setTitle] = useState(note.title);
  const [content, setContent] = useState(note.content);
  const { mutateAsync: update, isPending } = useUpdateNote();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await update({ id: note.id, payload: { title, content } });
    onClose();
  };

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, [onClose]);

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <h2>Edit Note</h2>
        <form onSubmit={handleSubmit}>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Title"
          />
          <textarea
            value={content}
            onChange={(e) => setContent(e.target.value)}
            placeholder="Content"
          />
          <div className="actions">
            <button type="submit" disabled={isPending}>
              Save
            </button>
            <button type="button" onClick={onClose}>
              Cancel
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default NoteEditorModal;
