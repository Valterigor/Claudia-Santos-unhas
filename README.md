# Claudinha Santos — Agenda online

## Publicação
1. Crie um projeto no Supabase (região próxima ao Brasil).
2. Execute `schema.sql` no SQL Editor.
3. Copie **Project URL** e a chave **publishable/anon** para `config.js`. NUNCA use a chave `service_role` no navegador.
4. Confira o número do WhatsApp (o informado possui 10 dígitos e pode estar incompleto).
5. Ajuste serviços, preços e duração em **dois lugares**: `config.js` e `schema.sql` (função `create_booking`).
6. Hospede `index.html` e `config.js` em Netlify, Cloudflare Pages ou hospedagem estática, com HTTPS. Use um domínio/subdomínio exclusivo.
7. Administre as reservas inicialmente em Supabase > Table Editor > bookings; cancele alterando status para `cancelled` (não apague o registro).

## Hospedagem grátis no GitHub Pages
1. Crie um repositório **público** no GitHub e envie os arquivos do projeto.
2. No repositório, abra **Settings > Pages**.
3. Em **Build and deployment**, selecione **Deploy from a branch**, escolha `main` e a pasta `/(root)`, e salve.
4. O site ficará disponível em `https://<seu-usuario>.github.io/<nome-do-repositorio>/`, sem domínio próprio pago.

## Como funciona
- Consulta os intervalos ocupados sem expor nomes/telefones.
- O banco valida horários, duração e sobreposição, usando bloqueio transacional para impedir reserva simultânea.
- Apenas confirma depois da gravação no banco.
- A interface não faz confirmação por WhatsApp nem envia lembretes automaticamente.
- Enquanto não houver Supabase configurado, o agendamento fica desativado (não gera confirmações falsas).

## Antes de abrir ao público
- Implementar proteção antispam: CAPTCHA/Turnstile validado no servidor, limites por IP e telefone, e monitoramento de abuso.
- Implementar painel administrativo com autenticação, política de cancelamento e notificações.
- Publicar política de privacidade e definir retenção de dados conforme LGPD.
- Verificar regras reais de expediente, pausas e feriados; a configuração inicial é segunda a sábado, 09h–18h.
- Ajustar a data/hora do dispositivo do usuário: para clientes fora do Brasil, a UI deve usar explicitamente America/Sao_Paulo.
- Não publique o projeto como sistema de produção completo sem os controles acima.
