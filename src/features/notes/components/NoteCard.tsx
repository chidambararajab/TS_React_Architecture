import React, { useState } from "react";
import { formatDateTime } from "../../../shared/utils/date";
import type { Note } from "../types";
import { useDeleteNote } from "../hooks/useDeleteNote";
import NoteEditorModal from "./NoteEditorModal";

const NoteCard: React.FC<{ note: Note }> = ({ note }) => {
  const { mutate: remove } = useDeleteNote();
  const [isEditing, setIsEditing] = useState(false);
  return (
    <div className="note-card">
      <h3>{note.title}</h3>
      <p>{note.content}</p>
      <small>{formatDateTime(note.createdAt)}</small>
      <div className="actions">
        <button onClick={() => setIsEditing(true)}>✏️ Edit</button>
        <button onClick={() => remove(note.id)}>🗑️ Delete</button>
      </div>

      {isEditing && (
        <NoteEditorModal note={note} onClose={() => setIsEditing(false)} />
      )}
    </div>
  );
};
export default NoteCard;
