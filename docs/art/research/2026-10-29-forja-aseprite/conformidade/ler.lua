-- O que o Aseprite ve num .aseprite, em JSON, para conferir o leitor e o escritor da Forja (FORJA-13).
-- Uso: aseprite -b <ficheiro.aseprite> --script-param out=<ficheiro.json> --script ler.lua

local spr = app.sprite
local out = app.params["out"]
-- A enumeracao do Lua numera os modos de outra maneira; o ficheiro usa 0 (normal) a 18 (divide).
local BLEND = {}
for i, m in ipairs({ BlendMode.NORMAL, BlendMode.MULTIPLY, BlendMode.SCREEN, BlendMode.OVERLAY, BlendMode.DARKEN,
  BlendMode.LIGHTEN, BlendMode.COLOR_DODGE, BlendMode.COLOR_BURN, BlendMode.HARD_LIGHT, BlendMode.SOFT_LIGHT,
  BlendMode.DIFFERENCE, BlendMode.EXCLUSION, BlendMode.HSL_HUE, BlendMode.HSL_SATURATION, BlendMode.HSL_COLOR,
  BlendMode.HSL_LUMINOSITY, BlendMode.ADDITION, BlendMode.SUBTRACT, BlendMode.DIVIDE }) do BLEND[m] = i - 1 end

local function field(v, k)
  local ok, r = pcall(function() return v[k] end)
  if ok then return r end
end

local function value(v)
  local t = type(v)
  if t == "userdata" then
    if field(v, "alpha") ~= nil then return { r = v.red, g = v.green, b = v.blue, a = v.alpha } end
    if field(v, "width") ~= nil and field(v, "x") ~= nil then return { x = v.x, y = v.y, w = v.width, h = v.height } end
    if field(v, "width") ~= nil then return { w = v.width, h = v.height } end
    if field(v, "x") ~= nil then return { x = v.x, y = v.y } end
    return tostring(v)
  elseif t == "table" then
    local o = {}
    for k, x in pairs(v) do o[k] = value(x) end
    return o
  end
  return v
end

local function props(obj)
  local o = {}
  for k, v in pairs(obj.properties) do o[k] = value(v) end
  return o
end

local function color(c)
  if c == nil or c.alpha == 0 then return nil end
  return { c.red, c.green, c.blue, c.alpha }
end

local function data(obj)
  return { text = obj.data ~= "" and obj.data or nil, color = color(obj.color), properties = props(obj) }
end

local layers = {}
local function walk(list, parent)
  for _, l in ipairs(list) do
    local e = { name = l.name, parent = parent, group = l.isGroup, tilemap = l.isTilemap,
      visible = l.isVisible, editable = l.isEditable, background = l.isBackground,
      continuous = l.isContinuous, reference = l.isReference, collapsed = l.isCollapsed,
      blend = BLEND[l.blendMode], opacity = l.opacity, user = data(l), cels = {} }
    if l.isTilemap then e.tileset = l.tileset.name end
    if not l.isGroup then
      for _, c in ipairs(l.cels) do
        table.insert(e.cels, { frame = c.frameNumber - 1, x = c.position.x, y = c.position.y,
          w = c.bounds.width, h = c.bounds.height, opacity = c.opacity, z = c.zIndex, user = data(c) })
      end
    end
    table.insert(layers, e)
    if l.isGroup then walk(l.layers, l.name) end
  end
end
walk(spr.layers, nil)

local tags = {}
for _, t in ipairs(spr.tags) do
  table.insert(tags, { name = t.name, from = t.fromFrame.frameNumber - 1, to = t.toFrame.frameNumber - 1,
    dir = t.aniDir, repeats = t.repeats, user = data(t) })
end

local slices = {}
for _, s in ipairs(spr.slices) do
  local e = { name = s.name, bounds = value(s.bounds), user = data(s) }
  if s.center then e.center = value(s.center) end
  if s.pivot then e.pivot = value(s.pivot) end
  table.insert(slices, e)
end
table.sort(slices, function(a, b) return a.name < b.name end) -- a ordem interna das slices nao conta

local frames = {}
for _, f in ipairs(spr.frames) do table.insert(frames, math.floor(f.duration * 1000 + 0.5)) end

-- Num RGB com a paleta toda preta, o Aseprite gera outra ao abrir: so a paleta Indexed e a do ficheiro.
local palette = {}
if spr.colorMode == ColorMode.INDEXED then
  local pal = spr.palettes[1]
  for i = 0, #pal - 1 do
    local c = pal:getColor(i)
    table.insert(palette, { c.red, c.green, c.blue, c.alpha })
  end
end

local tilesets = {}
for _, ts in ipairs(spr.tilesets) do
  table.insert(tilesets, { name = ts.name, w = ts.grid.tileSize.width, h = ts.grid.tileSize.height, count = #ts })
end

local modes = { [ColorMode.RGB] = "rgba", [ColorMode.GRAYSCALE] = "grayscale", [ColorMode.INDEXED] = "indexed" }
local doc = { width = spr.width, height = spr.height, mode = modes[spr.colorMode],
  transparent = spr.transparentColor, durations = frames, layers = layers, tags = tags, slices = slices,
  palette = palette, tilesets = tilesets, user = data(spr) }

local f = io.open(out, "w")
f:write(json.encode(doc))
f:close()
