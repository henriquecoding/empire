# tests/flock_test.gd — o bando de Reynolds: vai para o rumo e nao se desfaz.
extends GdUnitTestSuite

const PASSO := 1.0 / 30.0


func _bando() -> Flock:
	var f := Flock.new()
	for i in 8:
		f.add(Vector2(float(i) * 12.0, 150.0 + float(i % 3) * 10.0), Vector2(40.0, 0.0))
	return f


func test_o_bando_vai_para_o_rumo() -> void:
	var f := _bando()
	var rumo := Vector2(900.0, 120.0)
	var antes := f.center().distance_to(rumo)
	for _i in 300:
		f.step(PASSO, rumo)
	assert_float(f.center().distance_to(rumo)).is_less(antes)


func test_ninguem_se_cola_nem_se_perde() -> void:
	var f := _bando()
	for _i in 600:
		f.step(PASSO, Vector2(400.0, 150.0))
	var centro := f.center()
	for i in f.size():
		assert_float(f.positions[i].distance_to(centro)).is_less(Flock.REGRAS.vizinho * 3)
		assert_float(f.velocities[i].length()).is_between(
			Flock.REGRAS.min - 0.01, Flock.REGRAS.max + 0.01
		)
		for j in range(i + 1, f.size()):
			assert_float(f.positions[i].distance_to(f.positions[j])).is_greater(1.0)
