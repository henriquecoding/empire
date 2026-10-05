# ADR 0068 — O servidor é a autoridade do mundo

- **Estado:** design aceite; rede por fazer (UN-31/RG-25).

`src/sim/` continua puro. A rede vive numa camada separada que autentica intenções,
verifica autor, sequência, permissão e limites, e as entrega ao tick autoritativo.
Clientes não declaram dinheiro, propriedade, dano, fundação, captura ou vitória.
Transações são idempotentes; reconectar restaura o PlayerSlot e o estado do servidor.

Solo conserva a mesma fronteira local de autoridade. Isso não constitui implementação
de rede nem proteção contra um executável Solo adulterado. Não há lockstep obrigatório.

GitHub mantém fonte/CI; Vercel publica site, painel e Web export. Supabase guarda hoje
respostas e feedback; não executa o SimLoop. Servidor Godot persistente, transporte Web/
nativo, provedor e armazenamento remoto serão escolhidos com benchmark, sem criar
serviços pagos ou chaves de servidor nesta alteração.
