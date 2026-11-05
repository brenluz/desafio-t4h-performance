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
| 2026-11-05 | Hipótese do experimento 01 (índices nas chaves estrangeiras) escrita antes da mudança | este diário |

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
| P1 | Só existem os índices de chave primária | `banco/01-estrutura.sql` | seção `indexes`; itens de um pedido = Seq Scan em 1,5 mi linhas, 252 ms; pedidos de um cliente = Seq Scan, 143 ms | Toda busca por `cliente_id`, `pedido_id`, `status`, `criado_em` lê a tabela inteira | chaves estrangeiras: experimento 01 (planejado); `status`/`criado_em`: pendente |
| P2 | N+1 em `/clientes/:id/pedidos` (17 consultas por requisição para um cliente com 5 pedidos e 10 itens) | `api/src/rotas.js` (rota `/clientes/:id/pedidos`) | seção `queries per /clientes/42/pedidos` | Uma consulta por pedido e uma por item; com P1 vira 5 Seq Scans de `itens_pedido` por requisição | a investigar |
| P3 | Uma conexão nova por consulta, sem pool | `api/src/db.js` | 50× conectar+consultar = 4,6 s; 50 consultas numa conexão = 0,28 s | Cada conexão cria um processo no Postgres. **Cuidado:** o teste usa `psql`, que soma o custo de iniciar o programa; medir melhor antes de citar | a investigar |
| P4 | Paginação por status ordena tudo em disco e usa `OFFSET` até 19.980 | `/pedidos` | `external merge Disk: ~30 MB` por worker, 1.085 ms | Sem índice em `(status, criado_em, id)` e `work_mem` de 4 MB | a investigar |
| P5 | `count(*)` por status a cada página | `/pedidos` | Seq Scan, 288 ms | Contagem recalculada a cada requisição | a investigar |
| P6 | `criado_em::date BETWEEN`, traz `observacoes` sem usar, agrega no Node | `/relatorios/vendas-por-dia` | Seq Scan nas duas tabelas grandes, 756 ms, 12.951 linhas enviadas à API | O cast impede índice em `criado_em`; colunas e linhas demais trafegam | a investigar |
| P7 | `top-produtos` agrega todos os itens a cada chamada | `/relatorios/top-produtos` | 3.482 ms | Resultado só muda quando os dados mudam, mas é recalculado sempre | a investigar |
| P8 | Busca por e-mail com `lower(email)` sem índice | `/clientes?email=` | Seq Scan 100 mil linhas, 84 ms | Falta índice de expressão em `lower(email)` | a investigar |
| P9 | Busca `ILIKE '%termo%'` | `/produtos/busca` | Seq Scan 20 mil linhas, 24 ms | Índice B-tree não serve com `%` no começo; tabela pequena, prioridade baixa | a investigar |
| P10 | Postgres com configuração padrão | `docker-compose.yml` (sem `command`) | seção `settings`: `shared_buffers` 128 MB, `work_mem` 4 MB, 2 workers paralelos | Tabelas quentes (~280 MB) não cabem no cache; paralelismo num container de 1 CPU talvez só atrapalhe | a investigar |
| P11 | `SELECT *` em todas as rotas | `api/src/rotas.js` | `observacoes` média 274 caracteres | Lê e transfere colunas que a rota não devolve | a investigar |
| P12 | Log com o corpo inteiro de cada resposta | `api/src/server.js` | 591 linhas = 647 KB de log; maior linha 6.324 caracteres | Custo de CPU na API; irrelevante hoje (API a 7%), pode aparecer depois que o banco melhorar | a investigar |

Cuidados de contrato ao mexer: manter ordem (`criado_em DESC, id DESC`, `nome, id`, `receita DESC, id`), tipos (somas passam por `Number(...)`), e os casos de erro (`pagina=0`, `2024-02-30`, período invertido, `limite=0`/`51`).

Ainda não verificado: qual consulta consome mais tempo total **sob carga** (`pg_stat_statements` confirmaria ou mudaria a ordem de prioridade).

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

- **Status:** planejado (hipótese escrita antes da mudança)
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
- **Mudança:** `banco/03-indices-chaves-estrangeiras.sql` com os dois `CREATE INDEX` e `ANALYZE` no fim — commit `<preencher>`
- **Custo esperado:** espaço em disco e memória dos índices (medir com `pg_relation_size`); escrita mais lenta em `INSERT`/`UPDATE` (a documentação, seção 11.1, chama de "overhead to data manipulation operations"). Esta API só lê, então o custo de escrita não aparece na medição: registrar como limite.
- **Evidência a salvar:** `diagnostico/01-indices-fk/` com `EXPLAIN (ANALYZE, BUFFERS)` das duas consultas e o tamanho dos índices
- **Contrato:** `<preencher>`
- **Antes:** linha de base (pastas em [Linha de base](#linha-de-base))
- **Depois:** `<preencher pastas>`
- **Resultado (medianas):** `<preencher>`
- **Conclusão:** `<preencher>`

## Fontes

| # | Autor / organização | Título | Link | Acesso | Tipo (doc oficial / acadêmica / técnica primária / caso de mercado / blog) | Abordagem | O que diz (fato) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| F1 | PostgreSQL Global Development Group | PostgreSQL 16 Documentation, 5.4.5 Foreign Keys | https://www.postgresql.org/docs/16/ddl-constraints.html#DDL-CONSTRAINTS-FK | 2026-11-05 | doc oficial | índices | "the declaration of a foreign key constraint does not automatically create an index on the referencing columns"; recomenda indexar essas colunas ("it is often a good idea to index the referencing columns too") |
| F2 | PostgreSQL Global Development Group | PostgreSQL 16 Documentation, 11.1 Introduction (Indexes) | https://www.postgresql.org/docs/16/indexes-intro.html | 2026-11-05 | doc oficial | índices | Sem índice o sistema "would have to scan the entire test1 table, row by row"; o índice precisa ser mantido sincronizado com a tabela, o que "adds overhead to data manipulation operations" |

Meta do enunciado: mínimo 6 fontes, pelo menos 2 acadêmicas ou técnicas primárias.

## Alternativas

Para cada problema, as opções pesquisadas (o artigo precisa de pelo menos 3 numa tabela).

| Problema | Alternativa | Custo | Desempenho esperado | Risco | Esforço | Decisão e motivo |
| --- | --- | --- | --- | --- | --- | --- |

## Ideias não testadas

Viram fichas no `proximos-testes.md`: fonte, ganho esperado, como testaria, o que precisaria.

## Limites e dúvidas

- Medições na mesma máquina Windows/WSL com Docker Desktop; variação entre execuções pode passar de 30%.
- Diagnóstico inicial feito com banco ocioso, não sob carga.

## Uso de IA

| Data | Ferramenta | Para quê | Como verifiquei |
| --- | --- | --- | --- |
| 2026-11-05 | Claude Code | Resumo do enunciado e leitura do código da pasta | Conferi contra o PDF e os arquivos |
| 2026-11-05 | Claude Code | Escreveu e rodou `diagnostico/00-inicial/diag.sh` (só leitura) e listou os problemas P1–P12 | Saída bruta salva em `diagnostico/00-inicial/saida.txt`; conferir cada número contra o arquivo |
| 2026-11-05 | Claude Code | Criou este diário e o `.gitignore` | Revisado por mim |
| 2026-11-05 | Claude Code | Redigiu a hipótese do experimento 01 e abriu as fontes F1 e F2 para extrair as citações | Conferir as citações nos links |
