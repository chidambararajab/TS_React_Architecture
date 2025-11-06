export const NOTES = ['notes'] as const;
export const notesListKey = (filters: Record<string, any> = {}) => [...NOTES, 'list', filters] as const;
export const noteKey = (id: string) => [...NOTES, 'byId', id] as const;
