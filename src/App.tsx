import React, { Suspense, lazy } from "react";
import { BrowserRouter, Routes, Route, Link } from "react-router-dom";
import { AppProviders } from "./app/providers";
import "./App.css";

const NotesPage = lazy(() => import("./features/notes/components/NotesPage"));

export const App: React.FC = () => (
  <AppProviders>
    <BrowserRouter>
      <nav style={{ padding: 8 }}>
        <Link to="/">Home</Link> | <Link to="/notes">Notes</Link>
      </nav>
      <Suspense fallback={<div>Loading...</div>}>
        <Routes>
          <Route
            path="/"
            element={<div style={{ padding: 16 }}>Welcome</div>}
          />
          <Route path="/notes" element={<NotesPage />} />
        </Routes>
      </Suspense>
    </BrowserRouter>
  </AppProviders>
);
export default App;
