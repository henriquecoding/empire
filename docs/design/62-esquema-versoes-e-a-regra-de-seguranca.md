# 62 — Save · Esquema, versões e a regra de segurança

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Como a simulação é pura, o save é quase trivial: serializa GameState, mais o estado dos fluxos RNG. As regras à volta é que não são negociáveis.

```gdscript
# O que um ficheiro de save contém
{
  save_version: int          # desde a v1, com migrações explícitas
  worldgen_version: int      # §54 — se mudar, o mundo é regenerado ou recusado
  created_utc: int
  play_seconds: int
  seed: int
  rng_states: Dictionary     # §42 — o ESTADO, não a semente
  intents_since_tick: Array  # para repetição, opcional
  state: Dictionary          # GameState serializado, campo a campo
}
```

| Regra | Porquê |
| --- | --- |
| Escreve para ficheiro temporário e só depois renomeia | Um crash a meio da escrita não pode destruir o save. Renomear é atómico; escrever não é. |
| save_version desde a v1, com migrações explícitas | Um jogador que perca 40 horas por causa de um update não volta. E não há v0 — a primeira versão já é a 1. |
| Três slots com rotação, em user:// | Autosave no DAWN de cada dia. Um save corrompido nunca é o único. |
| Nunca load() nem ResourceLoader.load — grava com FileAccess.store_var(dados, false), lê com FileAccess.get_var(false) e valida os tipos base campo a campo | Um .tres arbitrário pode conter script embutido. É execução remota de código disfarçada de save, e é a falha de segurança clássica de jogos Godot. |
| Campos desconhecidos são ignorados, não são erro | Permite ler um save de uma versão futura sem rebentar — degrada em vez de recusar. |


> **A migração escreve-se quando se muda o campo, não quando se lança**
>
> Cada alteração ao GameState acrescenta uma função _migrate_N_to_N1(d: Dictionary) no mesmo commit. Deixar as migrações para o fim é como deixar os testes para o fim: nunca acontece, e a dívida é paga com saves de jogadores.
