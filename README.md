# Vaga Estágio Pesquisa e Inovação 2026 - Desafios Técnicos

Aplicação do desafio técnico da vaga de estágio em Pesquisa e Inovação da Tech for Humans. O enunciado, com a missão, as entregas e os critérios de avaliação, é enviado na largada. Este README cobre só como instalar, rodar e medir a aplicação, e é a referência de todos os comandos.

A aplicação é a API de uma loja fictícia, em Node.js (Express) com PostgreSQL 16, rodando em containers. Ela funciona, mas fica lenta sob carga e gasta mais recursos do que deveria. Todos os dados são sintéticos e gerados na primeira subida: 100 mil clientes, 20 mil produtos, 500 mil pedidos e 1,5 milhão de itens de pedido.

## Resultado deste trabalho

Seção acrescentada com a solução do desafio. Daqui para baixo, a partir de [Prazo e entrega](#prazo-e-entrega), o README é o original, com as instruções de instalar, rodar e medir.

**O problema.** Com 20 usuários simultâneos, o banco ficava no teto da sua CPU o tempo todo e as rotas lentas levavam dezenas de segundos. Os diagnósticos (em [`diagnostico/`](diagnostico/), com `pg_stat_statements`, `EXPLAIN (ANALYZE, BUFFERS)`, perfil da API e contadores do cgroup) apontaram as causas:

- nenhum índice além das chaves primárias: as buscas por cliente, por status, por dia, por e-mail e por trecho do nome liam tabelas inteiras;
- um N+1 em `/clientes/:id/pedidos` e uma conexão nova com o PostgreSQL a cada consulta;
- a paginação de `/pedidos` lendo da tabela as linhas que o `OFFSET` ia descartar;
- relatórios recalculados a cada chamada: `top-produtos` sobre todos os itens, o `count(*)` do total por status e a agregação de vendas por dia feita no Node;
- configuração do PostgreSQL que não combina com o limite de 1 CPU (consultas paralelas dividindo a mesma cota) e um cache menor que a tabela mais usada.

**O que mudou.** 15 mudanças aplicadas e medidas, cada uma no seu commit, e 2 aplicadas sem ganho e desfeitas. A lista, com antes e depois de cada uma, está em [`experimentos.md`](experimentos.md). O que as rotas respondem continua igual: o verificador de contrato passou em todas as medições.

**Resultado, com os mesmos limites de CPU e memória do enunciado:**

<!-- gerado:resumo -->
| Medida (limites originais: banco 1 CPU · 512 MB, API 0,5 CPU · 256 MB) | Aplicação original | Versão até o experimento 16 (rodada final) | Variação |
| --- | --- | --- | --- |
| Requisições por segundo | 2,61 | 351,81 | 134,8× |
| Tempo de resposta, mediana | 1.299,0 ms | 18,5 ms | −98,6% |
| Tempo de resposta, p95 | 25.375,2 ms | 189,1 ms | −99,3% |
| Tempo de resposta, p99 | 29.794,0 ms | 298,2 ms | −99,0% |
| Custo estimado por milhão de requisições (estudo de custo, 11/11, preços do AWS Fargate) | US$ 7,48 | US$ 0,068 | 110× menor |

Tempos e req/s: mediana de 3 medições de cada versão na rodada final (12/11), na mesma sessão ([tabela completa](experimentos.md#rodada-final-a-cadeia-inteira-numa-sessão-só)). Com **um quarto da CPU** (banco 0,25, API 0,125), a versão final ainda fez 68,44 req/s, 29× a aplicação original com toda a CPU, com custo por hora −71,1% ([estudo de custo](experimentos.md#estudo-de-custo-quanto-recurso-a-versão-final-precisa)).

**O ganho depende da carga.** Os 134,8× acima são com 20 usuários, como todas as medições do desafio. Na curva de capacidade (16/11, outra sessão), com 1 a 40 usuários, as req/s da versão final ficaram entre 87× (1 usuário) e 171× (10 usuários) as da original (144× com 20). A original já satura com 1 usuário. A versão final chega ao pico com 5 a 10 usuários (~392 req/s) e perde vazão com mais usuários: 350 req/s com 20 e 287 com 40 ([curva de capacidade](experimentos.md#curva-de-capacidade-1-a-40-usuários)).

**Depois da rodada final: o experimento 17.** A curva mostrou que, com 1 CPU, o banco rende menos quando roda muitas consultas ao mesmo tempo. Limitar o pool de conexões da API a 3 (antes, 20) aumentou a vazão com os mesmos 20 usuários e os mesmos limites. Na mesma sessão (16/11), contra a aplicação original:

| Medida (mesma sessão, 16/11) | Aplicação original | Versão final com pool de 3 | Variação |
| --- | --- | --- | --- |
| Requisições por segundo | 2,56 | 473,74 | 185,1× |
| Tempo de resposta, mediana | 1.304,2 ms | 25,2 ms | −98,1% |
| Tempo de resposta, p95 | 25.752,8 ms | 91,6 ms | −99,6% |
| Tempo de resposta, p99 | 29.557,9 ms | 103,6 ms | −99,6% |
| Custo estimado por milhão de requisições (mesmos limites, preços do AWS Fargate) | US$ 6,95 | US$ 0,038 | 185× menor |

O 134,8× da tabela de cima é da cadeia até o experimento 16 (rodada final, 12/11); a curva de capacidade e o estudo de custo também são de antes do 17. Detalhes das duas rodadas do 17 no [experimentos.md](experimentos.md#experimento-17-tamanho-do-pool-em-duas-rodadas).
<!-- /gerado:resumo -->

**Onde está cada coisa:**

| Arquivo ou pasta | O que tem |
| --- | --- |
| [`artigo/artigo.md`](artigo/artigo.md) | O artigo: diagnóstico, estado da arte, alternativas, escolha e resultados |
| [`experimentos.md`](experimentos.md) | Uma linha por mudança: fonte, status, antes, depois, pastas de resultados e conclusão; rodada final, estudo de custo e curva de capacidade |
| [`proximos-testes.md`](proximos-testes.md) | Ideias pesquisadas e não testadas, com o que ganhariam e como testar |
| [`notas/diario-de-bordo.md`](notas/diario-de-bordo.md) | O registro completo: hipóteses escritas antes de medir, previsões × resultado, fontes com citações, alternativas, limites, uso de IA |
| [`diagnostico/`](diagnostico/) | As saídas brutas de cada diagnóstico e pré-teste citadas no diário |
| [`resultados/`](resultados/) | Todas as medições do `medir.sh`, sem edição |
| [`analise/gerar.py`](analise/gerar.py) | Gera as tabelas do `experimentos.md`, o resumo acima e os gráficos de `artigo/img/` a partir de `resultados/` |
| `banco/03-*.sql` a `banco/10-*.sql`, `api/src/`, `docker-compose.yml` | As mudanças em si |

**Como repetir a comparação principal** (cada medição leva ~1 min 30 s; meça 3 vezes cada versão, na mesma sessão):

```bash
# versão final
docker compose down -v && docker compose up -d --build
scripts/verificar-contrato.sh comparar      # precisa terminar em "Contrato mantido"
scripts/medir.sh minha-versao-final          # 3 vezes

# aplicação original (commit da linha de base)
git switch --detach 1b5bd26
docker compose down -v && docker compose up -d --build
scripts/medir.sh minha-versao-original       # 3 vezes
git switch master
docker compose down -v && docker compose up -d --build
```

Para medir a cadeia inteira, da linha de base à versão final, numa sessão só: [`diagnostico/22-rodada-final/rodada.sh`](diagnostico/22-rodada-final/rodada.sh) (~2h30). Para a curva de capacidade (original e final com 1 a 40 usuários): [`diagnostico/23-curva-capacidade/curva.sh`](diagnostico/23-curva-capacidade/curva.sh) (~1h). Os dois scripts trocam de commit com `git switch`, então rode a partir de uma cópia fora do repositório. Para regenerar as tabelas e os gráficos depois de novas medições: `python3 analise/gerar.py` (só biblioteca padrão do Python).

## Prazo e entrega

- **Prazo e entregas:** estão no enunciado enviado na largada
- **Dúvidas:** no canal combinado na largada

## Estrutura

```
Vaga - Estágio Pesquisa e Inovação 2026/
├── AGENTS.md                  # instruções para agentes de IA (o CLAUDE.md aponta para ele)
├── docker-compose.yml         # API, banco e as ferramentas de medição
├── api/                       # código da API (Express + pg) e Dockerfile
├── banco/                     # scripts que criam as tabelas e geram os dados
├── carga/teste-carga.js       # teste de carga (k6)
├── contrato/verificar.js      # confere se as respostas da API continuam iguais
├── scripts/
│   ├── medir.sh               # roda a carga e salva o resultado
│   └── verificar-contrato.sh  # grava e compara as respostas da API
└── resultados/                # cada medição cria uma pasta aqui
```

## Requisitos

- Docker Desktop, ou Docker Engine com Compose v2 (`docker compose version`)
- Git
- Cerca de 2 GB livres em disco
- `bash` e `curl`. No macOS e no Linux já vêm instalados. No Windows, use o WSL 2.

Não precisa instalar Node.js, PostgreSQL nem k6: tudo roda em containers.

Se você já usa Docker e Git no dia a dia, pule para [Criar a sua cópia do desafio](#4-criar-a-sua-cópia-do-desafio). Se é a primeira vez, siga o passo a passo abaixo, na ordem.

## Passo a passo do zero

Nenhum passo pressupõe experiência anterior. Cada um termina com um comando para você conferir se deu certo antes de seguir.

### 1. Abrir um terminal

Todos os comandos deste README são digitados no terminal: uma janela onde você escreve um comando, aperta Enter e lê a resposta.

- **macOS:** abra o app **Terminal** (Cmd+Espaço, digite "Terminal"). [Guia do Terminal da Apple](https://support.apple.com/pt-br/guide/terminal/apd5265185d-f365-44cb-8b09-71a064a42125/mac).
- **Windows:** instale o WSL 2, que roda um Linux (Ubuntu) dentro do Windows, seguindo o [guia da Microsoft](https://learn.microsoft.com/pt-br/windows/wsl/install). Na prática, abra o PowerShell como administrador, rode `wsl --install`, reinicie e crie um usuário e uma senha quando o Ubuntu abrir. Depois disso, abra sempre o app **Ubuntu** e rode todos os comandos lá dentro, não no PowerShell nem no Prompt de Comando.
- **Linux:** abra o terminal da sua distribuição (no Ubuntu, Ctrl+Alt+T).

Três comandos que você vai usar o tempo todo:

```bash
pwd          # mostra em que pasta você está
ls           # lista os arquivos da pasta
cd pasta     # entra em uma pasta; "cd .." volta uma pasta
```

Se o nome da pasta tiver espaços ou acentos, coloque entre aspas: `cd "Minha Pasta"`. Para começar do básico, a MDN tem um [curso rápido de linha de comando](https://developer.mozilla.org/en-US/docs/Learn_web_development/Getting_started/Environment_setup/Command_line) (em inglês).

### 2. Instalar e configurar o Git

O Git guarda o histórico das suas mudanças. Neste desafio ele é parte da medição: cada resultado registra o commit que foi medido.

- **macOS:** rode `git --version`. Se não estiver instalado, o próprio sistema oferece a instalação.
- **Windows (dentro do Ubuntu do WSL) e Linux:** `sudo apt update && sudo apt install -y git`
- Outras opções em [git-scm.com/downloads](https://git-scm.com/downloads).

Depois, diga ao Git quem você é. Isso aparece em cada commit:

```bash
git config --global user.name "Seu Nome"
git config --global user.email "seu-email@exemplo.com"
git --version     # confere: deve mostrar algo como "git version 2.x"
```

Referências: [configurar o Git (GitHub Docs)](https://docs.github.com/pt/get-started/git-basics/set-up-git) e o livro [Pro Git em português](https://git-scm.com/book/pt-br/v2), gratuito.

### 3. Instalar o Docker

O Docker roda programas dentro de **containers**: ambientes isolados que já vêm com tudo o que o programa precisa. É por isso que você não instala Node.js nem PostgreSQL: a API e o banco rodam cada um no seu container. Para entender a ideia em poucos minutos, leia a [visão geral do Docker](https://docs.docker.com/get-started/docker-overview/) (em inglês).

- **macOS:** instale o [Docker Desktop para Mac](https://docs.docker.com/desktop/setup/install/mac-install/). Escolha a versão do seu processador: Apple (M1, M2…) ou Intel.
- **Windows:** instale o [Docker Desktop para Windows](https://docs.docker.com/desktop/setup/install/windows-install/) e, nas configurações, confirme que a [integração com o WSL 2](https://docs.docker.com/desktop/features/wsl/) está ligada para o Ubuntu (Settings → Resources → WSL integration).
- **Linux:** instale o [Docker Engine](https://docs.docker.com/engine/install/) da sua distribuição, que já traz o Compose, e siga os [passos pós-instalação](https://docs.docker.com/engine/install/linux-postinstall/) para rodar `docker` sem `sudo`.

No macOS e no Windows, o Docker Desktop precisa estar aberto (ícone da baleia na barra) para os comandos funcionarem. Confira:

```bash
docker --version          # Docker version 2x.x.x
docker compose version    # Docker Compose version v2.x.x
docker run hello-world    # baixa uma imagem de teste e imprime "Hello from Docker!"
```

Se os três funcionarem, o Docker está pronto.

### 4. Criar a sua cópia do desafio

O desafio é só esta pasta. Você baixa o repositório t4h-desafios, copia a pasta para um lugar seu e transforma a cópia em um repositório Git próprio, que depois vai para o seu GitHub.

No Windows, rode isto dentro do Ubuntu e deixe os arquivos na sua pasta pessoal do Linux (`cd ~`), não em `C:\` (`/mnt/c/...`), onde tudo fica bem mais lento.

```bash
cd ~
git clone https://github.com/tech4humans-brasil/t4h-desafios.git
mkdir meu-desafio
cp -R "t4h-desafios/Vaga - Estágio Pesquisa e Inovação 2026/." meu-desafio/
cd meu-desafio

git init -b main
git add .
git commit -m "chore: estado original do desafio"
ls        # deve mostrar AGENTS.md, CLAUDE.md, README.md, api, banco, carga, contrato, docker-compose.yml, resultados, scripts
```

A partir daqui, todos os comandos rodam dentro de `meu-desafio`. A pasta `t4h-desafios` pode ser apagada.

Para publicar no GitHub, crie um repositório público vazio (sem README) e siga [Adicionar código local ao GitHub](https://docs.github.com/pt/migrations/importing-source-code/using-the-command-line-to-import-source-code/adding-locally-hosted-code-to-github). Os comandos são estes, trocando `SEU-USUARIO` e `SEU-REPO`:

```bash
git remote add origin https://github.com/SEU-USUARIO/SEU-REPO.git
git push -u origin main
```

O GitHub não aceita a senha da conta no `git push`. Use o [GitHub CLI](https://cli.github.com/) (`gh auth login`) ou um [token de acesso pessoal](https://docs.github.com/pt/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) no lugar da senha.

Para editar o código, qualquer editor serve. Se for usar o VS Code no Windows, abra a pasta pelo Ubuntu com `code .` e veja [VS Code com WSL](https://code.visualstudio.com/docs/remote/wsl).

### 5. Subir a aplicação

Dentro da sua cópia:

```bash
docker compose up -d --build
```

O que esse comando faz:

- `up` cria e liga os containers descritos no `docker-compose.yml`: `banco` (PostgreSQL) e `api` (Node.js).
- `-d` roda em segundo plano e devolve o terminal para você.
- `--build` monta a imagem da API a partir do `api/Dockerfile`. Use sempre que mudar o código.

Na primeira vez, o Docker baixa as imagens (algumas centenas de MB, conforme a sua internet) e o banco gera os dados, o que leva de alguns segundos a 3 minutos, conforme a máquina. O comando só termina quando o banco está pronto. Para acompanhar a geração dos dados, em outro terminal: `docker compose logs -f banco` (Ctrl+C para sair). Você vai ver linhas como `Gerando 500.000 pedidos...`.

Confira se os dois containers estão de pé:

```bash
docker compose ps
```

```
NAME                          IMAGE                     ...   SERVICE   STATUS                    PORTS
desafio-performance-api-1     desafio-performance-api   ...   api       Up 3 seconds              127.0.0.1:3000->3000/tcp
desafio-performance-banco-1   postgres:16.4             ...   banco     Up 24 seconds (healthy)   127.0.0.1:5432->5432/tcp
```

O banco precisa aparecer como `(healthy)`. Referência dos comandos: [docker compose](https://docs.docker.com/reference/cli/docker/compose/) (em inglês).

### 6. Fazer as primeiras chamadas

A API responde em `http://127.0.0.1:3000`. O `curl` faz uma requisição HTTP pelo terminal e mostra a resposta:

```bash
curl http://127.0.0.1:3000/saude
# {"status":"ok"}

curl http://127.0.0.1:3000/clientes/1
# {"id":1,"nome":"Bruno Almeida","email":"cliente1@exemplo.com","cidade":"Fortaleza","criado_em":"2022-01-01T02:11:59.000Z"}

curl "http://127.0.0.1:3000/produtos/busca?q=mesa"
# [{"id":10061,"nome":"Mesa Basica Modelo 10061","categoria":"Moveis","preco_centavos":481580}, ...]

curl http://127.0.0.1:3000/clientes/abc
# {"erro":"id invalido"}
```

Quando a URL tiver `?` ou `&`, coloque entre aspas, como no terceiro exemplo. Também dá para abrir essas URLs no navegador. As outras rotas estão na tabela [Rotas](#rotas). Algumas, como os relatórios, demoram vários segundos: é essa lentidão que você vai investigar.

Para conhecer o `curl`, veja o [tutorial oficial](https://curl.se/docs/tutorial.html) (em inglês).

### 7. Gravar o contrato e medir a linha de base

Com a aplicação original no ar e antes de mudar qualquer coisa:

```bash
scripts/verificar-contrato.sh gravar
git add contrato/base.json
git commit -m "chore: grava contrato da aplicação original"

scripts/medir.sh 00-linha-de-base
scripts/medir.sh 00-linha-de-base
scripts/medir.sh 00-linha-de-base
git add resultados
git commit -m "chore: medições da linha de base"
```

O primeiro comando salva as respostas da aplicação original para comparar depois. Cada `medir.sh` mede o desempenho dela, leva cerca de 1 min 30 s e mostra onde salvou o resultado: uma pasta nova em `resultados/` por execução. As três execuções são o seu **antes**. Leia os números com `cat resultados/*-00-linha-de-base/resumo.txt`. O que cada arquivo significa e como seguir a partir daí está em [Como medir](#como-medir).

### 8. Parar e voltar depois

```bash
docker compose stop     # desliga os containers e mantém os dados
docker compose start    # liga de novo, sem gerar os dados outra vez
docker compose down     # remove os containers e mantém os dados
docker compose down -v  # remove containers e banco; a próxima subida gera os dados do zero
```

Se reiniciar o computador, abra o Docker Desktop e rode `docker compose up -d` dentro da sua cópia.

## Conceitos em um minuto

| Termo | O que é | Para ler mais |
| --- | --- | --- |
| Container e imagem | A imagem é o pacote com o programa e tudo de que ele precisa; o container é essa imagem rodando | [Docker overview](https://docs.docker.com/get-started/docker-overview/) |
| Docker Compose | Sobe vários containers juntos a partir do `docker-compose.yml` | [Docker Compose](https://docs.docker.com/compose/) |
| API e rota | Programa que responde a requisições HTTP; cada rota é um endereço, como `/clientes/1` | [Express](https://expressjs.com/) |
| Node.js e `pg` | Node.js roda JavaScript fora do navegador; `pg` é a biblioteca que a API usa para falar com o banco | [Introdução ao Node.js](https://nodejs.org/pt/learn/getting-started/introduction-to-nodejs), [node-postgres](https://node-postgres.com/) |
| PostgreSQL e `psql` | O banco de dados relacional da aplicação e o cliente de linha de comando dele | [Tutorial do PostgreSQL](https://www.postgresql.org/docs/16/tutorial.html), [psql](https://www.postgresql.org/docs/16/app-psql.html) |
| Teste de carga e k6 | Simula muitos usuários usando a API ao mesmo tempo; k6 é a ferramenta que faz isso aqui | [k6](https://grafana.com/docs/k6/latest/) |
| Mediana, p95 e p99 | Metade das requisições foi mais rápida que a mediana; 95% foram mais rápidas que o p95 e 99% que o p99 | [Métricas do k6](https://grafana.com/docs/k6/latest/using-k6/metrics/) |
| Commit | Um ponto salvo no histórico do Git, com as mudanças e uma mensagem | [Pro Git](https://git-scm.com/book/pt-br/v2) |

## Subir a aplicação

Resumo do [passo 5](#5-subir-a-aplicação), para quem já tem tudo instalado. Rode dentro desta pasta:

```bash
docker compose up -d --build
curl http://127.0.0.1:3000/saude      # {"status":"ok"}
```

O `up -d` só termina quando o banco está pronto para uso. Na primeira vez o banco gera os dados antes, o que leva de alguns segundos a 3 minutos, conforme a máquina. Para acompanhar, em outro terminal: `docker compose logs -f banco` (Ctrl+C para sair).

## Rotas

| Rota | Parâmetros | Devolve |
| --- | --- | --- |
| `GET /saude` | | `{"status":"ok"}` |
| `GET /clientes/:id` | | Um cliente |
| `GET /clientes?email=` | `email`, sem diferenciar maiúsculas | Lista de clientes com esse e-mail |
| `GET /clientes/:id/pedidos` | | Pedidos do cliente, do mais recente para o mais antigo, com itens e total |
| `GET /pedidos?status=&pagina=` | `status`: `pago`, `entregue`, `cancelado` ou `pendente`; `pagina` a partir de 1 | Página de 20 pedidos, do mais recente para o mais antigo, e o total do status |
| `GET /produtos/busca?q=` | `q` com pelo menos 3 caracteres | Até 20 produtos cujo nome contém o termo |
| `GET /relatorios/vendas-por-dia?inicio=&fim=` | datas `AAAA-MM-DD`, período de até 31 dias | Pedidos, itens e receita por dia, sem pedidos cancelados |
| `GET /relatorios/top-produtos?limite=` | `limite` de 1 a 50, padrão 10 | Produtos com maior receita, sem pedidos cancelados |

Valores em dinheiro estão em centavos. Datas saem em UTC.

## O que você pode mudar

- O código da API e o `Dockerfile`
- O `docker-compose.yml`: limites de CPU e memória, configuração dos serviços e serviços novos, como um cache
- As consultas, os índices, a estrutura das tabelas e a configuração do banco

Mais recurso custa mais. Se você aumentar o limite de CPU ou de memória de um container, ou adicionar um serviço, o ganho vem junto com um custo maior, e a comparação precisa mostrar os dois. O `medir.sh` coleta CPU e memória de todos os serviços do `docker-compose.yml` e registra os limites de cada um em `contexto.txt`.

**O que não pode mudar:**

- O que cada rota devolve, incluindo status HTTP, campos, valores e ordem. O verificador de contrato existe para provar isso.
- As ferramentas de medição: `carga/`, `contrato/verificar.js` e `scripts/`, e o `contrato/base.json` depois de gravado. Mudar a régua invalida a comparação.
- Os dados: `banco/01-estrutura.sql` e `banco/02-dados.sql` ficam como estão. Mudanças no banco vão em arquivos novos, como `banco/03-indices.sql` (veja [Voltar ao estado original](#voltar-ao-estado-original)).

## Como medir

O ciclo é sempre o mesmo: meça antes, mude uma coisa e meça depois.

**1. Grave o contrato, uma única vez, antes de mudar qualquer coisa:**

```bash
scripts/verificar-contrato.sh gravar
```

Ele chama 42 casos de teste e salva as respostas da aplicação original em `contrato/base.json`. Faça commit desse arquivo antes de qualquer mudança.

**2. Meça a linha de base, três vezes:**

```bash
scripts/medir.sh 00-linha-de-base     # repita mais duas vezes, com o mesmo rótulo
```

O rótulo dá nome à medição: um número e o que mudou, só com letras, números, ponto, hífen ou sublinhado. Exemplos: `00-linha-de-base`, `01-<o-que-mudou>`.

O script confere se a API está no ar, faz um aquecimento de 15 segundos, que não entra no resultado, e depois roda 20 usuários virtuais por 60 segundos, cada um fazendo requisições em sequência, sem pausa. Enquanto isso, coleta o uso de CPU e memória dos containers. No fim, roda o verificador de contrato e mostra um resumo na tela. Cada medição leva cerca de 1 min 30 s e cria uma pasta nova `resultados/<data>-<hora>-<rotulo>/`, por exemplo `resultados/20261105-143012-00-linha-de-base/`. Nada é sobrescrito: três execuções com o mesmo rótulo geram três pastas.

| Arquivo | Conteúdo |
| --- | --- |
| `resumo.txt` | Requisições por segundo, erros e tempo de resposta (mediana, p95, p99), no geral e por rota |
| `recursos.txt` | CPU e memória, média e máximo, de cada container durante a carga |
| `recursos.csv` | As amostras de CPU e memória usadas no `recursos.txt` |
| `contexto.txt` | Parâmetros da medição, commit e limites dos containers |
| `contrato.txt` | Saída do verificador de contrato, rodado logo depois da carga. A última linha diz se o contrato foi mantido |
| `resumo-k6.json` | Todas as métricas do k6 |

Não edite esses arquivos. Commite as pastas da linha de base antes da primeira mudança.

**3. Para cada mudança:**

1. Faça a mudança e commite. Assim o `contexto.txt` registra o commit medido e mostra `arquivos alterados sem commit: 0`.
2. Aplique e confira o contrato:

    ```bash
    docker compose up -d --build            # mudanças na API, no Dockerfile ou no compose
    # arquivo .sql novo em banco/: docker compose down -v && docker compose up -d --build
    scripts/verificar-contrato.sh comparar  # precisa terminar em "Contrato mantido"
    ```

3. Meça pelo menos 3 vezes com o mesmo rótulo: `scripts/medir.sh 01-<o-que-mudou>`.
4. Commite as pastas de `resultados/` dessa mudança em um commit separado.

Os parâmetros da carga podem ser alterados por variáveis de ambiente. Use os mesmos valores em todas as medições que você for comparar.

| Variável | Padrão | O que controla |
| --- | --- | --- |
| `VUS` | `20` | Usuários virtuais simultâneos |
| `DURACAO` | `60s` | Duração da medição |
| `AQUECIMENTO` | `15s` | Duração do aquecimento |
| `SEMENTE` | `42` | Semente do sorteio das URLs. A mesma semente repete as mesmas requisições |
| `PORTA_API` | `3000` | Porta da API na sua máquina, usada só para conferir se ela está no ar |

Exemplo: `VUS=50 DURACAO=120s scripts/medir.sh 05-carga-maior`

**Para a comparação ser justa:** meça sempre na mesma máquina, com os outros programas pesados fechados. Rode cada medição pelo menos 3 vezes e compare a mediana das execuções. Entre uma execução e outra, a diferença pode passar de 30%.

Na linha de base, algumas rotas são tão lentas que têm poucas requisições em 60 segundos. Nelas, os números por rota oscilam muito: use o resultado geral, ou aumente `DURACAO` em todas as medições.

**Encontrar as medições depois:**

```bash
ls resultados/                                 # todas as medições, por ordem de data
ls -d resultados/*-00-linha-de-base            # as execuções de um rótulo
cat resultados/*-00-linha-de-base/resumo.txt   # os números de todas elas
cat resultados/<pasta>/contexto.txt            # o commit e os parâmetros da medição
```

O `contexto.txt` registra o commit medido, então dá para saber qual versão do código gerou cada número.

**Medir o antes de novo:** se você trocar de máquina ou mudar os parâmetros da carga, as medições antigas deixam de ser comparáveis. Volte ao commit da linha de base (está no `contexto.txt` dela), recrie o banco e meça de novo:

```bash
git switch --detach <commit-da-linha-de-base>
docker compose down -v && docker compose up -d --build
scripts/medir.sh 00-linha-de-base     # três vezes
git switch main
docker compose down -v && docker compose up -d --build
```

As pastas novas em `resultados/` continuam lá quando você volta para a `main`. Depois, meça de novo também as mudanças que for comparar com esse antes.

## Acessar o banco

```bash
docker compose exec banco psql -U loja -d loja
```

Também dá para conectar de fora, por exemplo com DBeaver ou pgAdmin: host `127.0.0.1`, porta `5432`, usuário `loja`, banco `loja`, sem senha. A porta só aceita conexões da sua máquina.

Os logs da API ficam em `docker compose logs -f api`.

Para mudar parâmetros do PostgreSQL de um jeito que outra pessoa consiga repetir, passe cada um com `-c` no serviço `banco` do `docker-compose.yml`:

```yaml
  banco:
    image: postgres:16.4
    command: ["postgres", "-c", "shared_buffers=128MB"]
```

Aplique com `docker compose up -d`: o banco reinicia sem perder os dados. Para conferir o valor em uso: `docker compose exec banco psql -U loja -d loja -c 'SHOW shared_buffers;'`

## Voltar ao estado original

```bash
docker compose down -v      # apaga o banco
docker compose up -d --build
```

Tudo o que você fizer direto no `psql` se perde quando o banco é apagado. Para que outra pessoa consiga repetir o seu experimento, registre essas mudanças em um arquivo `.sql` dentro de `banco/`. Os arquivos dessa pasta rodam em ordem alfabética, só quando o banco é criado do zero.

## Guardar o experimento no repositório

1. Trabalhe numa cópia só desta pasta, num repositório seu, como no [passo 4](#4-criar-a-sua-cópia-do-desafio). O resto do t4h-desafios é de outros processos seletivos.
2. Faça commit das suas mudanças, do `contrato/base.json` e das pastas de `resultados/`, sem editar os arquivos gerados. Faça um commit por mudança, seguido do commit com os resultados dela.
3. Se mexer neste README, mantenha as instruções de subir e medir, para que outra pessoa consiga repetir o experimento.

## Usar um agente de IA

O [AGENTS.md](AGENTS.md) resume, para agentes como Claude Code, Codex ou Cursor, como rodar e medir a aplicação e o que não pode ser mudado. Ele não traz o enunciado: passe o enunciado para o agente junto com o seu pedido.

Abra o agente dentro da sua cópia desta pasta. Na raiz do t4h-desafios, o `CLAUDE.md` e a pasta `.claude/` são de quem mantém o repositório e não valem para o desafio.

## Problemas comuns

- **`docker: command not found` ou `Cannot connect to the Docker daemon`:** no macOS e no Windows, abra o Docker Desktop e espere o ícone da baleia parar de animar. No Windows, confira também a integração com o WSL ([passo 3](#3-instalar-o-docker)). No Linux, ligue o serviço com `sudo systemctl start docker`.
- **`permission denied` ao rodar `docker` no Linux:** seu usuário ainda não está no grupo `docker`. Siga os [passos pós-instalação](https://docs.docker.com/engine/install/linux-postinstall/) e abra um terminal novo.
- **`unknown command: docker compose` ou `docker: 'compose' is not a docker command`:** o Docker está desatualizado. Instale a versão atual pelo [passo 3](#3-instalar-o-docker). O comando antigo `docker-compose`, com hífen, não serve.
- **`No such file or directory` ao entrar na pasta:** o nome tem espaços ou acentos e precisa de aspas, por exemplo `cd "Vaga - Estágio Pesquisa e Inovação 2026"`. Use `ls` para ver o nome exato.
- **`permission denied: scripts/medir.sh`:** os scripts perderam a permissão de execução, o que acontece quando a pasta é baixada como ZIP em vez de clonada. Rode `chmod +x scripts/*.sh`.
- **Porta 5432 ou 3000 em uso:** pare o outro serviço ou troque o lado esquerdo do mapeamento em `ports:` no `docker-compose.yml`. Se trocar a porta da API, rode as medições com a nova porta, por exemplo `PORTA_API=3001 scripts/medir.sh 00-linha-de-base`.
- **`medir.sh` diz que a API não respondeu:** veja se o banco já terminou de gerar os dados (`docker compose logs banco`).
- **Erro `bash\r` ou `$'\r': command not found` no Windows:** o Git converteu as quebras de linha. Isso acontece quando o repositório é clonado pelo Git do Windows em vez do Git do Ubuntu. Rode `git config --global core.autocrlf false` e clone de novo, de preferência dentro do Ubuntu, como no [passo 4](#4-criar-a-sua-cópia-do-desafio).

## Observações Importantes

- Leia o enunciado inteiro antes de começar
- Mantenha-se dentro do prazo
- Em caso de dúvidas, use o canal combinado na largada

Boa sorte no seu desafio!
