# IDEON

IDEON é uma plataforma social para capturar, desenvolver, publicar e descobrir ideias. A identidade visual é própria, com feed social e leitura editorial.

## Estado do produto

O site publicado em GitHub Pages ainda é um protótipo estático (index.html). Ele permite criar, pesquisar, filtrar, favoritar e ler ideias no armazenamento local do navegador.

**Ainda não está conectado a um backend.** Portanto, login, feed compartilhado, Stories, mensagens, curtidas públicas, comentários, notificações, sincronização e IA não estão ativos no site. Os arquivos de infraestrutura abaixo preparam a base para essas funções, mas não criam automaticamente um serviço Supabase nem conectam a interface.

## Infraestrutura preparada

### Banco de dados

- supabase/schema.sql: fundação original — perfis, publicações, seguidores, curtidas, comentários, projetos, tarefas, notificações, RLS e bucket de mídia.
- supabase/migrations/202611170001_social_network.sql: expansão social — Stories de 24 horas e visualizações, salvos, conversas, participantes, mensagens, bloqueios, denúncias, preferências de privacidade, notificações automáticas para seguir/curtir/comentar e tabelas preparadas para Realtime.

### Recursos previstos

| Recurso | Infraestrutura | Estado no aplicativo |
|---|---|---|
| Cadastro e login | Supabase Auth | Aguardando conexão |
| Perfis e privacidade | profiles, user_settings | Aguardando conexão |
| Feed e publicações | posts + RLS | Local atualmente |
| Seguir usuários | follows | Aguardando conexão |
| Curtidas e comentários | post_likes, comments | Curtidas locais atualmente |
| Stories | stories, story_views | Aguardando conexão |
| Salvos | saved_posts | Favoritos locais atualmente |
| Mensagens diretas | conversations, messages | Aguardando conexão |
| Notificações | notifications + triggers | Aguardando conexão |
| Imagens e vídeos | Storage ideon-media | Aguardando conexão |
| Bloqueio e denúncias | user_blocks, content_reports | Aguardando conexão |
| Projetos e tarefas | projects, tasks | Aguardando conexão |
| Atualizações em tempo real | Supabase Realtime | Aguardando habilitação/conexão |
| Assistente IDEON IA | Requer função de servidor e provedor de IA | Não implementado |

## Configuração do backend (necessária)

1. Crie um projeto em https://supabase.com/dashboard.
2. Abra SQL Editor → New query.
3. Execute primeiro o arquivo supabase/schema.sql completo.
4. Execute depois supabase/migrations/202611170001_social_network.sql completo.
5. Em Project Settings → API, copie a Project URL e a chave publishable (ou anon legada).
6. Guarde esses dois valores para configurar a conexão do front-end.

**Não coloque a chave service_role no navegador, no GitHub ou em mensagens.** Ela ignora as políticas RLS e é secreta. A chave publishable/anon pode ser usada no cliente desde que as políticas RLS estejam corretamente ativadas.

### Ordem e cuidados

- A migração social depende das tabelas e do bucket criados em schema.sql; não execute fora da ordem.
- A migração foi preparada para execução após o schema-base, mas precisa ser testada em um projeto Supabase real antes de produção.
- Confirme em Database → Publications que supabase_realtime está habilitada para as tabelas indicadas.
- Configure os métodos de login e URLs de redirecionamento em Authentication → URL Configuration.
- Configure limites de upload, formatos permitidos, proteção contra abuso e moderação antes de abrir o cadastro ao público.
- A política de privacidade e os termos de uso precisam ser publicados antes do lançamento.

## Preservação das ideias locais

O protótipo guarda dados na chave localStorage chamada ideon_ideas. **Não apague essa chave nem limpe os dados do Safari.** A futura migração para contas deverá importar as ideias do dispositivo para o usuário autenticado, verificar duplicatas e só considerar a migração concluída depois de confirmar os registros no banco.

## Arquitetura alvo

- Front-end web responsivo, instalável como PWA quando o manifesto e service worker forem adicionados.
- Supabase Auth para identidade e sessões.
- PostgreSQL + Row Level Security para dados e permissões.
- Supabase Storage para mídia.
- Supabase Realtime para feed, mensagens e notificações em tempo real.
- Supabase Edge Functions para operações privilegiadas, moderação, notificações push e chamadas à IA.
- Chaves secretas apenas em variáveis de ambiente do servidor/funções.

## Próximas entregas de engenharia

1. Criar o projeto Supabase e executar os dois scripts SQL.
2. Conectar o cliente web sem expor segredos.
3. Implementar cadastro, login, recuperação de senha e perfil.
4. Migrar dados locais com confirmação e sem perda.
5. Implementar feed paginado, perfis públicos, seguir, curtir, comentar e salvar.
6. Implementar Stories, uploads, visualizações e expiração.
7. Implementar mensagens, notificações, bloqueios e denúncias.
8. Criar Edge Functions para push, moderação e IDEON IA.
9. Adicionar testes automatizados, monitoramento, acessibilidade e política de privacidade.

## Aviso

A infraestrutura no repositório é código-fonte e configuração, não um backend hospedado. Não anuncie recursos como ativos até que os scripts tenham sido executados, a conexão esteja configurada e os fluxos tenham sido testados em contas distintas.
