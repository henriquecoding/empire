"""Forja luz: faceted normals, a direct-light mask and a layered Aseprite study."""
from pathlib import Path

from . import contracts, lighting_export, pixel_lighter
from .cli import command, pair


def do_luz(args) -> dict:
    default = lighting_export.preset_for(args.kind) if args.kind else "character"
    return lighting_export.export(args.source, args.out or Path("build/forja/luz") / Path(args.source).stem,
                                  preset=args.preset or default, kind=args.kind, edited=args.mapas_editados,
                                  frame=args.quadro, light=args.posicao)


def register(sub) -> None:
    p = command(sub, "luz", "PNG nativo ou .aseprite -> normal facetada, mascara de luz, previa e .aseprite em camadas",
                do_luz)
    p.add_argument("source")
    p.add_argument("-o", "--out", help="pasta de saida (por omissao build/forja/luz/<nome>)")
    p.add_argument("--kind", choices=contracts.kinds(), help="conferir a tela do contrato nativo")
    p.add_argument("--preset", choices=pixel_lighter.PRESETS, help="perfil da superficie")
    p.add_argument("--mapas-editados", action="store_true", help="ler as camadas editadas num .aseprite RGB")
    p.add_argument("--quadro", type=int, default=0, help="indice de quadro para a previa, a partir de zero")
    p.add_argument("--posicao", type=pair, help="X,Y da primeira luz na previa, em pixels nativos")
