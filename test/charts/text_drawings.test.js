// @ts-check
/**
 * Unit test model & tata letak drawing Text (assets/charts/text_drawings.js).
 *
 * Jalankan dari folder cuan_app:
 *   node --test "test/charts/*.test.js"
 */
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const TextDrawings = require('../../assets/charts/text_drawings.js');

/** Ukuran palsu: setiap karakter selebar 10px. */
/** @param {string} text */
const measure = (text) => text.length * 10;
const point = { time: 1_700_000_000, price: 4500 };

describe('createText & normalizeText', () => {
  it('Text baru kosong (langsung diketik) dengan gaya default', () => {
    const text = TextDrawings.createText(point);
    assert.ok(text.id.startsWith('text_'));
    assert.deepEqual(text.point, point);
    assert.notEqual(text.point, point);
    assert.equal(text.text, '');
    assert.equal(text.textColor, TextDrawings.DEFAULTS.textColor);
    assert.equal(text.textOpacity, 1);
    assert.deepEqual([text.showBackground, text.showBorder, text.wrap, text.isLocked, text.hidden], [false, false, false, false, false]);
  });

  it('mempertahankan gaya yang sah dari Flutter', () => {
    const text = TextDrawings.normalizeText({
      id: 'text_x',
      point,
      text: 'Breakout',
      textColor: '#F23645',
      textOpacity: 0.7,
      textSize: 20,
      textBold: true,
      textItalic: true,
      showBackground: true,
      fillColor: '#FFEB3B',
      fillOpacity: 0.5,
      showBorder: true,
      borderColor: '#000000',
      wrap: true,
      wrapWidth: 120,
      isLocked: true,
    });
    assert.ok(text);
    assert.deepEqual(
      [text.id, text.text, text.textColor, text.textOpacity, text.textSize, text.textBold, text.textItalic, text.showBackground, text.fillColor, text.fillOpacity, text.showBorder, text.borderColor, text.wrap, text.wrapWidth, text.isLocked],
      ['text_x', 'Breakout', '#F23645', 0.7, 20, true, true, true, '#FFEB3B', 0.5, true, '#000000', true, 120, true],
    );
  });

  it('nilai tidak sah kembali ke default / dijepit', () => {
    const text = TextDrawings.normalizeText({ point, textSize: -4, textOpacity: -1, fillOpacity: 3, wrapWidth: 5, textColor: '' });
    assert.ok(text);
    assert.equal(text.textSize, TextDrawings.DEFAULTS.textSize);
    assert.equal(text.textOpacity, 0);
    assert.equal(text.fillOpacity, 1);
    assert.equal(text.wrapWidth, TextDrawings.MIN_WRAP_WIDTH);
    assert.equal(text.textColor, TextDrawings.DEFAULTS.textColor);
  });

  it('menolak data tanpa titik yang sah', () => {
    assert.equal(TextDrawings.normalizeText(null), null);
    assert.equal(TextDrawings.normalizeText({ text: 'x' }), null);
    assert.equal(TextDrawings.normalizeText({ point: { time: 1, price: NaN } }), null);
  });
});

describe('wrapLines', () => {
  it('mematah per kata sesuai lebar', () => {
    assert.deepEqual(TextDrawings.wrapLines('aa bb cc dd', 50, measure), ['aa bb', 'cc dd']);
  });

  it('baris baru dari user tetap, termasuk baris kosong', () => {
    assert.deepEqual(TextDrawings.wrapLines('aa\n\nbb', 50, measure), ['aa', '', 'bb']);
  });

  it('kata yang lebih panjang dari lebar dipatah per karakter', () => {
    assert.deepEqual(TextDrawings.wrapLines('abcdefg hi', 30, measure), ['abc', 'def', 'g', 'hi']);
  });
});

describe('layoutText', () => {
  const style = { ...TextDrawings.DEFAULTS, text: 'aaaa\nbb', textSize: 16 };
  const padding = TextDrawings.PADDING;

  it('tanpa wrap: lebar = baris terpanjang, tinggi = jumlah baris', () => {
    const layout = TextDrawings.layoutText(style, measure);
    assert.deepEqual(layout.lines, ['aaaa', 'bb']);
    assert.equal(layout.lineHeight, 20);
    assert.equal(layout.width, 40 + padding * 2);
    assert.equal(layout.height, 40 + padding * 2);
  });

  it('dengan wrap: lebar tetap = wrapWidth', () => {
    const layout = TextDrawings.layoutText({ ...style, text: 'aa bb cc', wrap: true, wrapWidth: 50 }, measure);
    assert.deepEqual(layout.lines, ['aa bb', 'cc']);
    assert.equal(layout.width, 50 + padding * 2);
  });
});

describe('hitTest & wrapWidthAt', () => {
  const layout = { lines: ['x'], lineHeight: 20, width: 100, height: 40 };
  const anchor = { x: 10, y: 10 };
  const options = { touchPadding: 8, handleRadius: 12, canResize: true };

  it('handle ubah lebar di tepi kanan diprioritaskan (hanya kalau boleh resize)', () => {
    assert.equal(TextDrawings.hitTest(anchor, layout, 112, 30, options), 'resize');
    assert.equal(TextDrawings.hitTest(anchor, layout, 112, 30, { ...options, canResize: false }), 'body');
  });

  it('di dalam kotak (plus ruang sentuh) = body, di luar = null', () => {
    assert.equal(TextDrawings.hitTest(anchor, layout, 4, 4, options), 'body');
    assert.equal(TextDrawings.hitTest(anchor, layout, 60, 70, options), null);
  });

  it('lebar wrap dari posisi jari, tidak di bawah minimum', () => {
    assert.equal(TextDrawings.wrapWidthAt(10, 10 + 150 + TextDrawings.PADDING * 2), 150);
    assert.equal(TextDrawings.wrapWidthAt(10, 12), TextDrawings.MIN_WRAP_WIDTH);
  });
});
