import { rest } from 'msw';

export const handlers = [
  rest.get('/api/notes', (req, res, ctx) => {
    return res(ctx.json([]));
  }),
];
