# IDEON

IDEON é um protótipo de uma plataforma para capturar, desenvolver e compartilhar ideias.

## Estado real do projeto

- A interface atual é um protótipo estático em `index.html`.
- A versão atual permite criar ideias, pesquisar, filtrar, favoritar e ler publicações no próprio navegador.
- Os dados antigos são mantidos na chave local `ideon_ideas`. **Não apague essa chave nem limpe os dados do Safari.**
- Login, sincronização, feed multiusuário, curtidas compartilhadas, comentários e IA ainda não estão conectados à interface.
- A pasta `supabase/` contém a primeira base de infraestrutura planejada; ela só passa a funcionar depois de criada e configurada uma instância Supabase.

## Fundação de backend adicionada

O arquivo [supabase/schema.sql](supabase/schema.sql) prepara:
- perfis ligados às contas autenticadas;
- publicações com visibilidade pública, seguidores ou privada;
- seguidores, curtidas e comentários;
- projetos e tarefas privadas;
- notificações;
- bucket de mídia;
- políticas de segurança por usuário (Row Level Security).

**Importante:** adicionar o SQL ao repositório não cria o banco. É necessário executar o script no SQL Editor de um projeto Supabase.

## Próxima configuração necessária

1. Criar um projeto em [Supabase](https://supabase.com/dashboard).
2. Abrir **SQL Editor → New query**.
3. Copiar o conteúdo de `supabase/schema.sql`, colar e executar.
4. Em **Project Settings → API**, obter a Project URL e a chave publishable/anon.
5. Enviar esses dois valores para configurar a conexão do aplicativo. Nunca enviar a `service_role` key e nunca colocar segredos privados no navegador.

## Segurança e preservação de dados

- As políticas RLS são parte essencial da proteção; não desative RLS para “fazer funcionar”.
- A chave `service_role` não deve ser usada no front-end.
- O protótipo local continua preservado enquanto a integração é preparada. A migração das ideias antigas para a conta na nuvem deve ser feita com uma rotina explícita de importação, sem apagar os dados locais.

## Estrutura atual

```
.
├── index.html
├── README.md
└── supabase/
    └── schema.sql
```

## Roadmap técnico

1. Criar e configurar o projeto Supabase.
2. Integrar cadastro, login, sessão e perfis.
3. Migrar ideias locais com confirmação e sem perda de dados.
4. Conectar feed, publicações, curtidas, seguidores e comentários.
5. Implementar projetos e tarefas.
6. Integrar o assistente IDEON IA por função de servidor, mantendo a chave do provedor fora do navegador.
7. Testar segurança, acessibilidade, responsividade e comportamento no Safari/iPhone.
