import { createSlice } from '@reduxjs/toolkit';
import type { PayloadAction } from '@reduxjs/toolkit';

interface SelectionState { selectedNoteId?: string | null; }
const initialState: SelectionState = { selectedNoteId: null };

const selectionSlice = createSlice({
  name: 'selection',
  initialState,
  reducers: {
    setSelectedNote: (s, a: PayloadAction<string | null>) => { s.selectedNoteId = a.payload; },
    clearSelectedNote: (s) => { s.selectedNoteId = null; },
  },
});

export const selectionActions = selectionSlice.actions;
export default selectionSlice.reducer;
