"""Isolate the generated wooden ladder by its connected alpha component."""
from collections import Counter
from PIL import Image


def access_ladder(plate):
    part = plate.crop((0, 0, round(plate.width * .29), plate.height))
    width, height = part.size
    pixels, seen, candidates = list(part.getdata()), set(), []
    for start, pixel in enumerate(pixels):
        if pixel[3] < 128 or start in seen:
            continue
        stack, component = [start], []
        seen.add(start)
        while stack:
            index = stack.pop()
            component.append(index)
            x, y = index % width, index // width
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                neighbour = ny * width + nx
                if (0 <= nx < width and 0 <= ny < height and neighbour not in seen
                        and pixels[neighbour][3] >= 128):
                    seen.add(neighbour)
                    stack.append(neighbour)
        xs, ys = [i % width for i in component], [i // width for i in component]
        box = (min(xs), min(ys), max(xs) + 1, max(ys) + 1)
        w, h = box[2] - box[0], box[3] - box[1]
        wood = sum(pixels[i][0] > pixels[i][1] * 1.05 for i in component) / len(component)
        if 2.0 <= h / w <= 9.0 and h >= height * .18 and wood > .35:
            candidates.append((h * wood, box, component))
    assert candidates, "The generated prop atlas contains no isolated wooden ladder"
    _, box, component = max(candidates, key=lambda item: item[0])
    image = part.crop(box)
    mask = Image.new("L", image.size)
    for index in component:
        mask.putpixel((index % width - box[0], index // width - box[1]), 255)
    image.putalpha(mask)
    return image.resize((24, 51), Image.Resampling.NEAREST)


def close_water_border(image):
    water = [p for p in image.crop((0, 618, 1280, 688)).getdata()
             if p[3] >= 128 and max(p[1], p[2]) > p[0] * 1.1]
    assert water, "A water border needs an opaque water sample"
    base = Image.new("RGBA", (1280, 32), Counter(water).most_common(1)[0][0])
    edge = image.crop((0, 688, 1280, 720))
    alpha = bytes(p[3] if not (p[0] > 110 and p[1] > 100 and
                              p[0] > p[2] * 1.15 and p[1] > p[2] * 1.15) else 0
                  for p in edge.getdata())
    edge.putalpha(Image.frombytes("L", edge.size, alpha))
    base.alpha_composite(edge)
    image.paste(base, (0, 688))
    return image
