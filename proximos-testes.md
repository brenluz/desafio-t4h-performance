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

## 4. Pool de conexões pequeno (testada: virou o experimento 17)

Testada em 16/11 e aplicada: pool de 3 conexões, +33,8% de req/s sobre o de 20 na mesma sessão. Resultados no `experimentos.md` (seção do experimento 17) e o raciocínio no diário. Os testes que sobraram dela estão nas fichas 9 e 10.

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

- **De onde veio:** F11 (Winand, "no-offset"): em vez de pular linhas, "just use a `where` clause that selects only data you haven’t seen yet"; o método é "even faster than `offset`" (afirmação sem números na página). A mesma página registra o custo: "you cannot directly navigate to arbitrary pages", e o cliente passa a enviar "a full keyset (often multiple columns)" em vez do número da página.
- **A ideia:** em vez de `pagina=N`, o cliente envia o último `(criado_em, id)` visto.
- **Por que não foi feito:** **quebra o contrato** (a API expõe `pagina` numérica de acesso aleatório). O experimento 06 (late row lookup) foi a alternativa compatível.
- **Como testaria:** só numa versão nova da API, com o contrato renegociado.

## 9. A API como próximo limite

- **De onde veio:** experimento 17: com o pool de 3, a API usa 79% da cota de 0,5 CPU (com o de 20, 61%). O Diagnóstico 04 (`diagnostico/11-diagnostico-04/perfil-api.txt`) mostrou a CPU da API indo para a leitura das linhas que vêm do banco (`parseDate`, `parseDataRowMessage`) e para o log.
- **A ideia:** um perfil novo da API com o pool de 3; candidatos já conhecidos: a ficha 6 (log sem o corpo da resposta) e menos colunas lidas por consulta (`SELECT *`, P11), sempre com o contrato igual.
- **O que acredito que ganharia (hipótese):** enquanto o banco estiver no teto, pouco ou nada em vazão; o ganho apareceria em CPU da API (custo) e como folga quando o banco deixar de ser o limite.
- **Como testaria:** o mesmo perfil do Diagnóstico 04, depois uma mudança por vez com 3 medições contra a versão final.
- **O que precisaria:** nada além do que existe.

## 10. Curva de capacidade e latência de rede com o pool de 3

- **De onde veio:** experimento 17. A escolha de 3 em vez de 2 se apoia num argumento não medido: com mais tempo de rede entre API e banco, um pool pequeno deixa a CPU do banco ociosa mais cedo (como aconteceu com 1). E a curva de capacidade foi medida com o pool de 20.
- **A ideia:** (1) a curva da versão final com o pool de 3, de 1 a 40 usuários; (2) os tamanhos 2, 3 e 5 com atraso artificial na rede entre a API e o banco (`tc qdisc ... netem delay`, que exige a permissão `NET_ADMIN` no container da API).
- **O que acredito que ganharia (hipótese):** (1) a queda depois de 10 usuários some ou diminui muito, porque o banco nunca vê mais de 3 consultas; (2) com alguns milissegundos de atraso, 2 perde para 3, e 3 perde para 5.
- **Como testaria:** (1) `diagnostico/23-curva-capacidade/curva.sh` só com a versão final; (2) blocos embaralhados como no 17, para cada atraso (0, 1 e 5 ms).
- **O que precisaria:** (2) uma mudança no `docker-compose.yml` só para o teste (capacidade `NET_ADMIN`), fora da versão final.

---

## Fontes citadas aqui

As referências completas, com links e trechos, estão na tabela de fontes de `notas/diario-de-bordo.md`:

- F9: Brett Wooldridge, "About Pool Sizing" (HikariCP Wiki). https://github.com/brettwooldridge/HikariCP/wiki/About-Pool-Sizing
- F27: Bianca Schroeder et al., "How to Determine a Good Multi-Programming Level for External Scheduling", ICDE 2006. https://www.cs.cmu.edu/~harchol/Papers/icde06.pdf
- F11: Markus Winand, "We need tool support for keyset pagination". https://use-the-index-luke.com/no-offset
- F13: PostgreSQL 16, 41.3 Materialized Views. https://www.postgresql.org/docs/16/rules-materializedviews.html
- F14: PostgreSQL 16, REFRESH MATERIALIZED VIEW. https://www.postgresql.org/docs/16/sql-refreshmaterializedview.html
- F17: PostgreSQL 16, F.35 pg_trgm. https://www.postgresql.org/docs/16/pgtrgm.html
- F20: PostgreSQL 16, 11.9 Index-Only Scans and Covering Indexes. https://www.postgresql.org/docs/16/indexes-index-only-scans.html
- F21: PostgreSQL 16, 20.4.1 `shared_buffers`. https://www.postgresql.org/docs/16/runtime-config-resource.html
