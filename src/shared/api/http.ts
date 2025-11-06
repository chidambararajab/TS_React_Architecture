import axios, { AxiosError } from 'axios';
import { z } from 'zod';

export const api = axios.create({
  baseURL: '/api',
  headers: { 'Content-Type': 'application/json' },
});

export type ApiError = { status: number; message: string };

export function parseAxiosError(err: unknown): ApiError {
  if (axios.isAxiosError(err)) {
    const e = err as AxiosError;
    return { status: e.response?.status ?? 0, message: e.message };
  }
  return { status: 0, message: (err as Error)?.message ?? 'Unknown Error' };
}
