import { configureStore } from '@reduxjs/toolkit';
import { combineReducers } from 'redux';
import uiReducer from '../shared/ui/uiSlice';
import selectionReducer from '../features/notes/selectionSlice';

const rootReducer = combineReducers({
  ui: uiReducer,
  selection: selectionReducer,
});

export const store = configureStore({
  reducer: rootReducer,
  devTools: import.meta.env.DEV,
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
