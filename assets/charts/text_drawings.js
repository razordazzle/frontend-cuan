// @ts-check
/**
 * Model & tata letak drawing Text di chart ala TradingView (fungsi murni, tanpa DOM).
 *
 * Text ditaruh di satu titik { time, price } = pojok kiri-atas kotaknya, lalu langsung diketik di tempat
 * (Text baru masih kosong). Isinya boleh beberapa baris,
 * dengan opsi background, border, dan text wrap (lebar kotak tetap, teks dipatah per kata).
 * Nama field gaya teks sama dengan teks trendline (`textColor`, `textSize`, ...), jadi modal settings teks
 * & tombol warna di toolbar chart bisa dipakai bersama.
 *
 * - Browser (tv_chart.html): `window.TextDrawings`
 * - Node (unit test):        `require('./text_drawings.js')`
 *
 * Unit test: `node --test "test/charts/*.test.js"` (dari folder cuan_app).
 */
(function (root) {
    'use strict';

    /** @typedef {{ time: number, price: number }} TextPoint */
    /** @typedef {{ x: number, y: number }} ScreenPoint */
    /**
     * @typedef {{
     *   text: string,
     *   textColor: string,
     *   textOpacity: number,
     *   textSize: number,
     *   textBold: boolean,
     *   textItalic: boolean,
     *   showBackground: boolean,
     *   fillColor: string,
     *   fillOpacity: number,
     *   showBorder: boolean,
     *   borderColor: string,
     *   wrap: boolean,
     *   wrapWidth: number,
     * }} TextStyle
     */
    /** @typedef {{ id: string, point: TextPoint, isLocked: boolean, hidden: boolean } & TextStyle} TextDrawing */
    /** Lebar teks dalam px untuk font drawing yang sedang diukur. */
    /** @typedef {(text: string) => number} MeasureText */
    /**
     * Kotak Text di layar relatif terhadap titiknya: `lines` sudah dipatah (wrap), `width`/`height` termasuk padding.
     * @typedef {{ lines: string[], lineHeight: number, width: number, height: number }} TextLayout
     */
    /** @typedef {'body' | 'resize'} TextHit */

    /** Gaya default Text baru (TradingView: biru, 14px, tanpa background/border/wrap, isi kosong). */
    /** @type {Readonly<TextStyle>} */
    const DEFAULTS = Object.freeze({
        text: '',
        textColor: '#2962FF',
        textOpacity: 1,
        textSize: 14,
        textBold: false,
        textItalic: false,
        showBackground: false,
        fillColor: '#2962FF',
        fillOpacity: 0.2,
        showBorder: false,
        borderColor: '#2962FF',
        wrap: false,
        wrapWidth: 200,
    });

    /** Jarak teks ke tepi kotak (background/border). */
    const PADDING = 6;
    const LINE_HEIGHT = 1.25;
    /** Lebar teks minimum saat kotak wrap dipersempit. */
    const MIN_WRAP_WIDTH = 40;

    /** @param {unknown} value */
    function isFiniteNumber(value) {
        return typeof value === 'number' && Number.isFinite(value);
    }

    /**
     * @param {unknown} value
     * @param {string} fallback
     */
    function colorOr(value, fallback) {
        return typeof value === 'string' && value ? value : fallback;
    }

    /**
     * Opacity 0..1 (dijepit); `fallback` kalau bukan angka.
     * @param {unknown} value
     * @param {number} fallback
     */
    function unitOr(value, fallback) {
        return isFiniteNumber(value) ? Math.min(1, Math.max(0, /** @type {number} */ (value))) : fallback;
    }

    /** @returns {string} */
    function newTextId() {
        return 'text_' + Date.now() + '_' + Math.random().toString(36).slice(2, 7);
    }

    /**
     * Text baru dengan gaya default di `point`.
     * @param {TextPoint} point
     * @returns {TextDrawing}
     */
    function createText(point) {
        return { id: newTextId(), point: { time: point.time, price: point.price }, isLocked: false, hidden: false, ...DEFAULTS };
    }

    /**
     * Text dari data luar (Flutter / clone); null kalau titiknya tidak sah. Field gaya yang kosong/tidak sah
     * memakai default.
     * @param {unknown} item
     * @returns {TextDrawing | null}
     */
    function normalizeText(item) {
        if (typeof item !== 'object' || item === null) return null;
        const raw = /** @type {Record<string, unknown>} */ (item);
        const point = /** @type {Record<string, unknown> | null} */ (typeof raw.point === 'object' ? raw.point : null);
        if (!point || !isFiniteNumber(point.time) || !isFiniteNumber(point.price)) return null;
        const { textSize, textOpacity, fillOpacity, wrapWidth } = raw;
        return {
            id: typeof raw.id === 'string' && raw.id ? raw.id : newTextId(),
            point: { time: /** @type {number} */ (point.time), price: /** @type {number} */ (point.price) },
            text: typeof raw.text === 'string' ? raw.text : DEFAULTS.text,
            textColor: colorOr(raw.textColor, DEFAULTS.textColor),
            textOpacity: unitOr(textOpacity, DEFAULTS.textOpacity),
            textSize: isFiniteNumber(textSize) && /** @type {number} */ (textSize) > 0 ? /** @type {number} */ (textSize) : DEFAULTS.textSize,
            textBold: raw.textBold === true,
            textItalic: raw.textItalic === true,
            showBackground: raw.showBackground === true,
            fillColor: colorOr(raw.fillColor, DEFAULTS.fillColor),
            fillOpacity: unitOr(fillOpacity, DEFAULTS.fillOpacity),
            showBorder: raw.showBorder === true,
            borderColor: colorOr(raw.borderColor, DEFAULTS.borderColor),
            wrap: raw.wrap === true,
            wrapWidth: isFiniteNumber(wrapWidth) ? Math.max(MIN_WRAP_WIDTH, /** @type {number} */ (wrapWidth)) : DEFAULTS.wrapWidth,
            isLocked: raw.isLocked === true,
            hidden: raw.hidden === true,
        };
    }

    /**
     * Font CSS drawing Text.
     * @param {Pick<TextStyle, 'textSize' | 'textBold' | 'textItalic'>} style
     * @returns {string}
     */
    function fontOf(style) {
        return `${style.textItalic ? 'italic ' : ''}${style.textBold ? 'bold' : '500'} ${style.textSize}px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif`;
    }

    /**
     * Patah teks per kata supaya tiap baris muat di `maxWidth`; kata yang lebih panjang dari `maxWidth`
     * dipatah per karakter. Baris baru (`\n`) dari user tetap dipertahankan.
     * @param {string} text
     * @param {number} maxWidth
     * @param {MeasureText} measure
     * @returns {string[]}
     */
    function wrapLines(text, maxWidth, measure) {
        /** @type {string[]} */
        const lines = [];
        for (const paragraph of text.split('\n')) {
            let line = '';
            for (const word of paragraph.split(' ')) {
                const candidate = line ? `${line} ${word}` : word;
                if (measure(candidate) <= maxWidth) {
                    line = candidate;
                    continue;
                }
                if (line) lines.push(line);
                // Kata tunggal yang tetap kepanjangan dipatah per karakter.
                line = '';
                for (const char of word) {
                    if (line && measure(line + char) > maxWidth) {
                        lines.push(line);
                        line = '';
                    }
                    line += char;
                }
            }
            lines.push(line);
        }
        return lines;
    }

    /**
     * Ukuran kotak Text (termasuk padding) & baris-barisnya.
     * @param {TextStyle} style
     * @param {MeasureText} measure
     * @returns {TextLayout}
     */
    function layoutText(style, measure) {
        const lines = style.wrap ? wrapLines(style.text, style.wrapWidth, measure) : style.text.split('\n');
        const lineHeight = Math.round(style.textSize * LINE_HEIGHT);
        const textWidth = style.wrap ? style.wrapWidth : Math.max(...lines.map(measure));
        return { lines, lineHeight, width: textWidth + PADDING * 2, height: lines.length * lineHeight + PADDING * 2 };
    }

    /**
     * Pusat handle ubah lebar (tepi kanan kotak, tengah) untuk Text yang wrap.
     * @param {ScreenPoint} anchor
     * @param {TextLayout} layout
     * @returns {ScreenPoint}
     */
    function resizeHandle(anchor, layout) {
        return { x: anchor.x + layout.width, y: anchor.y + layout.height / 2 };
    }

    /**
     * Bagian Text yang kena sentuhan: handle ubah lebar (hanya Text wrap yang terseleksi), lalu badan kotak.
     * @param {ScreenPoint} anchor
     * @param {TextLayout} layout
     * @param {number} x
     * @param {number} y
     * @param {{ touchPadding: number, handleRadius: number, canResize: boolean }} options
     * @returns {TextHit | null}
     */
    function hitTest(anchor, layout, x, y, { touchPadding, handleRadius, canResize }) {
        if (canResize) {
            const handle = resizeHandle(anchor, layout);
            if (Math.hypot(x - handle.x, y - handle.y) <= handleRadius) return 'resize';
        }
        const isInside = x >= anchor.x - touchPadding && x <= anchor.x + layout.width + touchPadding
            && y >= anchor.y - touchPadding && y <= anchor.y + layout.height + touchPadding;
        return isInside ? 'body' : null;
    }

    /**
     * Lebar wrap baru saat handle tepi kanan digeser ke `pointerX`.
     * @param {number} anchorX
     * @param {number} pointerX
     * @returns {number}
     */
    function wrapWidthAt(anchorX, pointerX) {
        return Math.max(MIN_WRAP_WIDTH, Math.round(pointerX - anchorX - PADDING * 2));
    }

    const TextDrawings = Object.freeze({
        DEFAULTS,
        PADDING,
        MIN_WRAP_WIDTH,
        createText,
        normalizeText,
        fontOf,
        wrapLines,
        layoutText,
        resizeHandle,
        hitTest,
        wrapWidthAt,
    });

    // @ts-ignore -- `module` hanya ada di Node (dipakai unit test).
    if (typeof module === 'object' && module.exports) {
        // @ts-ignore
        module.exports = TextDrawings;
    } else {
        /** @type {Record<string, unknown>} */ (root).TextDrawings = TextDrawings;
    }
})(typeof globalThis !== 'undefined' ? globalThis : this);
