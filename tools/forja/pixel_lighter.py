"""Faceted normals and light masks from Pixel Art Lighter v3.5.23 (Red Hat Sprite, MIT; see NOTICE.md)."""
from __future__ import annotations

from collections import deque
from dataclasses import dataclass
from math import atan2, cos, floor, hypot, pi, sin, sqrt

from PIL import Image

from .color import to_linear, to_srgb8

MAX_PIXELS = 512 * 512


@dataclass(frozen=True)
class Preset:
    shape: float
    normal: float
    depth: float
    convexity: float
    distance_cap: int
    smooth: int
    facets: int


PRESETS = {
    "character": Preset(0.65, 0.8, 1.2, 0.65, 8, 2, 15),
    "object": Preset(1.0, 1.0, 2.1, 0.65, 16, 3, 35),
    "architecture": Preset(1.0, 1.0, 3.5, 0.0, 16, 1, 20),
    "terrain": Preset(1.1, 1.0, 4.0, 0.12, 16, 3, 50),
}
FLAT = (0.0, 0.0, 1.0)


def _adjacent(w, h):
    for y in range(h):
        for x in range(w):
            i = y * w + x
            yield tuple(p for p, inside in ((i - 1, x > 0), (i + 1, x + 1 < w),
                                            (i - w, y > 0), (i + w, y + 1 < h)) if inside)


def _regions(pixels, neighbors):
    """Four-connected, equal-RGB regions; alpha marks the silhouette."""
    labels = [-1] * len(pixels)
    regions = []
    for i, color in enumerate(pixels):
        if not color[3] or labels[i] >= 0:
            continue
        region = [i]
        labels[i] = len(regions)
        for p in region:
            for n in neighbors[p]:
                if labels[n] < 0 and pixels[n][3] and pixels[n][:3] == color[:3]:
                    labels[n] = labels[i]
                    region.append(n)
        regions.append(region)
    return labels, regions


def _distance(labels, neighbors, cap):
    edges = deque(i for i, adj in enumerate(neighbors)
                  if labels[i] >= 0 and (len(adj) < 4 or any(labels[n] < 0 for n in adj)))
    distance = [cap] * len(labels)
    for p in edges:
        distance[p] = 1
    while edges:
        p = edges.popleft()
        for n in neighbors[p]:
            if labels[n] >= 0 and distance[n] > distance[p] + 1:
                distance[n] = distance[p] + 1
                edges.append(n)
    return distance


def _unit(v):
    length = hypot(*v) or 1.0
    return tuple(x / length for x in v)


def _mean(vectors):
    return _unit(tuple(map(sum, zip(*vectors)))) if vectors else FLAT


def _facet(v, preset):
    x, y, _ = v
    tilt = hypot(x, y)
    if tilt < 0.12:
        return FLAT
    angle = floor(atan2(y, x) / (pi / 4) + 0.5) * pi / 4
    bands = ((0.30, 0.24), (0.60, 0.48), (0.85, 0.72))
    rim = min(0.9, 0.6 * preset.shape) if not preset.convexity else next(
        (value for threshold, value in bands if tilt < threshold), 0.9)
    return cos(angle) * rim, sin(angle) * rim, sqrt(1 - rim * rim)


def _facets(region, raw, preset):
    values = [raw[p] for p in region if preset.convexity or hypot(*raw[p][:2]) >= 0.06]
    base = _facet(_mean(values), preset)
    if len(region) < round(180 - preset.facets * 1.1):
        return base, []
    groups = {}
    for p in region:
        x, y, _ = raw[p]
        key = floor(atan2(y, x) / (pi / 2) + 0.5) % 4 if hypot(x, y) > 0.35 else 9
        groups.setdefault(key, []).append(p)
    supported = [(g, _mean([raw[p] for p in g])) for g in groups.values()
                 if len(g) >= max(16, len(region) * 0.16)]
    if any(sum(x * y for x, y in zip(a, b)) < 0.8 - preset.facets * 0.001
           for i, (_, a) in enumerate(supported) for _, b in supported[:i]):
        return base, [(g, _facet(v, preset)) for g, v in supported]
    return base, []


def _normal_field(w, h, labels, neighbors, tones, regions, preset):
    distance = _distance(labels, neighbors, preset.distance_cap)
    field = [sqrt(d) * preset.convexity + t * preset.depth for d, t in zip(distance, tones)]
    solid = [tuple(n for n in adj if labels[n] >= 0) for adj in neighbors]
    for _ in range(preset.smooth):
        field = [(2 * field[p] + sum(field[n] for n in adj)) / (2 + len(adj))
                 for p, adj in enumerate(solid)]

    def at(p, x, y):
        if 0 <= x < w and 0 <= y < h and labels[y * w + x] >= 0:
            return field[y * w + x]
        return field[p]

    raw = [FLAT] * len(labels)
    for p, label in enumerate(labels):
        if label >= 0:
            x, y = p % w, p // w
            dx = at(p, x + 1, y) - at(p, x - 1, y)
            dy = at(p, x, y + 1) - at(p, x, y - 1)
            raw[p] = _unit((-dx * preset.shape, dy * preset.shape, 1))
    dirs = [FLAT] * len(labels)
    thin = set()
    for region in regions:
        base, parts = _facets(region, raw, preset)
        for p in region:
            dirs[p] = base
        for group, facet in parts:
            for p in group:
                dirs[p] = facet
        if tones[region[0]] <= 0.24:
            inside = sum(len(neighbors[p]) == 4 and all(labels[n] == labels[p] for n in neighbors[p])
                         for p in region)
            if inside < len(region) * 0.15:
                thin.update(region)
    # Dark, thin outlines take the direction of the nearest neighboring surface.
    queue = deque(p for p, label in enumerate(labels) if label >= 0 and p not in thin)
    while queue and thin:
        p = queue.popleft()
        for n in solid[p]:
            if n in thin:
                thin.remove(n)
                dirs[n] = dirs[p]
                queue.append(n)
    _merge_islands(dirs, labels, solid)
    return dirs


def _merge_islands(dirs, labels, solid):
    """Remove one- and two-pixel normal islands without touching the albedo."""
    seen = set()
    for p, label in enumerate(labels):
        if label < 0 or p in seen:
            continue
        group = [p]
        seen.add(p)
        for q in group:
            for n in solid[q]:
                if n not in seen and dirs[n] == dirs[p]:
                    seen.add(n)
                    group.append(n)
        if len(group) <= 2:
            neighbor = next((n for q in group for n in solid[q] if n not in group), None)
            if neighbor is not None:
                for q in group:
                    dirs[q] = dirs[neighbor]


def _receive(t, region, tones, labels, neighbors):
    # Gentler defaults for already shaded Empire sprites. Only local direct light uses this mask.
    receive = 0.55 + 0.45 * t ** 1.15
    if t < 0.35:
        rim = [[n for n in neighbors[p] if labels[n] >= 0 and labels[n] != labels[p]] for p in region]
        enclosed = sum(sum(tones[n] > t + 0.15 for n in ns) > len(ns) / 2 for ns in rim)
        receive *= 1 - 0.20 * min(1.0, enclosed / sqrt(len(region)))
    return round(255 * (0.52 + 0.48 * receive))


def generate(albedo: Image.Image, profile: str = "character") -> tuple[Image.Image, Image.Image]:
    """Normal (R right, G up, B toward camera) and grayscale light reception on the same grid."""
    if albedo.width * albedo.height > MAX_PIXELS:
        raise ValueError(f"luz: quadro nativo acima de {MAX_PIXELS} pixels")
    preset = PRESETS[profile]
    albedo = albedo.convert("RGBA")
    box = albedo.getchannel("A").getbbox()
    if box is None:
        return Image.new("RGBA", albedo.size), Image.new("RGBA", albedo.size)
    crop = albedo.crop(box)
    pixels = crop.get_flattened_data()
    neighbors = list(_adjacent(*crop.size))
    labels, regions = _regions(pixels, neighbors)
    lum = [(0.2126 * r + 0.7152 * g + 0.0722 * b) / 255 for r, g, b, _ in pixels]
    used = [lum[region[0]] for region in regions]
    low, high = min(used), max(used)
    tones = [(v - low) / (high - low) if high - low > 1e-5 else 0.75 for v in lum]
    dirs = _normal_field(*crop.size, labels, neighbors, tones, regions, preset)
    receive = [_receive(tones[region[0]], region, tones, labels, neighbors) for region in regions]
    norm_px, mask_px = [], []
    for i, (_, _, _, a) in enumerate(pixels):
        if a:
            x, y, z = dirs[i]
            vec = _unit((x * preset.normal, y * preset.normal, z))
            norm_px.append(tuple(floor((v + 1) * 127.5 + 0.5) for v in vec) + (a,))
            mask_px.append((receive[labels[i]],) * 3 + (a,))
        else:
            norm_px.append((0, 0, 0, 0))
            mask_px.append((0, 0, 0, 0))
    normal, mask = Image.new("RGBA", albedo.size), Image.new("RGBA", albedo.size)
    for dst, data in ((normal, norm_px), (mask, mask_px)):
        dst.paste(Image.frombytes("RGBA", crop.size, b"".join(bytes(p) for p in data)), box[:2])
    return normal, mask


def pack_surface(normal: Image.Image, mask: Image.Image) -> Image.Image:
    """Godot transport: R/G carry normal X/Y, B=0..254 is the mask; B=255 is the no-map sentinel."""
    surface = Image.new("RGB", normal.size)
    surface.putdata([(r, g, (m * 254 + 127) // 255) if a else (128, 128, 255)
                     for (r, g, _, a), (m, _, _, _) in zip(normal.get_flattened_data(), mask.get_flattened_data())])
    return surface


def preview(albedo: Image.Image, normal: Image.Image, mask: Image.Image,
            light: tuple[float, float]) -> Image.Image:
    """Moonfell's local point-light preview, at 1× and with the original alpha."""
    w, h = albedo.size
    z, radius = min(w, h) * 0.55, max(w, h)
    data = []
    for i, ((r, g, b, a), n, m) in enumerate(zip(albedo.get_flattened_data(), normal.get_flattened_data(), mask.get_flattened_data())):
        if not a:
            data.append((0, 0, 0, 0))
            continue
        direction = (light[0] - i % w, i // w - light[1], z)
        dot = sum(v * d for v, d in zip(_unit(tuple(c / 127.5 - 1 for c in n[:3])), _unit(direction)))
        attenuation = 1 / (1 + (hypot(*direction) / radius) ** 2)
        exposure = 0.55 + 1.2 * max(0.0, dot) * attenuation * (m[0] / 255)
        data.append(tuple(to_srgb8(to_linear(c) * exposure) for c in (r, g, b)) + (a,))
    return Image.frombytes("RGBA", albedo.size, b"".join(bytes(p) for p in data))
