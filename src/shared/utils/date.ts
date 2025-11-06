export const formatDateTime = (iso?: string) => {
  if (!iso) return '';
  const d = new Date(iso);
  return d.toLocaleString();
};
export default formatDateTime;
