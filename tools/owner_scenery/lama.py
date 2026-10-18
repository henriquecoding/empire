"""LaMa (Carve/LaMa-ONNX, 512 x 512) at the painting's own resolution (ADR 0085)."""
import numpy as np
import onnxruntime as ort

_S = None


def _sess(path):
    global _S
    if _S is None:
        o = ort.SessionOptions()
        o.intra_op_num_threads = 4
        _S = ort.InferenceSession(path, o, providers=['CPUExecutionProvider'])
    return _S


def _run(sess, img, msk):
    x = img.astype(np.float32).transpose(2, 0, 1)[None] / 255.0
    m = (msk > 0).astype(np.float32)[None, None]
    y = sess.run(None, {'image': x, 'mask': m})[0][0].transpose(1, 2, 0)
    if y.max() <= 1.5:
        y = y * 255.0
    return np.clip(y, 0, 255)


def inpaint_tiled(rgb, mask, model, win=512, margin=64, stride=64):
    """Native-resolution LaMa: fill the hole window by window, best-supported first.

    Each pass picks the 512x512 window whose core (the window less `margin` on the sides
    that are not the image border) has the most hole pixels weighted by how much of the
    window is already known, fills it, and commits the core. Filled pixels become context
    for the next window, so big holes are grown inward from their edges at full detail.
    """
    import cv2
    sess = _sess(model)
    H, W = mask.shape
    out = rgb.copy()
    rem = mask.copy()
    wy, wx = min(win, H), min(win, W)
    ys = sorted(set(list(range(0, H - wy + 1, stride)) + [H - wy]))
    xs = sorted(set(list(range(0, W - wx + 1, stride)) + [W - wx]))
    guard = 0
    while rem.any() and guard < 400:
        guard += 1
        ii = np.cumsum(np.cumsum(rem.astype(np.int32), 0), 1)
        ii = np.pad(ii, ((1, 0), (1, 0)))
        def box(y0, x0, y1, x1):
            return ii[y1, x1] - ii[y0, x1] - ii[y1, x0] + ii[y0, x0]
        best, pick = -1.0, None
        for y0 in ys:
            for x0 in xs:
                cy0 = y0 if y0 == 0 else y0 + margin
                cx0 = x0 if x0 == 0 else x0 + margin
                cy1 = y0 + wy if y0 + wy == H else y0 + wy - margin
                cx1 = x0 + wx if x0 + wx == W else x0 + wx - margin
                core = box(cy0, cx0, cy1, cx1)
                if core <= 0:
                    continue
                known = 1.0 - box(y0, x0, y0 + wy, x0 + wx) / float(wy * wx)
                score = core * known * known
                if score > best:
                    best, pick = score, (y0, x0, cy0, cx0, cy1, cx1)
        if pick is None:
            break
        y0, x0, cy0, cx0, cy1, cx1 = pick
        crop = out[y0:y0 + wy, x0:x0 + wx]
        cm = rem[y0:y0 + wy, x0:x0 + wx]
        if wy < win or wx < win:
            c2 = np.zeros((win, win, 3), np.uint8); c2[:wy, :wx] = crop
            m2 = np.ones((win, win), bool); m2[:wy, :wx] = cm
        else:
            c2, m2 = crop, cm
        m2d = cv2.dilate(m2.astype(np.uint8), np.ones((3, 3), np.uint8)) > 0
        res = _run(sess, c2, m2d)[:wy, :wx].astype(np.uint8)
        core = np.zeros_like(cm)
        core[cy0 - y0:cy1 - y0, cx0 - x0:cx1 - x0] = True
        sel = cm & core
        out[y0:y0 + wy, x0:x0 + wx][sel] = res[sel]
        rem[y0:y0 + wy, x0:x0 + wx][sel] = False
    return out
