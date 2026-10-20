export function removeVietnameseTones(str: string): string {
  if (!str) return '';
  return str
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[đĐ]/g, 'd')
    .toLowerCase()
    .trim();
}

export function matchesVietnameseSearch(target: string, query: string): boolean {
  if (!query || !query.trim()) return true;
  if (!target) return false;

  const targetNFC = target.normalize('NFC').toLowerCase();
  const queryNFC = query.trim().normalize('NFC').toLowerCase();

  if (targetNFC.includes(queryNFC)) return true;

  const targetUnaccent = removeVietnameseTones(target);
  const queryUnaccent = removeVietnameseTones(query);

  return targetUnaccent.includes(queryUnaccent);
}
