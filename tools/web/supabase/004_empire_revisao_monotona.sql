-- Uma pergunta recriada continua a sequencia: o historico e as abas antigas ficam validos.
BEGIN;
CREATE OR REPLACE FUNCTION public.empire_revisao()
RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    NEW.revisao := OLD.revisao + 1;
  ELSIF TG_TABLE_NAME = 'empire_respostas' THEN
    SELECT coalesce(max(revisao), 0) + 1 INTO NEW.revisao
      FROM public.empire_respostas_historico WHERE pergunta = NEW.pergunta;
  ELSE
    NEW.revisao := 1;
  END IF;
  IF TG_TABLE_NAME = 'empire_respostas' THEN
    IF NEW.proposta_texto IS NOT NULL THEN
      NEW.proposta_hash := pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(NEW.proposta_texto, 'UTF8')), 'hex');
    END IF;
  END IF;
  RETURN NEW;
END $$;
REVOKE EXECUTE ON FUNCTION public.empire_revisao() FROM PUBLIC, anon, authenticated;
NOTIFY pgrst, 'reload schema';
COMMIT;
