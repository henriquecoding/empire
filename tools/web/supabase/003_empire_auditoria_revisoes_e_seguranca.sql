-- Auditoria 11/10/2026: aditiva e compativel com o site anterior durante o deploy.
BEGIN;

ALTER TABLE public.empire_feedback ADD COLUMN IF NOT EXISTS revisao integer NOT NULL DEFAULT 1;
ALTER TABLE public.empire_feedback ADD COLUMN IF NOT EXISTS client_nonce uuid;
CREATE UNIQUE INDEX IF NOT EXISTS empire_feedback_client_nonce_key ON public.empire_feedback(client_nonce);
ALTER TABLE public.empire_respostas ADD COLUMN IF NOT EXISTS revisao integer NOT NULL DEFAULT 1;
ALTER TABLE public.empire_respostas ADD COLUMN IF NOT EXISTS proposta_texto text;
ALTER TABLE public.empire_respostas ADD COLUMN IF NOT EXISTS proposta_hash text;
ALTER TABLE public.empire_respostas ADD COLUMN IF NOT EXISTS fonte_sha text;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'empire_respostas_proposta_snapshot') THEN
    ALTER TABLE public.empire_respostas ADD CONSTRAINT empire_respostas_proposta_snapshot CHECK (
      (proposta_texto IS NULL AND proposta_hash IS NULL AND fonte_sha IS NULL) OR
      (proposta_texto IS NOT NULL AND char_length(proposta_texto) <= 20000 AND
       proposta_hash IS NOT NULL AND proposta_hash ~ '^[a-f0-9]{64}$' AND
       fonte_sha IS NOT NULL AND fonte_sha ~ '^[a-f0-9]{40}$')
    );
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.empire_revisao()
RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  NEW.revisao := CASE WHEN TG_OP = 'UPDATE' THEN OLD.revisao + 1 ELSE 1 END;
  IF TG_TABLE_NAME = 'empire_respostas' THEN
    IF NEW.proposta_texto IS NOT NULL THEN
      NEW.proposta_hash := pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(NEW.proposta_texto, 'UTF8')), 'hex');
    END IF;
  END IF;
  RETURN NEW;
END $$;
REVOKE EXECUTE ON FUNCTION public.empire_revisao() FROM PUBLIC, anon, authenticated;
CREATE OR REPLACE TRIGGER trg_empire_respostas_revisao BEFORE INSERT OR UPDATE ON public.empire_respostas
  FOR EACH ROW EXECUTE FUNCTION public.empire_revisao();
CREATE OR REPLACE TRIGGER trg_empire_feedback_revisao BEFORE INSERT OR UPDATE ON public.empire_feedback
  FOR EACH ROW EXECUTE FUNCTION public.empire_revisao();

CREATE TABLE IF NOT EXISTS public.empire_respostas_historico (
  pergunta text NOT NULL,
  revisao integer NOT NULL,
  resposta jsonb NOT NULL,
  arquivado_em timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (pergunta, revisao)
);
ALTER TABLE public.empire_respostas_historico ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.empire_respostas_historico FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.empire_respostas_historico TO authenticated;
GRANT ALL ON public.empire_respostas_historico TO service_role;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'empire_respostas_historico'
    AND policyname = 'empire_respostas_historico_admin') THEN
    CREATE POLICY empire_respostas_historico_admin ON public.empire_respostas_historico
      FOR SELECT TO authenticated USING ((SELECT public.empire_e_admin()));
  END IF;
END $$;

CREATE SCHEMA IF NOT EXISTS empire_private;
REVOKE ALL ON SCHEMA empire_private FROM PUBLIC, anon, authenticated;
CREATE OR REPLACE FUNCTION empire_private.arquivar_resposta()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  INSERT INTO public.empire_respostas_historico(pergunta, revisao, resposta)
    VALUES (NEW.pergunta, NEW.revisao, to_jsonb(NEW));
  RETURN NEW;
END $$;
REVOKE EXECUTE ON FUNCTION empire_private.arquivar_resposta() FROM PUBLIC, anon, authenticated;
INSERT INTO public.empire_respostas_historico(pergunta, revisao, resposta)
  SELECT pergunta, revisao, to_jsonb(r) FROM public.empire_respostas r ON CONFLICT DO NOTHING;
CREATE OR REPLACE TRIGGER trg_empire_respostas_historico AFTER INSERT OR UPDATE ON public.empire_respostas
  FOR EACH ROW EXECUTE FUNCTION empire_private.arquivar_resposta();

CREATE OR REPLACE FUNCTION public.empire_feedback_teto()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  -- Lock partilhado por todos os pedidos REST, retido ate COMMIT/ROLLBACK.
  PERFORM pg_catalog.pg_advisory_xact_lock(1212765778, 1);
  NEW.criado_em := clock_timestamp();
  IF NEW.client_nonce IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.empire_feedback WHERE client_nonce = NEW.client_nonce
  ) THEN RETURN NULL; END IF;
  IF (SELECT count(*) FROM public.empire_feedback WHERE criado_em > clock_timestamp() - interval '10 minutes') >= 30
    OR (SELECT count(*) FROM public.empire_feedback WHERE criado_em > clock_timestamp() - interval '1 day') >= 500 THEN
    RAISE EXCEPTION 'Recebemos demasiados reportes nos últimos minutos. Tenta outra vez mais tarde.'
      USING ERRCODE = 'P0001', HINT = 'empire_feedback_teto';
  END IF;
  RETURN NEW;
END $$;
REVOKE EXECUTE ON FUNCTION public.empire_feedback_teto() FROM PUBLIC, anon, authenticated;
GRANT INSERT(client_nonce) ON public.empire_feedback TO anon, authenticated;

REVOKE TRUNCATE, TRIGGER, REFERENCES ON public.empire_feedback, public.empire_respostas, public.empire_admins
  FROM PUBLIC, anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.empire_admins FROM PUBLIC, anon, authenticated;
REVOKE UPDATE ON public.empire_feedback FROM authenticated;
GRANT UPDATE(estado, nota_admin) ON public.empire_feedback TO authenticated;
REVOKE UPDATE ON public.empire_respostas FROM authenticated;
GRANT UPDATE(escolha, texto, titulo, estado, proposta_texto, proposta_hash, fonte_sha)
  ON public.empire_respostas TO authenticated;
REVOKE EXECUTE ON FUNCTION public.rls_auto_enable() FROM PUBLIC, anon, authenticated;

NOTIFY pgrst, 'reload schema';
COMMIT;
