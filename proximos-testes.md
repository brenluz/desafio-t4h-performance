# Próximos testes

Ideias que apareceram na pesquisa ou nos diagnósticos e **não foram testadas** (por falta de tempo, ou porque a carga deste desafio não permite medir). Nenhum número aqui é resultado de experimento: quando há número, ele vem de um pré-teste ou diagnóstico salvo em `diagnostico/`, e isso está indicado. As fontes (F1, F2, ...) estão listadas no fim.

---

## 1. Resumo de vendas por dia pré-calculado (`vendas-por-dia`)

- **De onde veio:** Diagnóstico 05 (`diagnostico/15-diagnostico-05/ranking.txt`): `vendas-por-dia` era 85,2% do tempo do banco. Mesma técnica dos experimentos 07 e 11 (visão materializada; F13, F14).
- **A ideia:** uma visão materializada com uma linha por dia (`dia`, pedidos distintos, itens, receita), só de pedidos não cancelados. A rota passaria a ler ≤ 31 linhas prontas em vez de agregar ~13 mil itens. Funciona porque a contagem de pedidos distintos é somável entre dias: cada pedido pertence a um único dia.
- **O que acredito que ganharia (hipótese):** `vendas-por-dia`, hoje a rota mais lenta (~400 ms de mediana no experimento 12), cairia para perto das rotas que leem dados prontos (~11 ms no experimento 12), e o banco teria muito mais folga, porque é a única consulta pesada que restou.
- **Por que não foi feito:** depois do experimento 12, a rota já melhorou 43% **sem** dado pré-calculado. Este teste somaria um terceiro caso de dado que pode ficar desatualizado (ver item 2), e a decisão foi parar nos ganhos sem essa ressalva.
- **Como testaria:** `banco/10-resumo-vendas-dia.sql` com a visão e um índice único em `dia`; rota lendo `WHERE dia BETWEEN $1 AND $2 ORDER BY dia`; prova de equivalência do JSON nas mesmas 735 janelas do experimento 09 (`diagnostico/12-vendas-sql/equivalencia.js`); 3 medições contra o experimento 12.
- **O que precisaria:** uma decisão de negócio sobre quanto atraso o relatório aceita, e um plano de atualização. Atenção: cancelar um pedido antigo muda o dia em que ele foi feito, então atualizar só "hoje" estaria errado.

## 2. Custo de manter as visões atualizadas sob carga

- **De onde veio:** ressalva dos experimentos 07 e 11. Aqui a API só lê e os dados nunca mudam, então as visões nunca ficam velhas e o ganho medido é o melhor caso. F13 (dados "not always current"), F14 (`REFRESH ... CONCURRENTLY`).
- **A ideia:** rodar a carga normal do `medir.sh` enquanto um script à parte executa `REFRESH MATERIALIZED VIEW CONCURRENTLY` nas duas visões a cada N segundos, e comparar com a medição sem refresh.
- **O que acredito que ganharia:** não é um ganho, é uma medida honesta do custo da técnica. Custo de um refresh completo medido nos pré-testes, com o banco ocioso: ~979 ms (`top-produtos`, `diagnostico/09-top-produtos/pre-teste.txt`) e ~94 ms (contagem por status, `diagnostico/14-contagem-status/pre-teste.txt`). Num banco de 1 CPU já no teto, cada refresh disputa a mesma cota.
- **Como testaria:** script em `diagnostico/` com laço de `REFRESH ... CONCURRENTLY` + `sleep N`, para N = 60, 10 e 1 s; 3 medições de cada contra o experimento 12.
- **O que precisaria:** nada além do que existe (não muda `carga/`, `scripts/` nem o contrato).

## 3. Resumos mantidos por gatilho em vez de visões

- **De onde veio:** alternativa registrada nos experimentos 07 e 11.
- **A ideia:** tabelas de resumo (por produto, por status) atualizadas por gatilhos em `itens_pedido` e `pedidos`, sempre exatas, sem refresh.
- **O que acredito que ganharia:** a mesma velocidade de leitura das visões, sem dado velho. O custo passaria para a escrita: cada pedido novo, cancelamento ou mudança de status atualizaria o resumo, e todas as escritas do mesmo status (só 4 linhas na contagem) disputariam a mesma linha, serializando as escritas.
- **Por que não foi feito:** a carga deste desafio só lê; não haveria como medir o custo que importa (o da escrita).
- **Como testaria:** um script de carga de escrita à parte (fora de `carga/`, que não pode mudar) inserindo pedidos e mudando status, medindo a vazão de escrita com e sem gatilhos.
- **O que precisaria:** rotas ou scripts de escrita e um critério de carga de escrita realista.

## 4. Pool de conexões pequeno

- **De onde veio:** F9 (HikariCP, "About Pool Sizing"): conexões ativas perto de `(núcleos × 2) + discos`, e "you want a small pool [...] and you want the rest of the application threads blocked on the pool". O experimento 04 usou `max: 20` de propósito, para isolar o custo de abrir conexões.
  - **Indício medido depois (curva de capacidade, 16/11, `experimentos.md`):** a versão final faz 392 req/s com 5 e 10 usuários e cai para 350 com 20 (−10,8%) e 287 com 40 (−26,8%), com o banco a ~97–100% da cota em todos esses pontos. A CPU do banco por requisição sobe de 2,53 ms (5 e 10 usuários) para 2,85 ms (20) e 3,36 ms (40). Ou seja, concorrência demais no banco custa CPU, e o pool de 20 deixa passar mais consultas simultâneas do que 1 CPU atende bem.
- **A ideia:** `max` de 2 a 8 no `Pool` (`api/src/db.js`), para que menos consultas disputem a única CPU do banco ao mesmo tempo; os demais pedidos esperam na API.
- **O que acredito que ganharia (hipótese):** com 20 usuários, voltar para perto do pico da curva (~390 req/s, +10% sobre os 350 de hoje), com menos troca de contexto e menos consultas paradas no meio quando a cota de CPU acaba. Pode também piorar, se a fila no pool ficar longa ou se um pool pequeno deixar a CPU ociosa enquanto as conexões esperam a rede e o Node.
- **Como testaria:** um experimento por valor (2, 4, 8), 3 medições cada, contra a versão final com `max: 20`, intercalados (A-B-B-A) na mesma sessão; depois, a curva de capacidade (`diagnostico/23-curva-capacidade/curva.sh`) com o melhor valor, para ver se a queda depois de 10 usuários some.
- **O que precisaria:** nada além do que existe.

## 5. Índice GiST em vez de GIN para a busca por trigramas

- **De onde veio:** F17 (pg_trgm): os dois tipos de índice atendem `ILIKE`; a documentação remete a outra seção para a comparação de desempenho.
- **A ideia:** trocar o índice do experimento 10 por `USING gist (nome gist_trgm_ops)`.
- **O que acredito que ganharia:** não sei. A busca já está perto das rotas mais rápidas no experimento 12 (~88 ms de mediana, ~6% do banco no Diagnóstico 05). Teste de curiosidade técnica, prioridade baixa.
- **Como testaria:** pré-teste com `ROLLBACK` como em `diagnostico/13-busca-trgm/`, depois 3 medições.
- **O que precisaria:** nada além do que existe.

## 6. Log sem o corpo inteiro da resposta (P12)

- **De onde veio:** Diagnósticos 04 e 05 (`log-api.txt`, `perfil-api.txt`): o middleware de `api/src/server.js` grava o corpo inteiro de cada resposta (~11 MB por minuto no Diagnóstico 05), e escrita em stream aparece no topo do perfil da API.
- **A ideia:** registrar só método, URL, status e duração.
- **O que acredito que ganharia (hipótese):** menos CPU na API. Hoje a API usa ~21% da sua cota e quase não sofre throttling, então isso não aumentaria as req/s; serviria para reduzir o limite de CPU da API (custo).
- **Como testaria:** mudança no middleware, 3 medições, olhando a CPU da API; depois, uma medição com o limite da API reduzido.
- **O que precisaria:** confirmar que o conteúdo do log não é usado por ninguém (ele não faz parte do contrato da API, mas é um comportamento observável).

## 7. Índice que cobre `pedidos` com um cache maior

- **De onde veio:** experimento 16 (feito): o índice que cobre `pedidos` cortou 93% das visitas de `vendas-por-dia` à tabela, mas não aumentou a vazão, porque os +20,5 MB do índice disputaram o `shared_buffers` de 256 MB com páginas de `pedidos` que as outras rotas usam.
- **A ideia:** repetir o experimento 16 com `shared_buffers` de ~288 MB (o suficiente para o índice novo e o conjunto quente do experimento 14).
- **O que acredito que ganharia (hipótese):** o ganho de `vendas-por-dia` sem a perda das outras rotas, em troca de ~32 MiB a mais de memória fixa (que, pelo critério de custo, precisaria se pagar em vazão).
- **Como testaria:** mudança de configuração + o diagnóstico de cache de `diagnostico/19-shared-buffers/`, 3 medições contra o experimento 14.
- **O que precisaria:** nada além do que existe; atenção ao limite de 512 MB do container (memória fixa passaria de ~350 MiB).

## 8. Paginação por cursor (keyset)

- **De onde veio:** F11 (Winand, "no-offset"): o método de busca por chave é "even faster than offset" (afirmação sem números na página).
- **A ideia:** em vez de `pagina=N`, o cliente envia o último `(criado_em, id)` visto.
- **Por que não foi feito:** **quebra o contrato** (a API expõe `pagina` numérica de acesso aleatório). O experimento 06 (late row lookup) foi a alternativa compatível.
- **Como testaria:** só numa versão nova da API, com o contrato renegociado.

---

## Fontes citadas aqui

As referências completas, com links e trechos, estão na tabela de fontes de `notas/diario-de-bordo.md`:

- F9: Brett Wooldridge, "About Pool Sizing" (HikariCP Wiki). https://github.com/brettwooldridge/HikariCP/wiki/About-Pool-Sizing
- F11: Markus Winand, "We need tool support for keyset pagination". https://use-the-index-luke.com/no-offset
- F13: PostgreSQL 16, 41.3 Materialized Views. https://www.postgresql.org/docs/16/rules-materializedviews.html
- F14: PostgreSQL 16, REFRESH MATERIALIZED VIEW. https://www.postgresql.org/docs/16/sql-refreshmaterializedview.html
- F17: PostgreSQL 16, F.35 pg_trgm. https://www.postgresql.org/docs/16/pgtrgm.html
- F20: PostgreSQL 16, 11.9 Index-Only Scans and Covering Indexes. https://www.postgresql.org/docs/16/indexes-index-only-scans.html
- F21: PostgreSQL 16, 20.4.1 `shared_buffers`. https://www.postgresql.org/docs/16/runtime-config-resource.html
