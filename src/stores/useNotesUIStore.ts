import { create } from "zustand";

type Filter = { q?: string; sort?: "newest" | "oldest" };
type State = {
  filter: Filter;
  selectedNoteId?: string | null;
  isEditModalOpen: boolean;
  setFilter: (f: Partial<Filter>) => void;
  setSelectedNote: (id?: string | null) => void;
  openEditModal: (id?: string) => void;
  closeEditModal: () => void;
};

export const useNotesUIStore = create<State>((set) => ({
  filter: {},
  selectedNoteId: null,
  isEditModalOpen: false,
  setFilter: (f) => set((s) => ({ filter: { ...s.filter, ...f } })),
  setSelectedNote: (id) => set(() => ({ selectedNoteId: id ?? null })),
  openEditModal: (id) =>
    set(() => ({ isEditModalOpen: true, selectedNoteId: id ?? null })),
  closeEditModal: () => set(() => ({ isEditModalOpen: false })),
}));
