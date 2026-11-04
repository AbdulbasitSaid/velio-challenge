import { cropTo16x10 } from '@/lib/photo';

describe('photo crop (S6 D4)', () => {
  test('a portrait keeps its centre band at 16:10', () => {
    expect(cropTo16x10(1280, 1707)).toEqual({ sx: 0, sy: 454, sw: 1280, sh: 800 });
  });
  test('a panorama keeps its centre at 16:10', () => {
    expect(cropTo16x10(4000, 1000)).toEqual({ sx: 1200, sy: 0, sw: 1600, sh: 1000 });
  });
  test('16:10 already is untouched', () => {
    expect(cropTo16x10(1600, 1000)).toEqual({ sx: 0, sy: 0, sw: 1600, sh: 1000 });
  });
});
