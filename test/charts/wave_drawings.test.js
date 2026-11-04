// @ts-check
/**
 * Unit test model & geometri Path / Elliott Wave (assets/charts/wave_drawings.js).
 *
 * Jalankan dari folder cuan_app:
 *   node --test "test/charts/*.test.js"
 */
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const WaveDrawings = require('../../assets/charts/wave_drawings.js');

/** @param {number[]} prices */
const pointsOf = (prices) => prices.map((price, i) => ({ time: 1_700_000_000 + i * 86_400, price }));

describe('jenis wave', () => {
  it('jumlah titik mengikuti TradingView (titik awal + satu per gelombang)', () => {
    assert.equal(WaveDrawings.requiredPoints('elliottImpulse'), 6);
    assert.equal(WaveDrawings.requiredPoints('elliottCorrection'), 4);
    assert.equal(WaveDrawings.requiredPoints('elliottTriangle'), 6);
    assert.equal(WaveDrawings.requiredPoints('path'), null);
    assert.equal(WaveDrawings.minPoints('path'), 2);
  });

  it('hanya Elliott Wave yang selesai otomatis saat titiknya lengkap', () => {
    assert.equal(WaveDrawings.isComplete('elliottCorrection', 3), false);
    assert.equal(WaveDrawings.isComplete('elliottCorrection', 4), true);
    assert.equal(WaveDrawings.isComplete('path', 50), false);
  });

  it('isWaveKind menolak jenis lain', () => {
    assert.equal(WaveDrawings.isWaveKind('elliottTriangle'), true);
    assert.equal(WaveDrawings.isWaveKind('trendline'), false);
    assert.equal(WaveDrawings.isWaveKind('toString'), false);
  });
});

describe('label gelombang', () => {
  it('titik awal tanpa label, sisanya derajat Intermediate', () => {
    const labels = [0, 1, 2, 3, 4, 5].map((i) => WaveDrawings.labelAt('elliottImpulse', i));
    assert.deepEqual(labels, [null, '(1)', '(2)', '(3)', '(4)', '(5)']);
    assert.deepEqual(
      [1, 2, 3, 4, 5].map((i) => WaveDrawings.labelAt('elliottTriangle', i)),
      ['(A)', '(B)', '(C)', '(D)', '(E)'],
    );
    assert.equal(WaveDrawings.labelAt('path', 1), null);
  });

  it('label di atas puncak dan di bawah lembah', () => {
    const points = pointsOf([100, 120, 110, 140, 130, 160]);
    const sides = points.map((_, i) => WaveDrawings.labelSide(points, i));
    assert.deepEqual(sides, ['below', 'above', 'below', 'above', 'below', 'above']);
  });

  it('wave turun: puncak & lembah ikut terbalik', () => {
    const points = pointsOf([160, 130, 140, 100]);
    const sides = points.map((_, i) => WaveDrawings.labelSide(points, i));
    assert.deepEqual(sides, ['above', 'below', 'above', 'below']);
  });
});

describe('normalizeWave', () => {
  it('mengisi gaya default jenisnya dan menyalin titik', () => {
    const points = pointsOf([1, 2, 3, 4]);
    const wave = WaveDrawings.normalizeWave({ kind: 'elliottCorrection', points });
    assert.ok(wave);
    assert.equal(wave.color, WaveDrawings.KINDS.elliottCorrection.color);
    assert.equal(wave.width, 2);
    assert.equal(wave.style, 'solid');
    assert.equal(wave.opacity, 1);
    assert.equal(wave.isLocked, false);
    assert.ok(wave.id.startsWith('wave_'));
    assert.notEqual(wave.points[0], points[0]);
    assert.deepEqual(wave.points, points);
  });

  it('mempertahankan gaya yang sah dari Flutter', () => {
    const wave = WaveDrawings.normalizeWave({
      id: 'wave_x',
      kind: 'path',
      points: pointsOf([1, 2, 3]),
      color: '#F23645',
      width: 3,
      style: 'dotted',
      opacity: 0.5,
      isLocked: true,
      hidden: true,
    });
    assert.deepEqual(
      wave && [wave.id, wave.color, wave.width, wave.style, wave.opacity, wave.isLocked, wave.hidden],
      ['wave_x', '#F23645', 3, 'dotted', 0.5, true, true],
    );
  });

  it('menolak jenis, jumlah titik, atau titik yang tidak sah', () => {
    assert.equal(WaveDrawings.normalizeWave(null), null);
    assert.equal(WaveDrawings.normalizeWave({ kind: 'trendline', points: pointsOf([1, 2]) }), null);
    assert.equal(WaveDrawings.normalizeWave({ kind: 'elliottImpulse', points: pointsOf([1, 2, 3]) }), null);
    assert.equal(WaveDrawings.normalizeWave({ kind: 'path', points: pointsOf([1]) }), null);
    assert.equal(WaveDrawings.normalizeWave({ kind: 'path', points: [{ time: 1, price: NaN }, { time: 2, price: 1 }] }), null);
  });

  it('gaya garis tidak dikenal kembali ke solid & opacity dijepit 0..1', () => {
    const wave = WaveDrawings.normalizeWave({ kind: 'path', points: pointsOf([1, 2]), style: 'wavy', opacity: 4 });
    assert.equal(wave?.style, 'solid');
    assert.equal(wave?.opacity, 1);
  });
});

describe('hitTest', () => {
  const screen = [{ x: 0, y: 100 }, { x: 50, y: 0 }, { x: 100, y: 100 }];

  it('titik terdekat dalam radius diprioritaskan', () => {
    assert.deepEqual(WaveDrawings.hitTest(screen, 48, 4, 10, 5), { part: 'anchor', pointIndex: 1 });
  });

  it('segmen kena di luar radius titik', () => {
    assert.deepEqual(WaveDrawings.hitTest(screen, 75, 52, 10, 5), { part: 'body' });
  });

  it('jauh dari wave = tidak kena; titik null dilewati beserta segmennya', () => {
    assert.equal(WaveDrawings.hitTest(screen, 50, 90, 10, 5), null);
    assert.equal(WaveDrawings.hitTest([screen[0], null, screen[2]], 25, 50, 10, 5), null);
  });
});

describe('arrowHead', () => {
  it('sayap simetris di belakang ujung panah', () => {
    const wings = WaveDrawings.arrowHead({ x: 0, y: 0 }, { x: 10, y: 0 }, 4);
    assert.ok(wings);
    const [a, b] = wings;
    assert.ok(a.x < 10 && b.x < 10);
    assert.ok(Math.abs(a.x - b.x) < 1e-9);
    assert.ok(Math.abs(a.y + b.y) < 1e-9);
    assert.ok(Math.abs(Math.hypot(10 - a.x, a.y) - 4) < 1e-9);
  });

  it('segmen nol tidak berpanah', () => {
    assert.equal(WaveDrawings.arrowHead({ x: 5, y: 5 }, { x: 5, y: 5 }, 4), null);
  });
});
