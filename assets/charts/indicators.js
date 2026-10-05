// @ts-check
/**
 * Rumus technical indicator untuk chart (fungsi murni, tanpa DOM / Lightweight Charts).
 *
 * Satu-satunya sumber perhitungan indikator di app. Definisi mengikuti TradingView:
 * EMA & RMA di-seed dengan SMA, RSI memakai Wilder (RMA).
 *
 * - Browser (tv_chart.html): `window.Indicators`
 * - Node (unit test):        `require('./indicators.js')`
 *
 * Unit test: `node --test "test/charts/*.test.js"` (dari folder cuan_app).
 */
(function (root) {
    'use strict';

    /** @typedef {{ time: number, open: number, high: number, low: number, close: number, volume?: number }} Candle */
    /** @typedef {{ time: number, value: number }} Point */
    /** Array sejajar dengan input; `null` = data belum cukup untuk dihitung. */
    /** @typedef {Array<number | null>} Series */
    /** @typedef {'SMA' | 'EMA' | 'SMMA (RMA)' | 'WMA' | 'VWMA'} MovingAverageType */

    // ===== Harga sumber =====

    /**
     * Nilai harga sesuai pilihan "Source" (label UI atau alias TradingView).
     * @param {Candle} candle
     * @param {string} [source='Close'] Open | High | Low | Close | (H + L)/2 | (H + L + C)/3 | (O + H + L + C)/4
     * @returns {number}
     */
    function sourceValue(candle, source = 'Close') {
        switch (source.toLowerCase().trim()) {
            case 'open': return candle.open;
            case 'high': return candle.high;
            case 'low': return candle.low;
            case 'hl2':
            case '(h + l)/2': return (candle.high + candle.low) / 2;
            case 'hlc3':
            case '(h + l + c)/3': return (candle.high + candle.low + candle.close) / 3;
            case 'ohlc4':
            case '(o + h + l + c)/4': return (candle.open + candle.high + candle.low + candle.close) / 4;
            default: return candle.close;
        }
    }

    /**
     * @param {readonly Candle[]} candles
     * @param {string} source
     * @returns {number[]}
     */
    function sourceValues(candles, source) {
        return candles.map((candle) => sourceValue(candle, source));
    }

    // ===== Moving average (array angka -> Series sejajar) =====

    /**
     * Simple moving average, O(n).
     * @param {readonly number[]} values
     * @param {number} length
     * @returns {Series}
     */
    function sma(values, length) {
        /** @type {Series} */
        const out = new Array(values.length).fill(null);
        let sum = 0;
        for (let i = 0; i < values.length; i++) {
            sum += values[i];
            if (i >= length) sum -= values[i - length];
            if (i >= length - 1) out[i] = sum / length;
        }
        return out;
    }

    /**
     * Exponential smoothing dengan seed SMA (dasar EMA & RMA ala TradingView), O(n).
     * @param {readonly number[]} values
     * @param {number} length
     * @param {number} alpha
     * @returns {Series}
     */
    function exponentialSmoothing(values, length, alpha) {
        /** @type {Series} */
        const out = new Array(values.length).fill(null);
        if (values.length < length) return out;
        let previous = 0;
        for (let i = 0; i < length; i++) previous += values[i];
        previous /= length;
        out[length - 1] = previous;
        for (let i = length; i < values.length; i++) {
            previous = alpha * values[i] + (1 - alpha) * previous;
            out[i] = previous;
        }
        return out;
    }

    /**
     * Exponential moving average, alpha = 2 / (length + 1).
     * @param {readonly number[]} values
     * @param {number} length
     * @returns {Series}
     */
    function ema(values, length) {
        return exponentialSmoothing(values, length, 2 / (length + 1));
    }

    /**
     * Wilder's smoothing / SMMA (RMA), alpha = 1 / length.
     * @param {readonly number[]} values
     * @param {number} length
     * @returns {Series}
     */
    function rma(values, length) {
        return exponentialSmoothing(values, length, 1 / length);
    }

    /**
     * Weighted moving average (bobot 1..length, data terbaru terbesar), O(n) dengan rolling sum.
     * @param {readonly number[]} values
     * @param {number} length
     * @returns {Series}
     */
    function wma(values, length) {
        /** @type {Series} */
        const out = new Array(values.length).fill(null);
        const denominator = length * (length + 1) / 2;
        let weightedSum = 0;
        let sum = 0;
        for (let i = 0; i < values.length; i++) {
            const value = values[i];
            if (i < length) {
                weightedSum += value * (i + 1);
                sum += value;
            } else {
                // Semua bobot turun 1 (yang paling lama keluar), data baru masuk dengan bobot `length`.
                weightedSum += length * value - sum;
                sum += value - values[i - length];
            }
            if (i >= length - 1) out[i] = weightedSum / denominator;
        }
        return out;
    }

    /**
     * Volume-weighted moving average: sma(value * volume) / sma(volume).
     * @param {readonly number[]} values
     * @param {readonly number[]} volumes sejajar dengan `values`
     * @param {number} length
     * @returns {Series}
     */
    function vwma(values, volumes, length) {
        const priceVolume = sma(values.map((value, i) => value * volumes[i]), length);
        const volume = sma(volumes, length);
        return priceVolume.map((pv, i) => {
            const v = volume[i];
            return pv === null || !v ? null : pv / v;
        });
    }

    /**
     * @param {MovingAverageType} type
     * @param {readonly number[]} values
     * @param {number} length
     * @param {readonly number[]} [volumes] wajib untuk VWMA
     * @returns {Series}
     */
    function movingAverage(type, values, length, volumes) {
        switch (type) {
            case 'SMA': return sma(values, length);
            case 'EMA': return ema(values, length);
            case 'SMMA (RMA)': return rma(values, length);
            case 'WMA': return wma(values, length);
            case 'VWMA':
                if (!volumes) throw new Error('VWMA membutuhkan data volume');
                return vwma(values, volumes, length);
            default: throw new Error(`Moving average tidak dikenal: ${type}`);
        }
    }

    // ===== Point series (siap dipakai Lightweight Charts) =====

    /**
     * Gabungkan waktu & Series jadi Point, buang yang null.
     * @param {readonly number[]} times
     * @param {Series} series
     * @returns {Point[]}
     */
    function toPoints(times, series) {
        /** @type {Point[]} */
        const points = [];
        for (let i = 0; i < series.length; i++) {
            const value = series[i];
            if (value !== null) points.push({ time: times[i], value: value });
        }
        return points;
    }

    /**
     * Simple Moving Average dari candle.
     * @param {readonly Candle[]} candles
     * @param {number} period
     * @param {string} [source='Close']
     * @returns {Point[]}
     */
    function smaPoints(candles, period, source = 'Close') {
        return toPoints(candles.map((c) => c.time), sma(sourceValues(candles, source), period));
    }

    /**
     * Relative Strength Index (Wilder), sama dengan `ta.rsi` TradingView.
     * Titik pertama ada di candle ke-`period` (butuh `period` perubahan harga).
     * @param {readonly Candle[]} candles
     * @param {number} period
     * @param {string} [source='Close']
     * @returns {Point[]}
     */
    function rsiPoints(candles, period, source = 'Close') {
        if (candles.length <= period) return [];
        const values = sourceValues(candles, source);
        const changes = values.length - 1;
        /** @type {number[]} */
        const gains = new Array(changes);
        /** @type {number[]} */
        const losses = new Array(changes);
        for (let i = 0; i < changes; i++) {
            const change = values[i + 1] - values[i];
            gains[i] = change > 0 ? change : 0;
            losses[i] = change < 0 ? -change : 0;
        }
        const avgGains = rma(gains, period);
        const avgLosses = rma(losses, period);

        /** @type {Point[]} */
        const points = [];
        for (let i = period - 1; i < changes; i++) {
            const up = /** @type {number} */ (avgGains[i]);
            const down = /** @type {number} */ (avgLosses[i]);
            const rsi = down === 0 ? 100 : up === 0 ? 0 : 100 - 100 / (1 + up / down);
            points.push({ time: candles[i + 1].time, value: rsi });
        }
        return points;
    }

    /**
     * Moving average dari Point series lain (mis. garis "Smoothing MA" di atas SMA).
     * Volume untuk VWMA diambil dari candle dengan waktu yang sama.
     * @param {readonly Point[]} points
     * @param {MovingAverageType} type
     * @param {number} length
     * @param {readonly Candle[]} candles
     * @returns {Point[]}
     */
    function smoothPoints(points, type, length, candles) {
        if (points.length === 0) return [];
        /** @type {number[] | undefined} */
        let volumes;
        if (type === 'VWMA') {
            const volumeByTime = new Map(candles.map((c) => [c.time, c.volume || 0]));
            volumes = points.map((p) => volumeByTime.get(p.time) || 0);
        }
        const smoothed = movingAverage(type, points.map((p) => p.value), length, volumes);
        return toPoints(points.map((p) => p.time), smoothed);
    }

    /**
     * Geser Point sejumlah `offset` bar (input "Offset"); titik yang keluar dari rentang candle dibuang.
     * @param {readonly Point[]} points
     * @param {number} offset positif = ke kanan, negatif = ke kiri
     * @param {readonly Candle[]} candles
     * @returns {Point[]}
     */
    function shiftPoints(points, offset, candles) {
        if (!offset) return points.slice();
        const indexByTime = new Map(candles.map((c, i) => [c.time, i]));
        /** @type {Point[]} */
        const shifted = [];
        for (const point of points) {
            const index = indexByTime.get(point.time);
            if (index === undefined) continue;
            const target = index + offset;
            if (target >= 0 && target < candles.length) {
                shifted.push({ time: candles[target].time, value: point.value });
            }
        }
        return shifted;
    }

    const Indicators = Object.freeze({
        sourceValue,
        sma,
        ema,
        rma,
        wma,
        vwma,
        movingAverage,
        smaPoints,
        rsiPoints,
        smoothPoints,
        shiftPoints,
    });

    // @ts-ignore -- `module` hanya ada di Node (dipakai unit test).
    if (typeof module === 'object' && module.exports) {
        // @ts-ignore
        module.exports = Indicators;
    } else {
        /** @type {Record<string, unknown>} */ (root).Indicators = Indicators;
    }
})(typeof globalThis !== 'undefined' ? globalThis : this);
