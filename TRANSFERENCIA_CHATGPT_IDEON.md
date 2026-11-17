# TRANSFERÊNCIA COMPLETA DO PROJETO IDEON

Este documento reúne o contexto técnico e as instruções para continuar o IDEON em outra conta do ChatGPT. O repositório GitHub é a fonte principal dos arquivos; este documento não substitui nem copia os arquivos de código.

## 1. Projeto

IDEON é uma plataforma para capturar, desenvolver, publicar e descobrir ideias, com visão de evoluir para uma comunidade/rede social com recursos de IA.

### Identidade visual
- Direção aprovada: estilo 100% Apple.
- Visual minimalista, premium e moderno.
- Paleta principal: branco, preto e cinza.
- Tipografia de sistema/SF Pro quando disponível.
- Ícones finos; modo escuro opcional.

## 2. Repositório e arquivos

Repositório público (branch principal: `main`):
https://github.com/oliveiradiasbruno226-collab/ideon-projeto-2026

Arquivos confirmados na branch `main`:
- `index.html` — protótipo web atual.
  https://github.com/oliveiradiasbruno226-collab/ideon-projeto-2026/blob/main/index.html
- `README.md` — documentação técnica e estado do produto.
  https://github.com/oliveiradiasbruno226-collab/ideon-projeto-2026/blob/main/README.md
- `supabase/schema.sql` — schema base: perfis, publicações, seguidores, curtidas, comentários, projetos, tarefas, notificações, RLS e bucket de mídia.
  https://github.com/oliveiradiasbruno226-collab/ideon-projeto-2026/blob/main/supabase/schema.sql
- `supabase/migrations/202611170001_social_network.sql` — expansão social: configurações de privacidade, Stories, visualizações, salvos, conversas, mensagens, bloqueios, denúncias, notificações e preparação para Realtime.
  https://github.com/oliveiradiasbruno226-collab/ideon-projeto-2026/blob/main/supabase/migrations/202611170001_social_network.sql

Não foram confirmados outros arquivos no diretório raiz além dos listados. Não presumir que existam imagens, assets, pacote npm, app Expo ou funções Edge já implementadas.

## 3. Estado real do produto

O site atual é um protótipo estático em `index.html`. Ele permite criar, pesquisar, filtrar, favoritar e ler ideias, mantendo os dados no armazenamento local do navegador, na chave:
`localStorage["ideon_ideas"]`.

O protótipo ainda NÃO tem:
- cadastro/login funcional;
- banco remoto conectado;
- feed compartilhado entre usuários;
- Stories reais;
- mensagens diretas;
- curtidas/comentários públicos;
- notificações funcionais;
- sincronização entre dispositivos;
- assistente de IA conectado.

As curtidas e favoritos existentes são locais no navegador. Não anunciar esses recursos como rede social funcional.

## 4. Estado do Supabase

Os scripts SQL já estão no GitHub, mas o estado registrado do projeto é que o Supabase ainda não foi implantado/testado e a interface ainda não está conectada.

Ordem prevista:
1. Criar/abrir o projeto Supabase.
2. No SQL Editor, executar o conteúdo completo de `supabase/schema.sql`.
3. Depois executar o conteúdo completo de `supabase/migrations/202611170001_social_network.sql`.
4. Revisar erros e validar as tabelas, policies RLS, triggers, bucket e publicação Realtime.
5. Configurar Auth e URLs de redirecionamento.
6. Só então integrar o front-end usando Project URL e chave publishable/anon.
7. Nunca expor a chave `service_role` no navegador, GitHub ou mensagens.

Não afirmar que o banco está funcionando até executar e testar os scripts num projeto real.

## 5. Preservação de dados locais

ATENÇÃO: não limpar os dados do Safari nem apagar a chave `ideon_ideas` do armazenamento local. Antes de integrar autenticação, implementar migração das ideias locais para a conta autenticada, com prevenção de duplicatas e confirmação de que os registros chegaram ao banco. Não remover os dados locais até a migração ser confirmada.

## 6. Próximas etapas recomendadas

1. Fazer backup/baixar uma cópia do repositório atual.
2. Revisar o protótipo e manter as funções locais que já funcionam.
3. Criar e validar o projeto Supabase com os dois SQLs, na ordem indicada.
4. Integrar Supabase Auth: cadastro, login, logout e recuperação de senha.
5. Conectar perfil e sincronização das ideias com migração segura dos dados locais.
6. Implementar feed, perfis, seguir, curtidas, comentários e salvos.
7. Implementar Stories e upload de mídia.
8. Implementar conversas, mensagens, notificações, bloqueios e denúncias.
9. Criar Edge Functions para tarefas privilegiadas, moderação e integração segura com IA.
10. Testar permissões RLS com pelo menos duas contas diferentes, além de testes de segurança, acessibilidade e mobile.
11. Atualizar documentação para refletir somente o que foi realmente testado.

## 7. Restrições de trabalho do proprietário

- O proprietário trabalha principalmente pelo iPhone 14.
- Priorizar instruções simples, numeradas e adequadas ao celular.
- Priorizar soluções gratuitas e evitar gastos sem autorização.
- Não pedir para reconstruir o IDEON do zero.
- Não substituir arquivos nem executar migrações destrutivas sem explicar o impacto e obter autorização.
- Preservar o código existente e os dados locais.
- O proprietário deseja continuidade prática, não apenas explicações teóricas.

## 8. Prompt para a nova conta do ChatGPT

Estou transferindo o projeto IDEON para esta conta. Leia este documento e examine o repositório público:
https://github.com/oliveiradiasbruno226-collab/ideon-projeto-2026

Comece analisando os arquivos reais, especialmente `index.html`, `README.md`, `supabase/schema.sql` e `supabase/migrations/202611170001_social_network.sql`. Não confunda este projeto com o SUPER TRADUTOR AI.

Quero continuar exatamente do estado registrado: protótipo estático funcional localmente; scripts SQL no GitHub; Supabase ainda não implantado/testado; front-end ainda não conectado. Antes de alterar qualquer coisa, explique o que encontrou, confirme o que já funciona e proponha o próximo passo mais seguro. Não reconstrua do zero, não apague dados locais e não exponha segredos. Dê instruções passo a passo compatíveis com iPhone.

---
Documento de continuidade. Consulte sempre o repositório para verificar a versão mais recente dos arquivos.
