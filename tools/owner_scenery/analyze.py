"""Depth and sky masks for the owner's compositions (ADR 0086).

python analyze.py OUTDIR IMAGE...   (writes NAME_depth.npy, NAME_cls.npy and previews)

Depth Anything V2 (disparity: bigger is nearer) and SegFormer ADE20k on the composition
resized to the 1280 x 720 frame. separate.py reads both.
"""
import sys, os, json
import numpy as np, torch
from PIL import Image
from transformers import pipeline, AutoImageProcessor, SegformerForSemanticSegmentation
out = sys.argv[1]; files = sys.argv[2:]
torch.set_num_threads(4)
depth = pipeline('depth-estimation', model='depth-anything/Depth-Anything-V2-Large-hf', device='cpu')
proc = AutoImageProcessor.from_pretrained('nvidia/segformer-b5-finetuned-ade-640-640')
seg = SegformerForSemanticSegmentation.from_pretrained('nvidia/segformer-b5-finetuned-ade-640-640').eval()
labels = seg.config.id2label
rng = np.random.RandomState(3); pal = rng.randint(0, 255, (256, 3)).astype(np.uint8)
for f in files:
    name = os.path.splitext(os.path.basename(f))[0]
    im = Image.open(f).convert('RGB').resize((1280, 720), Image.LANCZOS)
    d = depth(im)['predicted_depth']
    d = torch.nn.functional.interpolate(d[None] if d.ndim == 3 else d[None, None], size=(720, 1280), mode='bicubic')[0, 0].numpy()
    np.save(os.path.join(out, name + '_depth.npy'), d.astype(np.float32))
    dn = (d - d.min()) / (d.max() - d.min()); Image.fromarray((dn * 255).astype(np.uint8)).save(os.path.join(out, name + '_depth.png'))
    # segformer, tiled at 640 crops for detail
    with torch.no_grad():
        inp = proc(images=im, return_tensors='pt', do_resize=True, size={'height': 720, 'width': 1280})
        logits = seg(**inp).logits
        logits = torch.nn.functional.interpolate(logits, size=(720, 1280), mode='bilinear')[0]
    np.save(os.path.join(out, name + '_logits.npy'), logits.numpy().astype(np.float16))
    cls = logits.argmax(0).numpy()
    np.save(os.path.join(out, name + '_cls.npy'), cls.astype(np.uint8))
    counts = {labels[int(c)]: int((cls == c).sum()) for c in np.unique(cls)}
    print(name, sorted(counts.items(), key=lambda kv: -kv[1])[:14])
    vis = (0.45 * np.asarray(im) + 0.55 * pal[cls]).astype(np.uint8)
    Image.fromarray(vis).save(os.path.join(out, name + '_cls.png'))
