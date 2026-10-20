"""Separate one owner composition into the game's scenery layers.

Frame space is 1280x720. A view config gives, in SOURCE frame px (the composition resized
to 1280x720, before alignment):
  floors      [yu, yl]  feet on the upper and lower floor
  cuts        [far, mid] depth thresholds (model disparity: bigger is nearer)
  remove      rects/polys of what the game draws itself (buildings, actors, ladders, boats)
  orbs        [cx, cy, r] painted sun/moon (the game draws its own)
  rail        rects of the low things standing on the upper floor (fences, walls): factor 1
  spans       {layer: [x0, x1]} the clean horizontal span that tiles for far/mid/strip
Outputs (aligned to the game floors y517 / y618.5), RGBA uint8 1280x720 each:
  sky, far, mid, near, strip
"""
import json
import numpy as np
import cv2
from PIL import Image, ImageDraw

W, H = 1280, 720
GROUND = 517
UNDER = 618.5
SKY_ID = 2


def load_rgb(path):
    return np.asarray(Image.open(path).convert('RGB').resize((W, H), Image.LANCZOS))


def shape_mask(shapes, dilate=0):
    m = Image.new('L', (W, H), 0)
    d = ImageDraw.Draw(m)
    for s in shapes or []:
        if isinstance(s, dict) and 'poly' in s:
            d.polygon([tuple(p) for p in s['poly']], fill=255)
        else:
            x0, y0, x1, y1 = s
            d.rectangle([x0, y0, x1, y1], fill=255)
    a = np.asarray(m) > 0
    if dilate:
        a = cv2.dilate(a.astype(np.uint8), np.ones((2 * dilate + 1,) * 2, np.uint8)) > 0
    return a


def row_map(yu, yl):
    """Source row for each target row (float); <0 or >=H means outside the painting."""
    t = np.arange(H, dtype=np.float32)
    s = np.empty_like(t)
    top = t < GROUND
    mid = (t >= GROUND) & (t < UNDER)
    low = t >= UNDER
    s[top] = t[top] - (GROUND - yu)
    s[mid] = yu + (t[mid] - GROUND) * (yl - yu) / (UNDER - GROUND)
    s[low] = yl + (t[low] - UNDER)
    return s


def remap(a, rows, nearest=False):
    mx = np.tile(np.arange(W, dtype=np.float32), (H, 1))
    my = np.tile(rows[:, None], (1, W)).astype(np.float32)
    interp = cv2.INTER_NEAREST if nearest else cv2.INTER_LINEAR
    src = a.astype(np.uint8) if a.dtype == bool else a
    out = cv2.remap(src, mx, my, interp, borderMode=cv2.BORDER_CONSTANT, borderValue=0)
    return out.astype(bool) if a.dtype == bool else out


def clean(m, open_px=1, close_px=2, min_area=24):
    m = m.astype(np.uint8)
    if close_px:
        m = cv2.morphologyEx(m, cv2.MORPH_CLOSE, np.ones((2 * close_px + 1,) * 2, np.uint8))
    if open_px:
        m = cv2.morphologyEx(m, cv2.MORPH_OPEN, np.ones((2 * open_px + 1,) * 2, np.uint8))
    n, lab, st, _ = cv2.connectedComponentsWithStats(m, 8)
    keep = np.zeros(n, bool)
    keep[1:] = st[1:, cv2.CC_STAT_AREA] >= min_area
    return keep[lab]


def superpixel_depth(img, depth, region, n=7000):
    """Median depth per SLIC superpixel: layer edges follow the painting, not the model."""
    from skimage.segmentation import slic
    seg = slic(img, n_segments=n, compactness=12, start_label=0, mask=region)
    out = depth.copy()
    ids = seg[region]
    med = np.zeros(seg.max() + 1, np.float32)
    for i in np.unique(ids):
        med[i] = np.median(depth[seg == i])
    out[region] = med[seg[region]]
    return out


def fill_sky(rgb, known, extra_top, flat=False):
    """Sky behind everything: each row's robust colour where the row has sky, carried down
    past the last such row and reflected up past the first, with the gradient continued."""
    out = rgb.astype(np.float32).copy()
    rowc = np.full((H, 3), np.nan, np.float32)
    count = known.sum(axis=1).astype(np.float32)
    # a row speaks for the sky only where a fair share of it is sky: near the horizon the few
    # sky pixels left are cloud edges and haze, and their median is too light
    enough = max(8.0, 0.08 * W)
    for y in range(H):
        k = known[y]
        if count[y] >= enough:
            rowc[y] = np.median(out[y, k], axis=0)
    good = np.flatnonzero(~np.isnan(rowc[:, 0]))
    if len(good) >= 2:
        last = good[-1]
        tail = good[good >= last - 60]
        for c in range(3):  # below the last good row the sky goes on with its own trend
            k_, b_ = np.polyfit(tail.astype(np.float32), rowc[tail, c], 1)
            rows = np.minimum(np.arange(last + 1, H), last + 48)  # a short trend, then held
            rowc[last + 1:, c] = np.clip(k_ * rows + b_, 0, 255)
        count = np.where(~np.isnan(rowc[:, 0]), np.maximum(count, enough), 0.0)
    ok = np.flatnonzero(~np.isnan(rowc[:, 0]))
    if len(ok) == 0:
        raise ValueError('no sky')
    # rows with few sky pixels do not get to set the colour of the whole row
    wgt = np.where(np.isnan(rowc[:, 0]), 0.0, count)
    ker = np.ones(41, np.float32)
    den = np.convolve(wgt, ker, 'same')
    for c in range(3):
        v = np.nan_to_num(rowc[:, c])
        num = np.convolve(v * wgt, ker, 'same')
        sm = np.where(den > 0, num / np.maximum(den, 1e-6), np.nan)
        good = np.flatnonzero(~np.isnan(sm))
        rowc[:, c] = np.interp(np.arange(H), good, sm[good])
    ok = np.flatnonzero(count >= 8)
    first = ok[0]
    for y in range(first - 1, -1, -1):
        r = min(H - 1, 2 * first - y)
        rowc[y] = rowc[r] + 2.0 * (rowc[first] - rowc[r])
    fill = np.repeat(rowc[:, None, :], W, axis=1)
    if not flat and len(ok):
        # above the painting: its first sky rows, reflected, carry the texture up (an overcast
        # sky keeps its clouds) on the continued gradient
        first = int(ok[0])
        for y in range(first - 1, -1, -1):
            r = min(H - 1, 2 * first - y)
            tex = np.where(known[r][:, None], out[r] - rowc[r], 0.0)
            fill[y] = rowc[y] + tex
            known[y] = known[r]
    out = fill if flat else np.where(known[..., None] & (np.arange(H)[:, None] >= ok[0])[..., None], out, fill)
    return np.clip(out, 0, 255).astype(np.uint8)


def differs(a, b, thr):
    return np.abs(a.astype(np.int16) - b.astype(np.int16)).max(axis=2) > thr


def seamless(rgb, alpha, x0, x1, inpaint, band=96, behind=None):
    """Make columns [x0, x1) tile: roll the seam to the middle and let LaMa join it."""
    w = x1 - x0
    tile = rgb[:, x0:x1].copy()
    a = alpha[:, x0:x1].copy() if alpha is not None else None
    sh = w // 2
    t = np.roll(tile, sh, axis=1)
    hole = np.zeros((H, w), bool)
    hole[:, max(0, sh - band // 2):min(w, sh + band // 2)] = True
    if a is not None:
        ar = np.roll(a, sh, axis=1)
        if behind is not None:
            bt = np.roll(behind[:, x0:x1], sh, axis=1)
            comp = np.where(ar[..., None], t, bt)
        else:
            comp = t
        rows = np.flatnonzero(ar.any(axis=1))
        hole[:rows.min() if len(rows) else 0] = False
        filled = inpaint(comp, hole)
        if behind is not None:
            new_a = ar.copy()
            new_a[hole] = differs(filled, bt, 30)[hole]
            new_a = np.where(hole, clean(new_a, 1, 2, 40), ar)
        else:
            new_a = ar
        t = np.where(hole[..., None], filled, t)
        return np.roll(t, -sh, axis=1), np.roll(new_a, -sh, axis=1)
    filled = inpaint(t, hole)
    return np.roll(filled, -sh, axis=1), None


def rgba(rgb, a):
    return np.dstack([np.where(a[..., None], rgb, 0).astype(np.uint8), (a.astype(np.uint8) * 255)])


def save(path, arr):
    Image.fromarray(arr).save(path)


def load_cfg(path):
    with open(path) as f:
        return json.load(f)


def dilate_mask(m, px):
    return cv2.dilate(m.astype(np.uint8), np.ones((2 * px + 1,) * 2, np.uint8)) > 0


def silhouette(own, gap=48, base=None, lowest=H, smooth=7, bridge=None):
    """Per column, the top row of the layer (a solid plane below it): small gaps bridged by
    interpolation, no top where the gap is wide; `base` rows down are solid everywhere."""
    h, w = own.shape
    o = clean(own, 1, 1, 30)
    # a column's top is the first row of a vertical run of 4 layer pixels
    run = o & np.roll(o, -1, 0) & np.roll(o, -2, 0) & np.roll(o, -3, 0)
    has = run.any(axis=0)
    top = np.where(has, np.argmax(run, axis=0), h).astype(np.float32)
    cols = np.flatnonzero(has)
    if len(cols):
        for a, b in zip(cols[:-1], cols[1:]):
            if 1 < b - a <= gap:
                top[a + 1:b] = np.interp(np.arange(a + 1, b), [a, b], [top[a], top[b]])
    if base is not None:
        top = np.minimum(top, base)
    from scipy.ndimage import grey_opening
    top = grey_opening(top, size=smooth)  # spikes narrower than `smooth` go
    if bridge is not None:  # across a loop's joint the outline runs straight from edge to edge
        a, b = bridge
        a, b = max(1, a), min(w - 1, b)
        top[a:b] = np.interp(np.arange(a, b), [a - 1, b], [top[a - 1], top[b]])
    yy = np.arange(h)[:, None]
    return (yy >= top[None, :]) & (yy < lowest)


def shift_fill(rgb, hole, fallback=None, banned=None):
    """Fill `hole` by copying the painting's own patches (OpenCV shift-map, in CIELab).

    `banned` pixels are not copied from (a unique landmark must not be cloned); they are
    put back afterwards. What shift-map leaves empty goes to `fallback` (LaMa)."""
    if not hole.any():
        return rgb
    lab = cv2.cvtColor(rgb, cv2.COLOR_RGB2LAB)
    dst = np.zeros_like(lab)
    unknown = hole | (banned if banned is not None else False)
    cv2.xphoto.inpaint(lab, (~unknown).astype(np.uint8), dst, cv2.xphoto.INPAINT_SHIFTMAP)
    left = unknown & (dst == 0).all(axis=2)
    out = cv2.cvtColor(dst, cv2.COLOR_LAB2RGB)
    out = np.where(hole[..., None], out, rgb)
    if left.any():
        if fallback is not None:
            out = np.where(left[..., None], fallback(out, left), out)
        else:
            out = cv2.inpaint(out, left.astype(np.uint8), 3, cv2.INPAINT_TELEA)
    return np.where(hole[..., None], out, rgb)


def column_tops(own):
    o = clean(own, 1, 1, 30)
    run = o & np.roll(o, -1, 0) & np.roll(o, -2, 0) & np.roll(o, -3, 0)
    has = run.any(axis=0)
    return np.where(has, np.argmax(run, axis=0), H).astype(np.float32)


def best_span(own, img, lo, hi, min_w, step=4, look=12, must=()):
    """The loop [x0, x1) within [lo, hi) whose two edges match best: the layer's top at
    the same height and the same colours along the edge columns. Every (a, b) in `must` (a
    landmark of the kingdom) lies inside the loop."""
    tops = column_tops(own)
    f = img.astype(np.float32)
    best, pick = None, (lo, hi)
    for x0 in range(lo, hi - min_w + 1, step):
        for x1 in range(x0 + min_w, hi + 1, step):
            if any(x0 > ma - look or x1 < mb + look for ma, mb in must):
                continue
            a = f[:, x0:x0 + look]
            b = f[:, x1 - look:x1]
            ma = own[:, x0:x0 + look].any(axis=1) | own[:, x1 - look:x1].any(axis=1)
            col = np.abs(a.mean(axis=1) - b.mean(axis=1)).mean(axis=1)
            colour = col[ma].mean() if ma.any() else 0.0
            # an empty or low column needs no join at all
            content = (H - min(tops[x0], H)) + (H - min(tops[x1 - 1], H))
            cost = abs(tops[x0] - tops[x1 - 1]) * 2.0 + colour + 0.25 * content - 0.002 * (x1 - x0)
            if best is None or cost < best:
                best, pick = cost, (x0, x1)
    return list(pick)


def edge_caps(own, pl, pr, seed=7):
    """Where the near plane may grow into its side pads: a rounded, bumpy cap on every
    vertical run that the frame edge cuts, so an outpainted canopy closes itself."""
    h, w = own.shape
    out = np.zeros_like(own)
    rng = np.random.RandomState(seed)
    bumps = np.convolve(rng.rand(h + 32), np.ones(16) / 16, 'same')[16:16 + h]
    for col, pad, step in ((pl, pl, -1), (w - pr - 1, pr, 1)):
        if pad <= 0:
            continue
        c = own[:, max(0, col - 3):col + 4].any(axis=1) if step < 0 else own[:, col - 3:col + 1].any(axis=1)
        ys = np.flatnonzero(c)
        if len(ys) == 0:
            continue
        runs = np.split(ys, np.flatnonzero(np.diff(ys) > 2) + 1)
        for run in runs:
            a, b = run[0], run[-1]
            yc, hh = (a + b) / 2.0, max(1.0, (b - a) / 2.0)
            for d in range(1, pad + 1):
                x = col + step * d
                y = np.arange(h)
                reach = pad * (0.7 + 0.3 * bumps[y])
                ok = (np.abs(y - yc) / hh) ** 2 + (d / reach) ** 2 < 1.0
                out[:, x] |= ok
    return out


def guided_fill(rgb, hole, guide, source, block=8, step=4, border=2.0):
    """Texture by numbers: LaMa's `guide` says what goes in the hole; each `block` x `block`
    cell of it is replaced by the cell of the painting (`source` pixels only) whose blurred
    look is closest and whose edges meet the cells already placed. The fill keeps the
    painting's own pixels instead of LaMa's soft ones."""
    if not hole.any():
        return rgb
    h, w = hole.shape
    out = rgb.astype(np.float32).copy()
    out[hole] = guide[hole]
    blur = lambda a: cv2.GaussianBlur(a.astype(np.float32), (0, 0), block / 3.0)
    feat_img = blur(rgb)
    # candidates: whole cells of known painting
    ok = source & ~hole
    ii = np.pad(np.cumsum(np.cumsum((~ok).astype(np.int32), 0), 1), ((1, 0), (1, 0)))
    ys, xs = np.mgrid[0:h - block + 1:step, 0:w - block + 1:step]
    ys, xs = ys.ravel(), xs.ravel()
    bad = ii[ys + block, xs + block] - ii[ys, xs + block] - ii[ys + block, xs] + ii[ys, xs]
    ys, xs = ys[bad == 0], xs[bad == 0]
    if len(ys) == 0:
        return out.astype(np.uint8)
    q = block // 2
    def feats(img, yy, xx):
        cells = np.stack([img[yy + j * q + q // 2, xx + i * q + q // 2] for j in range(2) for i in range(2)], 1)
        return cells.reshape(len(yy), -1)
    cand_f = feats(feat_img, ys, xs)
    raw = rgb.astype(np.float32)
    cand_left = np.stack([raw[ys + j, xs] for j in range(block)], 1).reshape(len(ys), -1)
    cand_top = np.stack([raw[ys, xs + i] for i in range(block)], 1).reshape(len(ys), -1)
    guide_blur = blur(np.where(hole[..., None], guide, rgb))
    done = ~hole
    hy, hx = np.nonzero(hole)
    for by in range(hy.min() // block * block, hy.max() + 1, block):
        for bx in range(hx.min() // block * block, hx.max() + 1, block):
            y1, x1 = min(h, by + block), min(w, bx + block)
            cell = hole[by:y1, bx:x1]
            if not cell.any() or y1 - by < block or x1 - bx < block:
                continue
            f = feats(guide_blur, np.array([by]), np.array([bx]))
            cost = ((cand_f - f) ** 2).mean(axis=1)
            if bx > 0 and done[by:y1, bx - 1].all():
                left = out[by:y1, bx - 1].reshape(-1)
                cost += border * ((cand_left - left) ** 2).mean(axis=1)
            if by > 0 and done[by - 1, bx:x1].all():
                top = out[by - 1, bx:x1].reshape(-1)
                cost += border * ((cand_top - top) ** 2).mean(axis=1)
            k = int(np.argmin(cost))
            patch = raw[ys[k]:ys[k] + block, xs[k]:xs[k] + block]
            out[by:y1, bx:x1][cell] = patch[cell]
            done[by:y1, bx:x1] = True
    return np.clip(out, 0, 255).astype(np.uint8)


def clone_strips(img, depth, cls, clones):
    """Cover a building with the painting's own scenery beside it: each clone is
    {"dst": [x0, y0, x1, y1], "src_x": [a, b]}, the strip beside the destination (b <= x0 or
    a >= x1). Its columns repeat across the destination, every other copy mirrored, starting
    from the side that touches the strip, so each join meets the column it came from."""
    for c in clones:
        x0, y0, x1, y1 = c["dst"]
        a, b = c["src_x"]
        w = b - a
        cols = np.empty(x1 - x0, np.int64)
        for x in range(x0, x1):
            t = (x - b) % (2 * w) if b <= x0 else (a - 1 - x) % (2 * w)
            mirrored = t < w
            if b <= x0:
                cols[x - x0] = b - 1 - t if mirrored else a + (t - w)
            else:
                cols[x - x0] = a + t if mirrored else b - 1 - (t - w)
        for arr in (img, depth, cls):
            arr[y0:y1, x0:x1] = arr[y0:y1][:, cols]
    return img, depth, cls
