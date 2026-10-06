-- tools/web/supabase/002_empire_reportes_teto.sql — o envio público com a hora do
-- servidor e com teto (relatório de auditoria de 06/10/2026: RISK-01, RISK-02).
--
-- Corre-se depois da 001, no SQL Editor ou como migração. É idempotente.
--
-- RISK-02 · criado_em tinha DEFAULT now(), mas um valor por omissão não impede quem
--   envia de mandar outro, e o painel ordena por ele: uma data futura ficava sempre
--   no topo da triagem. A hora passa a ser sempre a do servidor, e quem envia só
--   escreve as colunas do formulário.
--
-- RISK-01 · qualquer pessoa enviava sem limite. A tabela não guarda IP nem conta, e
--   isso fica (é a promessa do site); por isso o teto é do canal inteiro:
--     · o mesmo reporte (tipo, mensagem e email) dentro de dez minutos não se grava
--       outra vez — é o reenvio depois de uma falha de rede, e o envio diz que correu
--       bem;
--     · acima de 30 reportes em dez minutos, ou de 500 num dia, a base recusa com
--       uma mensagem que o site mostra a quem envia.
--   Um teto por origem pede guardar algo da origem: fica para o dono decidir.
--   O controlo vive na base, e não no site: um pedido REST direto passa por ele.

-- ── A hora e o teto, num gatilho que corre depois da limpeza ────────────────
-- SECURITY DEFINER para contar as linhas que quem envia não pode ler (RLS). A
-- função de gatilho não se chama pela API, e o EXECUTE fica fechado à mesma.

CREATE OR REPLACE FUNCTION public.empire_feedback_teto()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  NEW.criado_em := now();
  IF EXISTS (
    SELECT 1 FROM public.empire_feedback f
    WHERE f.criado_em > now() - interval '10 minutes'
      AND f.tipo = NEW.tipo
      AND f.mensagem = NEW.mensagem
      AND f.email IS NOT DISTINCT FROM NEW.email
  ) THEN
    RETURN NULL;
  END IF;
  IF (SELECT count(*) FROM public.empire_feedback f
      WHERE f.criado_em > now() - interval '10 minutes') >= 30
     OR (SELECT count(*) FROM public.empire_feedback f
         WHERE f.criado_em > now() - interval '1 day') >= 500 THEN
    RAISE EXCEPTION 'Recebemos demasiados reportes nos últimos minutos. Tenta outra vez mais tarde.'
      USING ERRCODE = 'P0001', HINT = 'empire_feedback_teto';
  END IF;
  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.empire_feedback_teto() FROM PUBLIC, anon, authenticated;

-- "limpar" corre antes de "teto" (os gatilhos BEFORE correm pela ordem do nome):
-- o reporte repetido compara-se já limpo.
CREATE OR REPLACE TRIGGER trg_empire_feedback_teto
  BEFORE INSERT ON public.empire_feedback
  FOR EACH ROW EXECUTE FUNCTION public.empire_feedback_teto();

-- ── Quem envia só escreve o formulário ──────────────────────────────────────
-- O id, o estado, a nota, as datas: tudo o resto vem do valor por omissão ou do
-- gatilho. A administração continua a mudar o estado e a nota pelo UPDATE.

REVOKE INSERT ON public.empire_feedback FROM anon, authenticated;
GRANT INSERT (tipo, mensagem, assunto, area, nome, email, versao)
  ON public.empire_feedback TO anon, authenticated;

-- ── Reforço que os advisors pediram ─────────────────────────────────────────
-- A chave estrangeira de quem respondeu, com índice; e o auth.uid() da política
-- avaliado uma vez por pedido, e não uma vez por linha.

CREATE INDEX IF NOT EXISTS empire_respostas_atualizado_por_idx
  ON public.empire_respostas(atualizado_por);

ALTER POLICY "empire_admins_proprio" ON public.empire_admins
  USING (user_id = (SELECT auth.uid()));
