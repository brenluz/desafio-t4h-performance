# Diário de bordo

Registro de trabalho para escrever o `artigo/artigo.md` no fim. Não é entrega: é a fonte de onde o artigo, o `experimentos.md` e o `proximos-testes.md` vão sair.

Regras que valem aqui também:

- Número de antes e depois só vem de `resultados/` (aponte a pasta). Número de diagnóstico só vem de arquivo em `diagnostico/`.
- Separar **fato** (medido, com arquivo) de **hipótese/opinião**.
- Fonte só entra com link que foi aberto e conferido.

## Mapa para o artigo

| Seção do artigo | Sai daqui |
| --- | --- |
| 1. Resumo | [Linha de base](#linha-de-base) + tabela final de [Experimentos](#experimentos) |
| 2. Contexto e diagnóstico | [Diagnóstico inicial](#diagnóstico-inicial) |
| 3. Estado da arte | [Fontes](#fontes), agrupadas por abordagem |
| 4. Alternativas consideradas | [Alternativas](#alternativas) |
| 5. Solução escolhida | Campo "por que esta e não outra" de cada experimento |
| 6. Experimento e resultado | [Experimentos](#experimentos) |
| 7. Limites e testes futuros | [Ideias não testadas](#ideias-não-testadas) + [Limites e dúvidas](#limites-e-dúvidas) |
| 8. Referências | [Fontes](#fontes) |
| 9. Uso de IA | [Uso de IA](#uso-de-ia) |

## Linha do tempo

| Data | O que aconteceu | Commit / pasta |
| --- | --- | --- |
| 2026-11-05 | Recebido o enunciado (prazo: 14 dias corridos, até 2026-11-19) | — |
| 2026-11-05 | Cópia do desafio em `~/meu-desafio` (WSL), estado original commitado | `7f36358` |
| 2026-11-05 | Contrato gravado com a aplicação original (42 respostas) | `1b5bd26` |
| 2026-11-05 | Linha de base medida 3 vezes, contrato mantido nas 3 | `ff30500` |
| 2026-11-05 | `.idea/` no `.gitignore` (senão o `contexto.txt` acusaria arquivo sem commit) | `aff5380` |
| 2026-11-05 | Diagnóstico inicial (EXPLAIN ANALYZE e outros, só leitura) | `diagnostico/00-inicial/` |
| 2026-11-05 | Hipótese do experimento 01 (índices nas chaves estrangeiras) escrita antes da mudança | `59460b4` |
| 2026-11-05 | Experimento 01: índices criados, plano conferido, medido 3 vezes; +78% req/s, p95 −55% | `979c83c`, `09222ee`, `5b3c082` |
| 2026-11-05 | Diagnóstico 02 com `pg_stat_statements`: `/pedidos` = 46,5% do tempo do banco | `4aef666`, `f4ff869` |
| 2026-11-05 | Hipótese do experimento 02 (índice `status, criado_em, id`) escrita antes da mudança | `1f5b233` |
| 2026-11-05 | Experimento 02: índice criado, plano conferido, medido 3 vezes; +42% req/s e p95 −18% sobre o 01 | `4640d9c`, `e8bafec`, `b8357ef` |
| 2026-11-05 | Hipótese do experimento 03 (N+1 em `/clientes/:id/pedidos`) escrita antes da mudança | `9957cfa` |
| 2026-11-05 | Experimento 03: consulta única, medido 3 vezes; rota −91%, +45% req/s, p95 geral +12,5% | `8293e59`, `9bb2e7a`, `06bccf0` |
| 2026-11-05 | Decidido fazer o pool de conexões antes dos relatórios; hipótese do experimento 04 escrita antes da mudança | `c60aa28` |
| 2026-11-05 | Pool implementado; contagem de sessões antes e depois (918 → 49) | `f54c2ba`, `a68bdfb`, `c9cb474` |
| 2026-11-09 | Primeiras medições do 04 descartadas (arquivos sem commit e dias diferentes); experimento 03 remedido e 04 medido na mesma sessão: +11,7% req/s, mediana −62% | `4cb8796`, pastas de 09/11 |
| 2026-11-09 | Pré-teste dos índices para `vendas-por-dia` (com `ROLLBACK`); hipótese do experimento 05 escrita antes da mudança | `c22f6d3`, `194f9e4` |
| 2026-11-09 | Experimento 05: índice de expressão, medido 3 vezes na mesma sessão do 04; +18,7% req/s, p95 −35%, p99 +47% | `7114534`, `047abf3`, `aea7616` |
| 2026-11-09 | Diagnóstico 03 (`pg_stat_statements` + EXPLAINs quentes): página de `/pedidos` = 46,7% do banco; prioridades revistas, P4b antes de `top-produtos` | `ac441de`, `d06ebb9` |
| 2026-11-09 | Pré-teste do P4b: blocos temporários explicados (plano vira `Seq Scan`+Sort para `cancelado`/`pagina=15000`); reescrita "late row lookup" validada ociosa; hipótese do experimento 06 escrita antes da mudança | `77f0c15`, `4d78d1a` |
| 2026-11-09 | Experimento 06: late row lookup, medido 3 vezes na mesma noite do 05; p95 da rota −95%, +28% req/s, p99 −33%; relatórios pioraram | `77edbe6`, `6deaaab`, `a39645d` |
| 2026-11-09 | Pré-teste da visão materializada para `top-produtos` (equivalência linha a linha, `ROLLBACK`); hipótese do experimento 07 escrita antes da mudança | `7fd5034`, `ec7d902` |
| 2026-11-09 | Experimento 07 (feito pelo Claude Code a pedido): visão materializada; 2,7× req/s, p95 −80%, p99 −90%; mediana +26%; CPU da API e memória do banco perto do limite | `02fe13e`, `15eb4a4`, `a3ffd77` |
| 2026-11-09 | Pré-teste do índice de e-mail (`ROLLBACK`); hipótese do experimento 08 escrita antes da mudança | `c5d1b6a`, `39a4993` |
| 2026-11-09 | Experimento 08 (feito pelo Claude Code a pedido): índice de e-mail; +15,5% req/s, p95 −15%; banco a 63% de CPU, API a 96% da cota: gargalo passou para a API | `516c2ad`, `3dd7fa4`, `6d2aa5c` |
| 2026-11-09 | Diagnóstico 04 (feito pelo Claude Code a pedido): profiler do V8 na API + `pg_stat_statements`; `vendas-por-dia` = ~99% das linhas que a API analisa e 39,3% do banco; busca e `count(*)` ~28% cada | `bd0a058`, `a527d2e` |
| 2026-11-09 | Pré-teste de equivalência da agregação no SQL (735 janelas, 0 diferenças); hipótese do experimento 09 escrita antes da mudança | `a682db8`, `9b928a0` |
| 2026-11-09 | Experimento 09 (feito pelo Claude Code a pedido): agregação no SQL; +62% req/s, mediana −67%, API de 96% para ~20% da cota; banco de volta ao teto; achado do throttling de CPU (51% dos períodos) | `3da8e3e`, `adf386e`, `c9835b3`, `d4f8c22` |
| 2026-11-09 | Pré-teste do índice de trigramas para a busca (consultas parametrizadas, equivalência, `ROLLBACK`); hipótese do experimento 10 escrita antes da mudança | `6b85ec8`, `5157d27` |
| 2026-11-09 | Experimento 10 (feito pelo Claude Code a pedido): índice `pg_trgm`; +24% req/s, busca −67%; banco segue no teto | `0520020`, `668745f`, `d1f3c8f` |
| 2026-11-09 | Pré-teste da contagem por status pré-calculada (equivalência inclusive para status sem pedidos, `ROLLBACK`); hipótese do experimento 11 escrita antes da mudança | `diagnostico/14-contagem-status/`, este diário |

## Ambiente

Todas as medições precisam ser nesta mesma máquina para serem comparáveis.

- Windows 11 Home, WSL 2 (Ubuntu), Docker Desktop (Docker 29.5.3, Compose v5.1.4)
- Docker Desktop enxerga 16 CPUs e ~8 GB de memória; os limites dos containers estão no `contexto.txt` de cada medição
- Parâmetros de carga: padrão (`VUS=20`, `DURACAO=60s`, `AQUECIMENTO=15s`, `SEMENTE=42`)

## Linha de base

Commit medido: `1b5bd26`. Pastas:

- [`resultados/20261105-165057-00-linha-de-base`](../resultados/20261105-165057-00-linha-de-base/resumo.txt)
- [`resultados/20261105-165331-00-linha-de-base`](../resultados/20261105-165331-00-linha-de-base/resumo.txt)
- [`resultados/20261105-165546-00-linha-de-base`](../resultados/20261105-165546-00-linha-de-base/resumo.txt)

| Execução | req/s | mediana | p95 | erros | banco CPU média | banco mem média | API CPU média | API mem média |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 165057 | 1.53 | 2478.8 ms | 45258.1 ms | 0.87% | 96.8% | 396.2 MiB | 7.4% | 27.6 MiB |
| 165331 | 1.60 | 2346.9 ms | 46763.0 ms | 0.00% | 99.3% | 418.6 MiB | 7.0% | 31.3 MiB |
| 165546 | 1.48 | 2506.8 ms | 47089.5 ms | 0.00% | 98.5% | 393.8 MiB | 6.4% | 31.3 MiB |
| **Mediana** | **1.53** | **2478.8 ms** | **46763.0 ms** | — | **98.5%** | **396.2 MiB** | **7.0%** | **31.3 MiB** |

Observações (fatos, das pastas acima):

- O banco fica no teto do limite (1 CPU) durante toda a carga; a API usa menos de 10% do limite dela (0,5 CPU).
- Rotas mais lentas pela mediana: `pedidos-do-cliente` (~38–41 s), `top-produtos` (29–59 s, só 1 requisição por execução), `pedidos-por-status` (~15–17 s), `vendas-por-dia` (~13–17 s).
- A execução 165057 teve 1 erro: `GET /clientes/31435/pedidos` estourou o timeout de 60 s do k6 (`carga/teste-carga.js`).
- Rotas lentas têm poucas amostras (1 a 27 por execução): comparar pelo resultado geral, não por rota.

## Diagnóstico inicial

Evidência: [`diagnostico/00-inicial/saida.txt`](../diagnostico/00-inicial/saida.txt), gerada por [`diagnostico/00-inicial/diag.sh`](../diagnostico/00-inicial/diag.sh) com a aplicação original e o banco **ocioso** (uma consulta por vez). Sob carga os tempos são muito maiores porque tudo disputa 1 CPU.

Dados de contexto (do mesmo arquivo): `pedidos` 500 mil linhas / 174 MB, `itens_pedido` 1,5 milhão / 107 MB, `clientes` 100 mil / 11 MB, `produtos` 20 mil / 2 MB. Cada cliente tem 5 pedidos. `observacoes` tem em média 274 caracteres.

| # | Problema | Onde | Evidência (ocioso) | Hipótese de causa | Status |
| --- | --- | --- | --- | --- | --- |
| P1 | Só existem os índices de chave primária | `banco/01-estrutura.sql` | seção `indexes`; itens de um pedido = Seq Scan em 1,5 mi linhas, 252 ms; pedidos de um cliente = Seq Scan, 143 ms | Toda busca por `cliente_id`, `pedido_id`, `status`, `criado_em` lê a tabela inteira | chaves estrangeiras: resolvido no experimento 01; `status`/`criado_em`: pendente |
| P2 | N+1 em `/clientes/:id/pedidos` (17 consultas por requisição para um cliente com 5 pedidos e 10 itens) | `api/src/rotas.js` (rota `/clientes/:id/pedidos`) | seção `queries per /clientes/42/pedidos` | Uma consulta por pedido e uma por item; com P1 vira 5 Seq Scans de `itens_pedido` por requisição | resolvido no experimento 03 (2 consultas por requisição) |
| P3 | Uma conexão nova por consulta, sem pool | `api/src/db.js` | 50× conectar+consultar = 4,6 s; 50 consultas numa conexão = 0,28 s | Cada conexão cria um processo no Postgres. **Cuidado:** o teste usa `psql`, que soma o custo de iniciar o programa; medir melhor antes de citar | resolvido no experimento 04 (pool, −95% de conexões) |
| P4 | Paginação por status ordena tudo em disco e usa `OFFSET` até 19.980 | `/pedidos` | `external merge Disk: ~30 MB` por worker, 1.085 ms | Sem índice em `(status, criado_em, id)` e `work_mem` de 4 MB | parcial: `Sort` em disco resolvido no experimento 02 para os status grandes, mas o `OFFSET` ainda busca ~20 mil linhas inteiras da tabela por chamada (e `cancelado`/`pagina=15000` ainda ordenam em disco) — maior consumidor do banco (Diagnóstico 03: 46,7%); **resolvido no experimento 06** (late row lookup: p95 da rota 28 s → 1,5 s) |
| P5 | `count(*)` por status a cada página | `/pedidos` | Seq Scan, 288 ms | Contagem recalculada a cada requisição | parecia resolvido no Diagnóstico 03 (42 ms quente, 2,5% do banco), mas voltou a pesar no Diagnóstico 04: 27,0% (346 chamadas × 87 ms), porque o resto encolheu; prioridade 3 |
| P6 | `criado_em::date BETWEEN`, traz `observacoes` sem usar, agrega no Node | `/relatorios/vendas-por-dia` | Seq Scan nas duas tabelas grandes, 756 ms, 12.951 linhas enviadas à API | O cast impede índice em `criado_em`; colunas e linhas demais trafegam | scan resolvido no experimento 05 (índice de expressão, −71% na rota); transporte de ~12.900 linhas por chamada **resolvido no experimento 09** (agregação no SQL: 7 linhas, API de 96% para ~20% da cota) |
| P7 | `top-produtos` agrega todos os itens a cada chamada | `/relatorios/top-produtos` | 3.482 ms | Resultado só muda quando os dados mudam, mas é recalculado sempre | confirmado (Diagnóstico 03: 21,3%, 2.053 ms quente ocioso); **resolvido no experimento 07** (visão materializada: 37,9 s → 0,13 s sob carga); atualização em produção não testada |
| P8 | Busca por e-mail com `lower(email)` sem índice | `/clientes?email=` | Seq Scan 100 mil linhas, 84 ms | Falta índice de expressão em `lower(email)` | **resolvido no experimento 08** (rota 974 → 195 ms; banco caiu de 87% para 63% de CPU) |
| P9 | Busca `ILIKE '%termo%'` | `/produtos/busca` | Seq Scan 20 mil linhas, 24 ms | Índice B-tree não serve com `%` no começo; tabela pequena, prioridade baixa | virou 29,3% do banco no Diagnóstico 04; **resolvido no experimento 10** (`pg_trgm`: rota 306 → 100 ms) |
| P10 | Postgres com configuração padrão | `docker-compose.yml` (sem `command`) | seção `settings`: `shared_buffers` 128 MB, `work_mem` 4 MB, 2 workers paralelos | Tabelas quentes (~280 MB) não cabem no cache; paralelismo num container de 1 CPU talvez só atrapalhe | a investigar |
| P11 | `SELECT *` em todas as rotas | `api/src/rotas.js` | `observacoes` média 274 caracteres | Lê e transfere colunas que a rota não devolve | a investigar |
| P12 | Log com o corpo inteiro de cada resposta | `api/src/server.js` | 591 linhas = 647 KB de log; maior linha 6.324 caracteres | Custo de CPU na API; irrelevante hoje (API a 7%), pode aparecer depois que o banco melhorar | medido no Diagnóstico 04: 3 MB de log por minuto, mas `JSON.stringify`/escrita não aparecem entre as funções quentes; prioridade 4 |

Cuidados de contrato ao mexer: manter ordem (`criado_em DESC, id DESC`, `nome, id`, `receita DESC, id`), tipos (somas passam por `Number(...)`), e os casos de erro (`pagina=0`, `2024-02-30`, período invertido, `limite=0`/`51`).

Ainda não verificado: qual consulta consome mais tempo total **sob carga** (`pg_stat_statements` confirmaria ou mudaria a ordem de prioridade). Feito depois do experimento 01: ver [Diagnóstico 02](#diagnóstico-02-onde-o-banco-gasta-tempo-sob-carga-depois-do-experimento-01).

## Diagnóstico 02: onde o banco gasta tempo sob carga (depois do experimento 01)

Evidência: [`diagnostico/02-pg-stat-statements/`](../diagnostico/02-pg-stat-statements/). O `coletar.sh` liga o `pg_stat_statements` só durante a coleta (arquivo de compose à parte, usado com `-f`, para não contaminar o `medir.sh`), aquece, zera os contadores, roda a mesma carga do `medir.sh` (20 VUs, 60 s, semente 42), salva o ranking e devolve o banco à configuração normal (extensão removida, `shared_preload_libraries` vazio — conferido depois). Commits `4aef666` (script) e `f4ff869` (saída). Estado do código: experimento 01 aplicado.

Fonte do método: F3 (o módulo registra estatísticas de planejamento e execução de todas as consultas; precisa estar em `shared_preload_libraries` e exige reinício do servidor).

Soma do `total_exec_time` de todas as consultas: ~557 s em 60 s de carga, ou seja, em média ~9 consultas em andamento ao mesmo tempo num banco de 1 CPU: a maior parte desse tempo é espera na fila.

| Rota (peso na carga) | % do tempo do banco | Consulta principal (`ranking.txt`) | Média por chamada |
| --- | --- | --- | --- |
| `/pedidos?status=` (15%) | **46,5%** | página com `OFFSET` 30,3% + `count(*)` 16,2% | 6.753,8 ms + 3.611,0 ms |
| `vendas-por-dia` (8%) | 24,4% | join que devolve ~12.900 linhas por chamada (168.037 linhas em 13 chamadas) | 10.463,1 ms |
| `top-produtos` (2%) | 12,4% | agregação completa | 23.096,1 ms |
| `cliente-por-email` (15%) | 9,8% | `lower(email)` sem índice | 1.552,1 ms |
| `busca-produtos` (15%) | 3,2% | `ILIKE` | 526,9 ms |
| `pedidos-do-cliente` (20%) | ~3% | as 4 consultas indexadas no experimento 01 | 6,1 a 97,3 ms |
| `cliente` (25%) | ~0,6% | chave primária | 61,5 ms |

Leitura (fatos do `ranking.txt` e hipóteses separadas):

- **Fato:** a consulta de página de `/pedidos` escreveu 88.734 blocos temporários (~693 MB em disco em 25 chamadas, ~28 MB cada): a ordenação em disco do diagnóstico inicial se confirma sob carga. O `count(*)` leu 423.430 blocos do disco em 25 chamadas.
- **Fato:** `pedidos-do-cliente` usa ~3% do tempo de consulta do banco, mas leva 12,4 s de mediana (`carga.txt`). Em 46 requisições houve ~1.000 consultas (46 em `pedidos`, 230 em `itens_pedido`, 675 em `produtos`, mais os clientes): o N+1. A busca de itens por `pedido_id`, que leva 0,28 ms com o banco ocioso, teve média de 24,8 ms aqui.
- **Hipótese:** o tempo dessa rota é fila. Ela faz ~22 consultas em sequência, cada uma esperando a vez num banco saturado pelas rotas de `/pedidos` e relatórios.
- **Não medido:** o custo de abrir conexão (P3) não aparece no `pg_stat_statements` (não é consulta). ~950 das ~1.185 consultas da execução vêm do N+1, cada uma com conexão nova, então o custo real do N+1 no banco é maior que os ~3%.
- **Limites:** uma execução só; `total_exec_time` é tempo decorrido (inclui espera por CPU), não CPU pura; a coleta roda com o `pg_stat_statements` ligado, que tem custo próprio (a carga deu 2,96 req/s, na faixa do experimento 01, sem sinal de custo grande).

**Decisão (Diagnóstico 02):** atacar `/pedidos` antes do N+1. Motivos: (1) é o maior consumidor do recurso saturado; com a fila mais curta todas as rotas esperam menos, inclusive as 22 consultas do N+1; (2) resolver o N+1 primeiro aceleraria muito aquela rota, mas aliviaria pouco o banco, e na carga de ciclo fechado os usuários liberados iriam pedir mais `/pedidos` e relatórios; (3) um arquivo `.sql`, sem mudar código, risco quase nulo para o contrato; o N+1 exige reescrever a rota mantendo ordem, totais e formato. **A favor do N+1 primeiro** (registrado para o artigo): o custo de conexão escondido e o maior efeito numa rota que é 20% da carga. N+1 e pool ficam como próximos passos, depois de um novo ranking.

## Diagnóstico 03: onde o banco gasta tempo depois do experimento 05

Evidência: [`diagnostico/07-ranking-apos-05/`](../diagnostico/07-ranking-apos-05/). Mesmo método do Diagnóstico 02 (`coletar.sh` reusa o compose de lá; extensão removida e banco restaurado no fim). Estado do código: experimentos 01–05 aplicados. A carga da coleta fez 10,64 req/s, dentro da faixa do experimento 05 (10,70–11,35): o custo do `pg_stat_statements` continua pequeno. O arquivo `consultas-ociosas.txt` traz o `EXPLAIN (ANALYZE, BUFFERS)` das consultas restantes, com o cache quente logo após a carga.

Soma do `total_exec_time`: ~1.220 s em 60 s de carga ≈ 20 consultas em andamento o tempo todo, num banco de 1 CPU. Com o pool, os 20 usuários virtuais estão sempre com uma consulta na fila do banco: a espera na fila domina qualquer tempo sob carga.

| # | Consulta (rota) | % do tempo | Chamadas | Média sob carga | Ocioso (quente) | Leitura por chamada |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | página de `/pedidos` (`LIMIT/OFFSET`) | **46,7%** | 111 | 5.131,8 ms | 345,8 ms (`OFFSET 19980`) | ~10.100 páginas (~79 MB) |
| 2 | `top-produtos` | 21,3% | 12 | 21.662,0 ms | 2.052,7 ms | ~12.600 páginas |
| 3 | `vendas-por-dia` | 19,7% | 52 | 4.620,5 ms | 239,6 ms | ~16.800 páginas; devolve ~12.900 linhas/chamada (672.311 no total) |
| 4 | `clientes?email=` | 6,3% | 113 | 680,6 ms | 76,8 ms | Seq Scan em 100 mil clientes |
| 5 | `count(*)` por status | 2,5% | 111 | 277,1 ms | 42,3 ms | `Index Only Scan`, resolvido na prática |
| 6 | `busca-produtos` (`ILIKE`) | 2,2% | 108 | 250,0 ms | 12,1 ms | tabela pequena |
| 7 | `pedidos-do-cliente` (consulta única) | 0,8% | 149 | 66,7 ms | — | era 20% da carga; virou irrelevante no banco |
| 8 | `clientes/:id` | 0,4% | 343 | 14,9 ms | — | — |

Leitura (fatos do `ranking.txt` e `consultas-ociosas.txt`; hipóteses marcadas):

- **Fato:** a consulta de página de `/pedidos` virou o maior consumidor isolado (46,7%). O índice do experimento 02 eliminou o `Sort`, mas o plano ocioso mostra o `Index Scan` percorrendo **20.000 linhas** (20.101 páginas de buffer) para devolver 20: o `OFFSET` desce o índice **e busca cada linha inteira na tabela** (`SELECT *`, linhas de ~299 bytes com `observacoes`), inclusive as 19.980 descartadas.
- **Fato:** a mediana da rota sob carga é 1,0 s, mas a média da consulta é 5,1 s: a distribuição é muito torta. Páginas baixas são rápidas; páginas altas de `pago` (300 mil linhas) percorrem até 20 mil linhas. **Revisão do que o experimento 05 supôs:** a cauda de `pedidos-por-status` não vem do `count(*)` (hoje só 2,5%, com `Index Only Scan` e `Heap Fetches: 0`), vem da própria consulta de página com `OFFSET` alto.
- **Fato:** `top-produtos` ocioso caiu de 3.482 ms (Diagnóstico 00) para 2.053 ms: o planejador agora usa `Index Only Scan` no índice do experimento 02 para o filtro de status. O custo restante é ler os 1,5 milhão de `itens_pedido` (Seq Scan, ~9.500 páginas) a cada chamada: nenhum índice evita isso; só dado derivado ou cache.
- **Fato:** em `vendas-por-dia`, o que sobrou é o laço de itens (~15.500 páginas por chamada buscando ~13 mil itens pedido a pedido) e o transporte de ~12.900 linhas com `observacoes` para somar no Node.
- **Fato:** `clientes?email=` segue com Seq Scan de 100 mil linhas a cada chamada (P8, nunca atacado): 6,3% do banco pela rota de 15% de peso.
- **Fato não explicado (resolvido no pré-teste do experimento 06,** [`diagnostico/08-pedidos-offset/pre-teste.txt`](../diagnostico/08-pedidos-offset/pre-teste.txt)**):** a consulta de página registrou 10.743 blocos temporários escritos. A suposição "Index Scan puro" valia só para os status grandes: para `cancelado` (50 mil linhas) com offset alto, o planejador acha mais barato trocar o índice por `Seq Scan` paralelo + ordenação externa em disco (`external merge`, ~5 MB por worker, 618,9 ms ocioso), porque buscar 20 mil linhas inteiras pelo índice sai caro demais. O caso do contrato `pagina=15000` em `pago` (OFFSET 299.980) também ordena 300 mil linhas em disco (~30 MB por worker, 992,9 ms). O contador global confirmou: a série do pré-teste criou 6 arquivos temporários (~110 MB) no banco.
- As três primeiras consultas somam **87,7%** do tempo do banco.

### Prioridades revistas (antes de escolher o próximo experimento)

| Prioridade | Problema | % do banco | Ideia principal | Esforço/risco |
| --- | --- | --- | --- | --- |
| 1 | P4b: página de `/pedidos` busca ~20 mil linhas na tabela para devolver 20 | 46,7% | "late row lookup": subconsulta pega só os 20 `id` via `Index Only Scan` (sem ir à tabela nas linhas puladas) e um join busca as 20 linhas inteiras | código (SQL da rota); ordem total garantida por `(criado_em, id)`, contrato preservável |
| 2 | P7: `top-produtos` relê 1,5 mi de itens por chamada | 21,3% | tabela derivada com o resumo por produto em `banco/06-*.sql` (a regra 5 do AGENTS.md permite "dados derivados" em `.sql` novos) | médio; honestidade: dados aqui são estáticos, num sistema real precisaria de estratégia de atualização |
| 3 | P6c: `vendas-por-dia` transporta ~12.900 linhas por chamada | 19,7% | agregar no SQL (`GROUP BY` por dia), devolvendo ≤31 linhas | código + cuidado com contrato (formato do dia, `Number()`) |
| 4 | P8: e-mail sem índice | 6,3% | índice de expressão `lower(email)` | trivial, um `.sql` |
| 5+ | `count(*)` (2,5%), `ILIKE` (2,2%), log da API (P12; API a ~18% de CPU) | ~5% | — | próximos testes |

**Decisão (Diagnóstico 03):** a ordem anterior apontava `top-produtos` como próximo alvo; o ranking mostra que a página de `/pedidos` custa mais que o dobro dele. Próximo experimento: P4b. Os itens 2–4 vêm depois, cada um medido separadamente.

## Diagnóstico 04: onde a API e o banco gastam CPU depois do experimento 08

Contexto: no experimento 08 o banco caiu para 63% de CPU e a API subiu para 96% da sua cota (0,5 CPU). Otimizar só o banco deixou de bastar; era preciso ver dentro do processo Node.

Evidência: [`diagnostico/11-diagnostico-04/`](../diagnostico/11-diagnostico-04/). Feito pelo Claude Code a pedido. O `coletar.sh` sobe o banco com `pg_stat_statements` (compose do Diagnóstico 02) e a API com o profiler de amostragem do V8 (`node --prof`, compose à parte `docker-compose.api-prof.yml`), roda a mesma carga do `medir.sh` (20 VUs, 60 s, semente 42), coleta o ranking, o volume de log da API por rota e o perfil de CPU (`node --prof-process`), e devolve banco e API à configuração normal (conferido: API rodando `node src/server.js`). Código: experimentos 01–08.

**Custo do diagnóstico:** com profiler, 40,98 req/s, ~10% abaixo do experimento 08 (45,40). Esperado: o `--prof` registra amostras continuamente.

### API (`perfil-api.txt`)

- **Fato:** 23,9% de todas as amostras são coleta de lixo (GC); 9,7% são JavaScript identificado. 52,7% ficaram "Unaccounted" e 37,7% em bibliotecas compartilhadas: o `--prof-process` dentro do container Alpine não consegue resolver os símbolos C++ do binário do Node (falta `nm`/binutils na imagem). **Limite:** a divisão fina do código nativo não é confiável; a leitura vale para as partes em JS e para o GC.
- **Fato:** no perfil "bottom up", as funções JS que mais chamam esse código nativo são todas do caminho de **leitura de linhas vindas do banco**: `parseDate` de `postgres-date` (23,1%, converte cada `timestamp` em `Date`), `parseDataRowMessage` de `pg-protocol` (12,1%), `_handleDataRow` do `pg` (5,9%), `parseInteger` (2,8%), e o próprio handler de `vendas-por-dia` (`rotas.js:162`, 7,2%, o laço que soma por dia).
- **Fato (cruzando com o ranking, coluna `rows`):** de ~2,46 milhões de linhas devolvidas pelo banco à API em 60 s, **2.430.485 (≈ 99%) são de `vendas-por-dia`** (188 chamadas × ~12.900 linhas, cada uma com `criado_em` e `observacoes` de ~274 caracteres, que a rota nem usa). Todas as outras consultas juntas devolveram ~25 mil linhas.
- **Hipótese (forte):** a CPU da API é dominada por `vendas-por-dia`: analisar ~2,4 milhões de linhas por minuto, criar 2,4 milhões de objetos `Date` e strings de `observacoes` (ordem de 670 MB alocados por minuto só nessa coluna), e o GC limpando tudo isso.
- **Fato (`log-api.txt`):** a API escreveu 3,07 MB de log em 60 s (2.486 linhas, ~1,2 KB por linha; maiores: `pedidos-do-cliente` 2,3 KB/linha, `busca-produtos` 2,0 KB, `pedidos-por-status` 2,0 KB). `JSON.stringify` e escrita de log não aparecem entre as funções quentes. **P12 (log) é real mas pequeno perto do resto.**

### Banco (`ranking.txt`)

Soma do `total_exec_time`: ~111 s em 60 s (≈ 1,9 consultas em andamento em média; no Diagnóstico 03 eram ~20). O banco já não tem fila longa.

| # | Consulta (rota) | % do tempo | Chamadas | Média sob carga | Linhas devolvidas |
| --- | --- | --- | --- | --- | --- |
| 1 | `vendas-por-dia` (join, ~12.900 linhas por chamada) | **39,3%** | 188 | 232,2 ms | 2.430.485 |
| 2 | `busca-produtos` (`ILIKE '%termo%'`, Seq Scan) | **29,3%** | 384 | 84,9 ms | 7.680 |
| 3 | `count(*)` por status | **27,0%** | 346 | 86,9 ms | 346 |
| 4 | `pedidos-do-cliente` (consulta única) | 2,2% | 519 | 4,6 ms | 7.725 |
| 5 | página de `/pedidos` (late lookup) | 1,5% | 346 | 4,7 ms | 6.920 |
| 6 | `cliente-por-email` | 0,5% | 361 | 1,5 ms | 361 |
| 7 | `clientes/:id` | 0,3% | 1.163 | 0,3 ms | 1.163 |
| 8 | `top-produtos` (visão) | 0,0% | 44 | 0,5 ms | 440 |

- **Fato:** as três primeiras somam **95,6%** do banco. As otimizadas nos experimentos 03, 06, 07 e 08 viraram ruído (≤ 2,2% cada).
- **Fato:** `busca-produtos` (P9) e `count(*)` (P5) eram 2,2% e 2,5% no Diagnóstico 03 e agora são 29% e 27%: não ficaram mais caras por chamada no ocioso; ganharam peso relativo porque todo o resto encolheu e porque são chamadas ~3× mais.

### Prioridades revistas

| Prioridade | Problema | Peso | Ideia | Por quê |
| --- | --- | --- | --- | --- |
| **1** | **P6c: `vendas-por-dia` agregada no Node** | **~99% das linhas que a API analisa + 39,3% do banco** | agregar no SQL (`GROUP BY` dia; `count(DISTINCT pedido)`, `sum`), devolvendo ≤ 31 linhas | ataca **os dois** recursos ao mesmo tempo: some quase todo o trabalho de análise de linhas, `Date` e GC da API, e o banco deixa de mandar 2,4 mi de linhas/min |
| 2 | P9: `ILIKE '%termo%'` | 29,3% do banco | índice GIN com `pg_trgm` | extensão padrão do PostgreSQL; consulta igual |
| 3 | P5: `count(*)` por status | 27,0% do banco | contagem pré-calculada por status (visão materializada de 4 linhas) ou contador | mesma discussão de dados derivados do experimento 07 |
| 4 | P12: log com corpo inteiro | 3 MB/min; não aparece no perfil | reduzir o que vai para o log | pequeno; e muda comportamento observável (log), não o contrato |

**Decisão (Diagnóstico 04):** próximo experimento é P6c. É o único que alivia a API (o teto atual) e o maior consumidor do banco ao mesmo tempo.

## Experimentos

Uma entrada por mudança, na ordem em que foram feitas. Copiar o modelo.

<!--
### 01-<rotulo>

- **Problema:** P?
- **Hipótese:** mudar X deve reduzir o p95 da rota Y, porque Z.
- **Fonte da ideia:** [link]
- **Por que esta e não outra:** ...
- **Mudança:** commit `<hash>` — o que mudou, em uma frase
- **Contrato:** mantido? (`contrato.txt` das pastas)
- **Antes:** linha de base ou 0N-...; pastas: ...
- **Depois:** pastas: ...
- **Resultado (medianas):** req/s A → B | p95 A → B | banco CPU/mem A → B | API CPU/mem A → B
- **Custo:** mudou limite de CPU/memória ou adicionou serviço?
- **Conclusão:** aplicada e medida / aplicada sem ganho (e por quê)
- **Gargalo que apareceu depois:** ...
-->

### 01-indices-fk

- **Status:** aplicada e medida — ganho confirmado
- **Problema:** P1 (sem índices nas chaves estrangeiras), que agrava o P2 (N+1)
- **Hipótese:** criar índices em `pedidos(cliente_id)` e `itens_pedido(pedido_id)` deve reduzir o p95 geral e aumentar as requisições por segundo, com o maior efeito na rota `pedidos-do-cliente`, porque hoje cada requisição dessa rota faz 6 leituras completas de tabela (1 em `pedidos`, 500 mil linhas, e 5 em `itens_pedido`, 1,5 milhão de linhas) para devolver 5 pedidos e 10 itens.
- **Previsões que dá para conferir:**
  - `EXPLAIN` das consultas por `cliente_id` e por `pedido_id` passa de `Seq Scan` para `Index Scan` (ou `Bitmap Index Scan`).
  - `pedidos-do-cliente` cai muito; `cliente` e `cliente-por-email` também devem melhorar indiretamente, porque deixam de esperar na fila do banco saturado.
  - `top-produtos` e `vendas-por-dia` devem mudar pouco: elas agregam boa parte das tabelas e o filtro delas não é por chave estrangeira.
  - O banco provavelmente continua perto de 100% de CPU, puxado pelas outras rotas ainda sem índice.
- **O que derrubaria a hipótese:** o plano continuar com `Seq Scan` depois do índice, ou o p95 geral e as req/s não mudarem além da variação normal entre execuções (que pode passar de 30%).
- **Fonte da ideia:** PostgreSQL 16, seção 5.4.5 (Foreign Keys): a declaração de chave estrangeira não cria índice automaticamente nas colunas que referenciam. Seção 11.1: sem índice o banco lê a tabela inteira, linha por linha. Ver [Fontes](#fontes) F1 e F2.
- **Por que esta e não outra:** é a mudança de menor esforço e risco para o maior problema medido. Não muda código nem resposta, só o banco. O N+1 (P2) e o pool (P3) ficam para experimentos separados, para isolar o efeito de cada um.
- **Mudança:** `banco/03-indices-chaves-estrangeiras.sql` com os dois `CREATE INDEX` e `ANALYZE` no fim — commit `979c83c`. Evidência em `09222ee` (commit medido). Resultados em `5b3c082`.
- **Custo esperado:** espaço em disco e memória dos índices (medir com `pg_relation_size`); escrita mais lenta em `INSERT`/`UPDATE` (a documentação, seção 11.1, chama de "overhead to data manipulation operations"). Esta API só lê, então o custo de escrita não aparece na medição: registrar como limite.

#### Evidência do plano (banco ocioso, uma consulta por vez)

Arquivos em `diagnostico/01-indices-fk/`; o "antes" vem de `diagnostico/00-inicial/saida.txt`.

| Consulta | Antes | Depois | Plano |
| --- | --- | --- | --- |
| itens de um pedido (`pedido_id = 1000`) | 252,1 ms | 0,278 ms | `Parallel Seq Scan` (1,5 mi linhas) → `Index Scan using itens_pedido_pedido_id_idx`, 4 páginas lidas |
| pedidos de um cliente (`cliente_id = 42`) | 142,7 ms | 0,456 ms | `Parallel Seq Scan` (500 mil linhas) → `Index Scan using pedidos_cliente_id_idx`, 8 páginas lidas |

O `Planning Time` de 35 ms na primeira consulta é o cache de catálogo frio logo depois de recriar o banco; a segunda planejou em 2,3 ms.

**Custo medido** (`tamanho-indices.txt`): `itens_pedido_pedido_id_idx` 21 MB + `pedidos_cliente_id_idx` 5.720 kB ≈ 26,7 MB a mais em disco, cerca de 10% dos ~281 MB das duas tabelas.

#### Medição sob carga

- **Contrato:** mantido nas 3 execuções (`contrato.txt`)
- **Antes:** linha de base, mediana das 3 pastas em [Linha de base](#linha-de-base)
- **Depois:** commit `09222ee`, pastas:
  - [`resultados/20261105-172652-01-indices-fk`](../resultados/20261105-172652-01-indices-fk/resumo.txt)
  - [`resultados/20261105-173051-01-indices-fk`](../resultados/20261105-173051-01-indices-fk/resumo.txt)
  - [`resultados/20261105-173531-01-indices-fk`](../resultados/20261105-173531-01-indices-fk/resumo.txt)

| Execução | req/s | mediana | p95 | erros | banco CPU média | banco mem média | API CPU média | API mem média |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 172652 | 2.73 | 2200.7 ms | 21153.9 ms | 0.00% | 100.9% | 391.8 MiB | 12.6% | 39.7 MiB |
| 173051 | 2.65 | 2011.8 ms | 21642.0 ms | 0.52% | 97.6% | 380.2 MiB | 12.7% | 41.7 MiB |
| 173531 | 2.95 | 1999.7 ms | 20898.2 ms | 0.00% | 95.5% | 383.4 MiB | 14.3% | 36.5 MiB |
| **Mediana** | **2.73** | **2011.8 ms** | **21153.9 ms** | — | **97.6%** | **383.4 MiB** | **12.7%** | **39.7 MiB** |

| Métrica (mediana das 3) | Linha de base | 01-indices-fk | Variação |
| --- | --- | --- | --- |
| Requisições/s | 1.53 | 2.73 | +78% |
| p95 geral | 46763.0 ms | 21153.9 ms | −55% |
| Mediana geral | 2478.8 ms | 2011.8 ms | −19% |
| Banco CPU média | 98.5% | 97.6% | ≈ igual (continua no teto) |
| Banco mem média | 396.2 MiB | 383.4 MiB | ≈ igual |
| API CPU média | 7.0% | 12.7% | sobe junto com as req/s |
| API mem média | 31.3 MiB | 39.7 MiB | sobe junto com as req/s |

As faixas não se sobrepõem: linha de base 1.48–1.60 req/s e p95 45,3–47,1 s; depois 2.65–2.95 req/s e p95 20,9–21,6 s. A diferença é maior que a variação entre execuções.

Por rota (mediana das medianas das 3 execuções; poucas amostras, usar com cuidado):

| Rota | Linha de base | 01-indices-fk |
| --- | --- | --- |
| `pedidos-do-cliente` | 41090.1 ms | 12604.5 ms (−69%) |
| `cliente` | 896.2 ms | 696.0 ms |
| `cliente-por-email` | 2498.9 ms | 2059.0 ms |

#### Previsões × resultado

| Previsão | Resultado |
| --- | --- |
| `Seq Scan` vira `Index Scan` | confirmada (`diagnostico/01-indices-fk/`) |
| `pedidos-do-cliente` cai muito | confirmada: −69% na mediana, mas ainda ~12,6 s |
| `cliente` e `cliente-por-email` melhoram indiretamente | parcialmente: melhora de ~20%, pequena perto da variação |
| `top-produtos` e `vendas-por-dia` mudam pouco | confirmada; os p95 dessas rotas até subiram em algumas execuções (ver abaixo) |
| Banco continua perto de 100% de CPU | confirmada: 95,5–100,9% |

- **Conclusão:** aplicada e medida, com ganho. Dobrou quase a vazão (+78% req/s) e cortou o p95 geral pela metade, sem mudar código nem resposta, ao custo de ~26,7 MB de índice. A hipótese se sustentou.
- **Gargalo que apareceu depois:**
  - O banco segue saturado (~98% de CPU). As consultas por chave estrangeira agora levam menos de 1 ms ociosas, mas `pedidos-do-cliente` ainda leva ~12,6 s sob carga: o tempo agora é fila no banco ocupado pelas outras rotas, somado às 17 consultas com 17 conexões novas por requisição (P2 e P3).
  - As rotas sem índice (`pedidos-por-status`, `vendas-por-dia`, `top-produtos`) viraram o peso principal. Elas foram chamadas mais vezes (ex.: `vendas-por-dia` 8–9 → 14–15 requisições por execução), porque a carga é de ciclo fechado: cada usuário virtual dispara a próxima requisição assim que a anterior volta, então rotas mais rápidas liberam os usuários para pedir mais rotas pesadas. Por isso os p95 dessas rotas não melhoraram e às vezes pioraram.
  - Uma requisição de `top-produtos` estourou o timeout de 60 s na execução 173051 (33,3% de erro na rota = 1 de 3).
- **Próximo passo sugerido:** descobrir qual consulta consome mais CPU do banco agora (ex.: `pg_stat_statements`) antes de escolher entre P4/P5 (`/pedidos`), P2 (N+1) e P3 (pool). Feito: [Diagnóstico 02](#diagnóstico-02-onde-o-banco-gasta-tempo-sob-carga-depois-do-experimento-01).

### 02-indice-pedidos-status

- **Status:** aplicada e medida — ganho confirmado
- **Problema:** P4 (paginação ordena em disco) e, em parte, P5 (`count(*)` lê a tabela inteira). Juntas são 46,5% do tempo do banco sob carga (Diagnóstico 02).
- **Hipótese:** um índice em `pedidos(status, criado_em DESC, id DESC)` deve reduzir o p95 geral e aumentar as req/s, porque a consulta de página passa a ler as linhas já na ordem do `ORDER BY` em vez de ordenar 100–300 mil linhas em disco a cada chamada; o `count(*)` pode ficar mais barato lendo o índice (menor) em vez da tabela de 174 MB.
- **Previsões que dá para conferir:**
  - `EXPLAIN` da página: some o `Sort` com `external merge Disk`; aparece `Index Scan` (ou `Index Scan Backward`) no novo índice.
  - `EXPLAIN` do `count(*)`: usa o índice. Se for `Index Only Scan` com muitos `Heap Fetches`, o mapa de visibilidade ainda não está preenchido (o `02-dados.sql` só roda `ANALYZE`, não `VACUUM`): isso vira um experimento separado.
  - `pedidos-por-status` cai muito, mas não some: o `OFFSET` ainda percorre até 19.980 entradas do índice e o `count(*)` até 300 mil.
  - **`pedidos-do-cliente` melhora sem ser tocada**, por esperar menos na fila do banco. Se não melhorar, é sinal de que o custo de conexão e o N+1 pesam mais do que o Diagnóstico 02 sugere.
  - O banco pode continuar saturado, agora puxado por `vendas-por-dia` e `top-produtos`.
- **O que derrubaria a hipótese:** o plano continuar com `Sort` em disco, ou req/s e p95 geral sem mudança além da variação entre execuções.
- **Fonte da ideia:** F4 (PostgreSQL 16, 11.4: o índice que casa com o `ORDER BY` dispensa a ordenação e, com `LIMIT`, permite pegar as primeiras linhas "without scanning the remainder at all"; um B-tree pode ser lido de trás para frente para `ORDER BY ... DESC`).
- **Por que esta e não outra:** maior consumidor do recurso saturado, menor esforço e risco (ver Diagnóstico 02). Alternativas para o `OFFSET` (paginação por cursor/keyset) mudariam a API e quebrariam o contrato; contagem em cache ou tabela de contadores fica para depois, se o `count(*)` continuar pesado.
- **Uma variável só:** sem `VACUUM` neste experimento, para não misturar o efeito do índice com o do mapa de visibilidade (o `VACUUM` afetaria todas as tabelas).
- **Mudança:** `banco/04-indice-pedidos-status.sql` (`CREATE INDEX pedidos_status_criado_em_id_idx ON pedidos (status, criado_em DESC, id DESC)` + `ANALYZE`) — commit `4640d9c`. Evidência em `e8bafec` (commit medido).
- **Custo esperado:** tamanho do índice (medir); escrita mais lenta (não aparece aqui, a API só lê).

#### Evidência do plano (banco ocioso, uma consulta por vez)

Arquivos em `diagnostico/03-indice-pedidos-status/`; o "antes" vem de `diagnostico/00-inicial/saida.txt` (sem nenhum índice novo; os índices do experimento 01 não afetam estas consultas).

| Consulta (`status = 'pago'`) | Antes | Depois | Plano |
| --- | --- | --- | --- |
| página 1 (`OFFSET 0`) | não medida no inicial | 0,703 ms | `Index Scan using pedidos_status_criado_em_id_idx`, 23 páginas lidas, sem `Sort` |
| página 1000 (`OFFSET 19980`) | 1.085,2 ms, `Sort` `external merge` em disco (~30 MB por worker) | 76,5 ms | `Index Scan` no novo índice, percorre 20.000 linhas, sem `Sort` |
| `count(*)` | 287,7 ms, `Parallel Seq Scan` | 234,0 ms | `Parallel Index Only Scan`, `Heap Fetches: 0`, 1.486 páginas em vez de ~20.800 |

- O `count(*)` usa o índice e não visita a tabela (`Heap Fetches: 0`), mas ficou só ~19% mais rápido: ainda conta 300 mil entradas a cada requisição. P5 continua aberto.
- `Heap Fetches: 0` porque o autovacuum já tinha rodado sozinho em todas as tabelas ~50 s depois da carga dos dados (`vacuum.txt`: `last_autovacuum` de `pedidos` 21:54:56 UTC; `ANALYZE` 21:54:08). Ou seja, o mapa de visibilidade foi preenchido sem `VACUUM` explícito, e o experimento separado com `VACUUM` previsto na hipótese perdeu o sentido. A primeira medição começou às 18:57:15 local (21:57:15 UTC), depois do autovacuum.

**Custo medido** (`tamanho-indices.txt`): `pedidos_status_criado_em_id_idx` 21 MB. Somando o experimento 01, os índices novos ocupam ~47,7 MB.

#### Medição sob carga

- **Contrato:** mantido nas 3 execuções (`contrato.txt`)
- **Antes:** experimento 01 (mediana das 3 pastas em [01-indices-fk](#01-indices-fk))
- **Depois:** commit `e8bafec`, pastas:
  - [`resultados/20261105-185715-02-indice-pedidos-status`](../resultados/20261105-185715-02-indice-pedidos-status/resumo.txt)
  - [`resultados/20261105-190052-02-indice-pedidos-status`](../resultados/20261105-190052-02-indice-pedidos-status/resumo.txt)
  - [`resultados/20261105-190307-02-indice-pedidos-status`](../resultados/20261105-190307-02-indice-pedidos-status/resumo.txt)

| Execução | req/s | mediana | p95 | erros | banco CPU média | banco mem média | API CPU média | API mem média |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 185715 | 4.03 | 1683.6 ms | 16235.9 ms | 0.00% | 99.9% | 412.2 MiB | 16.6% | 39.2 MiB |
| 190052 | 3.66 | 1895.8 ms | 17501.3 ms | 0.00% | 95.9% | 412.9 MiB | 14.8% | 40.2 MiB |
| 190307 | 3.87 | 1800.9 ms | 17306.0 ms | 0.00% | 94.5% | 416.3 MiB | 14.9% | 39.2 MiB |
| **Mediana** | **3.87** | **1800.9 ms** | **17306.0 ms** | — | **95.9%** | **412.9 MiB** | **14.9%** | **39.2 MiB** |

| Métrica (mediana das 3) | Linha de base | 01-indices-fk | 02-indice-pedidos-status | 02 vs 01 | 02 vs base |
| --- | --- | --- | --- | --- | --- |
| Requisições/s | 1.53 | 2.73 | 3.87 | +42% | +153% |
| p95 geral | 46763.0 ms | 21153.9 ms | 17306.0 ms | −18% | −63% |
| Mediana geral | 2478.8 ms | 2011.8 ms | 1800.9 ms | −10% | −27% |
| Banco CPU média | 98.5% | 97.6% | 95.9% | ≈ igual (no teto) | ≈ igual |
| Banco mem média | 396.2 MiB | 383.4 MiB | 412.9 MiB | +29,5 MiB | +16,7 MiB |
| API CPU média | 7.0% | 12.7% | 14.9% | sobe com as req/s | sobe com as req/s |
| API mem média | 31.3 MiB | 39.7 MiB | 39.2 MiB | ≈ igual | +7,9 MiB |

Faixas sem sobreposição com o experimento 01: req/s 2.65–2.95 → 3.66–4.03; p95 20,9–21,6 s → 16,2–17,5 s.

A memória do banco subiu ~30 MiB em relação ao experimento 01. **Hipótese** (não verificada): o índice novo, de 21 MB, passa a ocupar cache. Ainda dentro do limite de 512 MB.

Por rota (mediana das medianas das 3 execuções; poucas amostras, usar com cuidado):

| Rota | 01-indices-fk | 02-indice-pedidos-status | Variação |
| --- | --- | --- | --- |
| `pedidos-por-status` | 10848.1 ms | 3423.8 ms | −68% |
| `pedidos-do-cliente` | 12604.5 ms | 10103.5 ms | −20% (faixas sem sobreposição: 11,9–13,0 s → 10,1–10,3 s) |
| `cliente` | 696.0 ms | 551.3 ms | −21% |
| `cliente-por-email` | 2059.0 ms | 1906.3 ms | −7% |
| `busca-produtos` | 1147.3 ms | 1007.3 ms | −12% |
| `vendas-por-dia` | 11050.2 ms | 14590.1 ms | +32% (mais chamadas: 14–15 → 18–20 por execução) |
| `top-produtos` | 31794.7 ms | 31108.2 ms | ≈ igual |

#### Previsões × resultado

| Previsão | Resultado |
| --- | --- |
| Some o `Sort` em disco; aparece `Index Scan` no novo índice | confirmada (página 1000: 1.085 ms → 76,5 ms ocioso) |
| `count(*)` usa o índice; `VACUUM` separado se houver muitos `Heap Fetches` | usa (`Index Only Scan`, `Heap Fetches: 0` graças ao autovacuum), mas ganhou pouco (−19% ocioso) |
| `pedidos-por-status` cai muito, sem sumir | confirmada: −68% na mediana, ainda 3,4 s; p95 13–17 s |
| `pedidos-do-cliente` melhora sem ser tocada | confirmada, mas modesta (−20%): a fila menor ajuda, e a maior parte dos ~10 s continua. Coerente com o N+1 e as conexões pesarem bastante por conta própria |
| Banco continua saturado, puxado pelos relatórios | banco a 94,5–99,9%; `vendas-por-dia` piorou com mais chamadas (ciclo fechado). Falta um ranking novo para confirmar quem domina agora |

- **Conclusão:** aplicada e medida, com ganho. +42% req/s e −18% de p95 sobre o experimento 01, sem mudar código nem resposta, ao custo de 21 MB de índice e ~30 MiB a mais de memória média no banco. A hipótese se sustentou para a paginação; o `count(*)` continua caro.
- **Gargalo que apareceu depois (hipóteses, a confirmar com novo ranking):** `vendas-por-dia` e `top-produtos` (que já eram 37% do tempo do banco no Diagnóstico 02), o `count(*)` de `/pedidos`, e o N+1 + conexões de `pedidos-do-cliente`, que segue como a rota mais lenta entre as de maior peso (~10 s).
- **Próximo passo sugerido:** novo ranking com `pg_stat_statements` sobre o experimento 02, sem sobrescrever o ranking do Diagnóstico 02. (Decidido seguir direto para o N+1, sem novo ranking.)

### 03-n-mais-1

- **Status:** aplicada e medida — ganho em vazão, mediana e na rota-alvo; p95 geral piorou (explicado abaixo)
- **Problema:** P2 (N+1 em `/clientes/:id/pedidos`), rota de 20% da carga e a mais lenta entre as de maior peso (mediana ~10,1 s no experimento 02).
- **Situação atual (fato):** por requisição, 1 consulta de cliente + 1 de pedidos + 1 por pedido (5) + 1 por item (~14,7 em média: 675 consultas de produto em 46 requisições no Diagnóstico 02) ≈ 22 consultas em sequência, cada uma com conexão nova (`db.js`). Com os índices do experimento 01, cada consulta é barata (< 1 ms ociosa), mas sob carga cada uma espera a vez no banco saturado.
- **Hipótese:** trocar o laço por uma consulta só (`pedidos` + `itens_pedido` + `produtos` com `JOIN`, ordenada como hoje e agrupada no Node) deve derrubar a mediana e o p95 de `pedidos-do-cliente` e aumentar as req/s, porque a requisição passa de ~22 idas ao banco para 2, e cada ida sob carga custa uma espera na fila mais a abertura de uma conexão.
- **Previsões que dá para conferir:**
  - `pedidos-do-cliente` cai bem mais que os −20% do experimento 02 (ordem de grandeza: de ~10 s para perto do tempo de uma ou duas esperas na fila, ~1–2 s, como `cliente-por-email`).
  - req/s geral sobe; o p95 geral cai menos, porque passa a ser dominado por `vendas-por-dia`, `top-produtos` e `pedidos-por-status`.
  - O banco provavelmente continua saturado: na carga de ciclo fechado os usuários liberados vão pedir mais relatórios.
  - CPU da API pode subir um pouco (agrupamento das linhas em JS e mais req/s), mas cai o trabalho de abrir ~20 conexões por requisição.
- **O que derrubaria a hipótese:** `pedidos-do-cliente` sem queda clara além da variação, ou a nova consulta ficar lenta (plano com `Seq Scan`).
- **Duas variáveis inseparáveis (registrar no artigo):** como o `db.js` abre uma conexão por consulta, reduzir de ~22 para 2 consultas também reduz de ~22 para 2 conexões por requisição. Este experimento mede o efeito somado de menos idas ao banco **e** menos conexões. Para separar, seria preciso fazer o pool (P3) antes; o pool fica como experimento seguinte e vai mostrar o efeito das conexões nas outras rotas.
- **Fonte da ideia:** F5 (DataLoader: juntar buscas individuais num lote; "A naive application may have issued four round-trips [...] with DataLoader this application will make at most two"); F6 (guia do Rails, seção "N + 1 Queries Problem" — trecho a conferir).
- **Por que esta e não outra:** ver [Alternativas](#alternativas). Consulta única com `JOIN`: menos idas ao banco (2) e sem mudar o formato das datas, que é o risco do `json_agg`. O lote com `ANY` (3 consultas) seria igualmente válido; ficou de fora por fazer uma ida a mais.
- **Cuidados de contrato:** manter a ordem dos pedidos (`criado_em DESC, id DESC`) e dos itens (`id`), a ordem dos campos no objeto (`id, status, criado_em, total_centavos, itens`), o total calculado em JS como hoje, `[]` para cliente sem pedidos, 400 e 404 como hoje. `LEFT JOIN` para não perder pedido sem item, caso exista.
- **Mudança:** `api/src/rotas.js`, rota `/clientes/:id/pedidos`: o laço com uma consulta por pedido e por item virou uma consulta com `LEFT JOIN` em `itens_pedido` e `produtos`, ordenada por `p.criado_em DESC, p.id DESC, i.id`, agrupada no Node (um pedido novo começa quando o `id` muda) — commit `8293e59`. Evidência em `9bb2e7a` (commit medido).
  - Observação: ao colar o código, a IDE reformatou duas linhas não relacionadas (`{ erro: ... }` → `{erro: ...}`) e o `;` depois do `consultar(...)` ficou de fora. Sem efeito no comportamento (inserção automática de `;` do JavaScript; contrato mantido); só ruído de estilo no diff.
- **Custo esperado:** nenhum recurso novo; possível aumento pequeno de CPU/memória da API.

#### Evidência do plano (banco ocioso)

`diagnostico/04-n-mais-1/explain-pedidos-do-cliente.txt` (cliente 42): `Nested Loop Left Join` com três `Index Scan` — `pedidos_cliente_id_idx` (5 pedidos), `itens_pedido_pedido_id_idx` (5 voltas, 10 itens), `produtos_pkey` (10 voltas) — e um `Sort` em memória de 10 linhas. 64 páginas, todas em cache, **3,0 ms** de execução. Nenhum `Seq Scan`. Antes eram ~22 consultas separadas, cada uma com conexão nova.

#### Medição sob carga

- **Contrato:** mantido nas 3 execuções (`contrato.txt`)
- **Antes:** experimento 02 (mediana das 3 pastas em [02-indice-pedidos-status](#02-indice-pedidos-status))
- **Depois:** commit `9bb2e7a`, pastas:
  - [`resultados/20261105-192107-03-n-mais-1`](../resultados/20261105-192107-03-n-mais-1/resumo.txt)
  - [`resultados/20261105-192320-03-n-mais-1`](../resultados/20261105-192320-03-n-mais-1/resumo.txt)
  - [`resultados/20261105-192602-03-n-mais-1`](../resultados/20261105-192602-03-n-mais-1/resumo.txt)

| Execução | req/s | mediana | p95 | erros | banco CPU média | banco mem média | API CPU média | API mem média |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 192107 | 5.63 | 1056.0 ms | 19465.5 ms | 0.00% | 95.9% | 393.2 MiB | 18.0% | 57.2 MiB |
| 192320 | 5.77 | 904.9 ms | 19467.3 ms | 0.00% | 99.0% | 396.8 MiB | 16.4% | 50.5 MiB |
| 192602 | 5.55 | 997.6 ms | 19513.1 ms | 0.00% | 97.3% | 400.1 MiB | 17.3% | 56.3 MiB |
| **Mediana** | **5.63** | **997.6 ms** | **19467.3 ms** | — | **97.3%** | **396.8 MiB** | **17.3%** | **56.3 MiB** |

| Métrica (mediana das 3) | Linha de base | 01 | 02 | 03-n-mais-1 | 03 vs 02 | 03 vs base |
| --- | --- | --- | --- | --- | --- | --- |
| Requisições/s | 1.53 | 2.73 | 3.87 | 5.63 | +45% | +268% |
| p95 geral | 46763.0 ms | 21153.9 ms | 17306.0 ms | 19467.3 ms | **+12,5% (pior)** | −58% |
| Mediana geral | 2478.8 ms | 2011.8 ms | 1800.9 ms | 997.6 ms | −45% | −60% |
| Banco CPU média | 98.5% | 97.6% | 95.9% | 97.3% | ≈ igual (no teto) | ≈ igual |
| Banco mem média | 396.2 MiB | 383.4 MiB | 412.9 MiB | 396.8 MiB | −16,1 MiB | ≈ igual |
| API CPU média | 7.0% | 12.7% | 14.9% | 17.3% | +2,4 p.p. | +10,3 p.p. |
| API mem média | 31.3 MiB | 39.7 MiB | 39.2 MiB | 56.3 MiB | +17,1 MiB | +25,0 MiB |

Faixas contra o experimento 02: req/s 3.66–4.03 → 5.55–5.77 (sem sobreposição); p95 16,2–17,5 s → 19,47–19,51 s (sem sobreposição: a piora do p95 também é maior que a variação). Memória máxima da API chegou a 94,3 MiB, bem abaixo do limite de 256 MB.

Por rota (mediana das medianas das 3 execuções; poucas amostras nas rotas lentas):

| Rota | Chamadas por execução (02 → 03) | Mediana 02 | Mediana 03 | Variação |
| --- | --- | --- | --- | --- |
| `pedidos-do-cliente` | 52–56 → 72–79 | 10103.5 ms | 903.4 ms | **−91%** (p95 18306.1 → 1800.2 ms, −90%) |
| `cliente` | 62–66 → 103–106 | 551.3 ms | 404.1 ms | −27% |
| `busca-produtos` | 45–49 → 62–64 | 1007.3 ms | 805.6 ms | −20% |
| `cliente-por-email` | 40–42 → 54–57 | 1906.3 ms | 1705.4 ms | −11% |
| `pedidos-por-status` | 32–35 → 55–57 | 3423.8 ms | 2915.7 ms | −15% na mediana, mas p95 14612.2 → 21609.1 ms (+48%) |
| `vendas-por-dia` | 18–20 → 24–27 | 14590.1 ms | 17122.6 ms | +17% |
| `top-produtos` | 3–4 → 4–5 | 31108.2 ms | 37015.0 ms | +19% |

#### Previsões × resultado

| Previsão | Resultado |
| --- | --- |
| `pedidos-do-cliente` cai bem mais que −20%, para ~1–2 s | confirmada: 10,1 s → 0,9 s (−91%) |
| req/s geral sobe | confirmada: +45% |
| p95 geral cai, mas menos | **refutada**: subiu 12,5%, acima da variação |
| Banco continua saturado | confirmada: 95,9–99,0% |
| CPU da API sobe um pouco | confirmada: 14,9% → 17,3%. Não previsto: memória da API +17 MiB |

**Por que o p95 geral piorou (hipótese, coerente com os números):** o p95 é o tempo abaixo do qual ficam 95% de **todas** as requisições, ou seja, ele é decidido pelas ~19 requisições mais lentas de cada execução (5% de ~380). Com `pedidos-do-cliente` rápida, as requisições lentas passaram a ser quase só `vendas-por-dia`, `top-produtos` e a cauda de `pedidos-por-status`. Na carga de ciclo fechado, os usuários liberados chamaram mais essas rotas (`pedidos-por-status` 32–35 → 55–57 chamadas; `vendas-por-dia` 18–20 → 24–27), que disputam o mesmo banco saturado e ficaram mais lentas. A melhora numa rota piorou a cauda das outras.

**Hipóteses não verificadas:** a memória do banco caiu ~16 MiB talvez por haver menos conexões (processos do Postgres) abertas ao mesmo tempo; a memória da API subiu talvez por mais requisições em andamento ao mesmo tempo.

- **Conclusão:** aplicada e medida. Resolveu o problema da rota (−91%), aumentou a vazão (+45%) e cortou a mediana geral (−45%), sem recurso novo. Em troca, o p95 geral piorou 12,5% porque o gargalo ficou ainda mais concentrado nos relatórios e em `pedidos-por-status`. Lição para o artigo: com o banco saturado e carga de ciclo fechado, o p95 geral sozinho engana; é preciso olhar req/s, mediana e as rotas.
- **Duas variáveis juntas (lembrete):** o ganho é a soma de menos idas ao banco e menos conexões (~22 → 2 por requisição nesta rota).
- **Gargalo que apareceu depois:** `vendas-por-dia` (P6) e `top-produtos` (P7) dominam a cauda; `pedidos-por-status` ainda tem o `count(*)` (P5) e o `OFFSET`. O pool (P3) agora pesa menos: todas as rotas fazem 1–2 consultas.

### 04-pool-conexoes

- **Status:** aplicada e medida — ganho confirmado (vazão moderada, mediana grande)
- **Problema:** P3 (uma conexão nova por consulta, `api/src/db.js`). Escolhido antes dos relatórios para fechar a questão das conexões, que ficou misturada no experimento 03.
- **Situação atual (fato + estimativa):** cada consulta faz `new Client` → `connect` → consulta → `end`. O PostgreSQL cria um processo novo para cada conexão (F7). Pela mistura de rotas da carga, a média é ~1,35 consultas por requisição (cliente 1, e-mail 1, pedidos do cliente 2, pedidos por status 2, busca 1, relatórios 1), então a ~5,6 req/s do experimento 03 são ~7–8 conexões abertas e fechadas por segundo (estimativa, a confirmar com a contagem de sessões).
- **Hipótese:** reaproveitar conexões com `pg.Pool` deve aumentar as req/s e reduzir a mediana, porque o banco deixa de gastar CPU criando um processo e fazendo o handshake a cada consulta (F8: "a handshake which can take 20-30 milliseconds"), e essa CPU volta para as consultas, num banco que está no teto.
- **Tamanho do pool, uma variável só:** `max: 20`, igual ao número de usuários virtuais. Cada requisição faz no máximo uma consulta por vez, então a carga nunca passa de 20 consultas simultâneas: com 20 conexões ninguém espera na fila do pool e a concorrência no banco fica igual à de hoje. Assim o experimento mede só o custo de abrir conexões. O padrão do `pg` é 10 (F8), o que limitaria a concorrência e misturaria dois efeitos. **Testar um pool pequeno fica como experimento separado** (F9 sugere ~`(núcleos × 2) + discos` conexões, o que dá ~2–3 para um banco de 1 CPU).
- **Previsões que dá para conferir:**
  - Sessões abertas no banco durante 60 s de carga caem de centenas para no máximo ~20 (`pg_stat_database.sessions`, antes e depois).
  - req/s sobe e a mediana cai, mas **o ganho deve ser modesto** (ordem de 5–15%): com ~7–8 conexões por segundo, o custo de conexão é uma fração pequena da CPU do banco perto das consultas pesadas dos relatórios. Ganho relativo maior nas rotas rápidas (`cliente`, por chave primária, mediana ~0,4 s).
  - A memória do banco **sobe** (até 20 processos ficam vivos o tempo todo) e é o custo da mudança.
  - O banco continua saturado.
- **O que derrubaria a hipótese:** req/s e mediana sem mudança além da variação entre execuções. Nesse caso a conclusão seria "aplicada, sem ganho": nesta taxa de conexões o custo de abrir conexão não pesa, e o pool só se justificaria por outros motivos (limite de conexões, picos).
- **Fonte da ideia:** F7 (processo por conexão no PostgreSQL), F8 (node-postgres: custo do handshake, padrões do `Pool`), F9 (HikariCP: tamanho do pool).
- **Por que esta e não outra:** ver [Alternativas](#alternativas).
- **Cuidado de robustez:** o pool emite `error` quando uma conexão ociosa cai (ex.: o banco reinicia, como no `coletar.sh`); sem um ouvinte o processo Node pode cair (F8). Incluir `pool.on('error', ...)` que só registra no log: a conexão já é descartada pelo próprio pool.
- **Mudança:** `api/src/db.js`: `new Client`/`connect`/`end` por consulta virou um `Pool` com `max: 20` e `pool.query`, mais um ouvinte de `error` que só registra no log — commit `a68bdfb`.
- **Custo esperado:** memória do banco (processos persistentes); nenhum serviço novo.

#### Evidência: conexões abertas sob carga

`diagnostico/05-pool/` (script `sessoes.sh`, commits `f54c2ba` e `c9cb474`): contador `pg_stat_database.sessions` antes e depois de uma carga igual à do `medir.sh`.

| | Código | Conexões abertas durante a carga |
| --- | --- | --- |
| sem pool (`sessoes-antes.txt`) | `f54c2ba` (= experimento 03) | 918 |
| com pool (`sessoes-depois.txt`) | `a68bdfb` | 49 |

−95% de conexões. As ~49 restantes: o pool reabre conexões que ficam 10 s ociosas (`idleTimeoutMillis`, F8) e o `psql` da própria contagem.

**Ressalva:** a versão do script usada nas duas contagens tinha a carga duplicada por engano (duas cargas de 60 s seguidas; o arquivo `-carga.txt` guarda só a segunda). Corrigido no `c9cb474`. A comparação continua válida porque antes e depois rodaram exatamente a mesma carga dobrada; os números absolutos valem para ~120 s de carga, não 60 s.

#### Incidente: medições descartadas e remedição do "antes"

As primeiras medições do experimento 04 foram descartadas (commit `4cb8796`, pastas mantidas no repositório):

- `resultados/20261105-194857-04-pool-conexoes`, `resultados/20261109-191154-04-pool-conexoes`, `resultados/20261109-191341-04-pool-conexoes`
- **Motivo 1:** as três mostram `arquivos alterados sem commit: 5` (script corrigido e arquivos de sessões ainda sem commit; o código da API medido era o certo, `a68bdfb`).
- **Motivo 2:** foram feitas em dias diferentes, com números muito diferentes para o mesmo código: 4,34 req/s em 05/11 contra 10,32 e 10,23 em 09/11. O "antes" (experimento 03) tinha sido medido em 05/11. Algo no ambiente mudou entre os dias (não identificado: reinício da máquina, do Docker/WSL, programas abertos).

Por isso o experimento 03 foi **remedido em 09/11** (rótulo `03-n-mais-1-remedido`, commit `9bb2e7a`, com `git switch --detach`), seguido logo depois das 3 medições válidas do experimento 04, na mesma sessão e nas mesmas condições.

Efeito do ambiente, mesmo código do experimento 03: 5,63 req/s em 05/11 contra 8,44 req/s em 09/11 (+50%). **Consequência:** só se comparam medições da mesma sessão. As comparações 00 → 01 → 02 → 03 (todas de 05/11) continuam válidas entre si; o 04 se compara com o 03 remedido. A tabela-resumo do artigo precisa de uma rodada final (ver [Limites e dúvidas](#limites-e-dúvidas)).

#### Medição sob carga (09/11, mesma sessão)

- **Contrato:** mantido nas 6 execuções (`contrato.txt`)
- **Antes:** experimento 03 remedido, commit `9bb2e7a`:
  - [`resultados/20261109-192344-03-n-mais-1-remedido`](../resultados/20261109-192344-03-n-mais-1-remedido/resumo.txt)
  - [`resultados/20261109-192526-03-n-mais-1-remedido`](../resultados/20261109-192526-03-n-mais-1-remedido/resumo.txt)
  - [`resultados/20261109-192702-03-n-mais-1-remedido`](../resultados/20261109-192702-03-n-mais-1-remedido/resumo.txt)
- **Depois:** commit `4cb8796` (o código da API é o do `a68bdfb`; o `4cb8796` só acrescenta os resultados descartados), pastas:
  - [`resultados/20261109-194137-04-pool-conexoes`](../resultados/20261109-194137-04-pool-conexoes/resumo.txt)
  - [`resultados/20261109-194359-04-pool-conexoes`](../resultados/20261109-194359-04-pool-conexoes/resumo.txt)
  - [`resultados/20261109-194912-04-pool-conexoes`](../resultados/20261109-194912-04-pool-conexoes/resumo.txt)

| Execução | req/s | mediana | p95 | erros | banco CPU média | banco mem média | API CPU média | API mem média |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 03r 192344 | 8.46 | 705.3 ms | 13004.4 ms | 0.00% | 100.1% | 410.1 MiB | 15.3% | 58.4 MiB |
| 03r 192526 | 8.44 | 798.5 ms | 12718.9 ms | 0.00% | 100.5% | 412.5 MiB | 13.8% | 54.8 MiB |
| 03r 192702 | 7.78 | 792.6 ms | 13815.1 ms | 0.00% | 100.4% | 411.8 MiB | 15.4% | 60.2 MiB |
| **03r mediana** | **8.44** | **792.6 ms** | **13004.4 ms** | — | **100.4%** | **411.8 MiB** | **15.3%** | **58.4 MiB** |
| 04 194137 | 9.43 | 302.8 ms | 13421.3 ms | 0.00% | 100.5% | 416.7 MiB | 16.8% | 89.7 MiB |
| 04 194359 | 9.26 | 320.3 ms | 13042.1 ms | 0.00% | 100.3% | 421.5 MiB | 17.1% | 68.5 MiB |
| 04 194912 | 9.60 | 298.2 ms | 12977.6 ms | 0.00% | 98.3% | 412.6 MiB | 18.7% | 75.2 MiB |
| **04 mediana** | **9.43** | **302.8 ms** | **13042.1 ms** | — | **100.3%** | **416.7 MiB** | **17.1%** | **75.2 MiB** |

| Métrica (mediana das 3) | 03 remedido | 04-pool-conexoes | Variação |
| --- | --- | --- | --- |
| Requisições/s | 8.44 | 9.43 | +11,7% (faixas 7,78–8,46 → 9,26–9,60, sem sobreposição) |
| Mediana geral | 792.6 ms | 302.8 ms | **−61,8%** |
| p95 geral | 13004.4 ms | 13042.1 ms | ≈ igual (faixas 12,7–13,8 s e 13,0–13,4 s se sobrepõem) |
| Banco CPU média | 100.4% | 100.3% | ≈ igual (no teto) |
| Banco mem média | 411.8 MiB | 416.7 MiB | +4,9 MiB (pequeno, perto da variação) |
| API CPU média | 15.3% | 17.1% | +1,8 p.p. |
| API mem média | 58.4 MiB | 75.2 MiB | +16,8 MiB (máx. 99,8 MiB de 256 MB) |

Por rota (mediana das medianas das 3 execuções):

| Rota | 03 remedido | 04 | Variação |
| --- | --- | --- | --- |
| `cliente` | 338.4 ms | 95.1 ms | −72% |
| `pedidos-do-cliente` | 796.5 ms | 202.6 ms | −75% |
| `busca-produtos` | 601.9 ms | 300.4 ms | −50% |
| `cliente-por-email` | 1082.0 ms | 700.7 ms | −35% |
| `pedidos-por-status` | 1844.7 ms | 1251.5 ms | −32% |
| `vendas-por-dia` | 12210.8 ms | 12260.1 ms | ≈ igual |
| `top-produtos` | 20247.8 ms | 21886.7 ms | +8% (8–11 amostras, dentro da variação) |

#### Previsões × resultado

| Previsão | Resultado |
| --- | --- |
| Sessões abertas caem de centenas para ~20 | confirmada: 918 → 49 (com a ressalva da carga dobrada) |
| req/s sobe de forma modesta (5–15%) | confirmada: +11,7% |
| Mediana cai, ganho maior nas rotas rápidas | confirmada, e **bem maior que o previsto**: −62% na mediana geral; `cliente` 338 → 95 ms |
| Memória do banco sobe | quase nada: +4,9 MiB, perto da variação |
| Banco continua saturado | confirmada: 98,3–100,5% |

**Por que a mediana caiu muito mais que a vazão subiu (hipótese):** a previsão usou o custo de conexão com o banco ocioso (F8: 20–30 ms). Sob carga, o handshake e a criação do processo também esperam a vez na CPU saturada, então cada conexão custava bem mais. `cliente` (uma consulta por chave primária, < 1 ms) caiu ~240 ms por requisição, uma estimativa de quanto custava uma conexão sob carga. As rotas rápidas eram quase só custo de conexão; as pesadas (relatórios) eram quase só consulta, e por isso não mudaram. Como as pesadas continuam dominando a CPU do banco, a vazão total sobe pouco.

**Observação:** a preocupação levantada com as cargas do `sessoes.sh` (relatórios mais lentos com o pool) não se confirmou nas medições válidas: `vendas-por-dia` ≈ igual, `top-produtos` +8% com poucas amostras. Aquelas cargas não eram medições (sem aquecimento, seguidas, dobradas, outro dia).

- **Conclusão:** aplicada e medida, com ganho. Menos 95% de conexões, +11,7% de vazão e mediana −62%, sem serviço novo e com custo pequeno (+5 MiB no banco, +17 MiB na API). O p95 não mudou: ele é decidido pelos relatórios.
- **Gargalo que apareceu depois:** os relatórios (`vendas-por-dia` ~12 s, `top-produtos` ~22 s) e a cauda de `pedidos-por-status` (p95 ~13–16 s, `count(*)`) seguram o p95 e a CPU do banco.
- **Testes futuros ligados a este:** tamanho do pool pequeno (F9, ~2–4 conexões) como experimento separado.

### 05-indice-vendas-por-dia

- **Status:** aplicada e medida — ganho em vazão e p95; a cauda passou para `pedidos-por-status` e `top-produtos`
- **Problema:** P6 (`vendas-por-dia`): `criado_em::date BETWEEN` sem índice que sirva. No Diagnóstico 02 era 24,4% do tempo do banco; no experimento 04 a rota tem mediana ~12,3 s e está na cauda do p95.
- **Situação atual (fato, `diagnostico/06-vendas-por-dia/pre-teste.txt`, banco ocioso, código do experimento 04):** o experimento 01 já resolveu o lado dos itens (`Index Scan using itens_pedido_pedido_id_idx`). O que sobra é um `Parallel Seq Scan` em `pedidos` (500 mil linhas, ~165 mil descartadas por worker) para achar ~4.300 pedidos de 7 dias: **840 ms**, quase tudo no scan de `pedidos`. Dados uniformes: 682–687 pedidos por dia, de 2024-01-01 a 2025-12-31.
- **Pré-teste (fato, mesmo arquivo):** cada índice candidato criado dentro de uma transação com `ROLLBACK` (o `CREATE INDEX` do PostgreSQL é transacional; conferido no fim do arquivo que nenhum índice ficou):

| Opção | Plano em `pedidos` | Tempo (ocioso) |
| --- | --- | --- |
| Hoje | `Parallel Seq Scan` | 840,1 ms |
| A: índice de expressão `((criado_em::date))`, consulta igual | `Bitmap Index Scan on tmp_pedidos_dia` | 33,7 ms |
| B: consulta reescrita como intervalo (`criado_em >= inicio AND criado_em < fim + 1`) + índice em `criado_em` | `Bitmap Index Scan on tmp_pedidos_criado` | 18,4 ms |

  Uma execução só, e B rodou depois de A (cache mais quente: A leu 826 páginas do disco, B só 16). Numa primeira rodada no rascunho (não salva) os dois deram 21,2 e 20,3 ms. Conclusão: A e B são equivalentes, ambos ~25–40× mais rápidos que hoje.
- **Hipótese:** criar o índice de expressão `pedidos ((criado_em::date))` deve derrubar o tempo de `vendas-por-dia` e, por liberar CPU do banco (a rota era ~24% do tempo dele), aumentar as req/s e reduzir o p95 geral, porque a consulta deixa de ler os 500 mil pedidos a cada chamada.
- **Previsões que dá para conferir:**
  - `EXPLAIN`: `Seq Scan on pedidos` vira `Bitmap Index Scan` no novo índice.
  - `vendas-por-dia` cai de ~12 s para perto de 1 s ou menos sob carga.
  - req/s sobe de forma clara e o p95 geral cai, porque `vendas-por-dia` sai da cauda; a cauda passa a ser `top-produtos` e `pedidos-por-status`.
  - Pelo ciclo fechado, `top-produtos` pode piorar (mais chamadas).
  - CPU da API pode subir: a rota continua trazendo ~12.900 linhas por chamada (com `observacoes`) e somando em JS, agora mais vezes por segundo.
- **O que derrubaria a hipótese:** plano sem o índice, ou `vendas-por-dia` e req/s sem mudança além da variação.
- **Fonte da ideia:** F10 (PostgreSQL 16, 11.7 Indexes on Expressions).
- **Por que A e não B:** desempenho equivalente no pré-teste; A não muda código nem a consulta, então o risco ao contrato é nulo e é uma variável só (o banco). B deixaria um índice mais reaproveitável (serve qualquer filtro por intervalo de `criado_em`), mas exige mudar a rota e provar que o intervalo é idêntico ao `::date BETWEEN` (é, para `timestamp` sem fuso, mas é mais uma coisa a provar). Outras alternativas em [Alternativas](#alternativas).
- **Depois deste (ideia separada):** agregar no SQL (`GROUP BY` por dia) em vez de trazer ~12.900 linhas para somar em JS: menos dados trafegando e menos CPU na API. Fica para outro experimento, porque mexe no código e no contrato (formato do dia, somas `bigint` → `Number`).
- **Mudança:** `banco/05-indice-pedidos-dia.sql` (`CREATE INDEX pedidos_criado_em_dia_idx ON pedidos ((criado_em::date))` + `ANALYZE`) — commit `7114534`. Evidência em `047abf3` (commit medido). Resultados em `aea7616`.
- **Custo esperado:** tamanho do índice (medir); escrita mais lenta, e F10 diz que índices de expressão são "relatively expensive to maintain" (não aparece aqui, a API só lê).

#### Evidência do plano (banco ocioso)

`diagnostico/06-vendas-por-dia/explain-depois.txt` (2024-06-01 a 2024-06-07): `Bitmap Index Scan on pedidos_criado_em_dia_idx` (4.786 pedidos achados lendo 7 páginas do índice) + `Index Scan using itens_pedido_pedido_id_idx`. **31,4 ms**, contra 840,1 ms sem o índice no pré-teste. Confirma o pré-teste da opção A (33,7 ms). O `Planning Time` de 12 ms é o cache de catálogo frio logo depois de recriar o banco.

**Custo medido** (`tamanho-indices.txt`): `pedidos_criado_em_dia_idx` **3.552 kB** (~3,5 MB): o menor índice criado até aqui, porque guarda só uma data por pedido. Índices novos somam ~51 MB.

#### Medição sob carga (09/11, mesma sessão do experimento 04)

- **Contrato:** mantido nas 3 execuções (`contrato.txt`)
- **Antes:** experimento 04, as 3 pastas de 09/11 19:41–19:49 em [04-pool-conexoes](#04-pool-conexoes). Sem remedir: medido ~30 min antes, sem reiniciar máquina, Docker ou WSL (só o `down -v && up` do próprio experimento).
- **Depois:** commit `047abf3`, pastas:
  - [`resultados/20261109-201718-05-indice-vendas-por-dia`](../resultados/20261109-201718-05-indice-vendas-por-dia/resumo.txt)
  - [`resultados/20261109-202101-05-indice-vendas-por-dia`](../resultados/20261109-202101-05-indice-vendas-por-dia/resumo.txt)
  - [`resultados/20261109-203110-05-indice-vendas-por-dia`](../resultados/20261109-203110-05-indice-vendas-por-dia/resumo.txt)

| Execução | req/s | mediana | p95 | p99 | erros | banco CPU média | banco mem média | API CPU média | API mem média |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 201718 | 11.35 | 312.0 ms | 7177.6 ms | 30188.7 ms | 0.00% | 96.6% | 423.6 MiB | 18.4% | 48.0 MiB |
| 202101 | 11.19 | 320.4 ms | 8445.2 ms | 29885.9 ms | 0.00% | 97.2% | 424.8 MiB | 20.0% | 57.7 MiB |
| 203110 | 10.70 | 301.1 ms | 9592.1 ms | 34764.7 ms | 0.00% | 99.2% | 422.9 MiB | 18.1% | 43.4 MiB |
| **Mediana** | **11.19** | **312.0 ms** | **8445.2 ms** | **30188.7 ms** | — | **97.2%** | **423.6 MiB** | **18.4%** | **48.0 MiB** |

| Métrica (mediana das 3) | 04-pool-conexoes | 05-indice-vendas-por-dia | Variação |
| --- | --- | --- | --- |
| Requisições/s | 9.43 | 11.19 | +18,7% (faixas 9,26–9,60 → 10,70–11,35, sem sobreposição) |
| p95 geral | 13042.1 ms | 8445.2 ms | **−35,2%** (faixas 12,98–13,42 s → 7,18–9,59 s, sem sobreposição) |
| p99 geral | 20497.8 ms | 30188.7 ms | **+47% (pior)** |
| Mediana geral | 302.8 ms | 312.0 ms | ≈ igual (faixas se sobrepõem) |
| Banco CPU média | 100.3% | 97.2% | ≈ no teto |
| Banco mem média | 416.7 MiB | 423.6 MiB | +6,9 MiB |
| API CPU média | 17.1% | 18.4% | ≈ igual |
| API mem média | 75.2 MiB | 48.0 MiB | −27 MiB; varia muito entre execuções (43–58 MiB aqui, 68–90 no 04), provavelmente coleta de lixo do Node: não interpretar |

Por rota (mediana das medianas; chamadas por execução):

| Rota | Chamadas 04 → 05 | Mediana 04 | Mediana 05 | Variação | p95 04 → 05 |
| --- | --- | --- | --- | --- | --- |
| `vendas-por-dia` | 46–48 → 48–53 | 12260.1 ms | 3518.6 ms | **−71%** | 15708.3 → 9615.7 ms (−39%) |
| `top-produtos` | 9–11 → 10–11 | 21886.7 ms | 28646.2 ms | +31% (10–11 amostras) | — |
| `pedidos-por-status` | 83–94 → 97–105 | 1251.5 ms | 1290.9 ms | ≈ igual | **14877.9 → 28075.9 ms (+89%)** |
| `cliente` | | 95.1 ms | 95.2 ms | ≈ igual | |
| `pedidos-do-cliente` | | 202.6 ms | 204.7 ms | ≈ igual | |
| `busca-produtos` | | 300.4 ms | 304.2 ms | ≈ igual | |
| `cliente-por-email` | | 700.7 ms | 714.7 ms | ≈ igual | |

#### Previsões × resultado

| Previsão | Resultado |
| --- | --- |
| `Seq Scan` vira `Bitmap Index Scan` no novo índice | confirmada (840 → 31 ms ocioso) |
| `vendas-por-dia` cai de ~12 s para ~1 s ou menos | **parcial**: −71%, mas ainda 3,5 s |
| req/s sobe de forma clara e o p95 geral cai | confirmada: +18,7% e −35% |
| `top-produtos` pode piorar | confirmada: +31% (poucas amostras) |
| CPU da API pode subir | ≈ igual (17,1% → 18,4%) |
| (não previsto) | cauda de `pedidos-por-status` quase dobrou (p95 +89%) e o p99 geral piorou 47% |

**Por que `vendas-por-dia` ainda leva 3,5 s (hipótese):** a consulta leva 31 ms com o banco ocioso, mas o banco segue a ~97% de CPU, então ela espera na fila; e cada chamada ainda leva ~12.900 linhas (com `observacoes`, ~274 caracteres cada) do banco para a API, para somar em JS. A agregação no SQL (alternativa C) testaria a segunda parte.

**Por que a cauda de `pedidos-por-status` e o p99 pioraram (hipótese):** a mediana dessa rota não mudou (~1,3 s), mas o p95 dobrou: uma parte das chamadas fica muito lenta (23–36 s de p95). Com a CPU liberada por `vendas-por-dia`, a vazão subiu e `pedidos-por-status` foi mais chamada (+16%), disputando o banco com `top-produtos` (agregação de 1,5 milhão de linhas, ~29 s). As chamadas lentas devem ser as de `count(*)` em `pago` (300 mil entradas) e as de página alta, quando coincidem com um `top-produtos` em andamento. Não verificado: precisaria de um ranking novo (`pg_stat_statements`) ou dos tempos por status/página.

- **Conclusão:** aplicada e medida, com ganho. +18,7% de vazão e p95 geral −35%, por um índice de 3,5 MB, sem mudar código nem resposta. `vendas-por-dia` caiu 71%, mas não sumiu da fila. Em troca, o gargalo ficou ainda mais concentrado: `top-produtos` e a cauda de `pedidos-por-status` agora decidem o p99.
- **Gargalo que apareceu depois:** `top-produtos` (P7, ~29 s de mediana) e o `count(*)` de `pedidos-por-status` (P5). Agregar `vendas-por-dia` no SQL (alternativa C) fica como candidato menor. **Corrigido pelo Diagnóstico 03:** a cauda não era o `count(*)`, era a própria consulta de página.

### 06-pedidos-late-lookup

- **Status:** aplicada e medida — cauda de `pedidos-por-status` eliminada; ganho em vazão e p99; os relatórios pioraram (ciclo fechado)
- **Problema:** P4b (página de `/pedidos`): 46,7% do tempo do banco no Diagnóstico 03, o maior consumidor isolado. Escolhido pelas prioridades revistas, na frente de `top-produtos` (21,3%).
- **Situação atual (fatos, `diagnostico/07-ranking-apos-05/` e `diagnostico/08-pedidos-offset/pre-teste.txt`):**
  - O `SELECT *` com `OFFSET` busca da tabela as até 20.000 linhas inteiras (~299 bytes, com `observacoes`) que vai descartar: ~10.100 páginas (~79 MB) por chamada na média sob carga.
  - Para `cancelado` e nos offsets além do fim (`pagina=15000`), o planejador troca para `Seq Scan` + ordenação em disco (origem dos blocos temporários do Diagnóstico 03).
  - Piores casos ociosos hoje: `entregue`@19980 = 444 ms; `cancelado`@19980 = 619 ms (com disco); `pago`@299980 = 993 ms (com disco).
- **Hipótese:** reescrever a consulta como "late row lookup" — uma subconsulta pega só os 20 `id` via `Index Only Scan` no índice `(status, criado_em DESC, id DESC)` e um `JOIN` busca as 20 linhas inteiras pela chave primária — deve cortar a cauda de `pedidos-por-status` (p95 da rota) e o p99 geral, e aumentar as req/s, porque as linhas puladas deixam de ir à tabela (ficam só no índice, `Heap Fetches: 0`) e o planejador para de recorrer à ordenação em disco.
- **Pré-teste (fato, mesmo arquivo; consultas com valores literais, banco ocioso):**

| Caso | Atual | Reescrita |
| --- | --- | --- |
| `pago` OFFSET 0 | 3,8 ms | 19,6 ms |
| `pago` OFFSET 19980 | 131,4 ms | 46,3 ms |
| `pendente` OFFSET 19980 | 229,6 ms (Sort em memória) | 22,3 ms |
| `pago` OFFSET 299980 (caso do contrato `pagina=15000`) | 992,9 ms (`external merge` ~30 MB/worker) | 73,3 ms |

  A reescrita percorre as 300 mil entradas do índice em 48,8 ms sem tocar a tabela (`Heap Fetches: 0`) e ordena só as 20 linhas finais (quicksort de 31 kB). Não testada ociosa para `cancelado`/`entregue`: colher no `EXPLAIN` depois da mudança. O caso `OFFSET 0` piora uns 16 ms (duas idas ao índice em vez de uma); irrelevante perto do ganho na cauda.
- **Previsões que dá para conferir:**
  - `EXPLAIN` da reescrita em todos os status: `Index Only Scan` com `Heap Fetches: 0` + `Index Scan using pedidos_pkey`, sem `external merge`.
  - p95 da rota `pedidos-por-status` (hoje 23–36 s sob carga) cai forte; p99 geral (30,2 s) cai; req/s sobe acima da deriva de ~10% do mesmo dia.
  - Blocos temporários da consulta somem (conferir num ranking futuro).
  - Pelo ciclo fechado, os relatórios são mais chamados; `top-produtos` pode piorar e segue como próximo alvo.
  - Banco continua saturado (~97–100%).
- **O que derrubaria a hipótese:** plano sem `Index Only Scan` (ex.: mapa de visibilidade vazio logo após recriar o banco), ou cauda da rota e req/s sem mudança além da variação.
- **Fonte da ideia:** F11 (Winand: o banco precisa buscar e ordenar as linhas que o `OFFSET` vai pular — "big offsets impose a lot of work on the database"); F12 (PostgreSQL 7.6: "The rows skipped by an OFFSET clause still have to be computed inside the server; therefore a large OFFSET might be inefficient"). O "late row lookup" aplica a ideia mantendo a API: as linhas puladas são computadas só no índice, nunca na tabela.
- **Por que esta e não outra:** ver [Alternativas](#alternativas). Keyset/seek (recomendação principal do F11) é impossível aqui sem quebrar o contrato: a API expõe `pagina` numérica de acesso aleatório.
- **Cuidados de contrato:** `ORDER BY` repetido na consulta externa (o `JOIN` não garante ordem); a ordem `(criado_em DESC, id DESC)` é total (desempate por `id`), então as 20 linhas e a ordem são idênticas; página além do fim devolve `[]` como hoje (subconsulta vazia → join vazio; conferido no pré-teste do caso 299980, 0 linhas... conferir na prática pelo contrato); `count(*)` e o resto da rota não mudam.
- **Mudança:** `api/src/rotas.js`, consulta de página de `/pedidos`: `SELECT * ... LIMIT/OFFSET` virou subconsulta de `id` + `JOIN` pela chave primária, com o `ORDER BY` repetido fora — commit `77edbe6`. Evidência em `6deaaab` (commit medido). Observação: a IDE indentou o SQL com 2 espaços a mais que o resto do arquivo; só estilo.
- **Custo esperado:** nenhum recurso novo; `OFFSET 0` ~16 ms mais lento ocioso (duas leituras de índice).

#### Evidência do plano (banco ocioso)

`diagnostico/08-pedidos-offset/explain-depois.txt`: nos 4 status (OFFSET 19980) e no caso `pago` OFFSET 299980, o plano é sempre `Index Only Scan using pedidos_status_criado_em_id_idx` com `Heap Fetches: 0` + 20 × `Index Scan using pedidos_pkey`. Nenhum `Seq Scan`, nenhum `external merge`.

| Caso (ocioso) | Antes (`pre-teste.txt`, consulta atual) | Depois (`explain-depois.txt`) |
| --- | --- | --- |
| `pago` OFFSET 19980 | 131,4 ms | 6,5 ms |
| `entregue` OFFSET 19980 | 444,1 ms | 33,0 ms |
| `cancelado` OFFSET 19980 | 618,9 ms (`Seq Scan` + `external merge`) | 25,1 ms |
| `pendente` OFFSET 19980 | 229,6 ms (`Sort` em memória) | 5,8 ms |
| `pago` OFFSET 299980 | 992,9 ms (`external merge` ~30 MB/worker) | 54,6 ms |

#### Medição sob carga (09/11, mesma noite do experimento 05)

- **Contrato:** mantido nas 3 execuções (`contrato.txt`), inclusive o caso `pagina=15000` (página vazia)
- **Antes:** experimento 05, pastas de 09/11 20:17–20:31 em [05-indice-vendas-por-dia](#05-indice-vendas-por-dia). **Ressalva de sessão:** entre o 05 e o 06 o container do banco foi recriado duas vezes pelo `coletar.sh` do Diagnóstico 03 (sem `down -v`, mesmos dados); o cache voltou a esquentar com a carga do diagnóstico e o pré-teste. Não houve reinício da máquina, do Docker nem do WSL relatado.
- **Depois:** commit `6deaaab`, pastas:
  - [`resultados/20261109-211748-06-pedidos-late-lookup`](../resultados/20261109-211748-06-pedidos-late-lookup/resumo.txt)
  - [`resultados/20261109-211938-06-pedidos-late-lookup`](../resultados/20261109-211938-06-pedidos-late-lookup/resumo.txt)
  - [`resultados/20261109-212142-06-pedidos-late-lookup`](../resultados/20261109-212142-06-pedidos-late-lookup/resumo.txt)

| Execução | req/s | mediana | p95 | p99 | erros | banco CPU média | banco mem média | API CPU média | API mem média |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 211748 | 14.49 | 304.1 ms | 6855.3 ms | 19711.3 ms | 0.00% | 95.2% | 409.2 MiB | 21.8% | 81.7 MiB |
| 211938 | 14.32 | 314.8 ms | 5690.0 ms | 20226.0 ms | 0.00% | 98.3% | 434.3 MiB | 21.4% | 64.9 MiB |
| 212142 | 11.79 | 304.9 ms | 8765.5 ms | 26678.6 ms | 0.00% | 96.5% | 442.4 MiB | 19.4% | 78.7 MiB |
| **Mediana** | **14.32** | **304.9 ms** | **6855.3 ms** | **20226.0 ms** | — | **96.5%** | **434.3 MiB** | **21.4%** | **78.7 MiB** |

| Métrica (mediana das 3) | 05-indice-vendas-por-dia | 06-pedidos-late-lookup | Variação |
| --- | --- | --- | --- |
| Requisições/s | 11.19 | 14.32 | **+28%** (faixas 10,70–11,35 → 11,79–14,49, sem sobreposição; a 3ª execução ficou bem abaixo das outras duas) |
| p99 geral | 30188.7 ms | 20226.0 ms | **−33%** (faixas 29,9–34,8 s → 19,7–26,7 s, sem sobreposição) |
| p95 geral | 8445.2 ms | 6855.3 ms | −19% (faixas 7,2–9,6 s e 5,7–8,8 s **se sobrepõem**: melhora provável, não garantida) |
| Mediana geral | 312.0 ms | 304.9 ms | ≈ igual |
| Banco CPU média | 97.2% | 96.5% | ≈ no teto |
| Banco mem média | 423.6 MiB | 434.3 MiB | +10,7 MiB |
| API CPU média | 18.4% | 21.4% | +3,0 p.p. (mais req/s) |
| API mem média | 48.0 MiB | 78.7 MiB | varia muito entre execuções (coleta de lixo do Node): não interpretar |

Por rota (mediana das medianas; chamadas por execução):

| Rota | Chamadas 05 → 06 | Mediana 05 | Mediana 06 | p95 05 → 06 |
| --- | --- | --- | --- | --- |
| `pedidos-por-status` | 97–105 → 116–142 | 1290.9 ms | 791.1 ms (−39%) | **28075.9 → 1532.9 ms (−95%)**; p99 40599.3 → 2259.8 ms |
| `vendas-por-dia` | 48–53 → 59–67 | 3518.6 ms | 7154.4 ms (**+103%**) | 9615.7 → 16996.0 ms (+77%) |
| `top-produtos` | 10–11 → 12–14 | 28646.2 ms | 37850.0 ms (+32%) | — |
| `cliente-por-email` | | 714.7 ms | 794.2 ms (+11%) | |
| `cliente` | | 95.2 ms | 97.2 ms | |
| `pedidos-do-cliente` | | 204.7 ms | 209.1 ms | |
| `busca-produtos` | | 304.2 ms | 305.8 ms | |

#### Previsões × resultado

| Previsão | Resultado |
| --- | --- |
| `Index Only Scan` + `Heap Fetches: 0`, sem `external merge`, em todos os status | confirmada (5,8–54,6 ms ocioso nos 5 casos) |
| p95 da rota `pedidos-por-status` cai forte | confirmada: 28,1 s → 1,5 s (−95%) |
| p99 geral cai | confirmada: −33% |
| req/s sobe acima da deriva de ~10% | confirmada na mediana (+28%), mas a 3ª execução (11,79) ficou só ~5% acima da mediana do 05: variação alta entre execuções |
| Blocos temporários somem | não medido sob carga (não houve novo ranking); no `EXPLAIN` não há `external merge` |
| `top-produtos` pode piorar | confirmada: +32% |
| (não previsto) | `vendas-por-dia` dobrou (+103%) |
| Banco continua saturado | confirmada: 95,2–98,3% |

**Por que `vendas-por-dia` dobrou (hipótese):** ciclo fechado de novo. Com `pedidos-por-status` rápida, os usuários liberados chamaram mais os dois relatórios (+31% em `vendas-por-dia`, +30% em `top-produtos`), que agora disputam o banco entre si quase sozinhos. `vendas-por-dia` ainda busca ~13 mil itens por chamada e manda ~12.900 linhas para a API; `top-produtos` lê 1,5 milhão de itens. Os dois juntos passam a decidir o p95 e o p99.

- **Conclusão:** aplicada e medida, com ganho. A cauda de `pedidos-por-status` sumiu (p95 da rota −95%), a vazão subiu 28% e o p99 geral caiu 33%, sem recurso novo e sem mudar a resposta. O custo visível é o ciclo fechado empurrando a fila para os relatórios, que pioraram.
- **Gargalo que apareceu depois:** os dois relatórios (P7 `top-produtos` ~38 s; P6c `vendas-por-dia` ~7 s com ~63 chamadas). Seguem as prioridades 2 e 3 do Diagnóstico 03.

### 07-top-produtos-visao-materializada

- **Status:** aplicada e medida — maior ganho do desafio; o gargalo começou a sair do banco. **Implementado e medido pelo Claude Code a pedido** (ver [Uso de IA](#uso-de-ia)).
- **Problema:** P7 (`top-produtos`): a cada chamada agrega todos os 1,5 milhão de itens. Diagnóstico 03: 21,3% do tempo do banco com só 2% da carga; no experimento 06 a rota tem mediana ~38 s e, com `vendas-por-dia`, decide o p95/p99.
- **Situação atual (fato, `diagnostico/09-top-produtos/pre-teste.txt`, banco ocioso):** `Parallel Seq Scan` nos 1,5 milhão de itens + hash join com `pedidos` + agregação de 19.206 produtos, para devolver 10: **1.758,8 ms**. Nenhum índice evita ler todos os itens: o resultado depende de todos eles.
- **Pré-teste (fato, mesmo arquivo; tudo dentro de transação com `ROLLBACK`, conferido no fim que nada ficou):**
  - Construir a visão materializada com o resumo por produto (o custo de um `REFRESH` completo): **978,5 ms**, 19.206 linhas.
  - **Equivalência:** a consulta atual e a nova devolvem as mesmas 19.206 linhas, e comparadas posição a posição (todas as colunas, não só as 50 primeiras) há **0 diferenças**.
  - Nova consulta (`Index Scan` no índice `(receita_centavos DESC, produto_id)` + 10 ou 50 buscas em `produtos_pkey`): **0,103 ms** para limite 10 e para 50.
  - Tamanho: 2.072 kB no total (visão + 2 índices).
- **Hipótese:** pré-calcular o resumo por produto numa visão materializada (`banco/06-resumo-vendas-produto.sql`) e fazer a rota ler dela deve derrubar `top-produtos` de ~38 s para perto do tempo de fila de uma consulta trivial (centenas de ms), aumentar as req/s e reduzir o p99 geral, porque cada chamada deixa de ler 1,5 milhão de itens (~21% do tempo do banco no Diagnóstico 03), liberando CPU para as outras rotas.
- **Previsões que dá para conferir:**
  - `EXPLAIN` da rota: `Index Scan` na visão, sem `Seq Scan` em `itens_pedido`.
  - `top-produtos` cai de ~38 s para < 1 s sob carga.
  - req/s sobe; p99 geral cai (hoje 20,2 s, decidido pelos relatórios).
  - A cauda passa a ser só `vendas-por-dia` (que pelo ciclo fechado deve ser mais chamada; pode melhorar por ter menos concorrência pesada, ou piorar por ser mais chamada).
  - O banco provavelmente sai do teto pela primeira vez ou chega perto (`top-produtos` era a consulta mais cara por chamada).
- **O que derrubaria a hipótese:** a rota não usar a visão no plano, ou req/s e p99 sem mudança além da variação.
- **Fonte da ideia:** F13 (PostgreSQL 16, 41.3 Materialized Views: acesso "often much faster than accessing the underlying tables", com dados que podem ficar desatualizados, e o próprio exemplo de resumo de vendas atualizado à noite) e F14 (`REFRESH MATERIALIZED VIEW ... CONCURRENTLY` exige um índice `UNIQUE` sem expressão nem `WHERE`, criado aqui em `produto_id`).
- **Honestidade sobre os dados (registrar no artigo):** aqui os dados nunca mudam (a API só lê), então a visão nunca fica velha e o ganho medido é o melhor caso. Numa loja real o resumo precisaria ser atualizado: `REFRESH ... CONCURRENTLY` periódico (custo ~1 s de banco por refresh, medido acima; dados com atraso de até um intervalo) ou uma tabela mantida por gatilhos (sempre atual, mas cada `INSERT` em `itens_pedido` fica mais caro). A escolha depende de quanto atraso o negócio aceita no relatório. Isso não foi testado: vai para `proximos-testes.md`.
- **Por que esta e não outra:** ver [Alternativas](#alternativas).
- **Uma mudança lógica, dois arquivos:** a visão (`banco/`) e a consulta da rota (`api/`) não funcionam uma sem a outra; vão no mesmo commit.
- **Cuidados de contrato:** a visão agrupa por `i.produto_id` em vez de `pr.id, pr.nome, pr.categoria`: equivalente, porque `produto_id` é `NOT NULL`, tem chave estrangeira para `produtos` e `pr.id` é chave primária (provado no pré-teste: 0 diferenças). As somas continuam `bigint` → `Number()` na rota. Mesmo desempate (`receita DESC, id`). Casos de erro (`limite=0`, `51`) intocados.
- **Mudança:** `banco/06-resumo-vendas-produto.sql` + `api/src/rotas.js` (rota `top-produtos`) — commit `02fe13e`. Evidência em `15eb4a4` (commit medido). Resultados em `a3ffd77`.
  - Incidente de processo: o primeiro commit da mudança (`cdb35ab`) saiu só com o `.sql`, porque a edição da rota falhou; foi corrigido com `--amend` antes de recriar o banco e de medir (nada pushado nem medido nesse estado).
- **Custo esperado:** ~2 MB de disco; ~1 s a mais na criação do banco; nenhum serviço novo; custo de atualização em produção (não aparece aqui).

#### Evidência

- Criação do banco: o log mostra `running /docker-entrypoint-initdb.d/06-resumo-vendas-produto.sql` e `SELECT 19206`. Esperado ~90 s até o autovacuum terminar em todas as tabelas (inclusive `resumo_vendas_produto`) antes de medir.
- `diagnostico/09-top-produtos/explain-depois.txt`: `Index Scan using resumo_vendas_produto_receita_idx` + `Index Scan using produtos_pkey`; **0,193 ms** (limite 10) e **0,236 ms** (limite 50), contra 1.758,8 ms antes. Nenhum `Seq Scan`.
- `tamanho.txt`: visão + índices = **2.104 kB**.
- Contrato conferido antes de medir: os 5 casos de `top-produtos` iguais.

#### Medição sob carga (09/11, mesma sessão do experimento 06)

- **Contrato:** mantido nas 3 execuções
- **Antes:** experimento 06, pastas de 21:17–21:21. Medido ~15 min antes, sem reinício (só o `down -v && up` do próprio experimento).
- **Depois:** commit `15eb4a4`, pastas:
  - [`resultados/20261109-213632-07-top-produtos-visao-materializada`](../resultados/20261109-213632-07-top-produtos-visao-materializada/resumo.txt)
  - [`resultados/20261109-213755-07-top-produtos-visao-materializada`](../resultados/20261109-213755-07-top-produtos-visao-materializada/resumo.txt)
  - [`resultados/20261109-213918-07-top-produtos-visao-materializada`](../resultados/20261109-213918-07-top-produtos-visao-materializada/resumo.txt)

| Execução | req/s | mediana | p95 | p99 | erros | banco CPU média | banco mem média | API CPU média | API mem média |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 213632 | 36.18 | 424.9 ms | 1446.2 ms | 2203.5 ms | 0.00% | 84.4% | 448.1 MiB | 44.7% | 53.3 MiB |
| 213755 | 39.33 | 364.5 ms | 1404.0 ms | 1948.2 ms | 0.00% | 95.5% | 480.0 MiB | 44.6% | 42.2 MiB |
| 213918 | 39.30 | 383.8 ms | 1370.6 ms | 1837.8 ms | 0.00% | 86.9% | 478.3 MiB | 43.2% | 47.8 MiB |
| **Mediana** | **39.30** | **383.8 ms** | **1404.0 ms** | **1948.2 ms** | — | **86.9%** | **478.3 MiB** | **44.6%** | **47.8 MiB** |

| Métrica (mediana das 3) | 06-pedidos-late-lookup | 07-top-produtos-visao-materializada | Variação |
| --- | --- | --- | --- |
| Requisições/s | 14.32 | 39.30 | **+174% (2,7×)** (faixas 11,79–14,49 → 36,18–39,33) |
| p95 geral | 6855.3 ms | 1404.0 ms | **−80%** |
| p99 geral | 20226.0 ms | 1948.2 ms | **−90%** |
| Mediana geral | 304.9 ms | 383.8 ms | **+26% (pior)** (faixas 304–315 → 365–425 ms, sem sobreposição) |
| Banco CPU média | 96.5% | 86.9% | primeira vez claramente abaixo do teto (84–96%) |
| Banco mem média | 434.3 MiB | 478.3 MiB | **+44 MiB; máximo 507,4 MiB de 512 MiB** |
| API CPU média | 21.4% | 44.6% | **dobrou: ~89% do limite de 0,5 CPU (50%)** |
| API mem média | 78.7 MiB | 47.8 MiB | varia muito (coleta de lixo): não interpretar |

Por rota (mediana das medianas; chamadas por execução):

| Rota | Chamadas 06 → 07 | Mediana 06 | Mediana 07 | Variação |
| --- | --- | --- | --- | --- |
| `top-produtos` | 12–14 → 38–41 | 37850.0 ms | 130.4 ms | **−99,7%** |
| `vendas-por-dia` | 59–67 → 162–183 | 7154.4 ms | 1077.6 ms | **−85%** (p95 16996.0 → 2268.0 ms) |
| `pedidos-por-status` | 116–142 → 307–333 | 791.1 ms | 615.8 ms | −22% |
| `pedidos-do-cliente` | | 209.1 ms | 210.9 ms | ≈ igual |
| `cliente` | | 97.2 ms | 102.5 ms | +5% |
| `cliente-por-email` | 119–144 → 320–345 | 794.2 ms | 973.5 ms | **+23%** |
| `busca-produtos` | 124–148 → 324–356 | 305.8 ms | 439.3 ms | **+44%** |

#### Previsões × resultado

| Previsão | Resultado |
| --- | --- |
| `EXPLAIN` usa a visão, sem `Seq Scan` em itens | confirmada (0,19 ms) |
| `top-produtos` < 1 s sob carga | confirmada: 37,9 s → 0,13 s |
| req/s sobe e p99 cai | confirmada, muito além do previsto: +174% e −90% |
| A cauda passa a ser só `vendas-por-dia` | confirmada, e `vendas-por-dia` também caiu 85% (menos concorrência pesada), mesmo sendo chamada ~2,8× mais |
| O banco sai do teto ou chega perto | parcial: 84–96%, abaixo do teto pela primeira vez |
| (não previsto) | **a mediana geral piorou 26%**; `cliente-por-email` +23% e `busca-produtos` +44% |
| (não previsto) | **CPU da API dobrou e encosta no limite** (44,6% de 50%); memória do banco a 5 MiB do limite no pico |

**Por que a mediana geral piorou (hipótese):** com 2,7× mais requisições por segundo, as consultas baratas mas sem índice passaram a pesar. `cliente-por-email` faz `Seq Scan` em 100 mil clientes (~77 ms quente, Diagnóstico 03) e agora é chamada ~335 vezes por execução: ordem de 25 s de CPU do banco em 60 s, quase metade da CPU dele. `busca-produtos` (`ILIKE` com `Seq Scan`, ~12 ms × ~345 chamadas) soma mais um pouco. Essas rotas rápidas, que são ~45% da carga, esperam mais na fila — e é delas que vem a mediana. **Consequência:** o P8 (índice de e-mail), que era prioridade 4, provavelmente virou a 1. Precisa de um ranking novo para confirmar.

**Por que a CPU da API dobrou (hipótese):** ela atende 2,7× mais requisições; a cada uma serializa o JSON e grava no log o corpo inteiro da resposta (P12); e cada `vendas-por-dia` (~175 por execução) recebe ~12.900 linhas e soma no Node. Com 0,5 CPU de limite, a API está perto de virar o gargalo.

**Risco: memória do banco.** Máximo de 507,4 MiB num limite de 512 MiB. Pode ser cache de arquivos contado no container ou mais processos ativos ao mesmo tempo; não verificado. Se estourar, o container é morto. Vigiar nos próximos experimentos.

- **Conclusão:** aplicada e medida, com o maior ganho do desafio: 2,7× a vazão, p95 −80%, p99 −90%, por ~2 MB e uma consulta nova, com equivalência provada linha a linha. O ganho é o melhor caso, porque os dados nunca mudam aqui; em produção haveria o custo e o atraso do `REFRESH` (não testado). Em troca, a carga extra expôs três novos limites: `cliente-por-email` sem índice, CPU da API e memória do banco.
- **Gargalo que apareceu depois:** P8 (e-mail, provável maior consumidor do banco agora), CPU da API (P12 log + P6c agregação em JS), memória do banco no limite. Recomendado um Diagnóstico 04 antes de escolher.
- **Execução extra (feita pelo Breno):** [`resultados/20261109-214935-07-top-produtos-visao-materializada`](../resultados/20261109-214935-07-top-produtos-visao-materializada/resumo.txt), commit `22894c0` (mesmo código do `15eb4a4`, só documentação a mais): 38,95 req/s, p95 1.341,6 ms, p99 1.717,5 ms, contrato mantido. Coerente com as 3 execuções; não entra nas medianas acima (que usam as 3 do protocolo).

### 08-indice-email

- **Status:** aplicada e medida — ganho; **o banco saiu da saturação e o gargalo passou para a API**. **Implementado e medido pelo Claude Code a pedido.**
- **Problema:** P8 (`/clientes?email=`): `lower(email) = lower($1)` sem índice que sirva → `Seq Scan` em 100 mil clientes a cada chamada. Decidido fazer antes do Diagnóstico 04 (escolha do Breno), com base na estimativa do experimento 07.
- **Situação atual (fato, `diagnostico/10-email/pre-teste.txt`, banco ocioso):** `Seq Scan on clientes`, 99.999 linhas descartadas, **29,3 ms** (e-mail existente) e 29,6 ms (`CLIENTE3@EXEMPLO.COM`). No experimento 07 a rota foi chamada 320–345 vezes por execução: só esta consulta, ociosa, seria ~10 s de CPU do banco em 60 s; sob carga, mais.
- **Pré-teste (fato, mesmo arquivo; índice criado dentro de transação com `ROLLBACK`, conferido que nada ficou):** `Index Scan using clientes_lower_email_idx` em 0,077 ms (existente), 0,043 ms (maiúsculas) e 0,036 ms (inexistente). Índice de **4.792 kB**. Não há e-mails repetidos em `lower(email)`.
- **Hipótese:** criar o índice de expressão `clientes (lower(email))` deve derrubar `cliente-por-email` (~974 ms de mediana sob carga) e, ao tirar ~1/4 a 1/2 da CPU do banco, reduzir a mediana geral (que piorou 26% no experimento 07) e aumentar as req/s.
- **Previsões que dá para conferir:**
  - `EXPLAIN`: `Index Scan using clientes_lower_email_idx`.
  - `cliente-por-email` cai para perto de `cliente` (~100 ms, também uma busca por índice).
  - Mediana geral cai e as rotas rápidas (`cliente`, `busca-produtos`, `pedidos-do-cliente`) melhoram por esperarem menos.
  - req/s sobe, mas **talvez pouco**: a API já está a ~89% da sua cota de CPU (44,6% de 50%); se o banco aliviar, a API pode virar o teto.
  - CPU do banco cai abaixo dos ~87% do experimento 07.
- **O que derrubaria a hipótese:** o plano sem o índice, ou rota e mediana geral sem mudança além da variação.
- **Fonte da ideia:** F10 (PostgreSQL 16, 11.7): o próprio exemplo da documentação é este caso — "a common way to do case-insensitive comparisons is to use the lower function" e "CREATE INDEX test1_lower_col1_idx ON test1 (lower(col1))". F15 (`citext`) como alternativa.
- **Por que índice simples e não `UNIQUE`:** F10 diz que um índice `UNIQUE` em `lower()` impediria e-mails que diferem só em maiúsculas. Hoje não há repetidos, mas isso seria uma regra de negócio nova (e a rota devolve uma **lista**, prevendo vários clientes com o mesmo e-mail). Fora do escopo de desempenho.
- **Cuidados de contrato:** consulta igual, só muda o plano; `ORDER BY id` continua.
- **Mudança:** `banco/07-indice-clientes-email.sql` — commit `516c2ad`. Evidência em `3dd7fa4` (commit medido). Resultados em `6d2aa5c`.
- **Custo esperado:** ~4,8 MB de índice; escrita em `clientes` mais lenta (não aparece aqui).

#### Evidência

- Log da criação do banco: `running /docker-entrypoint-initdb.d/07-indice-clientes-email.sql`; autovacuum concluído em todas as tabelas antes de medir (~90 s).
- `diagnostico/10-email/explain-depois.txt`: os 4 casos de e-mail do contrato (`cliente3@exemplo.com`, `Cliente4@Exemplo.com`, `CLIENTE10@EXEMPLO.COM`, `ninguem@exemplo.com`) usam `Index Scan using clientes_lower_email_idx`, 0,075–0,117 ms. Antes: `Seq Scan`, 29,3 ms.
- `tamanho-indices.txt`: `clientes_lower_email_idx` 4.792 kB.
- Contrato conferido antes de medir: os 5 casos de e-mail iguais.

#### Medição sob carga (09/11, mesma sessão do experimento 07)

- **Contrato:** mantido nas 3 execuções
- **Antes:** experimento 07, 3 pastas de 21:36–21:39 (a execução extra de 21:49 confirma a faixa)
- **Depois:** commit `3dd7fa4`, pastas:
  - [`resultados/20261109-215711-08-indice-email`](../resultados/20261109-215711-08-indice-email/resumo.txt)
  - [`resultados/20261109-215833-08-indice-email`](../resultados/20261109-215833-08-indice-email/resumo.txt)
  - [`resultados/20261109-215955-08-indice-email`](../resultados/20261109-215955-08-indice-email/resumo.txt)

| Execução | req/s | mediana | p95 | p99 | erros | banco CPU média | banco mem média | API CPU média | API mem média |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 215711 | 42.47 | 393.9 ms | 1207.6 ms | 1612.6 ms | 0.00% | 57.9% | 450.3 MiB | 49.1% | 45.5 MiB |
| 215833 | 45.40 | 319.7 ms | 1191.8 ms | 1772.0 ms | 0.00% | 62.9% | 455.5 MiB | 48.2% | 52.6 MiB |
| 215955 | 46.31 | 314.0 ms | 1198.9 ms | 1608.0 ms | 0.00% | 73.8% | 451.4 MiB | 47.7% | 40.9 MiB |
| **Mediana** | **45.40** | **319.7 ms** | **1198.9 ms** | **1612.6 ms** | — | **62.9%** | **451.4 MiB** | **48.2%** | **45.5 MiB** |

| Métrica (mediana das 3) | 07-top-produtos-visao-materializada | 08-indice-email | Variação |
| --- | --- | --- | --- |
| Requisições/s | 39.30 | 45.40 | +15,5% (faixas 36,18–39,33 → 42,47–46,31, sem sobreposição) |
| p95 geral | 1404.0 ms | 1198.9 ms | −14,6% (faixas 1,37–1,45 s → 1,19–1,21 s, sem sobreposição) |
| p99 geral | 1948.2 ms | 1612.6 ms | −17,2% (faixas 1,84–2,20 s → 1,61–1,77 s, sem sobreposição) |
| Mediana geral | 383.8 ms | 319.7 ms | −16,7% (faixas 365–425 → 314–394 ms, **se sobrepõem**) |
| Banco CPU média | 86.9% | 62.9% | **−24 p.p.: o banco saiu da saturação** (57,9–73,8%) |
| Banco mem média | 478.3 MiB | 451.4 MiB | −27 MiB (máx. 497,1 MiB) |
| API CPU média | 44.6% | 48.2% | **96% da cota de 0,5 CPU: a API é o novo teto** |
| API mem média | 47.8 MiB | 45.5 MiB | ≈ igual |

Por rota (mediana das medianas):

| Rota | Mediana 07 | Mediana 08 | Variação |
| --- | --- | --- | --- |
| `cliente-por-email` | 973.5 ms | 195.2 ms | **−80%** |
| `vendas-por-dia` | 1077.6 ms | 969.0 ms | −10% |
| `busca-produtos` | 439.3 ms | 413.3 ms | −6% |
| `pedidos-por-status` | 615.8 ms | 630.9 ms | ≈ igual |
| `pedidos-do-cliente` | 210.9 ms | 297.3 ms | **+41%** |
| `cliente` | 102.5 ms | 181.5 ms | **+77%** |
| `top-produtos` | 130.4 ms | 193.0 ms | **+48%** |

#### Previsões × resultado

| Previsão | Resultado |
| --- | --- |
| `Index Scan` no novo índice | confirmada (4 casos, ≤ 0,12 ms) |
| `cliente-por-email` cai para perto de `cliente` | confirmada: 974 → 195 ms; hoje as duas estão em ~180–195 ms |
| Mediana geral cai e as rotas rápidas melhoram | **parcial/refutada**: mediana geral −17% (faixas se sobrepõem), mas `cliente` (+77%), `pedidos-do-cliente` (+41%) e `top-produtos` (+48%) **pioraram** |
| req/s sobe pouco porque a API está perto do teto | confirmada: +15,5%, e a API chegou a 96% da cota |
| CPU do banco cai abaixo de 87% | confirmada: 62,9% |

**Por que as rotas mais baratas pioraram (hipótese):** pela primeira vez o banco tem folga (63% de CPU), mas a API está a 96% da sua cota de 0,5 CPU. As rotas cujo trabalho no banco é quase nulo (`cliente`: uma busca por chave primária; `top-produtos`: 10 linhas prontas) agora gastam o tempo esperando a vez no processo Node (laço de eventos com uma CPU limitada), não no banco. O gargalo mudou de lugar: daqui para frente, otimizar o banco quase não ajuda; o que pesa é o trabalho da API por requisição (serializar JSON, gravar o corpo inteiro de cada resposta no log — P12 —, receber e somar ~12.900 linhas por `vendas-por-dia`, converter datas).

- **Conclusão:** aplicada e medida, com ganho: +15,5% de vazão, p95 −15%, p99 −17% e a rota −80%, por um índice de 4,8 MB. O resultado mais importante é estrutural: **o banco deixou de ser o gargalo** (63% de CPU) e **a API passou a ser** (96% da cota).
- **Gargalo que apareceu depois:** CPU da API. Diagnóstico 04 deve medir onde o processo Node gasta CPU.

### 09-vendas-agregada-no-sql

- **Status:** aplicada e medida — maior queda de mediana do desafio; a API saiu do teto e o banco voltou a ser o limite. **Implementado e medido pelo Claude Code a pedido.**
- **Problema:** P6c (`vendas-por-dia`): a rota traz ~12.900 linhas (pedido × item, com `criado_em` e `observacoes`) para somar por dia no Node. Diagnóstico 04: ≈ 99% das linhas que a API analisa (2,43 mi em 60 s), a maior parte da CPU da API (análise de linhas, `parseDate`, GC) e 39,3% do tempo do banco. Prioridade 1 do Diagnóstico 04.
- **Pré-teste (fato, `diagnostico/12-vendas-sql/pre-teste.txt`; só leitura):**
  - **Equivalência (`equivalencia.js`, rodado dentro do container da API — mesmo Node 20.18, mesmo `pg`, `TZ=UTC`):** para cada janela, roda a consulta atual + a agregação em JS copiada de `rotas.js`, e a consulta nova + a formatação nova, e compara o `JSON.stringify` dos dois. **735 janelas** (as 725 que a carga pode sortear, as 4 do contrato que devolvem 200, e 6 bordas: 31 dias, fora dos dados antes e depois, último dia, 29/02/2024), **5.160 dias, 0 diferenças**. Essas janelas, pelo caminho atual, levariam 9.529.464 linhas para a API.
  - **Banco (2024-06-01 a 2024-06-07, ocioso):** atual 25,3 ms devolvendo 12.922 linhas; nova 20,0 ms devolvendo 7 (`GroupAggregate` sobre o mesmo `Bitmap Index Scan` do experimento 05, ordenação em memória de ~0,5 MB).
- **Hipótese:** agregar no SQL (`GROUP BY` do dia, `count(DISTINCT p.id)`, `sum`) deve derrubar a CPU da API e o tempo de `vendas-por-dia`, aumentar as req/s e devolver às rotas baratas (`cliente`, `top-produtos`, `pedidos-do-cliente`) o tempo que perderam no experimento 08, porque a API deixa de analisar ~2,4 milhões de linhas por minuto (e de criar os `Date` e as strings de `observacoes` delas) e o banco deixa de enviá-las.
- **Previsões que dá para conferir:**
  - CPU da API cai bem abaixo dos 48,2% (96% da cota) do experimento 08.
  - `vendas-por-dia` cai de ~970 ms para perto de uma consulta comum (centenas de ms ou menos).
  - `cliente`, `top-produtos` e `pedidos-do-cliente` voltam para perto do experimento 07 (~100, ~130 e ~210 ms).
  - req/s sobe; com a API aliviada, o banco deve voltar a ser o limite, puxado por `busca-produtos` e `count(*)` (prioridades 2 e 3).
  - O tempo do banco nesta consulta muda pouco: a agregação passa a ser feita lá, mas sem enviar as linhas.
- **O que derrubaria a hipótese:** CPU da API sem queda clara, ou req/s sem mudança além da variação.
- **Fonte:** a ideia vem do Diagnóstico 04 (medição própria). Fonte externa a buscar na fase de pesquisa (ex.: documentação de agregação do PostgreSQL / custo de transferir linhas ao cliente).
- **Cuidados de contrato (todos cobertos pela prova de equivalência):** `dia` sai como texto `'YYYY-MM-DD'` via `to_char` (um `date` cru viraria `Date` no Node e mudaria o JSON); `count`/`sum` voltam como `bigint` em texto e passam por `Number()`; ordem por dia crescente; dias sem venda continuam ausentes; só pedidos com itens contam (o `JOIN` interno é o mesmo); ordem dos campos `dia, pedidos, itens, receita_centavos`. Validação de datas e erros 400 intocados.
- **Mudança:** `api/src/rotas.js`, rota `vendas-por-dia`: a consulta passa a agrupar por dia no banco e a rota só formata as ≤ 31 linhas (−22 linhas de JS) — commit `3da8e3e`. Evidência em `adf386e` (commit medido). Resultados em `c9835b3`.
- **Custo esperado:** um pouco mais de CPU no banco por chamada (agrupar e contar distintos), compensado por não serializar e enviar as linhas.

#### Evidência

- `diagnostico/12-vendas-sql/explain-depois.txt`: `GroupAggregate` sobre o `Bitmap Index Scan on pedidos_criado_em_dia_idx`, 7 linhas, **19,8 ms** ocioso (igual ao pré-teste).
- Contrato conferido antes de medir: os 7 casos de `vendas-por-dia` iguais, inclusive os 3 de erro (período invertido, 61 dias, `2024-02-30`).
- Resposta conferida à mão: `/relatorios/vendas-por-dia?inicio=2024-01-01&fim=2024-01-03` devolve `[{"dia":"2024-01-01","pedidos":616,"itens":3703,"receita_centavos":911023510}, ...]`.

#### Medição sob carga (09/11, mesma noite)

- **Contrato:** mantido nas 3 execuções
- **Antes:** experimento 08, 3 pastas de 21:57–21:59. Entre eles: Diagnóstico 04 (containers recriados duas vezes, sem `down -v`) e o pré-teste de equivalência.
- **Depois:** commit `adf386e`, pastas:
  - [`resultados/20261109-222257-09-vendas-agregada-no-sql`](../resultados/20261109-222257-09-vendas-agregada-no-sql/resumo.txt)
  - [`resultados/20261109-222417-09-vendas-agregada-no-sql`](../resultados/20261109-222417-09-vendas-agregada-no-sql/resumo.txt)
  - [`resultados/20261109-222536-09-vendas-agregada-no-sql`](../resultados/20261109-222536-09-vendas-agregada-no-sql/resumo.txt)

| Execução | req/s | mediana | p95 | p99 | erros | banco CPU média | banco mem média | API CPU média | API mem média |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 222257 | 72.44 | 106.3 ms | 899.6 ms | 1802.5 ms | 0.00% | 98.5% | 451.3 MiB | 10.2% | 26.3 MiB |
| 222417 | 74.50 | 103.2 ms | 899.9 ms | 1796.6 ms | 0.00% | 99.5% | 459.8 MiB | 9.4% | 26.7 MiB |
| 222536 | 73.51 | 104.8 ms | 897.5 ms | 1699.5 ms | 0.00% | 98.4% | 462.9 MiB | 9.8% | 26.8 MiB |
| **Mediana** | **73.51** | **104.8 ms** | **899.6 ms** | **1796.6 ms** | — | **98.5%** | **459.8 MiB** | **9.8%** | **26.7 MiB** |

| Métrica (mediana das 3) | 08-indice-email | 09-vendas-agregada-no-sql | Variação |
| --- | --- | --- | --- |
| Requisições/s | 45.40 | 73.51 | **+62%** (faixas 42,47–46,31 → 72,44–74,50) |
| Mediana geral | 319.7 ms | 104.8 ms | **−67%** (faixas 314–394 → 103–106 ms) |
| p95 geral | 1198.9 ms | 899.6 ms | −25% (faixas 1,19–1,21 s → 0,90 s) |
| p99 geral | 1612.6 ms | 1796.6 ms | +11% (faixas 1,61–1,77 s e 1,70–1,80 s **se sobrepõem**: ≈ igual ou um pouco pior) |
| API CPU média | 48.2% | 9.8% | **−80%: de 96% para ~20% da cota** |
| API mem média | 45.5 MiB | 26.7 MiB | −18,8 MiB, e estável entre execuções (26,3–26,8; antes variava 41–58): bem menos lixo para o GC |
| Banco CPU média | 62.9% | 98.5% | **voltou ao teto** |
| Banco mem média | 451.4 MiB | 459.8 MiB | ≈ (máx. 498,4 MiB) |

Por rota (mediana das medianas; chamadas por execução):

| Rota | Chamadas 08 → 09 | Mediana 08 | Mediana 09 | Variação |
| --- | --- | --- | --- | --- |
| `pedidos-do-cliente` | 540–583 → 893–928 | 297.3 ms | 102.3 ms | −66% |
| `top-produtos` | 44–45 → 77–80 | 193.0 ms | 94.6 ms | −51% |
| `cliente-por-email` | 377–411 → 638–653 | 195.2 ms | 97.0 ms | −50% |
| `cliente` | 660–710 → 1141–1162 | 181.5 ms | 94.9 ms | −48% |
| `pedidos-por-status` | 359–391 → 634–653 | 630.9 ms | 397.7 ms | −37% |
| `busca-produtos` | 396–428 → 649–666 | 413.3 ms | 305.8 ms | −26% |
| `vendas-por-dia` | 202–219 → 340–344 | 969.0 ms | 803.3 ms | −17%; p95 1683.5 → 2503.7 ms (+49%), p99 ~4,5–4,7 s |

#### Previsões × resultado

| Previsão | Resultado |
| --- | --- |
| CPU da API cai bem abaixo de 48,2% | confirmada: 9,8% |
| `vendas-por-dia` cai para centenas de ms ou menos | **parcial**: mediana 803 ms (−17%), e a cauda piorou: a rota foi 60% mais chamada num banco de novo saturado |
| `cliente`, `top-produtos`, `pedidos-do-cliente` voltam para perto do experimento 07 | confirmada, e ficaram melhores que no 07 (95, 95 e 102 ms contra 102, 130 e 211) |
| req/s sobe; o banco volta a ser o limite | confirmada: +62%; banco 98,5% |
| Tempo do banco nesta consulta muda pouco | não medido sob carga (falta ranking); ocioso: 25,3 → 19,8 ms |

#### Achado: os tempos estão "quantizados" em múltiplos de ~100 ms (throttling do limite de CPU)

- **Fato (`resumo.txt`):** quase todos os tempos ficaram perto de múltiplos de 100 ms: medianas 95, 97, 102, 306, 398, 803 ms; p95 194–202, 297, 593–600, 900 ms. Isso não aparece em lógica de aplicação.
- **Fato (`diagnostico/12-vendas-sql/cgroup-cpu.txt`, lido logo depois das medições):** o container do banco tem `cpu.max = 100000 100000` (100 ms de CPU por período de 100 ms = 1 CPU). Desde o início do container, **2.291 de 4.501 períodos (51%) foram limitados (throttled)**, somando 2.621,8 s de espera. A API: 7 de 2.340. Contadores acumulados desde a criação do container (inclui aquecimentos e contratos), não só a janela medida.
- **Fonte:** F16 (documentação do kernel Linux, CFS Bandwidth Control): dentro de cada período o grupo recebe até "quota" de CPU; "Throttled threads will not be able to run again until the next period when the quota is replenished"; período padrão de 100 ms.
- **Hipótese:** quando o banco gasta a cota de 100 ms antes do fim do período, todas as consultas em andamento ficam paradas até o período seguinte. Uma consulta de < 1 ms que cai nesse momento espera o resto do período: daí os degraus de ~100 ms. Ou seja, abaixo de ~100 ms o que limita a latência hoje é o **limite de CPU do container**, não a consulta.
- **Consequências para o trabalho:** (1) daqui para frente, otimizações que tiram poucos ms por consulta podem não aparecer na mediana; o que conta é reduzir a CPU total do banco (sair do throttling). (2) É um efeito do ambiente de medição (limite de 1 CPU), que também existiria num container com o mesmo limite em produção. (3) Vale para "Limites" e para o artigo: explica por que tempos sob carga não se parecem com os do `EXPLAIN`.

- **Conclusão:** aplicada e medida, com ganho grande: +62% de vazão e mediana −67% (de 320 para 105 ms), sem recurso novo, com equivalência provada em 735 janelas. A API caiu de 96% para ~20% da cota e passou a usar 19 MiB a menos de memória. O gargalo voltou ao banco, que agora passa metade dos períodos limitado pela cota de CPU; `vendas-por-dia` ficou com a pior cauda (p99 ~4,6 s).
- **Gargalo que apareceu depois:** CPU do banco: `busca-produtos` (P9) e `count(*)` (P5), que no Diagnóstico 04 já somavam 56% do banco, mais o próprio `vendas-por-dia`. Seguem as prioridades 2 e 3.

### 10-busca-trigramas

- **Status:** aplicada e medida — ganho em vazão; a CPU liberada virou mais requisições, não folga. **Implementado e medido pelo Claude Code a pedido.**
- **Problema:** P9 (`/produtos/busca`): `nome ILIKE '%' || termo || '%'` com `%` no começo; nenhum B-tree serve, então é `Seq Scan` nos 20 mil produtos a cada chamada, com comparação sem diferenciar maiúsculas linha a linha. Diagnóstico 04: 29,3% do tempo do banco; experimento 09: rota com mediana ~306 ms, 649–666 chamadas por execução, num banco de volta ao teto. Prioridade 2 do Diagnóstico 04.
- **Pré-teste (fato, `diagnostico/13-busca-trgm/pre-teste.txt`; extensão e índice dentro de transação com `ROLLBACK`, conferido que nada ficou):**
  - Feito com `PREPARE`/`EXECUTE` e `plan_cache_mode = force_custom_plan`, com o mesmo `'%' || $1 || '%'` da rota, para reproduzir o planejamento das consultas sem nome da API (cada chamada é planejada com o valor real).
  - Os 12 termos da carga casam com 1.000 a 2.000 produtos cada (antes do `LIMIT 20`).
  - **Hoje:** `Seq Scan` + ordenação top-N, **9,6–10,6 ms** por termo (inclusive para `inexistente`, que não casa com nada).
  - **Com o índice GIN `pg_trgm`:** `Bitmap Index Scan on produtos_nome_trgm_idx`, **0,95–1,95 ms** por termo; `inexistente` **0,03 ms**.
  - **Equivalência:** os 20 primeiros resultados de cada um dos 14 termos (260 linhas), com o índice e com o índice desligado (`enable_bitmapscan`/`enable_indexscan = off`), comparados com `EXCEPT ALL` incluindo a posição: **0 diferenças**.
  - Índice: **1.144 kB**.
- **Hipótese:** um índice GIN de trigramas em `produtos.nome` deve reduzir a CPU que o banco gasta em `busca-produtos` (~5–10× menos por chamada no ocioso) e, como o banco está no teto e em throttling em ~metade dos períodos, aumentar as req/s e baixar a mediana das rotas baratas, porque a busca deixa de comparar os 20 mil nomes a cada chamada e passa a visitar só os ~1.000–2.000 candidatos que o índice aponta.
- **Previsões que dá para conferir:**
  - `EXPLAIN` da rota: `Bitmap Index Scan on produtos_nome_trgm_idx` em todos os termos da carga.
  - `busca-produtos` cai de ~306 ms para perto do degrau de ~100 ms das rotas baratas.
  - CPU do banco cai abaixo de 98,5% (menos throttling); req/s sobe.
  - Ganho total **menor** que o do experimento 09: o custo ocioso por chamada era ~10 ms, e os maiores consumidores restantes provavelmente são `count(*)` e `vendas-por-dia`.
- **O que derrubaria a hipótese:** o planejador não usar o índice com o padrão vindo de parâmetro, ou rota e req/s sem mudança além da variação.
- **Fonte da ideia:** F17 (PostgreSQL 16, F.35 pg_trgm): os índices GIN/GiST de trigramas "support trigram-based index searches for LIKE, ILIKE [...] queries" e "the search string need not be left-anchored"; aviso: padrões sem trigramas extraíveis degeneram em varredura do índice inteiro (não é o caso: a rota exige ≥ 3 caracteres). A extensão é "trusted": pode ser instalada sem superusuário.
- **Por que esta e não outra:** ver [Alternativas](#alternativas).
- **Cuidados de contrato:** consulta igual (só muda o plano); mesmos resultados e ordem (provado no pré-teste); o caso `ab` (< 3 caracteres) continua recusado pela rota antes de chegar ao banco.
- **Mudança:** `banco/08-indice-produtos-trigramas.sql` (`CREATE EXTENSION pg_trgm` + índice GIN) — commit `0520020`. Evidência em `668745f` (commit medido). Resultados em `d1f3c8f`.
- **Custo esperado:** ~1,1 MB de índice; escrita em `produtos` mais lenta (índice GIN é mais caro de atualizar); não aparece aqui.

#### Evidência

- Log da criação do banco: `running /docker-entrypoint-initdb.d/08-indice-produtos-trigramas.sql`; autovacuum concluído em todas as tabelas antes de medir.
- `diagnostico/13-busca-trgm/explain-depois.txt` (consulta parametrizada, planos customizados como na API): `Bitmap Index Scan on produtos_nome_trgm_idx` para `cadeira`, `sem fio`, `modelo 12`, `reforcada`, `ERGO` (1,7–2,0 ms) e `inexistente` (0,03 ms). Índice: 1.144 kB.
- Contrato conferido antes de medir: os 6 casos de busca iguais (inclusive `ab`, recusado pela rota antes do banco).

#### Medição sob carga (09/11, mesma sessão do experimento 09)

- **Contrato:** mantido nas 3 execuções
- **Antes:** experimento 09, 3 pastas de 22:22–22:25.
- **Depois:** commit `668745f`, pastas:
  - [`resultados/20261109-223641-10-busca-trigramas`](../resultados/20261109-223641-10-busca-trigramas/resumo.txt)
  - [`resultados/20261109-223801-10-busca-trigramas`](../resultados/20261109-223801-10-busca-trigramas/resumo.txt)
  - [`resultados/20261109-223920-10-busca-trigramas`](../resultados/20261109-223920-10-busca-trigramas/resumo.txt)

| Execução | req/s | mediana | p95 | p99 | erros | banco CPU média | banco mem média | API CPU média | API mem média |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 223641 | 90.09 | 100.4 ms | 809.8 ms | 1805.1 ms | 0.00% | 98.9% | 453.9 MiB | 12.1% | 26.2 MiB |
| 223801 | 91.26 | 100.7 ms | 805.5 ms | 1491.2 ms | 0.00% | 98.6% | 463.6 MiB | 12.5% | 26.0 MiB |
| 223920 | 91.15 | 100.8 ms | 888.4 ms | 1403.0 ms | 0.00% | 99.3% | 465.6 MiB | 11.4% | 26.9 MiB |
| **Mediana** | **91.15** | **100.7 ms** | **809.8 ms** | **1491.2 ms** | — | **98.9%** | **463.6 MiB** | **12.1%** | **26.2 MiB** |

| Métrica (mediana das 3) | 09-vendas-agregada-no-sql | 10-busca-trigramas | Variação |
| --- | --- | --- | --- |
| Requisições/s | 73.51 | 91.15 | **+24%** (faixas 72,44–74,50 → 90,09–91,26) |
| Mediana geral | 104.8 ms | 100.7 ms | −4% (sem sobreposição, mas é o degrau de ~100 ms: ver experimento 09) |
| p95 geral | 899.6 ms | 809.8 ms | −10% (faixas 0,90 s → 0,81–0,89 s) |
| p99 geral | 1796.6 ms | 1491.2 ms | −17% (faixas 1,70–1,80 s e 1,40–1,81 s **se sobrepõem**) |
| Banco CPU média | 98.5% | 98.9% | ≈ no teto |
| Banco mem média | 459.8 MiB | 463.6 MiB | ≈ |
| API CPU média | 9.8% | 12.1% | sobe com as req/s |
| API mem média | 26.7 MiB | 26.2 MiB | ≈ |

Por rota (mediana das medianas; chamadas por execução):

| Rota | Chamadas 09 → 10 | Mediana 09 | Mediana 10 | Variação |
| --- | --- | --- | --- | --- |
| `busca-produtos` | 649–666 → 801–814 | 305.8 ms | 100.0 ms | **−67%** (p95 596.9 → 201.1 ms) |
| `pedidos-por-status` | 634–653 → 777–786 | 397.7 ms | 391.6 ms | ≈ igual |
| `vendas-por-dia` | 340–344 → 418–427 | 803.3 ms | 802.1 ms | ≈ igual (p95 2503.7 → 2207.4 ms) |
| `cliente`, `cliente-por-email`, `pedidos-do-cliente`, `top-produtos` | ~+23% cada | 94.9 / 97.0 / 102.3 / 94.6 ms | 95.4 / 97.2 / 102.9 / 97.3 ms | ≈ iguais (já no degrau de ~100 ms) |

Throttling do banco (`cpu.stat` lido logo depois das medições, acumulado desde a criação do container ~5 min antes): 2.404 de 2.978 períodos limitados (81%). **Não comparável** diretamente com os 51% do experimento 09: aquele container estava de pé havia mais tempo, com mais períodos ociosos no denominador. Só confirma que o banco segue limitado pela cota.

#### Previsões × resultado

| Previsão | Resultado |
| --- | --- |
| `Bitmap Index Scan` no novo índice em todos os termos | confirmada |
| `busca-produtos` cai de ~306 ms para o degrau de ~100 ms | confirmada: 100,0 ms |
| CPU do banco cai abaixo de 98,5% | **refutada**: 98,9%. A CPU liberada foi consumida na hora por mais requisições (ciclo fechado) |
| req/s sobe | confirmada: +24% |
| Ganho menor que o do experimento 09 | confirmada (+24% contra +62%) |

**Leitura (hipótese):** com o banco no teto e a carga de ciclo fechado, liberar CPU do banco não deixa o banco ocioso: os 20 usuários virtuais passam a fazer mais requisições até ele saturar de novo. O ganho aparece em vazão (+24%), não em CPU. As medianas das rotas baratas já estão no degrau mínimo de ~100 ms do throttling e não têm mais o que cair enquanto o banco estiver no teto.

- **Conclusão:** aplicada e medida, com ganho: +24% de vazão e a rota de busca −67%, por um índice de 1,1 MB, com resultado provado igual. O banco continua no teto.
- **Gargalo que apareceu depois:** `pedidos-por-status` (~392 ms, `count(*)` contando até 300 mil entradas) e `vendas-por-dia` (~802 ms, p99 ~3,4 s). Próximo: P5 (prioridade 3 do Diagnóstico 04).

### 11-contagem-por-status

- **Status:** planejado (hipótese escrita antes da mudança). **Implementado e medido pelo Claude Code a pedido.**
- **Problema:** P5 (`/pedidos?status=`): a cada página a rota conta todos os pedidos do status. Mesmo com `Index Only Scan` (experimento 02) e `Heap Fetches: 0`, conta até 300 mil entradas por chamada. Diagnóstico 04: 27,0% do tempo do banco; experimento 10: rota com mediana ~392 ms, ~780 chamadas por execução. Prioridade 3 do Diagnóstico 04.
- **Pré-teste (fato, `diagnostico/14-contagem-status/pre-teste.txt`; tudo dentro de transação com `ROLLBACK`, conferido que nada ficou; planos customizados como na API):**
  - Hoje: `pago` **65,3 ms** (`Parallel Index Only Scan`, 300 mil entradas), `pendente` 5,8 ms.
  - Construir a visão (custo de um `REFRESH` completo): **93,7 ms**, 4 linhas, 48 kB com o índice.
  - Nova consulta (`coalesce((SELECT total FROM contagem_pedidos_status WHERE status = $1), 0)`): **0,039 ms** (`pago`) e 0,010 ms (`pendente`).
  - **Equivalência:** para os 4 status e para um status sem pedidos (`perdido`), mesmo valor e mesmo tipo (`bigint`) dos dois lados. O `coalesce` existe para isso: o `count(*)` sempre devolve uma linha (0 quando não há pedidos); a visão não teria linha para um status sem pedidos e a rota quebraria em `contagem.total`.
- **Hipótese:** pré-calcular a contagem por status numa visão materializada deve tirar do banco a contagem de até 300 mil entradas por página, reduzindo a mediana de `pedidos-por-status` e aumentando as req/s, porque essa consulta era ~27% do tempo do banco e o banco está no teto.
- **Previsões que dá para conferir:**
  - `pedidos-por-status` cai de ~392 ms para perto do degrau de ~100–200 ms (a rota ainda faz a consulta de página).
  - req/s sobe; pelo experimento 10, o banco deve continuar no teto (a CPU liberada vira mais requisições).
  - `vendas-por-dia` passa a ser, sozinha, a rota que decide p95 e p99.
- **O que derrubaria a hipótese:** rota e req/s sem mudança além da variação.
- **Fonte da ideia:** F13 e F14 (visões materializadas e `REFRESH ... CONCURRENTLY`, que exige o índice `UNIQUE` criado em `status`), as mesmas do experimento 07.
- **Honestidade sobre os dados (mesma ressalva do experimento 07):** aqui os pedidos nunca mudam, então a contagem nunca fica velha. Numa loja real, cada pedido novo ou mudança de status alteraria a contagem: um `REFRESH` periódico (~94 ms de banco) deixaria o total da paginação atrasado até um intervalo; uma tabela de contadores mantida por gatilho ficaria sempre certa, mas cada `INSERT`/`UPDATE` em `pedidos` disputaria a mesma linha do status (gargalo de escrita). A escolha depende de quanto atraso o negócio aceita no "total" da paginação.
- **Por que esta e não outra:** ver [Alternativas](#alternativas).
- **Uma mudança lógica, dois arquivos:** `banco/09-contagem-pedidos-status.sql` + a consulta de contagem em `api/src/rotas.js` (rota `/pedidos`), no mesmo commit.
- **Cuidados de contrato:** `total` continua `Number(...)` de um `bigint`; o `coalesce` mantém 0 para status sem pedidos; a validação de status (400) acontece antes, sem mudança; a consulta de página do experimento 06 não muda.
- **Mudança:** commit `<preencher>`
- **Custo esperado:** 48 kB; ~94 ms a mais na criação do banco; em produção, o custo e o atraso do `REFRESH` (não testado).
- **Antes:** experimento 10, 3 pastas de 09/11 22:36–22:39 (mesma sessão).
- **Depois:** `<preencher pastas>`
- **Resultado (medianas):** `<preencher>`
- **Conclusão:** `<preencher>`

## Fontes

| # | Autor / organização | Título | Link | Acesso | Tipo (doc oficial / acadêmica / técnica primária / caso de mercado / blog) | Abordagem | O que diz (fato) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| F1 | PostgreSQL Global Development Group | PostgreSQL 16 Documentation, 5.4.5 Foreign Keys | https://www.postgresql.org/docs/16/ddl-constraints.html#DDL-CONSTRAINTS-FK | 2026-11-05 | doc oficial | índices | "the declaration of a foreign key constraint does not automatically create an index on the referencing columns"; recomenda indexar essas colunas ("it is often a good idea to index the referencing columns too") |
| F2 | PostgreSQL Global Development Group | PostgreSQL 16 Documentation, 11.1 Introduction (Indexes) | https://www.postgresql.org/docs/16/indexes-intro.html | 2026-11-05 | doc oficial | índices | Sem índice o sistema "would have to scan the entire test1 table, row by row"; o índice precisa ser mantido sincronizado com a tabela, o que "adds overhead to data manipulation operations" |
| F3 | PostgreSQL Global Development Group | PostgreSQL 16 Documentation, F.32 pg_stat_statements — track statistics of SQL planning and execution | https://www.postgresql.org/docs/16/pgstatstatements.html | 2026-11-05 | doc oficial | diagnóstico | "provides a means for tracking planning and execution statistics of all SQL statements executed by a server"; "must be loaded by adding pg_stat_statements to shared_preload_libraries [...] a server restart is needed"; `total_exec_time` = "Total time spent executing the statement, in milliseconds" |
| F5 | GraphQL Foundation (repositório graphql/dataloader) | DataLoader — README, seção "Batching" | https://github.com/graphql/dataloader#batching | 2026-11-05 | técnica primária (doc de biblioteca) | N+1 / lote | "DataLoader will coalesce all individual loads which occur within a single frame of execution (a single tick of the event loop) and then call your batch function with all requested keys."; "A naive application may have issued four round-trips to a backend for the required information, but with DataLoader this application will make at most two." |
| F6 | Rails Guides | Active Record Query Interface, 16.1 "N + 1 Queries Problem" | https://guides.rubyonrails.org/active_record_querying.html#n-1-queries-problem | 2026-11-05 | doc oficial (caso de mercado/framework) | N+1 | **A conferir no navegador:** só o título da seção foi confirmado; o texto da seção (1 consulta + N consultas; `includes` reduz para 2) ainda não foi lido literalmente |
| F7 | PostgreSQL Global Development Group | PostgreSQL 16 Documentation, 52.2 How Connections Are Established | https://www.postgresql.org/docs/16/connect-estab.html | 2026-11-05 | doc oficial | conexões | "PostgreSQL implements a 'process per user' client/server model"; o postmaster "spawns a new backend process every time a connection is requested" |
| F8 | node-postgres (Brian Carlson) | Pooling (#why) e API do Pool (#new-pool, #error) | https://node-postgres.com/features/pooling e https://node-postgres.com/apis/pool | 2026-11-05 | técnica primária (doc da biblioteca usada) | conexões | "Connecting a new client to the PostgreSQL server requires a handshake which can take 20-30 milliseconds"; "Incurring this cost every time we want to execute a query would substantially slow down our application"; `max` "By default this is set to 10"; `idleTimeoutMillis` padrão 10000; sem ouvinte de `error`, o Node "will emit an uncaught error and potentially crash your node process" |
| F9 | Brett Wooldridge (HikariCP) | About Pool Sizing (wiki) | https://github.com/brettwooldridge/HikariCP/wiki/About-Pool-Sizing | 2026-11-05 | técnica / caso de mercado (cita o projeto PostgreSQL e um vídeo da Oracle) | conexões | Fórmula atribuída ao projeto PostgreSQL: conexões ativas "somewhere near ((core_count * 2) + effective_spindle_count)"; "You want a small pool [...] and you want the rest of the application threads blocked on the pool"; exemplo da Oracle: reduzir só o pool levou a resposta "from ~100ms to ~2ms" |
| F10 | PostgreSQL Global Development Group | PostgreSQL 16 Documentation, 11.7 Indexes on Expressions | https://www.postgresql.org/docs/16/indexes-expressional.html | 2026-11-09 | doc oficial | índices | "An index column need not be just a column of the underlying table, but can be a function or scalar expression computed from one or more columns of the table"; "Index expressions are relatively expensive to maintain [...] However, the index expressions are not recomputed during an indexed search"; "useful when retrieval speed is more important than insertion and update speed" |
| F11 | Markus Winand | We need tool support for keyset pagination (use-the-index-luke.com, 2014, atualizado 2023) | https://use-the-index-luke.com/no-offset | 2026-11-09 | técnica primária (autor de referência em SQL/índices) | paginação | "Offset instructs the DBMS skip the first N results of a query. However, the database must still fetch these rows from the disk and bring them in order"; "big offsets impose a lot of work on the database"; recomenda o método "seek"/keyset ("even faster than offset" — afirmação sem números na página) |
| F12 | PostgreSQL Global Development Group | PostgreSQL 16 Documentation, 7.6 LIMIT and OFFSET | https://www.postgresql.org/docs/16/queries-limit.html | 2026-11-09 | doc oficial | paginação | "The rows skipped by an OFFSET clause still have to be computed inside the server; therefore a large OFFSET might be inefficient" |
| F13 | PostgreSQL Global Development Group | PostgreSQL 16 Documentation, 41.3 Materialized Views | https://www.postgresql.org/docs/16/rules-materializedviews.html | 2026-11-09 | doc oficial | dados derivados | "persist the results in a table-like form"; "access to the data stored in a materialized view is often much faster than accessing the underlying tables directly or through a view, the data is not always current; yet sometimes current data is not needed"; exemplo de resumo de vendas: "A job could be scheduled to update the statistics each night" |
| F14 | PostgreSQL Global Development Group | PostgreSQL 16 Documentation, REFRESH MATERIALIZED VIEW | https://www.postgresql.org/docs/16/sql-refreshmaterializedview.html | 2026-11-09 | doc oficial | dados derivados | "completely replaces the contents of a materialized view"; `CONCURRENTLY`: "Refresh the materialized view without locking out concurrent selects"; "only allowed if there is at least one UNIQUE index on the materialized view which uses only column names and includes all rows" |
| F15 | PostgreSQL Global Development Group | PostgreSQL 16 Documentation, F.10 citext | https://www.postgresql.org/docs/16/citext.html | 2026-11-09 | doc oficial | índices | "The citext module provides a case-insensitive character string type, citext. Essentially, it internally calls lower when comparing values." (F10, mesma seção 11.7 já citada, também traz: "a common way to do case-insensitive comparisons is to use the lower function", o exemplo `CREATE INDEX test1_lower_col1_idx ON test1 (lower(col1))` e o aviso de que um índice `UNIQUE` assim "would prevent creation of rows whose col1 values differ only in case") |
| F16 | The Linux Kernel documentation | CFS Bandwidth Control | https://docs.kernel.org/scheduler/sched-bwc.html | 2026-11-09 | doc oficial (técnica primária) | ambiente / limites de CPU | "Within each given 'period' (microseconds), a task group is allocated up to 'quota' microseconds of CPU time"; "Throttled threads will not be able to run again until the next period when the quota is replenished"; padrão `cpu.cfs_period_us=100ms`; `nr_throttled`: "Number of times the group has been throttled/limited". A página descreve a interface do cgroup v1 e remete ao `cgroup-v2.rst` para o `cpu.max` (não aberto) |
| F17 | PostgreSQL Global Development Group | PostgreSQL 16 Documentation, F.35 pg_trgm | https://www.postgresql.org/docs/16/pgtrgm.html | 2026-11-09 | doc oficial | índices | "A trigram is a group of three consecutive characters taken from a string"; os índices GiST/GIN do módulo "support trigram-based index searches for LIKE, ILIKE, ~, ~* and = queries"; "Unlike B-tree based searches, the search string need not be left-anchored"; "a pattern with no extractable trigrams will degenerate to a full-index scan"; módulo "trusted" |
| F4 | PostgreSQL Global Development Group | PostgreSQL 16 Documentation, 11.4 Indexes and ORDER BY | https://www.postgresql.org/docs/16/indexes-ordering.html | 2026-11-05 | doc oficial | índices | O índice permite atender o `ORDER BY` "without a separate sorting step"; com `LIMIT n`, "the first n rows can be retrieved directly, without scanning the remainder at all"; "The index can also be scanned backward, producing output satisfying ORDER BY x DESC" |

Meta do enunciado: mínimo 6 fontes, pelo menos 2 acadêmicas ou técnicas primárias.

## Alternativas

Para cada problema, as opções pesquisadas (o artigo precisa de pelo menos 3 numa tabela).

| Problema | Alternativa | Custo | Desempenho esperado | Risco | Esforço | Decisão e motivo |
| --- | --- | --- | --- | --- | --- | --- |
| P2 N+1 | Consulta única com `JOIN` e agrupamento no Node | nenhum recurso novo | 2 idas ao banco por requisição | baixo: ordem e totais calculados como hoje | baixo | **escolhida** (experimento 03) |
| P2 N+1 | Lote com `WHERE pedido_id = ANY($1)` e `WHERE id = ANY($1)` (estilo DataLoader, F5) | nenhum | 4 idas ao banco | baixo | baixo | descartada: uma ida a mais que o `JOIN`, mesmo ganho de fundo |
| P2 N+1 | Montar o JSON no Postgres (`json_agg`) | nenhum | 2 idas; menos trabalho na API | médio: o Postgres formata `timestamp` diferente do `pg`/Node (`criado_em`), quebraria o contrato sem conversão | médio | descartada pelo risco ao contrato |
| P5 `count(*)` | Visão materializada com a contagem por status (4 linhas) | 48 kB; ~94 ms de banco por `REFRESH` | 65,3 → 0,04 ms ocioso (pré-teste) | médio: total pode ficar velho entre refreshes (aqui nunca muda) | baixo (um `.sql` + uma consulta) | **escolhida** (experimento 11) |
| P5 `count(*)` | Tabela de contadores mantida por gatilho em `pedidos` | pequeno; cada escrita em `pedidos` atualiza um contador | igual na leitura, sempre certo | médio/alto: todas as escritas do mesmo status disputam a mesma linha | médio | descartada aqui: a API não escreve, não daria para medir o custo; fica em próximos testes |
| P5 `count(*)` | Estimativa por estatística (`pg_class.reltuples` / `EXPLAIN`) | nenhum | instantânea | **quebra o contrato**: o total precisa ser exato | baixo | descartada |
| P5 `count(*)` | Índices parciais por status | ~4 índices pequenos | ainda conta todas as entradas do status (só menores) | baixo | baixo | descartada: não muda a ordem de grandeza |
| P9 busca | Índice GIN `pg_trgm` em `produtos.nome` | ~1,1 MB; escrita mais cara | 9,6–10,6 → 0,95–1,95 ms ocioso (pré-teste) | baixo: consulta igual, resultado provado igual | trivial (um `.sql`) | **escolhida** (experimento 10) |
| P9 busca | Índice GiST `pg_trgm` | parecido | também atende `ILIKE` (F17) | baixo | trivial | não testado; a documentação remete a outra seção para a comparação GIN × GiST — fica como teste futuro |
| P9 busca | Busca textual (`tsvector`/`tsquery`) | coluna/índice novo | rápida | **quebra o contrato**: casa palavras, não trechos (`lumin` não acharia "Luminaria") | médio | descartada |
| P9 busca | B-tree em `lower(nome)` com `text_pattern_ops` | ~1 MB | só serve para busca ancorada no começo (`termo%`) | — | trivial | descartada: a busca é por trecho em qualquer posição |
| P9 busca | Cache por termo na API | memória | ~0 de banco | **enviesa a medição**: a carga usa só 12 termos fixos, o cache acertaria quase sempre, o que não representa usuários reais | baixo | descartada por honestidade de medição |
| P8 e-mail | Índice de expressão `clientes (lower(email))` | ~4,8 MB | 29,3 → 0,08 ms ocioso (pré-teste) | quase nulo: consulta igual | trivial (um `.sql`) | **escolhida** (experimento 08) |
| P8 e-mail | Índice `UNIQUE` em `lower(email)` | ~4,8 MB | igual | muda regra de negócio (proíbe e-mails iguais ignorando maiúsculas); a rota devolve lista | trivial | descartada: não é questão de desempenho |
| P8 e-mail | Coluna `citext` (F15) + índice | migração da coluna | igual | médio: mexe na estrutura (`01-estrutura.sql` não pode mudar; exigiria `ALTER TABLE` em `.sql` novo) e na consulta | médio | descartada: mesmo ganho com mais mudança |
| P8 e-mail | Guardar o e-mail já normalizado numa coluna nova | espaço + manter em sincronia | igual | médio: duplicação de dado | médio | descartada |
| P7 top-produtos | Visão materializada com resumo por produto + índice por receita | ~2 MB; ~1 s de banco por `REFRESH` | 1.758,8 → 0,1 ms ocioso (pré-teste) | médio: dados podem ficar velhos entre refreshes (aqui nunca mudam) | baixo/médio (um `.sql` + uma consulta) | **escolhida** (experimento 07) |
| P7 top-produtos | Tabela de resumo mantida por gatilhos em `itens_pedido`/`pedidos` | ~2 MB; cada escrita de item/pedido atualiza o resumo | igual à visão na leitura, sempre atual | médio: lógica de gatilho (mudança de status, cancelamento) e contenção de escrita no mesmo produto | alto | descartada aqui: a API não escreve, não daria para medir o custo; fica em próximos testes |
| P7 top-produtos | Cache na memória da API com tempo de expiração | memória da API | 1ª chamada lenta (~38 s sob carga), as seguintes instantâneas até expirar | baixo; cache por processo | baixo | descartada: com 2% da carga, cada expiração ainda gera uma chamada de 20–40 s que segura o p99 |
| P7 top-produtos | Índice cobrindo `itens_pedido (pedido_id) INCLUDE (produto_id, quantidade, preco)` | ~40+ MB | evitaria ir à tabela, mas continua lendo 1,5 milhão de entradas | baixo | baixo | descartada: não muda a ordem de grandeza |
| P4b página de `/pedidos` | "Late row lookup": subconsulta pega 20 `id` via `Index Only Scan`, `JOIN` busca as linhas inteiras | nenhum recurso novo | piores casos ociosos 131–993 ms → 22–73 ms (pré-teste) | baixo: mesma ordem total `(criado_em, id)`; `ORDER BY` repetido fora | baixo (SQL de uma rota) | **escolhida** (experimento 06) |
| P4b página de `/pedidos` | Keyset/seek pagination (F11) | nenhum | melhor possível (nunca percorre as puladas) | **quebra o contrato**: a API expõe `pagina` numérica de acesso aleatório | — | descartada: impossível sem mudar a API |
| P4b página de `/pedidos` | Índice cobrindo todas as colunas (`INCLUDE`) | ~duplica a tabela em disco | evita ir à tabela, mas ainda carrega linhas de ~299 bytes pelo índice | baixo | baixo | descartada: custo de espaço alto, ganho menor que o late lookup |
| P4b página de `/pedidos` | `work_mem` maior (ex.: 16 MB) no `command` do banco | memória (×100 conexões possíveis) | só elimina o spill de `cancelado`/`pagina=15000`; as 20 mil idas à tabela continuam | médio (memória sob carga) | trivial | descartada como solução; candidata a teste futuro de configuração |
| P6 vendas-por-dia | A: índice de expressão `((criado_em::date))` | índice novo (disco/memória) | 840 → 34 ms ocioso (pré-teste) | quase nulo: consulta igual | baixo (um `.sql`) | **escolhida** (experimento 05) |
| P6 vendas-por-dia | B: reescrever o filtro como intervalo + índice em `criado_em` | índice novo | 840 → 18 ms ocioso (equivalente a A) | baixo, mas muda a rota | baixo/médio | descartada por ora: mesmo ganho, mais uma variável (código) |
| P6 vendas-por-dia | C: agregar no SQL (`GROUP BY` por dia) | nenhum | menos linhas e menos CPU na API; não resolve o scan sozinho | médio: formato do dia, `bigint` → `Number` | médio | depois, como experimento separado |
| P6 vendas-por-dia | D: tabela/visão materializada com o resumo por dia | espaço pequeno; manutenção (atualizar a cada pedido ou periodicamente) | o mais rápido (lê ~7 linhas prontas) | médio/alto: dados velhos se a atualização falhar; aqui os dados nunca mudam, então mediria um cenário irreal | médio | descartada: ganho inflado pelos dados estáticos; registrar em próximos testes |
| P6 vendas-por-dia | E: cache de resposta (ex.: Redis) | serviço novo | alto para períodos repetidos (a carga sorteia entre 725 inícios) | médio: invalidação | médio/alto | descartada: serviço novo para algo que um índice resolve |
| P3 conexões | `pg.Pool` na API com `max: 20` (igual à concorrência atual) | nenhum serviço novo; memória do banco com conexões persistentes | elimina handshake e criação de processo por consulta | baixo; precisa de ouvinte de `error` | baixo | **escolhida** (experimento 04): isola o custo de conexão |
| P3 conexões | `pg.Pool` pequeno (~2–4, fórmula do F9) | idem, menos memória | pode ser melhor: menos consultas brigando pela única CPU | médio: fila no pool; mexe também na concorrência | baixo | depois, como experimento separado (tamanho do pool) |
| P3 conexões | PgBouncer (pooler externo) entre API e banco | serviço novo (CPU/memória, mais um container) | parecido com o pool na API para um único processo Node | médio: mais uma peça | médio | descartada: só compensa com várias instâncias da API; aqui é um processo só |
| P2 N+1 | Cache de resposta por cliente (ex.: Redis) | serviço novo (CPU/memória) | alto só para clientes repetidos; a carga sorteia entre 100 mil | médio: invalidação | alto | descartada: não ataca a causa; a carga quase não repete cliente |

## Ideias não testadas

Viram fichas no `proximos-testes.md`: fonte, ganho esperado, como testaria, o que precisaria.

## Limites e dúvidas

- Medições na mesma máquina Windows/WSL com Docker Desktop; variação entre execuções pode passar de 30%.
- Diagnóstico inicial feito com banco ocioso, não sob carga.
- Todas as medições (linha de base inclusive) rodaram pelo terminal do WebStorm, com a IDE aberta. A atividade de fundo da IDE (indexação, leitura de arquivos pelo `\\wsl.localhost`) pode somar ruído; não foi isolada. Indícios de que o efeito foi pequeno: o banco usou ~96–101% da cota de CPU em todas as execuções e a variação entre execuções ficou abaixo de 10% (linha de base: 1.48–1.60 req/s).
- `cpu_max` no `recursos.txt` não é confiável: aparece menor que `cpu_media` (ex.: banco 100.9% de média e 99.9% de máximo; API 12.7% de média e 9.8% de máximo). Provável comparação de texto em vez de número no `awk` do `medir.sh`, que não pode ser alterado. Usar só `cpu_media`.
- A carga do k6 é de ciclo fechado (cada usuário só pede a próxima depois da resposta anterior): melhorar uma rota aumenta o número de chamadas das outras, então o tempo por rota de rotas não alteradas pode piorar. Comparar pelo resultado geral.
- Custo de escrita dos índices (INSERT/UPDATE mais lentos) não aparece aqui: a API só lê.
- O autovacuum roda sozinho ~50 s depois de o banco ser recriado (`diagnostico/03-indice-pedidos-status/vacuum.txt`). Se uma medição começar antes disso, o autovacuum pode rodar durante a carga e os planos podem mudar (ex.: `Heap Fetches` no `count(*)`). Esperar o banco assentar depois de `down -v && up` antes de medir.
- `cpu_media` subestima um pouco a carga: o coletor do `medir.sh` continua amostrando por alguns segundos depois do fim da carga, e as últimas amostras de cada `recursos.csv` têm o banco quase parado (ex.: 0,05%, 6,90%). Afeta todas as medições do mesmo jeito, então as comparações continuam válidas.
- Mensagem `date: write error: Broken pipe (os error 32)` no fim do `medir.sh`: o `date` do coletor (uutils coreutils, Ubuntu 26.04) reclama quando o laço é encerrado no meio de uma escrita. Inofensiva: conferido que nenhum `recursos.csv` tem linha malformada (68–86 amostras por execução) e o `resumo.txt` vem do k6, não do coletor.
- **O ambiente muda entre dias:** o mesmo código (experimento 03) deu 5,63 req/s em 05/11 e 8,44 req/s em 09/11 (+50%). Causa não identificada. Só comparar medições da mesma sessão; no mesmo dia também houve deriva (pool: 10,3 req/s às 19:11 nas medições descartadas contra 9,4 às 19:41). **Plano:** rodada final no fim do trabalho, na mesma sessão, com linha de base e versão final (3 medições cada), para a tabela-resumo do artigo.
- **Throttling do limite de CPU (CFS):** com o banco no teto, o container é limitado em ~metade dos períodos de 100 ms (experimento 09: 2.291 de 4.501; F16), e os tempos sob carga ficam em degraus de ~100 ms. Ganhos de poucos ms por consulta podem não aparecer; o que aparece é reduzir a CPU total do banco. Os contadores do `cpu.stat` são acumulados desde a criação do container, não da janela de medição.
- O p95 geral depende da mistura de rotas: na carga de ciclo fechado, acelerar uma rota faz as outras serem mais chamadas e pode piorar a cauda (experimento 03). Comparar sempre req/s, mediana, p95 e as rotas juntos.

## Uso de IA

| Data | Ferramenta | Para quê | Como verifiquei |
| --- | --- | --- | --- |
| 2026-11-05 | Claude Code | Resumo do enunciado e leitura do código da pasta | Conferi contra o PDF e os arquivos |
| 2026-11-05 | Claude Code | Escreveu e rodou `diagnostico/00-inicial/diag.sh` (só leitura) e listou os problemas P1–P12 | Saída bruta salva em `diagnostico/00-inicial/saida.txt`; conferir cada número contra o arquivo |
| 2026-11-05 | Claude Code | Criou este diário e o `.gitignore` | Revisado por mim |
| 2026-11-05 | Claude Code | Redigiu a hipótese do experimento 01 e abriu as fontes F1 e F2 para extrair as citações | Conferir as citações nos links |
| 2026-11-05 | Claude Code | Leu as 3 pastas do experimento 01, calculou as medianas e escreveu a análise (previsões × resultado, ciclo fechado, `cpu_max`) | Números copiados de `resumo.txt` e `recursos.txt`; conferir contra as pastas |
| 2026-11-05 | Claude Code | Sugeriu o método do Diagnóstico 02 (script `coletar.sh` e compose à parte), analisou o `ranking.txt`, argumentou a ordem `/pedidos` antes do N+1, abriu F3 e F4 e redigiu a hipótese do experimento 02 | Script e saída no repositório; conferir números contra `ranking.txt` e citações nos links |
| 2026-11-05 | Claude Code | Leu a evidência e as 3 pastas do experimento 02, calculou medianas e variações, e escreveu a análise (previsões × resultado, autovacuum) | Números copiados de `diagnostico/03-...` e `resumo.txt`/`recursos.txt`; conferir contra os arquivos |
| 2026-11-05 | Claude Code | Redigiu a hipótese do experimento 03, a tabela de alternativas do N+1 e sugeriu o código da nova rota; buscou fontes (F5 verificada; F6 só o título; artigo Chen et al. ICSE 2014 não abriu e ficou de fora) | Conferir F6 no navegador; código revisado por mim e validado pelo verificador de contrato |
| 2026-11-05 | Claude Code | Leu as 3 pastas do experimento 03, calculou medianas e variações, analisou a piora do p95; investigou o aviso `Broken pipe` (checou todos os `recursos.csv`) | Números copiados de `resumo.txt`/`recursos.txt`; conferir contra as pastas |
| 2026-11-05 | Claude Code | Abriu F7–F9, redigiu a hipótese do experimento 04 (incluindo a escolha `max: 20` para isolar a variável), alternativas do P3, o código sugerido do pool e o script de contagem de sessões | Citações conferidas pelos links; código validado pelo verificador de contrato |
| 2026-11-09 | Claude Code | Notou a duplicação da carga no `sessoes.sh`, o `sem commit: 5` e a diferença entre dias nas primeiras medições do 04; sugeriu descartar e remedir o 03 na mesma sessão; calculou medianas e escreveu a análise | Números copiados de `resumo.txt`/`recursos.txt`/`contexto.txt`; conferir contra as pastas |
| 2026-11-09 | Claude Code | Escreveu e rodou o pré-teste de `vendas-por-dia` (índices candidatos em transação com `ROLLBACK`), abriu F10, redigiu a hipótese do experimento 05 e a tabela de alternativas do P6 | Saída bruta em `diagnostico/06-vendas-por-dia/pre-teste.txt`, com a lista de índices no fim provando que nada ficou no banco |
| 2026-11-09 | Claude Code | Leu a evidência e as 3 pastas do experimento 05, calculou medianas e variações (incluindo p99 e p95 por rota) e escreveu a análise | Números copiados de `explain-depois.txt`, `tamanho-indices.txt`, `resumo.txt` e `recursos.txt`; conferir contra os arquivos |
| 2026-11-09 | Claude Code | Escreveu e rodou o `coletar.sh` do Diagnóstico 03, analisou o ranking e os EXPLAINs quentes, revisou a hipótese da cauda do experimento 05 e propôs as prioridades (P4b antes de `top-produtos`) | Saídas brutas em `diagnostico/07-ranking-apos-05/`; conferir números contra `ranking.txt` e `consultas-ociosas.txt` |
| 2026-11-09 | Claude Code | Escreveu e rodou o pré-teste do P4b (investigou os blocos temporários e comparou a reescrita), abriu F11 e F12 e redigiu a hipótese do experimento 06 com o SQL sugerido | Saída bruta em `diagnostico/08-pedidos-offset/pre-teste.txt`; conferir citações nos links; código validado pelo verificador de contrato |
| 2026-11-09 | Claude Code | Leu a evidência e as 3 pastas do experimento 06, calculou medianas, faixas e variações por rota e escreveu a análise | Números copiados de `explain-depois.txt`, `pre-teste.txt`, `resumo.txt` e `recursos.txt`; conferir contra os arquivos |
| 2026-11-09 | Claude Code | **A pedido, implementou e rodou o experimento 07 inteiro**: pré-teste com prova de equivalência, hipótese, `banco/06-resumo-vendas-produto.sql`, mudança na rota, recriação do banco, evidência, contrato, 3 medições e commits; abriu F13 e F14 | Revisar o código e o SQL; equivalência provada no pré-teste (0 diferenças em 19.206 linhas) e pelo verificador de contrato; números conferíveis nos arquivos |
| 2026-11-09 | Claude Code | **A pedido, implementou e rodou o experimento 08** (índice de e-mail): pré-teste, hipótese, `.sql`, recriação do banco, evidência, contrato, medições e commits; abriu F15 e conferiu o exemplo de `lower()` em F10 | Saídas brutas em `diagnostico/10-email/`; números conferíveis nos arquivos |
| 2026-11-09 | Claude Code | **A pedido, fez o Diagnóstico 04**: script com profiler do V8 na API (compose à parte) + `pg_stat_statements` + volume de log por rota; interpretou o perfil e propôs as prioridades | Saídas brutas em `diagnostico/11-diagnostico-04/` (`perfil-api.txt`, `ranking.txt`, `log-api.txt`, `carga.txt`); o limite do perfil (símbolos C++ não resolvidos no Alpine) está registrado |
| 2026-11-09 | Claude Code | **A pedido, implementou e rodou o experimento 09**: script de equivalência byte a byte do JSON em 735 janelas, hipótese, mudança na rota, evidência, contrato, medições e commits | Saídas brutas em `diagnostico/12-vendas-sql/`; equivalência também conferida pelo verificador de contrato |
| 2026-11-09 | Claude Code | **A pedido, implementou e rodou o experimento 10** (`pg_trgm`): pré-teste parametrizado com prova de equivalência, hipótese, alternativas, `.sql`, evidência, contrato, medições e commits; abriu F17 | Saídas brutas em `diagnostico/13-busca-trgm/`; números conferíveis nos arquivos |
| 2026-11-09 | Claude Code | **A pedido, implementou e rodou o experimento 11** (contagem por status): pré-teste com equivalência, hipótese, alternativas, `.sql` + mudança na rota, evidência, contrato, medições e commits | Saídas brutas em `diagnostico/14-contagem-status/`; números conferíveis nos arquivos |
