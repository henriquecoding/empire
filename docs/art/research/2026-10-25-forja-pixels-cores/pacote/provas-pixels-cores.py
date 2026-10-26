"""Provas locais da Forja: diagnósticos, não um corretor nem arte aprovada.

Uso: python provas-pixels-cores.py --forja-dir /caminho/empire/tools/forja --out evidencias
Requer apenas Pillow e os módulos existentes da Forja; não faz chamadas de rede.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib
import importlib.util
import json
import sys
from collections import Counter
from pathlib import Path

from PIL import Image, ImageDraw


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--forja-dir', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--assets', type=Path)
    args = parser.parse_args()
    directory = args.forja_dir.resolve()
    spec = importlib.util.spec_from_file_location(
        'forja_research_snapshot', directory / '__init__.py',
        submodule_search_locations=[str(directory)])
    package = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = package
    spec.loader.exec_module(package)
    modules = {n: importlib.import_module(spec.name + '.' + n) for n in
               ['cleanup', 'lint', 'contracts', 'quantize', 'palette', 'pipeline', 'color', 'imageops']}
    cleanup, lint, contracts = (modules[n] for n in ['cleanup', 'lint', 'contracts'])
    quantize, palette, pipeline = (modules[n] for n in ['quantize', 'palette', 'pipeline'])
    args.out.mkdir(parents=True, exist_ok=True)
    results = {'source_sha256': {}, 'cases': {}, 'assets': {}}
    for f in sorted(directory.glob('*.py')):
        results['source_sha256'][f.name] = hashlib.sha256(f.read_bytes()).hexdigest()

    def pixels(image):
        return modules['imageops'].flat(image)

    def diff(a, b):
        return sum(p != q for p, q in zip(pixels(a), pixels(b)))

    def stats(image):
        rows = modules['imageops'].grid(image)
        groups4 = cleanup.components(rows, offsets=cleanup.N4)
        groups8 = cleanup.components(rows, offsets=cleanup.N8)
        opaque = sum(p[3] >= 128 for p in pixels(image))
        interior = sum(len(g) == 1 and len(list(cleanup._neighbors(rows, *g[0]))) == 8
                       and all(q[3] >= 128 for q in cleanup._neighbors(rows, *g[0]))
                       for _, g in groups8)
        lonely = sum(p[3] >= 128 and not any(q[3] >= 128 for q in cleanup._neighbors(rows, x, y))
                     for y, row in enumerate(rows) for x, p in enumerate(row))
        return {'size': list(image.size), 'opaque': opaque,
                'colors': len({p[:3] for p in pixels(image) if p[3] >= 128}),
                'components4': len(groups4), 'components8': len(groups8),
                'color_singletons4': sum(len(g) == 1 for _, g in groups4),
                'color_singletons8': sum(len(g) == 1 for _, g in groups8),
                'interior_color_singletons8': interior, 'alpha_orphans8': lonely}

    black, body, accent = (0, 0, 0, 255), (80, 80, 80, 255), (240, 220, 60, 255)
    base = Image.new('RGBA', (80, 80))
    draw = ImageDraw.Draw(base)
    draw.rectangle((20, 18, 59, 78), fill=body, outline=black, width=1)
    scatter, cluster = base.copy(), base.copy()
    for y in [26, 38, 50, 62]:
        for x in [25, 34, 43, 52]:
            scatter.putpixel((x, y), accent)
    ImageDraw.Draw(cluster).rectangle((36, 40, 39, 43), fill=accent)
    pal = palette.Palette([black[:3], body[:3], accent[:3]])
    for name, img in [('scatter', scatter), ('cluster', cluster)]:
        report = lint.check(img, contracts.get('royal_80'), pal)
        cleaned, info = cleanup.clean(img, policy='character')
        img.save(args.out / (name + '.png'))
        results['cases'][name] = {'stats': stats(img), 'lint': report,
                                  'cleanup_changed': diff(img, cleaned), 'cleanup': info}
    results['cases']['equal_histogram'] = Counter(pixels(scatter)) == Counter(pixels(cluster))

    capped, cap_info = pipeline.finish(scatter,
        pipeline.Options(kind='royal_80', colors=2, fit=False, outline='keep'),
        contracts.get('royal_80'), pal)
    results['cases']['palette_and_color_budget'] = {'requested_colors': 2,
        'supplied_palette_size': len(pal), 'output_colors': stats(capped)['colors'],
        'finish_palette_report': cap_info.get('palette')}

    face = Image.new('RGBA', (9, 9), (100, 100, 100, 255))
    face.putpixel((4, 4), (105, 105, 105, 255))
    changed, info = cleanup.clean(face, policy='character')
    kept, protected = cleanup.clean(face, policy='character', protect=[(4, 4, 5, 5)])
    results['cases']['subtle_detail'] = {'changed_without_protection': diff(face, changed),
        'changed_with_cleanup_protection': diff(face, kept), 'cleanup': info,
        'delta_oklab': modules['color'].delta((100, 100, 100), (105, 105, 105))}

    opts = pipeline.Options(kind='free', cleanup='character', protect=[(4, 4, 5, 5)],
                            fit=False, outline='keep')
    finished, info = pipeline.finish(face, opts, contracts.get('free'),
                                     palette.Palette([(100, 100, 100)]))
    results['cases']['protection_scope'] = {'cleanup_kept': info['cleanup']['protected_kept'],
        'protected_pixel_before': face.getpixel((4, 4)),
        'protected_pixel_after_finish': finished.getpixel((4, 4))}

    diagonal = Image.new('RGBA', (16, 16), body)
    for i in range(4, 12):
        diagonal.putpixel((i, i), accent)
    merged, count = cleanup.min_cluster(diagonal, 2)
    results['cases']['diagonal_helper'] = {'before': stats(diagonal), 'after': stats(merged),
        'changed': diff(diagonal, merged), 'reported_changes': count,
        'scope': 'min_cluster helper, not pipeline.finish default'}

    strip, square = Image.new('RGBA', (10, 10)), Image.new('RGBA', (10, 10))
    ImageDraw.Draw(strip).rectangle((3, 3, 6, 3), fill=accent)
    ImageDraw.Draw(square).rectangle((3, 3, 4, 4), fill=accent)
    results['cases']['area_vs_footprint'] = {
        '1x4_islands_reported': cleanup.small_islands(strip, 2),
        '2x2_islands_reported': cleanup.small_islands(square, 2)}

    eye_open = Image.new('RGBA', (9, 9), body)
    eye_open.putpixel((4, 4), black)
    eye_closed = Image.new('RGBA', (9, 9), body)
    corrected, count = quantize.blink([eye_open, eye_closed, eye_open])
    results['cases']['intentional_eye_blink'] = {'reported_changes': count,
        'middle_frame_changes': diff(eye_closed, corrected[1]),
        'middle_equals_open_after': corrected[1].tobytes() == eye_open.tobytes()}

    a = Image.new('RGBA', (16, 16), (100, 100, 100, 255))
    b = a.copy()
    ImageDraw.Draw(a).line((5, 2, 5, 13), fill=(110, 110, 110, 255))
    ImageDraw.Draw(b).line((6, 2, 6, 13), fill=(110, 110, 110, 255))
    moved, count = quantize.deflicker([a, b], threshold=0.05)
    zero, zero_count = quantize.deflicker([a, b], threshold=0)
    results['cases']['moving_near_color'] = {'reported_changes': count,
        'changed_pixels': diff(b, moved[1]), 'second_frame_equals_first_after':
        moved[1].tobytes() == a.tobytes(), 'threshold_zero_changes': zero_count}

    dark = Image.new('RGBA', (16, 16), (20, 20, 20, 255))
    dithered = quantize.to_palette(dark, palette.Palette([(0, 0, 0), (255, 255, 255)]),
                                   dither='bayer2', strength=0)
    results['cases']['dither_zero_helper'] = {'white_pixels':
        sum(p[:3] == (255, 255, 255) for p in pixels(dithered)),
        'total': 256, 'scope': 'explicit helper strength=0, not default pipeline option'}

    if args.assets:
        master_path = directory / 'empire_working.gpl'
        if not master_path.exists():
            master_path = directory.parents[1] / 'art/palettes/empire_working.gpl'
        master = palette.load(master_path)
        for name in ['rei', 'arqueiro', 'escudeiro']:
            path = args.assets / name / (name + '.png')
            img = Image.open(path).convert('RGBA')
            verdict = lint.check(img, contracts.get('royal_64' if name == 'escudeiro' else 'royal_80'), master)
            results['assets'][name] = {'stats': stats(img), 'lint_recomputed': verdict,
                                     'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
    (args.out / 'resultados.json').write_text(json.dumps(results, ensure_ascii=False, indent=2))
    print(json.dumps(results, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
