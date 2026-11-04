// @ts-check
/**
 * Model & geometri drawing multi-titik di chart: Path dan Elliott Wave (fungsi murni, tanpa DOM).
 *
 * Keempat tool adalah satu keluarga "wave": polyline berisi titik { time, price } berurutan.
 * - Path: jumlah titik bebas (minimal 2), diakhiri user, berpanah di titik terakhir.
 * - Elliott Wave: jumlah titik tetap (titik awal + satu titik per gelombang); setiap titik
 *   setelah titik awal diberi label gelombang derajat "Intermediate" TradingView: (1) .. (5), (A) .. (E).
 *
 * - Browser (tv_chart.html): `window.WaveDrawings`
 * - Node (unit test):        `require('./wave_drawings.js')`
 *
 * Unit test: `node --test "test/charts/*.test.js"` (dari folder cuan_app).
 */
(function (root) {
    'use strict';

    /** Nama jenis sama dengan `ChartDrawingTool.name` di Flutter. */
    /** @typedef {'path' | 'elliottImpulse' | 'elliottCorrection' | 'elliottTriangle'} WaveKind */
    /** @typedef {'solid' | 'dashed' | 'dotted'} LineStyle */
    /** @typedef {{ time: number, price: number }} WavePoint */
    /** @typedef {{ x: number, y: number }} ScreenPoint */
    /**
     * @typedef {{
     *   id: string,
     *   kind: WaveKind,
     *   points: WavePoint[],
     *   color: string,
     *   width: number,
     *   style: LineStyle,
     *   opacity: number,
     *   isLocked: boolean,
     *   hidden: boolean,
     * }} Wave
     */
    /**
     * @typedef {{
     *   title: string,
     *   labels: readonly string[],
     *   openEnded: boolean,
     *   endArrow: boolean,
     *   color: string,
     * }} WaveSpec
     * `labels[i]` = label titik ke-(i + 1); titik awal tanpa label. Jenis yang `openEnded`
     * (Path) tidak berlabel dan jumlah titiknya ditentukan user.
     */
    /** @typedef {{ part: 'anchor', pointIndex: number } | { part: 'body' }} WaveHit */

    /** @type {Readonly<Record<WaveKind, Readonly<WaveSpec>>>} */
    const KINDS = Object.freeze({
        path: Object.freeze({
            title: 'Path',
            labels: Object.freeze([]),
            openEnded: true,
            endArrow: true,
            color: '#2962FF',
        }),
        elliottImpulse: Object.freeze({
            title: 'Elliott Impulse Wave',
            labels: Object.freeze(['(1)', '(2)', '(3)', '(4)', '(5)']),
            openEnded: false,
            endArrow: false,
            color: '#FBC02D',
        }),
        elliottCorrection: Object.freeze({
            title: 'Elliott Correction Wave',
            labels: Object.freeze(['(A)', '(B)', '(C)']),
            openEnded: false,
            endArrow: false,
            color: '#FF9800',
        }),
        elliottTriangle: Object.freeze({
            title: 'Elliott Triangle Wave',
            labels: Object.freeze(['(A)', '(B)', '(C)', '(D)', '(E)']),
            openEnded: false,
            endArrow: false,
            color: '#FF9800',
        }),
    });

    /** Path minimal satu segmen. */
    const MIN_PATH_POINTS = 2;
    const LINE_STYLES = Object.freeze(['solid', 'dashed', 'dotted']);
    const DEFAULT_WIDTH = 2;
    /** Setengah sudut mata panah Path (30° ke tiap sisi). */
    const ARROW_HALF_ANGLE = Math.PI / 6;

    /**
     * @param {unknown} kind
     * @returns {kind is WaveKind}
     */
    function isWaveKind(kind) {
        return typeof kind === 'string' && Object.prototype.hasOwnProperty.call(KINDS, kind);
    }

    /**
     * Jumlah titik wajib; null untuk jenis yang jumlah titiknya bebas (Path).
     * @param {WaveKind} kind
     * @returns {number | null}
     */
    function requiredPoints(kind) {
        const spec = KINDS[kind];
        return spec.openEnded ? null : spec.labels.length + 1;
    }

    /**
     * Jumlah titik paling sedikit supaya wave sah.
     * @param {WaveKind} kind
     * @returns {number}
     */
    function minPoints(kind) {
        return requiredPoints(kind) ?? MIN_PATH_POINTS;
    }

    /**
     * True kalau semua titik sudah ditaruh dan wave otomatis selesai (hanya Elliott Wave).
     * @param {WaveKind} kind
     * @param {number} count
     * @returns {boolean}
     */
    function isComplete(kind, count) {
        const required = requiredPoints(kind);
        return required !== null && count >= required;
    }

    /**
     * Label gelombang titik ke-`index`; null untuk titik awal / jenis tanpa label.
     * @param {WaveKind} kind
     * @param {number} index
     * @returns {string | null}
     */
    function labelAt(kind, index) {
        return index > 0 ? KINDS[kind].labels[index - 1] ?? null : null;
    }

    /**
     * Sisi label: di atas puncak, di bawah lembah. Arah ditentukan segmen yang masuk ke titik
     * (naik = puncak); titik awal mengikuti kebalikan arah segmen keluarnya.
     * @param {readonly WavePoint[]} points
     * @param {number} index
     * @returns {'above' | 'below'}
     */
    function labelSide(points, index) {
        const point = points[index];
        const prev = points[index - 1];
        if (prev) return point.price >= prev.price ? 'above' : 'below';
        const next = points[index + 1];
        return next && next.price > point.price ? 'below' : 'above';
    }

    /** @param {unknown} value */
    function isFiniteNumber(value) {
        return typeof value === 'number' && Number.isFinite(value);
    }

    /** @returns {string} */
    function newWaveId() {
        return 'wave_' + Date.now() + '_' + Math.random().toString(36).slice(2, 7);
    }

    /**
     * Wave baru dengan gaya default jenisnya.
     * @param {WaveKind} kind
     * @param {readonly WavePoint[]} points
     * @returns {Wave}
     */
    function createWave(kind, points) {
        return {
            id: newWaveId(),
            kind,
            points: points.map((p) => ({ time: p.time, price: p.price })),
            color: KINDS[kind].color,
            width: DEFAULT_WIDTH,
            style: 'solid',
            opacity: 1,
            isLocked: false,
            hidden: false,
        };
    }

    /**
     * Wave dari data luar (Flutter / clone); null kalau jenis atau titiknya tidak sah.
     * @param {unknown} item
     * @returns {Wave | null}
     */
    function normalizeWave(item) {
        if (typeof item !== 'object' || item === null) return null;
        const raw = /** @type {Record<string, unknown>} */ (item);
        const kind = raw.kind;
        if (!isWaveKind(kind) || !Array.isArray(raw.points)) return null;

        /** @type {WavePoint[]} */
        const points = [];
        for (const p of raw.points) {
            if (typeof p !== 'object' || p === null) return null;
            const { time, price } = /** @type {Record<string, unknown>} */ (p);
            if (!isFiniteNumber(time) || !isFiniteNumber(price)) return null;
            points.push({ time: /** @type {number} */ (time), price: /** @type {number} */ (price) });
        }
        const required = requiredPoints(kind);
        if (required !== null ? points.length !== required : points.length < MIN_PATH_POINTS) return null;

        const style = /** @type {LineStyle} */ (LINE_STYLES.includes(/** @type {string} */ (raw.style)) ? raw.style : 'solid');
        return {
            id: typeof raw.id === 'string' && raw.id ? raw.id : newWaveId(),
            kind,
            points,
            color: typeof raw.color === 'string' && raw.color ? raw.color : KINDS[kind].color,
            width: isFiniteNumber(raw.width) && /** @type {number} */ (raw.width) > 0 ? /** @type {number} */ (raw.width) : DEFAULT_WIDTH,
            style,
            opacity: isFiniteNumber(raw.opacity) ? Math.min(1, Math.max(0, /** @type {number} */ (raw.opacity))) : 1,
            isLocked: raw.isLocked === true,
            hidden: raw.hidden === true,
        };
    }

    /**
     * @param {number} px
     * @param {number} py
     * @param {ScreenPoint} a
     * @param {ScreenPoint} b
     * @returns {number}
     */
    function distToSegment(px, py, a, b) {
        const dx = b.x - a.x;
        const dy = b.y - a.y;
        const lenSq = dx * dx + dy * dy;
        const t = lenSq === 0 ? 0 : Math.max(0, Math.min(1, ((px - a.x) * dx + (py - a.y) * dy) / lenSq));
        return Math.hypot(px - (a.x + t * dx), py - (a.y + t * dy));
    }

    /**
     * Bagian wave yang kena sentuhan di (x, y): titik terdekat dalam `anchorRadius`, lalu segmen
     * dalam `bodyRadius`. Titik `null` (di luar skala chart) dilewati beserta segmennya.
     * @param {ReadonlyArray<ScreenPoint | null>} screenPoints
     * @param {number} x
     * @param {number} y
     * @param {number} anchorRadius
     * @param {number} bodyRadius
     * @returns {WaveHit | null}
     */
    function hitTest(screenPoints, x, y, anchorRadius, bodyRadius) {
        let nearest = -1;
        let nearestDist = anchorRadius;
        screenPoints.forEach((p, i) => {
            if (!p) return;
            const dist = Math.hypot(x - p.x, y - p.y);
            if (dist <= nearestDist) {
                nearest = i;
                nearestDist = dist;
            }
        });
        if (nearest >= 0) return { part: 'anchor', pointIndex: nearest };

        for (let i = 1; i < screenPoints.length; i++) {
            const a = screenPoints[i - 1];
            const b = screenPoints[i];
            if (a && b && distToSegment(x, y, a, b) <= bodyRadius) return { part: 'body' };
        }
        return null;
    }

    /**
     * Dua ujung sayap mata panah di `to` untuk segmen `from` -> `to`; null kalau segmennya nol.
     * @param {ScreenPoint} from
     * @param {ScreenPoint} to
     * @param {number} size panjang sayap (px)
     * @returns {[ScreenPoint, ScreenPoint] | null}
     */
    function arrowHead(from, to, size) {
        if (from.x === to.x && from.y === to.y) return null;
        const angle = Math.atan2(to.y - from.y, to.x - from.x);
        /** @param {number} a */
        const wing = (a) => ({ x: to.x - size * Math.cos(a), y: to.y - size * Math.sin(a) });
        return [wing(angle - ARROW_HALF_ANGLE), wing(angle + ARROW_HALF_ANGLE)];
    }

    const WaveDrawings = Object.freeze({
        KINDS,
        isWaveKind,
        requiredPoints,
        minPoints,
        isComplete,
        labelAt,
        labelSide,
        createWave,
        normalizeWave,
        hitTest,
        arrowHead,
    });

    // @ts-ignore -- `module` hanya ada di Node (dipakai unit test).
    if (typeof module === 'object' && module.exports) {
        // @ts-ignore
        module.exports = WaveDrawings;
    } else {
        /** @type {Record<string, unknown>} */ (root).WaveDrawings = WaveDrawings;
    }
})(typeof globalThis !== 'undefined' ? globalThis : this);
