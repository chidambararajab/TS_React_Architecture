export interface Note {
  id: string;
  title: string;
  content: string;
  createdAt: string;
  updatedAt?: string;
}

export type CreateNoteDTO = Pick<Note, 'title' | 'content'>;
export type UpdateNoteDTO = Partial<CreateNoteDTO>;
