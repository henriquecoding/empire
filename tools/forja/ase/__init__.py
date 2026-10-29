"""O formato Aseprite na Forja (FORJA-14): ler, escrever e renderizar a especificacao 1.3 inteira, igual ao Aseprite.

`read` e `write` fazem a ida e volta sem perda; `render` da o quadro como o export do Aseprite; `build` monta um
sprite a partir de imagens. A conformidade prova-se contra o Aseprite 1.3.18.6 compilado (fixtures em
`tools/forja/tests/ase_fixtures/`).
"""
from .build import sprite as build
from .model import Cel, Layer, Slice, SliceKey, Sprite, Tag, Tileset, Typed, UserData
from .read import read
from .render import render
from .write import write

__all__ = ["Cel", "Layer", "Slice", "SliceKey", "Sprite", "Tag", "Tileset", "Typed", "UserData", "build", "read",
           "render", "write"]
