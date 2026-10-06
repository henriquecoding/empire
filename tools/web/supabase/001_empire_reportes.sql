-- tools/web/supabase/001_empire_reportes.sql — o Supabase do Empire, completo (ADR 0026).
--
-- Tudo o que o site precisa num projeto Supabase VAZIO, sem depender de nada que
-- lá exista: a administração, a limpeza de texto, os reportes do jogo e as
-- respostas às perguntas do docs/QUESTIONS.md. O desenho é o da Central de
-- Feedback do Recibo Certo (a migração 018 de lá: envio público, leitura só da
-- administração, código bloqueado no cliente e limpo outra vez aqui) — copiado,
-- e não ligado: este ficheiro não toca em base de dados nenhuma do Recibo Certo.
--
-- COMO SE USA
--   1. Cria um projeto no Supabase (ou usa um que já tenhas).
--   2. SQL Editor → cola este ficheiro inteiro → Run. É idempotente: correr
--      outra vez não estraga nada. Depois, da mesma maneira, a
--      002_empire_reportes_teto.sql (a hora do servidor e o teto do envio).
--   3. Authentication → Users → Add user: o teu email e uma palavra-passe.
--   4. Torna-te administrador (troca o email):
--        insert into public.empire_admins (user_id)
--        select id from auth.users where email = 'o-teu@email.pt'
--        on conflict do nothing;
--   5. Project Settings → API: copia o "Project URL" e a chave "publishable"
--      (sb_publishable_...) para a Vercel, como EMPIRE_SUPABASE_URL e
--      EMPIRE_SUPABASE_CHAVE (ou para tools/web/supabase/config.json).
--   6. Authentication → Sign In / Providers: desliga "Allow new users to sign
--      up" — só a administração precisa de conta, e o envio de reportes não a
--      pede.
--
-- O QUE FICA
--   empire_admins       quem administra (só o próprio se vê; escreve-se no SQL)
--   empire_e_admin()    a pergunta que as políticas fazem, e a que o painel faz
--   empire_feedback     reportes, sugestões e dúvidas: qualquer pessoa envia,
--                       só a administração lê, muda o estado e apaga
--   empire_respostas    a resposta a cada pergunta do QUESTIONS.md: só a
--                       administração lê e escreve

-- ── Administração ───────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.empire_admins (
  user_id    uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  criado_em  timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.empire_admins IS
  'Quem administra o Empire. Escreve-se só pelo SQL Editor (service role): não há política de escrita pela API.';

ALTER TABLE public.empire_admins ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies
                 WHERE tablename = 'empire_admins' AND policyname = 'empire_admins_proprio') THEN
    CREATE POLICY "empire_admins_proprio" ON public.empire_admins
      FOR SELECT TO authenticated USING (user_id = auth.uid());
  END IF;
END $$;

-- SECURITY DEFINER para as políticas das outras tabelas a poderem chamar sem
-- dar a ninguém leitura da lista de administradores.
CREATE OR REPLACE FUNCTION public.empire_e_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = ''
AS $$
  SELECT EXISTS (SELECT 1 FROM public.empire_admins WHERE user_id = auth.uid());
$$;

REVOKE EXECUTE ON FUNCTION public.empire_e_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.empire_e_admin() TO authenticated, service_role;

-- ── Limpeza de texto (a mesma da 018 do Recibo Certo) ───────────────────────
-- O site nunca mostra isto como HTML, mas limpa-se à mesma: alguém pode chamar
-- a API sem passar pelo site.

CREATE OR REPLACE FUNCTION public.empire_sem_tags(t text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT CASE WHEN t IS NULL THEN NULL
              ELSE regexp_replace(t, '</?[A-Za-z!][^>]*>', '', 'g') END;
$$;

-- ── empire_feedback ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.empire_feedback (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo          text NOT NULL
                CHECK (tipo IN ('sugestao', 'erro', 'duvida', 'mensagem')),
  mensagem      text NOT NULL CHECK (char_length(mensagem) BETWEEN 1 AND 4000),
  assunto       text CHECK (assunto IS NULL OR char_length(assunto) <= 160),
  area          text CHECK (area IS NULL OR char_length(area) <= 200),    -- página ou ecrã
  nome          text CHECK (nome IS NULL OR char_length(nome) <= 80),
  email         text CHECK (email IS NULL OR char_length(email) <= 254),
  versao        text CHECK (versao IS NULL OR char_length(versao) <= 64), -- o commit publicado
  estado        text NOT NULL DEFAULT 'novo'
                CHECK (estado IN ('novo', 'em_analise', 'valido', 'resolvido', 'rejeitado')),
  nota_admin    text CHECK (nota_admin IS NULL OR char_length(nota_admin) <= 4000),
  criado_em     timestamptz NOT NULL DEFAULT now(),
  resolvido_em  timestamptz
);

COMMENT ON TABLE public.empire_feedback IS
  'Reportes, sugestões e dúvidas sobre o Empire. Qualquer pessoa envia; só a administração lê. Sem user_id nem IP: quem quer resposta deixa o email.';

CREATE INDEX IF NOT EXISTS empire_feedback_criado_idx ON public.empire_feedback(criado_em DESC);
CREATE INDEX IF NOT EXISTS empire_feedback_estado_idx ON public.empire_feedback(estado);

ALTER TABLE public.empire_feedback ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  -- Qualquer pessoa envia, mas só um reporte novo e sem nota: o estado e a
  -- nota são da administração.
  IF NOT EXISTS (SELECT 1 FROM pg_policies
                 WHERE tablename = 'empire_feedback' AND policyname = 'empire_feedback_insert') THEN
    CREATE POLICY "empire_feedback_insert" ON public.empire_feedback
      FOR INSERT TO anon, authenticated
      WITH CHECK (estado = 'novo' AND nota_admin IS NULL AND resolvido_em IS NULL);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies
                 WHERE tablename = 'empire_feedback' AND policyname = 'empire_feedback_admin_select') THEN
    CREATE POLICY "empire_feedback_admin_select" ON public.empire_feedback
      FOR SELECT TO authenticated USING (public.empire_e_admin());
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies
                 WHERE tablename = 'empire_feedback' AND policyname = 'empire_feedback_admin_update') THEN
    CREATE POLICY "empire_feedback_admin_update" ON public.empire_feedback
      FOR UPDATE TO authenticated
      USING (public.empire_e_admin()) WITH CHECK (public.empire_e_admin());
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies
                 WHERE tablename = 'empire_feedback' AND policyname = 'empire_feedback_admin_delete') THEN
    CREATE POLICY "empire_feedback_admin_delete" ON public.empire_feedback
      FOR DELETE TO authenticated USING (public.empire_e_admin());
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.empire_feedback_limpar()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  NEW.mensagem := COALESCE(public.empire_sem_tags(NEW.mensagem), '');
  NEW.assunto := public.empire_sem_tags(NEW.assunto);
  NEW.nome := public.empire_sem_tags(NEW.nome);
  NEW.area := public.empire_sem_tags(NEW.area);
  NEW.nota_admin := public.empire_sem_tags(NEW.nota_admin);
  IF TG_OP = 'UPDATE' AND NEW.estado IS DISTINCT FROM OLD.estado THEN
    NEW.resolvido_em := CASE WHEN NEW.estado IN ('valido', 'resolvido', 'rejeitado') THEN now() END;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_empire_feedback_limpar ON public.empire_feedback;
CREATE TRIGGER trg_empire_feedback_limpar
  BEFORE INSERT OR UPDATE ON public.empire_feedback
  FOR EACH ROW EXECUTE FUNCTION public.empire_feedback_limpar();

-- ── empire_respostas ────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.empire_respostas (
  pergunta        text PRIMARY KEY CHECK (pergunta ~ '^Q-[0-9]{3}$'),
  escolha         text NOT NULL CHECK (escolha IN ('aprovar', 'outra', 'adiar')),
  texto           text CHECK (texto IS NULL OR char_length(texto) <= 4000),
  titulo          text CHECK (titulo IS NULL OR char_length(titulo) <= 300), -- o título na altura
  estado          text NOT NULL DEFAULT 'nova' CHECK (estado IN ('nova', 'aplicada')),
  atualizado_em   timestamptz NOT NULL DEFAULT now(),
  atualizado_por  uuid DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE SET NULL
);

COMMENT ON TABLE public.empire_respostas IS
  'A resposta do dono a cada pergunta aberta do docs/QUESTIONS.md do Empire. Só a administração lê e escreve. «aplicada» quando o repositório já a tem.';

ALTER TABLE public.empire_respostas ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies
                 WHERE tablename = 'empire_respostas' AND policyname = 'empire_respostas_admin_all') THEN
    CREATE POLICY "empire_respostas_admin_all" ON public.empire_respostas
      FOR ALL TO authenticated
      USING (public.empire_e_admin()) WITH CHECK (public.empire_e_admin());
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.empire_respostas_carimbo()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  NEW.texto := public.empire_sem_tags(NEW.texto);
  NEW.titulo := public.empire_sem_tags(NEW.titulo);
  NEW.atualizado_em := now();
  NEW.atualizado_por := auth.uid();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_empire_respostas_carimbo ON public.empire_respostas;
CREATE TRIGGER trg_empire_respostas_carimbo
  BEFORE INSERT OR UPDATE ON public.empire_respostas
  FOR EACH ROW EXECUTE FUNCTION public.empire_respostas_carimbo();

-- ── Privilégios ─────────────────────────────────────────────────────────────
-- O RLS decide as linhas; isto decide as operações. Quem não tem sessão só
-- insere reportes, e mais nada.

REVOKE ALL ON public.empire_admins FROM anon;
REVOKE ALL ON public.empire_respostas FROM anon;
REVOKE ALL ON public.empire_feedback FROM anon;
GRANT INSERT ON public.empire_feedback TO anon;
GRANT SELECT ON public.empire_admins TO authenticated;
GRANT INSERT, SELECT, UPDATE, DELETE ON public.empire_feedback TO authenticated;
GRANT INSERT, SELECT, UPDATE, DELETE ON public.empire_respostas TO authenticated;
