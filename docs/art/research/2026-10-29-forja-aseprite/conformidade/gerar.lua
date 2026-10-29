-- Gera, com o proprio Aseprite, os sprites de conformidade da Forja (FORJA-13).
-- Uso: aseprite -b --script-param out=<pasta> --script gerar.lua
-- Cada sprite cobre uma parte da especificacao 1.3; a Forja le-os e tem de os renderizar igual ao export do
-- Aseprite e de ver a mesma estrutura que o `ler.lua` ve.

local out = app.params["out"]
local rgba, graya = app.pixelColor.rgba, app.pixelColor.graya
local MODES = { BlendMode.NORMAL, BlendMode.MULTIPLY, BlendMode.SCREEN, BlendMode.OVERLAY, BlendMode.DARKEN,
  BlendMode.LIGHTEN, BlendMode.COLOR_DODGE, BlendMode.COLOR_BURN, BlendMode.HARD_LIGHT, BlendMode.SOFT_LIGHT,
  BlendMode.DIFFERENCE, BlendMode.EXCLUSION, BlendMode.HSL_HUE, BlendMode.HSL_SATURATION, BlendMode.HSL_COLOR,
  BlendMode.HSL_LUMINOSITY, BlendMode.ADDITION, BlendMode.SUBTRACT, BlendMode.DIVIDE }
local ALPHAS = { 0, 90, 200, 255 }

local function fill(img, f)
  for it in img:pixels() do it(f(it.x, it.y)) end
end

-- 1 e 2: os 19 modos de mistura, uma faixa de 4 filas por modo, sobre um fundo com alfa 0, 128 e 255,
-- com opacidades de camada e de cel diferentes; em RGBA e em Grayscale.
local function blends(mode, name, pixel)
  local spr = Sprite(48, 76, mode)
  local base = spr.layers[1]
  base.name = "base"
  local img = Image(48, 76, mode)
  fill(img, function(x, y)
    return pixel((x * 5) % 256, (y * 3) % 256, ((x + y) * 7) % 256, x < 8 and 0 or (x < 16 and 128 or 255))
  end)
  spr:newCel(base, 1, img, Point(0, 0))
  for i, m in ipairs(MODES) do
    local l = spr:newLayer()
    l.name = "m" .. (i - 1)
    l.blendMode = m
    l.opacity = 64 + (i * 37) % 192
    local band = Image(48, 4, mode)
    fill(band, function(x, y)
      return pixel((x * 11 + i * 20) % 256, (x * 3 + y * 50) % 256, (255 - x * 5) % 256, ALPHAS[(x % 4) + 1])
    end)
    local cel = spr:newCel(l, 1, band, Point(0, (i - 1) * 4))
    cel.opacity = 255 - (i * 23) % 128
  end
  spr:saveAs(out .. "/" .. name .. ".aseprite")
  spr:close()
end

blends(ColorMode.RGB, "blends_rgba", function(r, g, b, a) return rgba(r, g, b, a) end)
blends(ColorMode.GRAYSCALE, "blends_gray", function(r, g, b, a) return graya((r + g + b) // 3, a) end)

-- 3: a estrutura: grupos aninhados, camadas e grupos escondidos, cels ligadas (camada continua), opacidade de
-- cel, z-index, quatro direcoes de tag com repeticao, cor e dados, slices com 9-patch e pivo, dados e propriedades
-- no sprite, nas camadas, nas cels, nas tags e nas slices; quadros com duracoes diferentes.
do
  local spr = Sprite(32, 24, ColorMode.RGB)
  local body = spr.layers[1]
  body.name = "body"
  body.isContinuous = true
  local img = Image(10, 12, ColorMode.RGB)
  fill(img, function(x, y) return rgba(180, 60 + x * 10, 40 + y * 8, 255) end)
  local c = spr:newCel(body, 1, img, Point(11, 10))
  c.data = "corpo"
  c.color = Color { r = 10, g = 200, b = 30, a = 255 }
  c.properties.pose = "idle"
  local group = spr:newGroup()
  group.name = "equip"
  group.data = "grupo"
  local weapon = spr:newLayer()
  weapon.name = "weapon_bow_l1"
  weapon.parent = group
  weapon.blendMode = BlendMode.MULTIPLY
  weapon.opacity = 180
  weapon.color = Color { r = 255, g = 0, b = 0, a = 255 }
  weapon.properties.slot = "weapon"
  weapon.properties.level = 1
  local w = Image(14, 3, ColorMode.RGB)
  fill(w, function(x, y) return rgba(90, 70, 40 + x * 9, 200) end)
  local wc = spr:newCel(weapon, 1, w, Point(6, 14))
  wc.zIndex = -1
  wc.opacity = 220
  local inner = spr:newGroup()
  inner.name = "fx"
  inner.parent = group
  local glow = spr:newLayer()
  glow.name = "overlay"
  glow.parent = inner
  glow.blendMode = BlendMode.SCREEN
  local g = Image(6, 6, ColorMode.RGB)
  fill(g, function(x, y) return rgba(250, 230, 120, 40 * (x + y) % 256) end)
  spr:newCel(glow, 1, g, Point(20, 2))
  local hidden = spr:newLayer()
  hidden.name = "References"
  hidden.isVisible = false
  spr:newCel(hidden, 1, img, Point(0, 0))
  inner.isVisible = true
  spr:newFrame(1)
  spr:newFrame(2)
  spr.frames[1].duration = 0.1
  spr.frames[2].duration = 0.15
  spr.frames[3].duration = 0.2
  local moved = spr:newCel(weapon, 2, w, Point(8, 13))
  moved.zIndex = 2
  local tags = { { 1, 3, "idle", AniDir.FORWARD, 0 }, { 1, 2, "walk", AniDir.REVERSE, 2 },
    { 2, 3, "attack", AniDir.PING_PONG, 3 }, { 3, 3, "die", AniDir.PING_PONG_REVERSE, 1 } }
  for i, t in ipairs(tags) do
    local tag = spr:newTag(t[1], t[2])
    tag.name = t[3]
    tag.aniDir = t[4]
    tag.repeats = t[5]
    tag.color = Color { r = 40 * i, g = 100, b = 255 - 40 * i, a = 255 }
    tag.data = "tag " .. t[3]
    tag.properties.loop = (i % 2 == 0)
  end
  local pivot = spr:newSlice(Rectangle(0, 0, 32, 24))
  pivot.name = "pivot"
  pivot.pivot = Point(16, 22)
  pivot.properties.kind = "pivot"
  local nine = spr:newSlice(Rectangle(4, 4, 20, 12))
  nine.name = "socket_hand"
  nine.center = Rectangle(2, 2, 16, 8)
  nine.data = "mao"
  nine.color = Color { r = 0, g = 0, b = 255, a = 255 }
  spr.data = "sprite"
  spr.properties.contract = "royal_80"
  spr.properties.cells = { 64, 64 }
  spr.properties.pivot = Point(40, 78)
  spr.properties.box = Rectangle(1, 2, 3, 4)
  spr.properties.scale = 0.5
  spr.properties.nested = { slot = "body", tags = { "idle", "walk" }, ok = true }
  spr:saveAs(out .. "/structure.aseprite")
  spr:close()
end

-- 4: Indexed com indice transparente 5, cores com alfa, camada de fundo e opacidades (que o export indexado
-- ignora).
do
  local spr = Sprite(16, 16, ColorMode.INDEXED)
  local pal = Palette(12)
  for i = 0, 11 do
    pal:setColor(i, Color { r = i * 20, g = 255 - i * 20, b = (i * 50) % 256, a = i == 7 and 128 or 255 })
  end
  spr:setPalette(pal)
  spr.transparentColor = 5
  local base = spr.layers[1]
  local img = Image(16, 16, ColorMode.INDEXED)
  fill(img, function(x, y) return (x + y) % 12 end)
  spr:newCel(base, 1, img, Point(0, 0))
  app.command.BackgroundFromLayer()
  local top = spr:newLayer()
  top.name = "top"
  top.opacity = 100
  top.blendMode = BlendMode.MULTIPLY
  local t = Image(8, 8, ColorMode.INDEXED)
  fill(t, function(x, y) return (x * y) % 12 end)
  spr:newCel(top, 1, t, Point(4, 4))
  spr:saveAs(out .. "/indexed.aseprite")
  spr:close()
end

-- 5: um tilemap com tileset de pecas 4x4 e as tres inversoes.
do
  local spr = Sprite(16, 12, ColorMode.RGB)
  app.command.NewLayer { tilemap = true, gridBounds = Rectangle { 0, 0, 4, 4 } }
  local map = app.layer
  map.name = "terrain"
  spr:deleteLayer(spr.layers[1])
  for k = 1, 3 do
    local tile = spr:newTile(map.tileset, k)
    fill(tile.image, function(x, y) return rgba(60 * k, 20 * x + 10, 30 * y + 5, x == y and 128 or 255) end)
  end
  local tiles = Image(ImageSpec { width = 4, height = 3, colorMode = ColorMode.TILEMAP })
  local P = app.pixelColor
  local flags = { 0, P.TILE_XFLIP, P.TILE_YFLIP, P.TILE_DFLIP }
  fill(tiles, function(x, y) return ((x + y) % 4) | flags[(x + 2 * y) % 4 + 1] end)
  spr:newCel(map, 1, tiles, Point(0, 0))
  spr:saveAs(out .. "/tilemap.aseprite")
  spr:close()
end
