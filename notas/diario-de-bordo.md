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
| 2026-11-05 | Decidido fazer o pool de conexões antes dos relatórios; hipótese do experimento 04 escrita antes da mudança | este diário |

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
| P3 | Uma conexão nova por consulta, sem pool | `api/src/db.js` | 50× conectar+consultar = 4,6 s; 50 consultas numa conexão = 0,28 s | Cada conexão cria um processo no Postgres. **Cuidado:** o teste usa `psql`, que soma o custo de iniciar o programa; medir melhor antes de citar | experimento 04 planejado |
| P4 | Paginação por status ordena tudo em disco e usa `OFFSET` até 19.980 | `/pedidos` | `external merge Disk: ~30 MB` por worker, 1.085 ms | Sem índice em `(status, criado_em, id)` e `work_mem` de 4 MB | resolvido no experimento 02 (sem `Sort` em disco); o `OFFSET` ainda percorre até 20 mil entradas do índice |
| P5 | `count(*)` por status a cada página | `/pedidos` | Seq Scan, 288 ms | Contagem recalculada a cada requisição | parcial: experimento 02 trocou o Seq Scan por `Index Only Scan`, mas só −19% (ocioso); continua contando até 300 mil entradas por requisição |
| P6 | `criado_em::date BETWEEN`, traz `observacoes` sem usar, agrega no Node | `/relatorios/vendas-por-dia` | Seq Scan nas duas tabelas grandes, 756 ms, 12.951 linhas enviadas à API | O cast impede índice em `criado_em`; colunas e linhas demais trafegam | a investigar |
| P7 | `top-produtos` agrega todos os itens a cada chamada | `/relatorios/top-produtos` | 3.482 ms | Resultado só muda quando os dados mudam, mas é recalculado sempre | a investigar |
| P8 | Busca por e-mail com `lower(email)` sem índice | `/clientes?email=` | Seq Scan 100 mil linhas, 84 ms | Falta índice de expressão em `lower(email)` | a investigar |
| P9 | Busca `ILIKE '%termo%'` | `/produtos/busca` | Seq Scan 20 mil linhas, 24 ms | Índice B-tree não serve com `%` no começo; tabela pequena, prioridade baixa | a investigar |
| P10 | Postgres com configuração padrão | `docker-compose.yml` (sem `command`) | seção `settings`: `shared_buffers` 128 MB, `work_mem` 4 MB, 2 workers paralelos | Tabelas quentes (~280 MB) não cabem no cache; paralelismo num container de 1 CPU talvez só atrapalhe | a investigar |
| P11 | `SELECT *` em todas as rotas | `api/src/rotas.js` | `observacoes` média 274 caracteres | Lê e transfere colunas que a rota não devolve | a investigar |
| P12 | Log com o corpo inteiro de cada resposta | `api/src/server.js` | 591 linhas = 647 KB de log; maior linha 6.324 caracteres | Custo de CPU na API; irrelevante hoje (API a 7%), pode aparecer depois que o banco melhorar | a investigar |

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

**Decisão:** atacar `/pedidos` antes do N+1. Motivos: (1) é o maior consumidor do recurso saturado; com a fila mais curta todas as rotas esperam menos, inclusive as 22 consultas do N+1; (2) resolver o N+1 primeiro aceleraria muito aquela rota, mas aliviaria pouco o banco, e na carga de ciclo fechado os usuários liberados iriam pedir mais `/pedidos` e relatórios; (3) um arquivo `.sql`, sem mudar código, risco quase nulo para o contrato; o N+1 exige reescrever a rota mantendo ordem, totais e formato. **A favor do N+1 primeiro** (registrado para o artigo): o custo de conexão escondido e o maior efeito numa rota que é 20% da carga. N+1 e pool ficam como próximos passos, depois de um novo ranking.

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

- **Status:** planejado (hipótese escrita antes da mudança)
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
- **Mudança:** `api/src/db.js` — commit `<preencher>`
- **Custo esperado:** memória do banco (processos persistentes); nenhum serviço novo.
- **Evidência a salvar:** `diagnostico/05-pool/` com a contagem de sessões numa carga igual à do `medir.sh`, antes (código do experimento 03) e depois
- **Contrato:** `<preencher>`
- **Antes:** experimento 03 (pastas em [03-n-mais-1](#03-n-mais-1))
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
| F4 | PostgreSQL Global Development Group | PostgreSQL 16 Documentation, 11.4 Indexes and ORDER BY | https://www.postgresql.org/docs/16/indexes-ordering.html | 2026-11-05 | doc oficial | índices | O índice permite atender o `ORDER BY` "without a separate sorting step"; com `LIMIT n`, "the first n rows can be retrieved directly, without scanning the remainder at all"; "The index can also be scanned backward, producing output satisfying ORDER BY x DESC" |

Meta do enunciado: mínimo 6 fontes, pelo menos 2 acadêmicas ou técnicas primárias.

## Alternativas

Para cada problema, as opções pesquisadas (o artigo precisa de pelo menos 3 numa tabela).

| Problema | Alternativa | Custo | Desempenho esperado | Risco | Esforço | Decisão e motivo |
| --- | --- | --- | --- | --- | --- | --- |
| P2 N+1 | Consulta única com `JOIN` e agrupamento no Node | nenhum recurso novo | 2 idas ao banco por requisição | baixo: ordem e totais calculados como hoje | baixo | **escolhida** (experimento 03) |
| P2 N+1 | Lote com `WHERE pedido_id = ANY($1)` e `WHERE id = ANY($1)` (estilo DataLoader, F5) | nenhum | 4 idas ao banco | baixo | baixo | descartada: uma ida a mais que o `JOIN`, mesmo ganho de fundo |
| P2 N+1 | Montar o JSON no Postgres (`json_agg`) | nenhum | 2 idas; menos trabalho na API | médio: o Postgres formata `timestamp` diferente do `pg`/Node (`criado_em`), quebraria o contrato sem conversão | médio | descartada pelo risco ao contrato |
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
