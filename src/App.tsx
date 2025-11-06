import React, { Suspense } from "react";
import { BrowserRouter, Routes, Route, Link } from "react-router-dom";
import { AppProviders } from "./app/providers";
import NotesPage from "./routes/NotesPage";
import "./App.css";

const App: React.FC = () => (
  <AppProviders>
    <BrowserRouter>
      <nav className="nav">
        <Link to="/">Home</Link>
        <Link to="/notes">Notes</Link>
      </nav>
      <div className="container">
        <Suspense fallback={<div>Loading...</div>}>
          <Routes>
            <Route path="/" element={<div>Welcome to Notes App</div>} />
            <Route path="/notes" element={<NotesPage />} />
          </Routes>
        </Suspense>
      </div>
    </BrowserRouter>
  </AppProviders>
);
export default App;
