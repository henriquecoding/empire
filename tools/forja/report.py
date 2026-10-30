"""Relatorio HTML de uma forja: um ficheiro, sem nada de fora, para rever a olho.

Mostra a origem, a grade achada sobre um recorte 1:1, o resultado a 1x e
ampliado em fundos do jogo, a paleta usada, os achados do lint e o prompt
corretivo. Para animacoes, um leitor com a duracao de cada quadro.
"""
from __future__ import annotations

import base64
import html
import io
import json
from pathlib import Path

from PIL import Image

from .grid import Grid
from .imageops import flat, on_background, upscale

BACKGROUNDS = {"xadrez": None, "noite": (23, 19, 13), "dia": (214, 200, 160)}

STYLE = """
:root{--bg:#14110d;--fg:#eadfca;--mut:#a89a82;--line:#3a3127;--ok:#7fb069;--err:#e05a47;--warn:#e0b347}
body{margin:0;background:var(--bg);color:var(--fg);font:15px/1.5 system-ui,sans-serif}
main{max-width:1100px;margin:0 auto;padding:16px}
h1{font-size:22px;margin:8px 0}h2{font-size:17px;margin:22px 0 8px;color:var(--mut)}
img{image-rendering:pixelated;image-rendering:crisp-edges;max-width:100%}
.row{display:flex;flex-wrap:wrap;gap:12px;align-items:flex-start}
figure{margin:0;background:#0d0b08;border:1px solid var(--line);padding:8px;border-radius:6px}
figcaption{font-size:12px;color:var(--mut)}
table{border-collapse:collapse;width:100%}td,th{border-bottom:1px solid var(--line);padding:6px;text-align:left;vertical-align:top}
.error{color:var(--err)}.warn{color:var(--warn)}.info{color:var(--mut)}.ok{color:var(--ok)}
.sw{display:inline-block;width:22px;height:22px;border:1px solid #000;margin:1px}
pre{white-space:pre-wrap;background:#0d0b08;border:1px solid var(--line);padding:8px;border-radius:6px}
button{background:#2a241c;color:var(--fg);border:1px solid var(--line);padding:6px 10px;border-radius:4px}
"""


def data_uri(image: Image.Image) -> str:
    buf = io.BytesIO()
    image.save(buf, "PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode("ascii")


def _fig(image: Image.Image, caption: str, width: int | None = None) -> str:
    style = f' style="width:{width}px"' if width else ""
    return (f'<figure><img alt="{html.escape(caption)}" src="{data_uri(image)}"{style}>'
            f"<figcaption>{html.escape(caption)}</figcaption></figure>")


def _thumb(image: Image.Image, side: int = 480) -> Image.Image:
    scale = min(1.0, side / max(image.size))
    if scale >= 1:
        return image
    return image.resize((max(1, int(image.width * scale)), max(1, int(image.height * scale))), Image.Resampling.LANCZOS)


def _grid_crop(image: Image.Image, grid: Grid, side: int = 256) -> Image.Image:
    cx, cy = image.width // 2, image.height // 2
    box = (max(0, cx - side // 2), max(0, cy - side // 2), min(image.width, cx + side // 2), min(image.height, cy + side // 2))
    return overlay(image, grid).crop(box)


def overlay(image: Image.Image, grid: Grid, rgba=(255, 0, 64, 160)) -> Image.Image:
    """A imagem com as linhas de corte por cima, para o relatorio."""
    out = image.convert("RGBA").copy()
    line = Image.new("RGBA", (1, out.height), rgba)
    for x in grid.xs:
        if 0 <= x < out.width:
            out.alpha_composite(line, (x, 0))
    row = Image.new("RGBA", (out.width, 1), rgba)
    for y in grid.ys:
        if 0 <= y < out.height:
            out.alpha_composite(row, (0, y))
    return out


def _views(final: Image.Image, zoom: int) -> str:
    out = [_fig(final, "1x (tamanho real)")]
    for label, bg in BACKGROUNDS.items():
        out.append(_fig(upscale(on_background(final, bg, cell=4), zoom), f"{zoom}x sobre {label}"))
    return '<div class="row">' + "".join(out) + "</div>"


def _palette(final: Image.Image) -> str:
    colors = sorted({p[:3] for p in flat(final) if p[3] >= 128})
    cells = "".join(f'<span class="sw" title="#{c[0]:02X}{c[1]:02X}{c[2]:02X}" '
                    f'style="background:#{c[0]:02X}{c[1]:02X}{c[2]:02X}"></span>' for c in colors)
    return f"<p>{len(colors)} cores</p><div>{cells}</div>"


def _findings(verdict: dict) -> str:
    if not verdict["findings"]:
        return '<p class="ok">Nenhum achado: cumpre o contrato conferido.</p>'
    rows = "".join(f'<tr><td class="{f["severity"]}">{f["severity"]}</td><td>{html.escape(f["rule"])}</td>'
                   f'<td>{html.escape(f["message"])}</td><td><code>{html.escape(f["fix"] or "")}</code></td></tr>'
                   for f in verdict["findings"])
    return f"<table><tr><th>gravidade</th><th>regra</th><th>o que</th><th>corrige</th></tr>{rows}</table>"


def _page(title: str, body: str) -> str:
    return (f'<!doctype html><html lang="pt-BR"><head><meta charset="utf-8">'
            f'<meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title>'
            f"<style>{STYLE}</style></head><body><main>{body}</main></body></html>\n")


def _verdict_line(verdict: dict) -> str:
    cls = "ok" if verdict["ok"] else "error"
    word = "cumpre" if verdict["ok"] else "nao cumpre"
    return (f'<p class="{cls}"><b>{word}</b> o contrato <code>{html.escape(verdict["kind"])}</code> — '
            f'{verdict["errors"]} erros, {verdict["warnings"]} avisos</p>')


def _impure_map(final: Image.Image, cells: list, zoom: int, k: int = 1) -> Image.Image:
    """O resultado ampliado com as celulas misturadas a vermelho: onde o gerador desenhou abaixo da grade."""
    img = upscale(on_background(final, (23, 19, 13), 4), zoom)
    mark = Image.new("RGBA", (zoom * k, zoom * k), (255, 40, 40, 150))
    for x, y in cells:
        if 0 <= x < final.width and 0 <= y < final.height:
            img.alpha_composite(mark, (x * zoom, y * zoom))
    return img


def single(path: str | Path, source: Image.Image, grid: Grid, final: Image.Image, result: dict,
           impure: list | None = None) -> Path:
    verdict = result["lint"]
    zoom = max(2, min(10, 512 // max(final.size)))
    snap = result["snap"]
    body = [f"<h1>Forja · {html.escape(result['name'])}</h1>", _verdict_line(verdict),
            f'<p class="info">{html.escape(result["contract"]["label"])} — {html.escape(result["contract"]["status"])}</p>',
            "<h2>Origem e grade</h2>", '<div class="row">',
            _fig(_thumb(source), f"origem {source.width}x{source.height}"),
            _fig(_grid_crop(source, grid), f"grade achada (recorte 1:1): periodo {snap['grid']['period'][0]}, "
                 f"{snap['grid']['cells'][0]}x{snap['grid']['cells'][1]} celulas, confianca {snap['grid']['confidence']}"),
            "</div>", f"<p>pureza das celulas {snap['sample']['purity']} (so o miolo) · grade "
            f"{snap['grid'].get('origin')} · celulas apagadas {(snap.get('loss') or {}).get('erased_cells', '-')} · "
            f"fundo {html.escape(json.dumps(snap['background']))}</p>",
            "<h2>Resultado</h2>", _views(final, zoom), "<h2>Paleta</h2>", _palette(final),
            "<h2>Celulas misturadas</h2>", '<p class="info">A vermelho, onde o gerador desenhou mais fino do que a '
            "grade (muitas vezes o rosto): o voto escolhe uma cor e o traco fino perde-se.</p>",
            _fig(_impure_map(final, impure or [], zoom, result["finish"].get("cluster_upscale", 1)),
                 f"{len(impure or [])} celulas"),
            "<h2>Lint</h2>", _findings(verdict)]
    if verdict.get("prompt_feedback"):
        body += ["<h2>Prompt corretivo para o gerador</h2>", f"<pre>{html.escape(verdict['prompt_feedback'])}</pre>"]
    body += ["<h2>Proveniencia</h2>", f"<pre>{html.escape(json.dumps(result['provenance'], indent=1, ensure_ascii=False))}</pre>"]
    path = Path(path)
    path.write_text(_page(f"Forja · {result['name']}", "".join(body)), encoding="utf-8")
    return path


PLAYER = """<p><select id="tag"></select>
<label>escala <select id="zoom"><option>1</option><option>2</option><option selected>%d</option></select></label>
<label>fundo <select id="bg"><option value="#241f17">escuro</option><option value="#eee8df">claro</option></select></label></p>
<canvas id="cv"></canvas><p><button id="pp">pausar</button> <button id="st">quadro</button>
<label><input type="checkbox" id="on"> onion</label> <span id="ix"></span></p>
<script>
const F=%s,D=%s,T=%s;const cv=document.getElementById('cv'),cx=cv.getContext('2d');
const im=F.map(s=>{const i=new Image();i.src=s;return i});let k=0,run=true,t=null,tag=0;
const pick=document.getElementById('tag');T.forEach((a,i)=>{const o=document.createElement('option');o.value=i;o.textContent=a.name;pick.append(o)});
cx.imageSmoothingEnabled=false;
function draw(){const i=T[tag].indices[k],a=im[i],Z=Number(document.getElementById('zoom').value);
cv.width=a.naturalWidth*Z;cv.height=a.naturalHeight*Z;cx.imageSmoothingEnabled=false;
cx.fillStyle=document.getElementById('bg').value;cx.fillRect(0,0,cv.width,cv.height);
if(document.getElementById('on').checked && k>0){cx.globalAlpha=.3;cx.drawImage(im[T[tag].indices[k-1]],0,0,cv.width,cv.height);cx.globalAlpha=1}
cx.drawImage(a,0,0,cv.width,cv.height);document.getElementById('ix').textContent=(i+1)+'/'+F.length+' · '+D[i]+' ms';
document.getElementById('pp').textContent=run?'pausar':'reproduzir'}
function advance(){if(k+1<T[tag].indices.length){k++;return true}if(T[tag].loop){k=0;return true}return false}
function tick(){clearTimeout(t);draw();if(run)t=setTimeout(()=>{if(!advance())run=false;tick()},D[T[tag].indices[k]])}
document.getElementById('pp').onclick=()=>{clearTimeout(t);run=!run;if(run && k===T[tag].indices.length-1)k=0;tick()};
document.getElementById('st').onclick=()=>{clearTimeout(t);run=false;advance();draw()};
pick.onchange=()=>{clearTimeout(t);tag=Number(pick.value);k=0;run=true;tick()};
for(const id of ['zoom','bg','on'])document.getElementById(id).onchange=draw;
Promise.all(im.map(i=>i.decode())).then(tick);
</script>"""


def animation(path: str | Path, frames: list[Image.Image], durations: list[int], result: dict) -> Path:
    from . import timeline
    zoom = max(2, min(8, 384 // max(frames[0].size)))
    uris = json.dumps([data_uri(f) for f in frames])
    strip = Image.new("RGBA", (frames[0].width * len(frames), frames[0].height))
    for i, f in enumerate(frames):
        strip.alpha_composite(f, (i * f.width, 0))
    rows = "".join(f"<tr><td>{i}</td><td>{html.escape(json.dumps(r, ensure_ascii=False))}</td></tr>"
                   for i, r in enumerate(result.get("frames", [])))
    body = [f"<h1>Forja · {html.escape(result['name'])}</h1>",
            f'<p class="{"ok" if result.get("ok") else "error"}">{result.get("summary", "")}</p>',
            "<h2>Animacao</h2>", PLAYER % (zoom, uris, json.dumps(durations),
                                          json.dumps(timeline.playback(result["tags"]))),
            "<h2>Tira</h2>", _fig(upscale(on_background(strip, None, 4), 2), "todos os quadros, 2x"),
            "<h2>Medidas</h2>", f"<pre>{html.escape(json.dumps(result.get('metrics', {}), indent=1))}</pre>",
            "<h2>Quadros</h2>", f"<table>{rows}</table>",
            "<h2>Proveniencia</h2>", f"<pre>{html.escape(json.dumps(result.get('provenance', {}), indent=1, ensure_ascii=False))}</pre>"]
    path = Path(path)
    path.write_text(_page(f"Forja · {result['name']}", "".join(body)), encoding="utf-8")
    return path
