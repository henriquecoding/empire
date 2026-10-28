-- O plano gratuito do Supabase pausa o projeto ao fim de 7 dias sem atividade, e
-- o painel passa a dar «Failed to fetch» (28/10/2026, pela segunda vez). O
-- workflow .github/workflows/supabase-acordado.yml chama esta funcao de tres em
-- tres dias: um pedido real a base de dados, pela API, com a chave publicavel.
-- Nao le nenhuma tabela nem devolve dados. Aditiva e idempotente.
CREATE OR REPLACE FUNCTION public.empire_vivo()
RETURNS boolean LANGUAGE sql STABLE SET search_path = '' AS $$ SELECT true $$;
REVOKE EXECUTE ON FUNCTION public.empire_vivo() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.empire_vivo() TO anon, authenticated, service_role;
