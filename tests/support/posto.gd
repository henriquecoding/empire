# tests/support/posto.gd — quem trabalha numa obra, para os testes que medem o
# que ela rende (Q-121: uma obra com posto so rende inteiro com gente la).
extends RefCounted


## Um trabalhador teu, ja em cima de cada obra de pe com posto, e a ganancia do
## §15 a zero: quem mede a coluna "Payback" do §06 mede-a bruta, como o dossie.
static func staff_all() -> void:
	SimLoop.state.greed = 0
	var dono := SimLoop.units.owners[SimLoop.units.index_of(SimLoop.king_id)]
	var dados := Registry.entry(&"units", &"vagrant") as UnitData
	for obra in SimLoop.builds.slots:
		if obra.job_id != &"" and obra.standing() and obra.posts() > 0:
			for _k in obra.posts():
				SimLoop.units.spawn(SimLoop.state, dados, dono, obra.x)
