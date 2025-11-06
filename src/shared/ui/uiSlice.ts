import { createSlice } from "@reduxjs/toolkit";
import type { PayloadAction } from "@reduxjs/toolkit";

interface Toast {
  id: string;
  type: "info" | "success" | "error";
  message: string;
}
interface UIState {
  toasts: Toast[];
}

const initialState: UIState = { toasts: [] };

const uiSlice = createSlice({
  name: "ui",
  initialState,
  reducers: {
    addToast: (state, action: PayloadAction<Toast>) => {
      state.toasts.push(action.payload);
    },
    removeToast: (state, action: PayloadAction<string>) => {
      state.toasts = state.toasts.filter((t) => t.id !== action.payload);
    },
  },
});

export const uiActions = uiSlice.actions;
export default uiSlice.reducer;
