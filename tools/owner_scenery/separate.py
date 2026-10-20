"""Separate one owner composition into the game's planes (ADR 0085).

python separate.py tools/owner_scenery/views.json VIEW_ID ZIPDIR SEGDIR OUTDIR MODEL

ZIPDIR is the extracted Drive package (EMPIRE-Cenarios-24-2026-10-16/), SEGDIR what
analyze.py wrote for it, MODEL the LaMa ONNX file. OUTDIR/VIEW_ID is what
tools/export_owner_scenery.py --camadas reads.

Outputs full-resolution RGBA (1280x720 frame, floors moved to y517 / y618.5):
  sky.png      opaque gradient behind everything (painted clouds and orbs taken out)
  clouds.png   the painted clouds, none touching the frame edges (tiles at 1280)
  far.png      the loop tile [x0, x1) of the far plane, opaque below its silhouette
  mid.png      the loop tile of the middle plane
  near.png     the near plane, outpainted `near_pad` px to each side (shown once per period)
  strip.png    what stands on the walking line and everything below it (tiles at 1280)
  meta.json    loop spans, pads and floors
"""
import os
import sys
import json
import numpy as np
import cv2
sys.path.insert(0, os.path.dirname(__file__))
import layers as L
from lama import inpaint_tiled


def main():
    cfg_path, vid, zipdir, segdir, outdir, model = sys.argv[1:7]
    allcfg = L.load_cfg(cfg_path)
    allcfg = allcfg.get('views', allcfg)  # tools/owner_scenery/views.json, or a bare map of views
    cfg = dict(allcfg[vid])
    base_id = None
    while 'inherit' in cfg:  # a variant keeps its base's boxes, floors and loops
        base_id = cfg.pop('inherit')
        base = dict(allcfg[base_id])
        base.update(cfg)
        cfg = base
    os.makedirs(outdir, exist_ok=True)
    name = os.path.splitext(os.path.basename(cfg['src']))[0]
    img = L.load_rgb(os.path.join(zipdir, cfg['src']))
    depth = np.load(os.path.join(segdir, name + '_depth.npy'))
    cls = np.load(os.path.join(segdir, name + '_cls.npy'))
    img, depth, cls = L.clone_strips(img.copy(), depth, cls, cfg.get('clone', []))
    lama = lambda rgb, m: inpaint_tiled(rgb, m, model)
    fill = lambda rgb, m, ban=None: L.shift_fill(rgb, m, lama, ban)
    yu, yl = cfg['floors']
    if 'cuts' in cfg:
        c_far, c_mid = cfg['cuts']
    else:  # relative to the sky and to the walking line, so one rule fits every painting
        d_sky = float(np.median(depth[(cls == L.SKY_ID) & (np.arange(L.H)[:, None] < yu)]))
        d_path = float(np.median(depth[max(0, yu - 4):yu + 2]))
        rf, rm = cfg.get('cuts_rel', [0.22, 0.67])
        c_far, c_mid = d_sky + rf * (d_path - d_sky), d_sky + rm * (d_path - d_sky)
        cfg.setdefault('rail_min', c_mid)
        print(vid, 'depth sky %.1f path %.1f cuts %.1f %.1f' % (d_sky, d_path, c_far, c_mid))
    yy = np.arange(L.H)[:, None] * np.ones((1, L.W))
    above = yy < yu

    remove = np.zeros((L.H, L.W), bool)
    for item in cfg.get('remove', []):
        box = L.shape_mask([item[:4] if isinstance(item, list) else item])
        if isinstance(item, list) and len(item) > 4:
            gate = item[4]
            if isinstance(gate, float) and gate < 1.5:  # a fraction of the way to the path
                gate = c_far + gate * (c_mid - c_far)
            box &= depth >= gate
        remove |= box
    remove = L.dilate_mask(remove, 3)
    orbs = np.zeros((L.H, L.W), np.uint8)
    for cx, cy, r in cfg.get('orbs', []):
        cv2.circle(orbs, (int(cx), int(cy)), int(r), 1, -1)
    orbs = orbs > 0
    if cfg.get('find_orbs'):
        lum = img.astype(np.float32).mean(axis=2)
        bright = (lum > cfg.get('orb_lum', 205)) & above & (depth < c_far)
        n, lab, st, cen = cv2.connectedComponentsWithStats(bright.astype(np.uint8), 8)
        for i in range(1, n):
            x, y, w, h, area = st[i]
            if not (18 <= w <= 220 and 10 <= h <= 220 and 0.6 <= w / h <= 2.6):
                continue
            if area / float(w * h) < 0.5:
                continue
            r = max(w, h) / 2.0 * cfg.get('orb_halo', 1.6)
            cx, cy = x + w / 2.0, y + (h / 2.0 if w / h < 1.4 else h)
            m = np.zeros((L.H, L.W), np.uint8)
            cv2.circle(m, (int(cx), int(cy)), int(r), 1, -1)
            orbs |= m > 0
            print(vid, 'orb', int(cx), int(cy), int(r), 'area', int(area))
    sky = (cls == L.SKY_ID) & (depth < cfg.get('sky_max', c_far * 0.6)) & above
    sky = L.clean(sky, 1, 1, 64) | (orbs & above)
    sky |= L.shape_mask(cfg.get('force_sky')) & above
    sky &= ~L.shape_mask(cfg.get('not_sky'))
    region = above & ~sky
    sd = L.superpixel_depth(img, depth, region, cfg.get('superpixels', 7000))
    far = region & (sd < c_far)
    mid = region & (sd >= c_far) & (sd < c_mid)
    near = region & (sd >= c_mid)
    for key, m in (('force_far', far), ('force_mid', mid), ('force_near', near)):
        f = L.shape_mask(cfg.get(key)) & region
        far &= ~f
        mid &= ~f
        near &= ~f
        m |= f
    mark = L.shape_mask(cfg.get('landmark'))
    mark_own = mark & ~(L.clean(cls == L.SKY_ID, 0, 0, 1) & (depth < c_far))
    remove |= L.dilate_mask(mark_own, 2)
    rail_box = L.shape_mask(cfg.get('rail')) & ~L.shape_mask(cfg.get('rail_exclude'))
    rail = rail_box & region & ((depth >= cfg.get('rail_min', c_mid)) | near) & ~remove
    for m in (far, mid, near):
        m &= ~rail & ~remove

    rows = L.row_map(yu, yl)
    A = lambda a: L.remap(a, rows, a.dtype == bool)
    img_a = A(img)
    sky_a, far_a, mid_a, near_a, rail_a, rem_a, orb_a = (
        A(m) for m in (sky, far, mid, near, rail, remove, orbs))
    unique_a = A(L.shape_mask(cfg.get('unique')))
    inside = (rows >= 0) & (rows <= L.H - 1)
    outside = ~np.tile(inside[:, None], (1, L.W))
    up = yy < L.GROUND
    sky_a |= outside & up & ~L.dilate_mask(near_a | mid_a, 6)

    # ── sky and clouds ──
    known = sky_a & ~orb_a & ~outside & ~L.dilate_mask(~sky_a & up, 2)
    base = L.fill_sky(img_a, known.copy(), 0, flat=True)
    cloud = known & L.differs(img_a, base, cfg.get('cloud_thr', 26))
    cloud = L.clean(L.dilate_mask(cloud, 1) & known, 1, 2, cfg.get('cloud_min', 80))
    first_in = int(np.flatnonzero(inside)[0])
    n, lab, st, _ = cv2.connectedComponentsWithStats(cloud.astype(np.uint8), 8)
    for i in range(1, n):
        x, y, w, _ = st[i, :4]
        if x <= 1 or x + w >= L.W - 1 or y <= first_in + 1:
            cloud[lab == i] = False
    if not cfg.get('clouds', True):
        cloud[:] = False
    cloud &= ~A(L.shape_mask(cfg.get('no_clouds')))
    clouds_rgb = img_a.copy()
    known_sky = known & ~L.dilate_mask(cloud, 2)
    S = L.fill_sky(img_a, known_sky.copy(), 0)
    farcols = far_a.any(axis=0)
    horizon = int(np.percentile(np.argmax(far_a, axis=0)[farcols], 90)) if farcols.any() else L.GROUND
    # Small gaps in the sky (a chimney, a mast) get LaMa, so a cloud runs on behind them; big
    # ones (behind a volcano, a castle, the near trees) keep the painting's own row gradient:
    # LaMa fills those lighter than the sky around them, and they show as a block.
    hole = ~known_sky & (yy < horizon + 24) & ~outside
    n, lab, st, _ = cv2.connectedComponentsWithStats(hole.astype(np.uint8), 8)
    small = np.zeros(n, bool)
    small[1:] = st[1:, cv2.CC_STAT_AREA] < cfg.get('sky_lama_max', 2500)
    hole = small[lab]
    if hole.any():
        S = np.where(hole[..., None], lama(S, hole), S)
    L.save(os.path.join(outdir, 'sky.png'), L.rgba(S, np.ones((L.H, L.W), bool)))
    L.save(os.path.join(outdir, 'clouds.png'), L.rgba(clouds_rgb, cloud))
    if os.environ.get('SKY_ONLY'):
        return

    thr = cfg.get('alpha_thr', 30)
    band = cfg.get('band', 96)
    spans = dict(cfg.get('spans', {}))
    for key, own in (('far', far_a), ('mid', mid_a)):
        if key in cfg.get('auto_spans', {}):
            lo, hi, mw = cfg['auto_spans'][key]
            must = [(b[0], b[2]) for b in cfg.get('unique', []) if key == 'far' and lo <= b[0] and b[2] <= hi]
            spans[key] = L.best_span(own & up, img_a, lo, hi, mw, must=must)
    base_meta = os.path.join(os.path.dirname(outdir), str(base_id), 'meta.json')
    if base_id and os.path.exists(base_meta):
        with open(base_meta) as f:
            bm = json.load(f)
        loops_base = bm.get('loops')
        if loops_base is None:  # an older run: the loops are in its log
            import ast
            with open(os.path.join(os.path.dirname(outdir), str(base_id) + '.log')) as f:
                line = [x for x in f if ' loops ' in x][-1]
            loops_base = ast.literal_eval(line.split(' loops ', 1)[1])
        for key in ('far', 'mid'):
            spans[key] = list(loops_base[key])
    spans.setdefault('far', [0, L.W])
    spans.setdefault('mid', [0, L.W])
    spans.setdefault('strip', [0, L.W])
    print(vid, 'loops', spans)
    loops = {k: list(v) for k, v in spans.items()}

    def tiled(own, holes, behind, span, lowest, solid=None, seam_top=0, src=None, extra=None):
        """The plane on its loop [x0, x1), joined at the wrap. A solid plane is opaque
        below its silhouette and keeps the painting where nothing nearer covered it."""
        x0, x1 = span
        w = x1 - x0
        sh = w // 2
        r = lambda a: np.roll(a[:, x0:x1], sh, axis=1)
        o, h, b, im, ban = r(own), r(holes), r(behind), r(img_a), r(unique_a)
        ok_src = r(src) if src is not None else o
        ty = np.arange(L.H)[:, None] * np.ones((1, w))
        live = ty < lowest
        o &= live
        ban &= o
        h &= ~o & live
        seam = np.zeros_like(o)
        seam[:, max(0, sh - band // 2):sh + band // 2] = True
        if solid is not None:
            gap, sbase = solid.get('gap', 48), solid.get('base')
            if solid.get('shape'):  # trees and bushes: their own closed outline, not a wall to the ground
                k = 2 * solid['shape'] + 1
                ker = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (k, k))
                sil = cv2.morphologyEx(o.astype(np.uint8), cv2.MORPH_CLOSE, ker) > 0
                sil = L.clean(sil, 1, 1, 60)
            else:
                sil = L.silhouette(o, gap, sbase, lowest, solid.get('smooth', 7),
                                   (max(0, sh - band // 2), sh + band // 2))
            if extra is not None:  # a removed thing this plane surrounds: the plane goes on behind it
                sil |= r(extra)
            alpha = sil & live
            keep = o & ~seam & ~h
            comp = np.where(keep[..., None], im, b)
            if solid.get('fill', 'guided') == 'guided':  # LaMa says what; the painting's cells fill it
                todo = alpha & ~keep
                filled = L.guided_fill(comp, todo, lama(comp, todo), keep & ~ban)
            else:
                filled = fill(comp, ~keep & ~ban, ban)
            filled = np.where(seam[..., None], lama(filled, seam & alpha), filled)
            rgb = np.where(keep[..., None], im, filled)
        else:
            rows_o = np.flatnonzero(o.any(axis=1))
            top = rows_o.min() if len(rows_o) else 0
            hole = (h | (seam & (ty >= max(0, top - 8, seam_top)))) & live
            comp = np.where(o[..., None], im, b)
            guide = lama(comp, hole) if hole.any() else comp
            filled = L.guided_fill(comp, hole, guide, ok_src & ~hole & ~ban & live)
            alpha = o.copy()
            alpha[hole] = L.differs(filled, b, thr)[hole]
            alpha = np.where(hole, L.clean(alpha, 1, 2, 60), alpha) & live
            rgb = np.where(hole[..., None], filled, comp)
        return np.roll(rgb, -sh, axis=1), np.roll(alpha, -sh, axis=1)

    def render(rgb, a, span, behind):
        idx = (np.arange(L.W) - span[0]) % (span[1] - span[0])
        return np.where(a[:, idx][..., None], rgb[:, idx], behind)

    lowest = L.GROUND + 24
    nearer = (mid_a | near_a | rail_a | rem_a | (up & ~sky_a & ~far_a)) & up
    F, Fa = tiled(far_a, nearer, S, spans['far'], lowest,
                  solid={'gap': 4000, 'fill': cfg.get('far_fill', 'guided'), 'smooth': cfg.get('far_smooth', 41)})
    def alternate(rgb, a, span, behind, mode):
        """The tile twice: as painted, then without its one-off landmarks (or mirrored)."""
        x0, x1 = span
        if mode == 'mirror':
            return np.hstack([rgb, rgb[:, ::-1]]), np.hstack([a, a[:, ::-1]]), [x0, x0 + 2 * (x1 - x0)]
        town = unique_a[:, x0:x1] & a
        if mode not in ('unique', 'clone') or not town.any():
            return rgb, a, span
        if mode == 'clone':  # the canyon on each side of the landmark, mirrored inward
            cols = np.flatnonzero(town.any(axis=0))
            h0, h1 = max(1, cols.min() - 8), min(rgb.shape[1] - 1, cols.max() + 9)
            mid = (h0 + h1) // 2
            src = np.array([2 * h0 - 1 - x if x < mid else 2 * h1 - 1 - x for x in range(h0, h1)])
            src = np.mod(src, rgb.shape[1])  # the tile is a seamless loop: the mirror wraps
            r2, a2 = rgb.copy(), a.copy()
            r2[:, h0:h1] = rgb[:, src]
            a2[:, h0:h1] = a[:, src]
            seam = np.zeros_like(a)
            seam[:, mid - 6:mid + 6] = True
            seam &= a2
            r2 = np.where(seam[..., None], lama(np.where(a2[..., None], r2, behind[:, x0:x1]), seam), r2)
            return np.hstack([rgb, r2]), np.hstack([a, a2]), [x0, x0 + 2 * (x1 - x0)]
        hole = L.dilate_mask(town, 4)
        b = behind[:, x0:x1]
        comp = np.where(a[..., None], rgb, b)
        # the plane stays solid: its outline runs across where the town was, from the ridge on
        # one side to the ridge on the other (not along the hole's floor, which left a box),
        # and what fills it is copied from the plane's own rock and woods, never from the sky
        a2 = np.where(hole, L.silhouette(a & ~hole.any(axis=0), 4000, None, L.GROUND + 24), a)
        todo = hole & a2
        filled = L.shift_fill(comp, todo, lama, ~(a & ~hole) & ~todo) if todo.any() else comp
        r2 = np.where(hole[..., None], filled, rgb)
        return np.hstack([rgb, r2]), np.hstack([a, a2]), [x0, x0 + 2 * (x1 - x0)]

    F, Fa, spans['far'] = alternate(F, Fa, spans['far'], S, cfg.get('far_alt', 'unique'))
    Fcomp = render(F, Fa, spans['far'], S)
    lo_rows = (yy >= L.GROUND - 160) & up
    cover = (mid_a & lo_rows)[:, spans['mid'][0]:spans['mid'][1]].any(axis=0).mean()
    mid_shape = cfg.get('mid_close', 16) if cover < cfg.get('mid_wall', 0.6) else None
    print(vid, 'mid cover %.2f' % cover, 'shape' if mid_shape else 'wall')
    mid_base = cfg.get('mid_base')
    mid_base = None if mid_base is None else float(mid_base + (L.GROUND - yu))
    M, Ma = tiled(mid_a, (near_a | rail_a | rem_a) & up, Fcomp, spans['mid'], lowest,
                  solid={'gap': cfg.get('mid_gap', 48), 'base': mid_base,
                         'fill': cfg.get('mid_fill', 'guided'), 'shape': mid_shape},
                  extra=A(L.shape_mask(cfg.get('mid_extra'))) & rem_a)
    M, Ma, spans['mid'] = alternate(M, Ma, spans['mid'], Fcomp, cfg.get('mid_alt', 'none'))
    Mcomp = render(M, Ma, spans['mid'], Fcomp)

    # near: outpainted to each side, so its edge never cuts a tree in the middle
    pl, pr = cfg.get('near_pad', [0, 0])
    xs = np.arange(-pl, L.W + pr)

    def ext(rgb, a, span, behind):
        idx = (xs - span[0]) % (span[1] - span[0])
        return np.where(a[:, idx][..., None], rgb[:, idx], behind)
    sky_x = np.abs(xs) % (2 * L.W)
    sky_x = np.where(sky_x < L.W, sky_x, 2 * L.W - 1 - sky_x)
    behind_n = ext(M, Ma, spans['mid'], ext(F, Fa, spans['far'], S[:, sky_x]))
    pad = lambda a: np.pad(a, ((0, 0), (pl, pr)) + (((0, 0),) if a.ndim == 3 else ()))
    own_n, img_n, ban_n = pad(near_a & up), pad(img_a), pad(unique_a & near_a)
    ty_n = np.arange(L.H)[:, None] * np.ones((1, len(xs)))
    edge = np.zeros_like(own_n)
    edge[:, :pl] = True
    edge[:, pl + L.W:] = True
    touching = near_a & (yy < first_in + 4)
    holes_n = pad((rem_a & up & L.dilate_mask(near_a, 12)) | (outside & up & L.dilate_mask(touching, 40)))
    holes_n &= ~own_n & (ty_n < L.GROUND + 2)
    edge_n = edge & L.edge_caps(own_n, pl, pr) & ~own_n & (ty_n < L.GROUND + 2)
    comp_n = np.where(own_n[..., None], img_n, behind_n)
    if holes_n.any():
        filled_n = L.guided_fill(comp_n, holes_n, lama(comp_n, holes_n), own_n & ~holes_n & ~ban_n)
    else:
        filled_n = comp_n
    if edge_n.any():
        filled_n = np.where(edge_n[..., None], lama(filled_n, edge_n), filled_n)
    Na = own_n.copy()
    Na[holes_n] = L.differs(filled_n, behind_n, thr)[holes_n]
    Na = np.where(holes_n, L.clean(Na, 1, 2, 60), Na) & (ty_n < L.GROUND + 2)
    Na |= edge_n & L.differs(filled_n, behind_n, thr)
    Na = np.where(edge_n, L.clean(Na, 1, 2, 60), Na)
    N = np.where((holes_n | edge_n)[..., None], filled_n, comp_n)
    Ncomp = np.where(Na[:, pl:pl + L.W][..., None], N[:, pl:pl + L.W], Mcomp)

    # strip: the rail on the walking line and everything below it (factor 1)
    below = ~up
    rail_zone = L.remap(L.shape_mask(cfg.get('rail')), rows, True)
    strip_own = (rail_a | below) & ~rem_a & ~outside
    strip_holes = (rem_a & (below | rail_zone)) | (outside & below)
    T, Ta = tiled(strip_own, strip_holes, Ncomp, spans['strip'], L.H + 1, seam_top=L.GROUND - 8,
                  src=(rail_a | below) & ~rem_a & ~outside)
    Ta[L.GROUND:] = True

    for key, rgb, a in (('far', F, Fa), ('mid', M, Ma), ('near', N, Na), ('strip', T, Ta)):
        L.save(os.path.join(outdir, key + '.png'), L.rgba(rgb, a))
    if mark.any():
        L.save(os.path.join(outdir, 'landmark.png'), L.rgba(img_a, A(mark_own)))

    def moved(shift):
        def at(rgb, a, span, factor, behind):
            idx = (np.arange(L.W) + int(shift * factor) - span[0]) % (span[1] - span[0])
            return np.where(a[:, idx][..., None], rgb[:, idx], behind)
        si = np.arange(L.W) + int(shift * 0.03125)
        si = np.where(si < L.W, si, 2 * L.W - 2 - si)
        v = S[:, si]
        ci = (np.arange(L.W) + int(shift * 0.07)) % L.W
        v = np.where(cloud[:, ci][..., None], clouds_rgb[:, ci], v)
        v = at(F, Fa, spans['far'], 0.125, v)
        v = at(M, Ma, spans['mid'], 0.25, v)
        per = cfg.get('near_period', 2560)
        ni = (np.arange(L.W) + int(shift * 0.5) + pl) % per
        ok = ni < N.shape[1]
        nic = np.minimum(ni, N.shape[1] - 1)
        v = np.where((Na[:, nic] & ok[None, :])[..., None], N[:, nic], v)
        return at(T, Ta, spans['strip'], 1.0, v)
    L.save(os.path.join(outdir, 'preview.png'), moved(0))
    L.save(os.path.join(outdir, 'preview_moved.png'), moved(640))
    L.save(os.path.join(outdir, 'preview_far.png'), moved(2300))
    dbg = img_a.copy()
    for m, col in ((far_a, (0, 0, 255)), (mid_a, (0, 255, 0)), (near_a, (255, 255, 0)),
                   (rail_a, (255, 0, 255)), (rem_a, (255, 0, 0)), (sky_a & ~cloud, (0, 255, 255)),
                   (cloud, (255, 255, 255))):
        dbg[m] = (dbg[m] * 0.5 + np.array(col) * 0.5).astype(np.uint8)
    L.save(os.path.join(outdir, 'masks.png'), dbg)
    L.save(os.path.join(outdir, 'source.png'), img)
    meta = {'view': vid, 'src': cfg['src'], 'floors': [yu, yl], 'spans': spans, 'loops': loops,
            'near_pad': [pl, pr], 'near_period': cfg.get('near_period', 2560)}
    with open(os.path.join(outdir, 'meta.json'), 'w') as f:
        json.dump(meta, f, indent=1)


if __name__ == '__main__':
    main()
