# NOTICE — componentes de terceiros

Este ficheiro lista o software e os assets de terceiros que o Empire usa ou distribui, e as atribuições que as
respetivas licenças exigem. A lista mestra, com a prova de cada licença, é
[`docs/legal/THIRD_PARTY_ASSETS.csv`](docs/legal/THIRD_PARTY_ASSETS.csv). Atualiza os dois ao mesmo tempo.

## Distribuído com o jogo

### Godot Engine

Este jogo usa o Godot Engine, disponível sob a seguinte licença:

> Copyright (c) 2014-present Godot Engine contributors.
> Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
> documentation files (the "Software"), to deal in the Software without restriction, including without limitation
> the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and
> to permit persons to whom the Software is furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all copies or substantial portions
> of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
> TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
> CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
> IN THE SOFTWARE.

O executável do Godot inclui bibliotecas de terceiros (por exemplo FreeType, ENet e mbed TLS) cujos avisos também
têm de acompanhar o jogo. **Antes da demo**, gera a lista exata da versão usada — o Godot expõe-na em
`Engine.get_copyright_info()` e `Engine.get_license_info()` — e mostra-a no ecrã de créditos, como descreve a
documentação oficial: <https://docs.godotengine.org/en/stable/about/complying_with_licenses.html>. É um item da
RELEASE_CHECKLIST.

## Só no desenvolvimento (não distribuído)

| Componente | Licença | Onde |
|---|---|---|
| gdUnit4 6.2.1 — Mike Schulze | MIT | `addons/gdUnit4/` (excluído do *export*) |
| gdtoolkit (gdformat, gdlint) — Pawel Lampe | MIT | instalado pelo CI |

## Planeado (entra com ADR, e com a sua linha aqui)

GodotSteam · Godot Aseprite Wizard · LimboAI · fontes · música e efeitos sonoros.
