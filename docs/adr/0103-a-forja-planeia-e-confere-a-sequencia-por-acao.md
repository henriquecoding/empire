# ADR 0103 — A Forja planeia e confere a sequência por ação

- Estado: aceite, no âmbito da auditoria pedida pelo dono
- Data: 2026-10-30
- Tarefa: [FORJA-17](../backlog/FORJA-17.md)
- Complementa ADRs 0094, 0097, 0100, 0101 e 0102.

## Problema

As regras de sprite individual não eram conservadas integralmente pela prancha. O caminho de animação
ignorava redução/cadeia, não expunha o modo de contorno e podia alterar uma ação usando outra como referência.
Previews reproduziam toda a tira em ciclo, independentemente das tags. Metadados incompletos podiam omitir
quadros. O pedido fiel mandava conservar a pose estática enquanto pedia uma sequência de poses diferentes.

## Decisão

1. O pedido inclui `forja.animation_plan/1`: tela, pivô, tags, cadência e chaves já fixadas nas bibles.
   Contactos e quadros de ação não são adivinhados. Contagens experimentais são estudos explícitos.
   Identidade, materiais, expressão e equipamento continuam vinculados ao conceito; as articulações seguem
   a ação. Os intermediários não se fabricam rodando um recorte rígido.
2. Tempos, telas, nomes, intervalos e cobertura da timeline são validados antes de exportar. `anim` recusa
   contagens incompatíveis. `sheet` conserva o diagnóstico de poses em falta/excesso; o excesso recebe
   tag `unassigned` e o contrato não passa. Holds exigem quadro, tempo válido e motivo.
3. A prancha conserva consulta, grade, perdas, transformação e hashes por quadro em
   `forja.animation_lineage/1`. A cadeia anterior tem de corresponder ao atlas de entrada e fica conservada.
   Redução herdada permanece diagnóstica. Uma cadeia de atlas não é aceite como a de um sprite individual.
   `--scale 1`, `--cells`, `--method`, `--reduce`, `--outline keep`, `--native-root` e `--lineage` não ficam
   silenciosamente sem efeito.
4. Deflicker e lock operam dentro de cada tag. Lock só altera uma pegada alfa compatível e preserva áreas
   de ação/proteção declaradas. Um rosto ocluído ou com silhueta diferente fica para revisão da pose.
5. Prévia e relatório reproduzem a direção, duração e loop da tag escolhida; ataques/mortes param no fim.
   GIF sem repetição omite `loop`; APNG usa uma reprodução, frames completos com blend SOURCE.
   A contagem de poses ignora RGB invisível. As medidas de cintilação respeitam limites entre ações.

## Limites

As medidas não aprovam anatomia, atuação ou biomecânica. A cadeia de animação documenta perdas, mas não
implementa um portão de aprovação artística de sequências equivalente ao `forja entrega` do mestre estático.
Nenhum novo asset foi integrado nem aprovado. A ligação aos endpoints de animação do PixelLab continua
explicitamente ausente; a pesquisa atual regista requisitos e incompatibilidades de contagem.

Essas duas lacunas são fechadas posteriormente pela [ADR 0104](0104-a-forja-gera-e-reve-animacoes-nativas.md),
com adaptadores, revisão da sequência e reparo nativo de quadros. As limitações de avaliação artística mantêm-se.

Sem dependências novas no projeto. Fontes primárias, casos reproduzidos e validação estão na
[auditoria](../art/research/2026-10-30-forja-auditoria/AUDITORIA.md).
