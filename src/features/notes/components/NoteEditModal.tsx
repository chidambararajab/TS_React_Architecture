import React, { useEffect, useState } from "react";
import { useNotesUIStore } from "../../../stores/alias";
import { useNote } from "../hooks/useNote";
import { useUpdateNote } from "../hooks/useUpdateNote";

// Use small alias exporter to avoid circular import issues in single-file script
// The alias will be created below. This file expects useNotesUIStore to be imported from alias.

const NoteEditModal: React.FC = () => {
  const selectedId = (useNotesUIStore as any)((s: any) => s.selectedNoteId);
  const isOpen = (useNotesUIStore as any)((s: any) => s.isEditModalOpen);
  const close = (useNotesUIStore as any)((s: any) => s.closeEditModal);
  const { data: note, isLoading } = useNote(selectedId);
  const update = useUpdateNote();

  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");

  useEffect(() => {
    if (note) {
      setTitle(note.title || "");
      setContent(note.content || "");
    }
  }, [note]);

  if (!isOpen) return null;

  const onSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedId) return;
    await update.mutateAsync({ id: selectedId, payload: { title, content } });
    close();
  };

  return (
    <div
      onClick={(e) => {
        if (e.target === e.currentTarget) close();
      }}
      style={{
        position: "fixed",
        inset: 0,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: 16,
        background: "rgba(0,0,0,0.45)",
        backdropFilter: "blur(2px)",
        zIndex: 1000,
      }}
    >
      <div
        role="dialog"
        aria-modal="true"
        style={{
          background: "#fff",
          padding: 24,
          borderRadius: 12,
          width: "min(92vw, 560px)",
          boxShadow: "0 10px 30px rgba(0,0,0,0.25)",
          color: "#111827",
          maxHeight: "85vh",
          overflow: "auto",
        }}
      >
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            marginBottom: 16,
          }}
        >
          <h3 style={{ margin: 0, fontSize: 20, fontWeight: 600 }}>
            Edit Note
          </h3>
          <button
            type="button"
            aria-label="Close"
            onClick={close}
            style={{
              appearance: "none",
              border: "none",
              background: "transparent",
              cursor: "pointer",
              fontSize: 20,
              lineHeight: 1,
              padding: 6,
              borderRadius: 6,
            }}
          >
            ×
          </button>
        </div>
        {isLoading && (
          <div style={{ marginBottom: 12, color: "#6B7280", fontSize: 14 }}>
            Loading...
          </div>
        )}
        <form onSubmit={onSave} style={{ display: "grid", gap: 12 }}>
          <label style={{ display: "grid", gap: 6 }}>
            <span style={{ fontSize: 13, color: "#374151" }}>Title</span>
            <input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Enter title"
              style={{
                width: "100%",
                padding: "10px 12px",
                borderRadius: 8,
                border: "1px solid #E5E7EB",
                outline: "none",
                fontSize: 14,
                color: "#111827",
              }}
            />
          </label>
          <label style={{ display: "grid", gap: 6 }}>
            <span style={{ fontSize: 13, color: "#374151" }}>Content</span>
            <textarea
              value={content}
              onChange={(e) => setContent(e.target.value)}
              placeholder="Write your note..."
              rows={8}
              style={{
                width: "100%",
                padding: "10px 12px",
                borderRadius: 8,
                border: "1px solid #E5E7EB",
                outline: "none",
                fontSize: 14,
                color: "#111827",
                resize: "vertical",
                minHeight: 160,
              }}
            />
          </label>
          <div
            style={{
              display: "flex",
              gap: 8,
              justifyContent: "flex-end",
              marginTop: 4,
            }}
          >
            <button
              type="button"
              onClick={close}
              style={{
                padding: "10px 14px",
                borderRadius: 8,
                border: "1px solid #E5E7EB",
                background: "#F9FAFB",
                color: "#111827",
                cursor: "pointer",
              }}
            >
              Cancel
            </button>
            <button
              type="submit"
              style={{
                padding: "10px 14px",
                borderRadius: 8,
                border: "1px solid #2563EB",
                background: "#2563EB",
                color: "white",
                cursor: "pointer",
                fontWeight: 600,
              }}
            >
              Save
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default NoteEditModal;
