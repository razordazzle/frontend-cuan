// @ts-check
/**
 * Unit test rumus indikator chart (assets/charts/indicators.js).
 *
 * Jalankan dari folder cuan_app:
 *   node --test "test/charts/*.test.js"
 */
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const Indicators = require('../../assets/charts/indicators.js');

/** @typedef {{ time: number, open: number, high: number, low: number, close: number, volume: number }} Candle */
/** @typedef {Array<number | null>} Series */

const EPSILON = 1e-9;

/**
 * @param {Series} actual
 * @param {Series} expected
 */
function assertSeriesClose(actual, expected) {
  assert.equal(actual.length, expected.length, 'panjang series berbeda');
  actual.forEach((value, i) => {
    const want = expected[i];
    if (want === null || value === null) {
      assert.equal(value, want, `index ${i}`);
    } else {
      assert.ok(Math.abs(value - want) < EPSILON, `index ${i}: ${value} != ${want}`);
    }
  });
}

/** PRNG deterministik (mulberry32) supaya data acak sama di setiap run. */
function createRandom(seed = 42) {
  let state = seed;
  return () => {
    state = (state + 0x6d2b79f5) | 0;
    let t = Math.imul(state ^ (state >>> 15), 1 | state);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/**
 * @param {number} count
 * @returns {Candle[]}
 */
function randomCandles(count) {
  const random = createRandom();
  /** @type {Candle[]} */
  const candles = [];
  let close = 1000;
  for (let i = 0; i < count; i++) {
    const open = close;
    close = Math.max(1, open + (random() - 0.5) * 40);
    candles.push({
      time: 1_700_000_000 + i * 86_400,
      open,
      high: Math.max(open, close) + random() * 10,
      low: Math.min(open, close) - random() * 10,
      close,
      volume: Math.round(1_000 + random() * 9_000),
    });
  }
  return candles;
}

/**
 * @param {number[]} closes
 * @returns {Candle[]}
 */
function candlesFromCloses(closes) {
  return closes.map((close, i) => ({ time: i, open: close, high: close, low: close, close, volume: 1 }));
}

// ===== Referensi naive (langsung dari definisi rumus, sengaja tidak dioptimasi) =====

/** @param {number[]} values @param {number} length @returns {Series} */
const referenceSma = (values, length) =>
  values.map((_, i) => (i < length - 1 ? null : values.slice(i - length + 1, i + 1).reduce((a, b) => a + b, 0) / length));

/** @param {number[]} values @param {number} length @param {number} alpha @returns {Series} */
function referenceExponential(values, length, alpha) {
  /** @type {number | null} */
  let previous = null;
  return values.map((value, i) => {
    if (i < length - 1) return null;
    previous = previous === null
      ? values.slice(0, length).reduce((a, b) => a + b, 0) / length
      : alpha * value + (1 - alpha) * previous;
    return previous;
  });
}

/** @param {number[]} values @param {number} length @returns {Series} */
const referenceWma = (values, length) =>
  values.map((_, i) =>
    i < length - 1
      ? null
      : values.slice(i - length + 1, i + 1).reduce((acc, v, k) => acc + v * (k + 1), 0) / (length * (length + 1) / 2));

/** @param {number[]} values @param {number[]} volumes @param {number} length @returns {Series} */
const referenceVwma = (values, volumes, length) =>
  values.map((_, i) => {
    if (i < length - 1) return null;
    let priceVolume = 0;
    let volume = 0;
    for (let k = i - length + 1; k <= i; k++) {
      priceVolume += values[k] * volumes[k];
      volume += volumes[k];
    }
    return priceVolume / volume;
  });

/**
 * RSI Wilder langkah demi langkah (seed rata-rata `period` perubahan pertama).
 * @param {number[]} closes
 * @param {number} period
 * @returns {number[]}
 */
function referenceRsi(closes, period) {
  /** @type {number[]} */
  const result = [];
  let avgGain = 0;
  let avgLoss = 0;
  for (let i = 1; i < closes.length; i++) {
    const change = closes[i] - closes[i - 1];
    const gain = Math.max(change, 0);
    const loss = Math.max(-change, 0);
    if (i <= period) {
      avgGain += gain / period;
      avgLoss += loss / period;
      if (i < period) continue;
    } else {
      avgGain = (avgGain * (period - 1) + gain) / period;
      avgLoss = (avgLoss * (period - 1) + loss) / period;
    }
    result.push(avgLoss === 0 ? 100 : avgGain === 0 ? 0 : 100 - 100 / (1 + avgGain / avgLoss));
  }
  return result;
}

// ===== Test =====

describe('sourceValue', () => {
  const candle = { time: 0, open: 10, high: 20, low: 4, close: 15 };

  it('mengikuti label Source di UI', () => {
    assert.equal(Indicators.sourceValue(candle, 'Open'), 10);
    assert.equal(Indicators.sourceValue(candle, 'High'), 20);
    assert.equal(Indicators.sourceValue(candle, 'Low'), 4);
    assert.equal(Indicators.sourceValue(candle, 'Close'), 15);
    assert.equal(Indicators.sourceValue(candle, '(H + L)/2'), 12);
    assert.equal(Indicators.sourceValue(candle, '(H + L + C)/3'), 13);
    assert.equal(Indicators.sourceValue(candle, '(O + H + L + C)/4'), 12.25);
  });

  it('menerima alias TradingView & default ke close', () => {
    assert.equal(Indicators.sourceValue(candle, 'hl2'), 12);
    assert.equal(Indicators.sourceValue(candle, 'hlc3'), 13);
    assert.equal(Indicators.sourceValue(candle, 'ohlc4'), 12.25);
    assert.equal(Indicators.sourceValue(candle), 15);
    assert.equal(Indicators.sourceValue(candle, 'tidak dikenal'), 15);
  });
});

describe('moving average', () => {
  const values = [1, 2, 3, 4, 5];

  it('menghitung contoh hitung tangan', () => {
    assertSeriesClose(Indicators.sma(values, 3), [null, null, 2, 3, 4]);
    // EMA alpha 0.5, seed SMA(1,2,3) = 2 -> 0.5*4 + 0.5*2 = 3 -> 0.5*5 + 0.5*3 = 4
    assertSeriesClose(Indicators.ema(values, 3), [null, null, 2, 3, 4]);
    // RMA alpha 1/3: (4 + 2*2)/3 = 8/3 -> (5 + 2*8/3)/3 = 31/9
    assertSeriesClose(Indicators.rma(values, 3), [null, null, 2, 8 / 3, 31 / 9]);
    // WMA bobot 1,2,3 (penyebut 6)
    assertSeriesClose(Indicators.wma(values, 3), [null, null, 14 / 6, 20 / 6, 26 / 6]);
    // VWMA (1*1 + 2*1 + 3*2) / (1 + 1 + 2)
    assertSeriesClose(Indicators.vwma([1, 2, 3], [1, 1, 2], 3), [null, null, 9 / 4]);
  });

  it('mengembalikan null semua kalau data kurang dari length', () => {
    for (const type of /** @type {const} */ (['SMA', 'EMA', 'SMMA (RMA)', 'WMA'])) {
      assertSeriesClose(Indicators.movingAverage(type, [1, 2], 3), [null, null]);
    }
  });

  it('VWMA bernilai null kalau total volume 0', () => {
    assertSeriesClose(Indicators.vwma([1, 2, 3], [0, 0, 0], 3), [null, null, null]);
  });

  it('sama dengan referensi naive pada data acak', () => {
    const candles = randomCandles(400);
    const closes = candles.map((c) => c.close);
    const volumes = candles.map((c) => c.volume);
    for (const length of [1, 2, 9, 14, 50]) {
      assertSeriesClose(Indicators.sma(closes, length), referenceSma(closes, length));
      assertSeriesClose(Indicators.ema(closes, length), referenceExponential(closes, length, 2 / (length + 1)));
      assertSeriesClose(Indicators.rma(closes, length), referenceExponential(closes, length, 1 / length));
      assertSeriesClose(Indicators.wma(closes, length), referenceWma(closes, length));
      assertSeriesClose(Indicators.vwma(closes, volumes, length), referenceVwma(closes, volumes, length));
    }
  });

  it('movingAverage memilih rumus sesuai tipe smoothing di UI', () => {
    const closes = randomCandles(60).map((c) => c.close);
    assert.deepEqual(Indicators.movingAverage('SMA', closes, 5), Indicators.sma(closes, 5));
    assert.deepEqual(Indicators.movingAverage('EMA', closes, 5), Indicators.ema(closes, 5));
    assert.deepEqual(Indicators.movingAverage('SMMA (RMA)', closes, 5), Indicators.rma(closes, 5));
    assert.deepEqual(Indicators.movingAverage('WMA', closes, 5), Indicators.wma(closes, 5));
  });

  it('melempar error untuk VWMA tanpa volume & tipe tidak dikenal', () => {
    assert.throws(() => Indicators.movingAverage('VWMA', values, 3), /volume/);
    // @ts-expect-error -- sengaja tipe tidak valid
    assert.throws(() => Indicators.movingAverage('HMA', values, 3), /tidak dikenal/);
  });
});

describe('smaPoints', () => {
  it('menghasilkan titik mulai candle ke-period dengan waktu yang sesuai', () => {
    const candles = candlesFromCloses([1, 2, 3, 4, 5]);
    assert.deepEqual(Indicators.smaPoints(candles, 3), [
      { time: 2, value: 2 },
      { time: 3, value: 3 },
      { time: 4, value: 4 },
    ]);
  });

  it('memakai source yang dipilih', () => {
    const candles = randomCandles(50);
    const highs = candles.map((c) => c.high);
    const expected = referenceSma(highs, 10).flatMap((value) => (value === null ? [] : [value]));
    assertSeriesClose(Indicators.smaPoints(candles, 10, 'High').map((p) => p.value), expected);
  });

  it('kosong kalau candle kurang dari period', () => {
    assert.deepEqual(Indicators.smaPoints(candlesFromCloses([1, 2]), 3), []);
  });
});

describe('rsiPoints', () => {
  it('sama dengan RSI Wilder referensi pada data acak', () => {
    const candles = randomCandles(400);
    const closes = candles.map((c) => c.close);
    for (const period of [2, 7, 14, 21]) {
      const points = Indicators.rsiPoints(candles, period);
      assertSeriesClose(points.map((p) => p.value), referenceRsi(closes, period));
    }
  });

  it('titik pertama di candle ke-period, jumlah titik = candle - period', () => {
    const candles = randomCandles(30);
    const points = Indicators.rsiPoints(candles, 14);
    assert.equal(points.length, 16);
    assert.equal(points[0].time, candles[14].time);
    assert.equal(points.at(-1)?.time, candles.at(-1)?.time);
  });

  it('100 saat harga naik terus atau datar, 0 saat turun terus', () => {
    const rising = candlesFromCloses(Array.from({ length: 30 }, (_, i) => 100 + i));
    const falling = candlesFromCloses(Array.from({ length: 30 }, (_, i) => 200 - i));
    const flat = candlesFromCloses(new Array(30).fill(100));
    assert.ok(Indicators.rsiPoints(rising, 14).every((p) => p.value === 100));
    assert.ok(Indicators.rsiPoints(falling, 14).every((p) => p.value === 0));
    assert.ok(Indicators.rsiPoints(flat, 14).every((p) => p.value === 100));
  });

  it('selalu di rentang 0..100', () => {
    assert.ok(Indicators.rsiPoints(randomCandles(300), 14).every((p) => p.value >= 0 && p.value <= 100));
  });

  it('kosong kalau candle tidak lebih dari period', () => {
    assert.deepEqual(Indicators.rsiPoints(candlesFromCloses(new Array(14).fill(1)), 14), []);
  });
});

describe('smoothPoints', () => {
  it('menerapkan moving average ke nilai Point & mempertahankan waktunya', () => {
    const points = [1, 2, 3, 4, 5].map((value, i) => ({ time: 10 + i, value }));
    assert.deepEqual(Indicators.smoothPoints(points, 'SMA', 3, []), [
      { time: 12, value: 2 },
      { time: 13, value: 3 },
      { time: 14, value: 4 },
    ]);
  });

  it('VWMA mengambil volume dari candle dengan waktu yang sama', () => {
    const candles = [
      { time: 1, open: 0, high: 0, low: 0, close: 0, volume: 1 },
      { time: 2, open: 0, high: 0, low: 0, close: 0, volume: 1 },
      { time: 3, open: 0, high: 0, low: 0, close: 0, volume: 2 },
    ];
    const points = [{ time: 1, value: 1 }, { time: 2, value: 2 }, { time: 3, value: 3 }];
    assert.deepEqual(Indicators.smoothPoints(points, 'VWMA', 3, candles), [{ time: 3, value: 9 / 4 }]);
  });

  it('kosong kalau input kosong', () => {
    assert.deepEqual(Indicators.smoothPoints([], 'EMA', 3, []), []);
  });
});

describe('shiftPoints', () => {
  const candles = candlesFromCloses([1, 2, 3, 4, 5]);
  const points = [{ time: 1, value: 10 }, { time: 2, value: 20 }, { time: 3, value: 30 }];

  it('menggeser ke kanan & membuang yang lewat candle terakhir', () => {
    assert.deepEqual(Indicators.shiftPoints(points, 2, candles), [
      { time: 3, value: 10 },
      { time: 4, value: 20 },
    ]);
  });

  it('menggeser ke kiri & membuang yang sebelum candle pertama', () => {
    assert.deepEqual(Indicators.shiftPoints(points, -2, candles), [{ time: 0, value: 20 }, { time: 1, value: 30 }]);
  });

  it('offset 0 mengembalikan salinan (tidak mengubah input)', () => {
    const shifted = Indicators.shiftPoints(points, 0, candles);
    assert.deepEqual(shifted, points);
    assert.notEqual(shifted, points);
  });

  it('mengabaikan titik yang waktunya tidak ada di candle', () => {
    assert.deepEqual(Indicators.shiftPoints([{ time: 99, value: 1 }], 1, candles), []);
  });
});

describe('modul', () => {
  it('immutable supaya rumus tidak bisa ditimpa dari luar', () => {
    assert.ok(Object.isFrozen(Indicators));
  });
});
