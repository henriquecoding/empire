# tools/perfilador.gd — o tempo de cada funcao de GDScript, sem abrir o editor (RG-18).
#
# Fora do jogo. Faz de editor: escuta o debugger remoto do motor, liga o perfilador
# "servers" (o mesmo do separador Profiler do editor) quando o tools/desempenho.gd diz
# que acabou de aquecer, soma FRAMES frames e escreve as funcoes por tempo proprio e por
# tempo total, por frame. E assim que se achou o que a auditoria de 08/10/2026 corrigiu.
#
#   godot --headless --path . -s tools/perfilador.gd -- 400 build/perfil.txt &
#   xvfb-run -a godot --path . --rendering-driver dummy --fixed-fps 30 --resolution 1280x720 \
#     --remote-debug tcp://127.0.0.1:6008 tools/desempenho.tscn -- --novo --frames 600
#
# O protocolo e o do core/debugger/remote_debugger.cpp do Godot 4.7: cada mensagem e um
# Array [nome, fio, dados] com o tamanho a frente (o put_var/get_var de um StreamPeer).
extends SceneTree

const PORTA := 6008
const LISTA := 70
## Quantas funcoes cada frame traz: todas as que correram, para a soma ser a do jogo.
const FUNCOES := 4000
const MS := 1000.0

var _servidor := TCPServer.new()
var _par: StreamPeerTCP
var _alvo := 400
var _saida := "build/perfil.txt"
var _fio := 0
var _ligado := false
var _frames := 0
var _assinaturas := {}
var _somas := {}  # assinatura -> [chamadas, proprio s, total s]
var _frame_s := 0.0
var _fisica_s := 0.0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_alvo = int(args[0])
	if args.size() > 1:
		_saida = args[1]
	_servidor.listen(PORTA, "127.0.0.1")
	print("perfilador: a escutar em %d" % PORTA)


func _process(_delta: float) -> bool:
	if _par == null:
		if _servidor.is_connection_available():
			_par = _servidor.take_connection()
		return false
	_par.poll()
	if _par.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		_escrever()
		return true
	while _par.get_available_bytes() > 4:
		var m: Variant = _par.get_var()
		if not m is Array or (m as Array).size() < 3:
			continue
		if _ler(m[0], int(m[1]), m[2]):
			_par.put_var(["profiler:servers", _fio, [false]])
			_escrever()
			return true
	return false


## Uma mensagem do jogo. Devolve se ja chegam os frames.
func _ler(nome: String, fio: int, dados: Array) -> bool:
	match nome:
		"desempenho:medir":
			_fio = fio
			_par.put_var(["profiler:servers", _fio, [true, [FUNCOES, false]]])
			_ligado = true
		"servers:function_signature":
			_assinaturas[int(dados[1])] = String(dados[0])
		"servers:profile_frame":
			if _ligado:
				_somar(dados)
				_frames += 1
	return _frames >= _alvo


## O ServersProfilerFrame do motor: seis numeros, os servidores, e as funcoes de 5 em 5.
func _somar(d: Array) -> void:
	_frame_s += float(d[1])
	_fisica_s += float(d[3])
	var i := 6
	var servidores: int = d[i]
	i += 1
	for _s in servidores:
		i += 2 + int(d[i + 1])
	var n: int = int(d[i]) / 5
	i += 1
	for _f in n:
		var soma: Array = _somas.get(int(d[i]), [0, 0.0, 0.0])
		soma[0] += int(d[i + 1])
		soma[1] += float(d[i + 2])
		soma[2] += float(d[i + 3])
		_somas[int(d[i])] = soma
		i += 5


func _escrever() -> void:
	var n := maxf(1.0, float(_frames))
	var linhas := PackedStringArray()
	linhas.append(
		(
			"%d frames | frame %.2f ms | fisica %.2f ms (medias, com o custo do perfilador)"
			% [_frames, _frame_s * MS / n, _fisica_s * MS / n]
		)
	)
	for coluna: int in [2, 1]:
		var ids := _somas.keys()
		ids.sort_custom(func(a: int, b: int) -> bool: return _somas[a][coluna] > _somas[b][coluna])
		linhas.append(
			(
				"== por tempo %s: ms/frame | chamadas/frame | a outra ms/frame"
				% ("total" if coluna == 2 else "proprio")
			)
		)
		for k: int in ids.slice(0, LISTA):
			var s: Array = _somas[k]
			(
				linhas
				. append(
					(
						"%8.3f %9.1f %8.3f  %s"
						% [
							s[coluna] * MS / n,
							s[0] / n,
							s[3 - coluna] * MS / n,
							_assinaturas.get(k, "?"),
						]
					)
				)
			)
	var ficheiro := FileAccess.open(_saida, FileAccess.WRITE)
	ficheiro.store_string("\n".join(linhas) + "\n")
	ficheiro.close()
	print("perfilador: %s (%d frames)" % [_saida, _frames])
	quit()
