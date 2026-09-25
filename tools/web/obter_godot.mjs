// tools/web/obter_godot.mjs — o motor fixado e o template Web, para um build sem
// nada instalado (a Vercel, ou um checkout frio).
//
// A versão é a de `.godot-version`, e mais nenhuma: é a mesma regra da acção
// `.github/actions/godot` — um número vive num sítio. As duas coisas saem dos
// releases oficiais do Godot por pedidos parciais (zip_remoto.mjs): do .zip do
// motor tira-se o binário, e do .tpz de 1,2 GB tira-se só o template Web sem
// threads, que é o que o preset `Web` do export_presets.cfg usa.
//
// Com cache: se o que lá está já tem o tamanho certo, não se volta a descarregar.
//
//   node tools/web/obter_godot.mjs <pasta-da-cache>   → escreve <pasta>/godot-<versão>
//   node tools/web/obter_godot.mjs <pasta> --so-templates   → só o template (motor já há)

import {
  existsSync, readFileSync, statSync, chmodSync, mkdirSync, copyFileSync, writeFileSync,
} from "node:fs";
import { join, resolve, dirname } from "node:path";
import { homedir } from "node:os";
import { fileURLToPath } from "node:url";
import { extrair } from "./zip_remoto.mjs";

const RAIZ = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
const BASE = "https://github.com/godotengine/godot-builds/releases/download";
// O template que o preset Web pede: thread_support desligado, release.
const TEMPLATE = "web_nothreads_release.zip";

function pronto(ficheiro, minimo) {
  return existsSync(ficheiro) && statSync(ficheiro).size >= minimo;
}

export async function obter(cache, { motor: comMotor = true } = {}) {
  const V = readFileSync(join(RAIZ, ".godot-version"), "utf8").trim();
  if (!V) throw new Error("obter_godot: .godot-version está vazio");
  mkdirSync(cache, { recursive: true });

  // O motor. 4.6-stable -> Godot_v4.6-stable_linux.x86_64 dentro do .zip.
  const motor = join(cache, `godot-${V}`);
  if (comMotor) {
    if (!pronto(motor, 1e6)) {
      const nome = `Godot_v${V}_linux.x86_64`;
      await extrair(`${BASE}/${V}/${nome}.zip`, [[nome, motor]]);
    }
    chmodSync(motor, 0o755);
  }

  // Os templates vivem onde o Godot os procura: XDG_DATA_HOME, ou ~/.local/share.
  // A pasta tem o nome da versão com ponto: 4.6-stable -> 4.6.stable.
  const dados = process.env.XDG_DATA_HOME || join(homedir(), ".local", "share");
  const pasta = join(dados, "godot", "export_templates", V.replace("-", "."));
  const template = join(pasta, TEMPLATE);
  if (!pronto(template, 1e6)) {
    // Guarda-se também na cache: é o que sobrevive entre builds na Vercel.
    const guardado = join(cache, `${V}-${TEMPLATE}`);
    if (!pronto(guardado, 1e6)) {
      await extrair(`${BASE}/${V}/Godot_v${V}_export_templates.tpz`, [
        [`templates/${TEMPLATE}`, guardado],
      ]);
    }
    mkdirSync(pasta, { recursive: true });
    copyFileSync(guardado, template);
    writeFileSync(join(pasta, "version.txt"), V.replace("-", ".") + "\n");
  }
  return { versao: V, motor, template };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const args = process.argv.slice(2);
  const soTemplates = args.includes("--so-templates");
  const pasta = args.find((a) => !a.startsWith("--"));
  const cache = resolve(pasta || join(RAIZ, "node_modules", ".cache", "empire"));
  const { versao, motor, template } = await obter(cache, { motor: !soTemplates });
  console.log(`obter_godot: Godot ${versao}`);
  if (!soTemplates) console.log(`obter_godot: motor em ${motor}`);
  console.log(`obter_godot: template em ${template}`);
}
