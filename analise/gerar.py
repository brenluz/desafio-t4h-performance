#!/usr/bin/env python3
"""Gera as tabelas do experimentos.md, o resumo do README e os gráficos de artigo/img/ a partir de resultados/.

Só lê resultados/, nunca escreve lá. Os números das tabelas são os dos arquivos gravados pelo
medir.sh (resumo.txt, recursos.txt, contexto.txt, contrato.txt). As únicas contas feitas aqui são:
mediana das 3 medições de cada valor, variação entre antes e depois, CPU em % da cota do container
e custo por hora / por milhão de requisições (fórmula do estudo de custo, fonte F22 do diário).
Usa só a biblioteca padrão do Python.

Uso, na raiz do repositório:  python3 analise/gerar.py
"""

import json
import math
import re
import statistics
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
RESULTADOS = RAIZ / "resultados"
IMG = RAIZ / "artigo" / "img"
EXPERIMENTOS_MD = RAIZ / "experimentos.md"
README_MD = RAIZ / "README.md"

# AWS Fargate, Linux/x86, US East, conferido em 11/11/2026 (F22). Serve para comparar configurações, não é orçamento.
PRECO_VCPU_HORA = 0.04048
PRECO_GB_HORA = 0.004445

ROTAS = ["cliente", "cliente-por-email", "pedidos-do-cliente", "pedidos-por-status",
         "busca-produtos", "vendas-por-dia", "top-produtos"]

# Medições de cada experimento original (início do nome da pasta). Ficam de fora as descartadas,
# registradas no experimentos.md: as 3 primeiras do 04 e a execução extra do 07.
MEDICOES = {
    "00": ["20261105-165057", "20261105-165331", "20261105-165546"],
    "01": ["20261105-172652", "20261105-173051", "20261105-173531"],
    "02": ["20261105-185715", "20261105-190052", "20261105-190307"],
    "03": ["20261105-192107", "20261105-192320", "20261105-192602"],
    "03-remedido": ["20261109-192344", "20261109-192526", "20261109-192702"],
    "04": ["20261109-194137", "20261109-194359", "20261109-194912"],
    "05": ["20261109-201718", "20261109-202101", "20261109-203110"],
    "06": ["20261109-211748", "20261109-211938", "20261109-212142"],
    "07": ["20261109-213632", "20261109-213755", "20261109-213918"],
    "08": ["20261109-215711", "20261109-215833", "20261109-215955"],
    "09": ["20261109-222257", "20261109-222417", "20261109-222536"],
    "10": ["20261109-223641", "20261109-223801", "20261109-223920"],
    "11": ["20261109-224702", "20261109-224822", "20261109-224942"],
    "12": ["20261109-230625", "20261109-230744", "20261109-230904"],
    "12-remedido": ["20261111-170206", "20261111-170326", "20261111-170447"],
    "13": ["20261111-170935", "20261111-171055", "20261111-171216"],
    "14": ["20261111-172915", "20261111-173035", "20261111-173155"],
    "15": ["20261111-181323", "20261111-181443", "20261111-181604"],
    "16": ["20261111-182805", "20261111-182926", "20261111-183047"],
    # 17: rodada 2 do tamanho do pool (16/11); antes = pool de 20 e depois = pool de 3, nos mesmos blocos.
    "17-antes": ["20261116-212110", "20261116-212357", "20261116-213343"],
    "17": ["20261116-211822", "20261116-212645", "20261116-213055"],
}

APLICADA = "Aplicada e medida"
SEM_GANHO = "Aplicada, sem ganho (desfeita)"

# Uma linha por ideia aplicada. "antes" é a medição de comparação, sempre da mesma sessão do "depois".
# A conclusão é texto, sem números: os números da linha vêm das pastas.
EXPERIMENTOS = [
    dict(id="01", rotulo="01-indices-fk", mudanca="Índices nas chaves estrangeiras `pedidos (cliente_id)` e `itens_pedido (pedido_id)`",
         fontes="F1, F2", status=APLICADA, antes="00", antes_texto="linha de base", rota="pedidos-do-cliente",
         conclusao="Ganho. As rotas que buscam pedidos e itens deixam de ler as tabelas inteiras. Custo: espaço dos índices e escrita mais cara (a API só lê; não medido)."),
    dict(id="02", rotulo="02-indice-pedidos-status", mudanca="Índice `pedidos (status, criado_em DESC, id DESC)` para a página de `/pedidos`",
         fontes="F4, F3", status=APLICADA, antes="01", antes_texto="exp. 01", rota="pedidos-por-status",
         conclusao="Ganho. O índice casa com o `ORDER BY` e tira a ordenação; o `count(*)` do total continua caro (resolvido no 11)."),
    dict(id="03", rotulo="03-n-mais-1", mudanca="N+1 de `/clientes/:id/pedidos` trocado por uma consulta com `JOIN`",
         fontes="F5, F6, F25", status=APLICADA, antes="02", antes_texto="exp. 02", rota="pedidos-do-cliente",
         conclusao="Ganho na rota e na vazão. O p95 geral piorou: com a carga em ciclo fechado, a fila foi para os relatórios."),
    dict(id="04", rotulo="04-pool-conexoes", mudanca="`pg.Pool` (`max: 20`) no lugar de uma conexão nova por consulta",
         fontes="F7, F8, F9", status=APLICADA, antes="03-remedido", antes_texto="exp. 03 remedido (09/11)", rota=None,
         conclusao="Ganho. Menos conexões e processos novos no PostgreSQL; a mediana caiu muito, o p95 continuou decidido pelos relatórios."),
    dict(id="05", rotulo="05-indice-vendas-por-dia", mudanca="Índice de expressão `pedidos ((criado_em::date))`",
         fontes="F10", status=APLICADA, antes="04", antes_texto="exp. 04", rota="vendas-por-dia",
         conclusao="Ganho. `vendas-por-dia` deixa de varrer `pedidos`; o p99 geral piorou porque a fila passou para `top-produtos` e `pedidos-por-status`."),
    dict(id="06", rotulo="06-pedidos-late-lookup", mudanca="Late row lookup na página de `/pedidos` (o `OFFSET` anda só no índice)",
         fontes="F11, F12", status=APLICADA, antes="05", antes_texto="exp. 05", rota="pedidos-por-status",
         conclusao="Ganho. As linhas puladas pelo `OFFSET` não são mais lidas da tabela; a cauda de `pedidos-por-status` some."),
    dict(id="07", rotulo="07-top-produtos-visao-materializada", mudanca="Visão materializada com o resumo de vendas por produto",
         fontes="F13, F14", status=APLICADA, antes="06", antes_texto="exp. 06", rota="top-produtos",
         conclusao="Maior ganho do trabalho. É o melhor caso: os dados nunca mudam aqui, e o custo do `REFRESH` sob carga não foi medido (próximos testes)."),
    dict(id="08", rotulo="08-indice-email", mudanca="Índice de expressão `clientes (lower(email))`",
         fontes="F10, F15", status=APLICADA, antes="07", antes_texto="exp. 07", rota="cliente-por-email",
         conclusao="Ganho. O banco deixa de ser o gargalo e a API passa a ser (CPU da API no teto da cota)."),
    dict(id="09", rotulo="09-vendas-agregada-no-sql", mudanca="`vendas-por-dia` agregada no SQL (`GROUP BY`) em vez de no Node",
         fontes="Diagnóstico 04 (perfil da API)", status=APLICADA, antes="08", antes_texto="exp. 08", rota="vendas-por-dia",
         conclusao="Ganho. A API sai do teto de CPU e o gargalo volta ao banco; equivalência do JSON provada em todas as janelas da carga. A cauda da própria rota piorou: ela passou a ser mais chamada, num banco de novo saturado."),
    dict(id="10", rotulo="10-busca-trigramas", mudanca="Índice GIN `pg_trgm` em `produtos.nome`",
         fontes="F17", status=APLICADA, antes="09", antes_texto="exp. 09", rota="busca-produtos",
         conclusao="Ganho. A busca por trecho (`ILIKE '%termo%'`) passa a usar índice, com resultado provado igual."),
    dict(id="11", rotulo="11-contagem-por-status", mudanca="Contagem de pedidos por status numa visão materializada",
         fontes="F13, F14", status=APLICADA, antes="10", antes_texto="exp. 10", rota="pedidos-por-status",
         conclusao="Ganho. O total da página deixa de contar todos os pedidos do status a cada chamada; mesma ressalva de dados estáticos do 07."),
    dict(id="12", rotulo="12-sem-paralelismo", mudanca="`max_parallel_workers_per_gather=0`",
         fontes="F18, F19, F16", status=APLICADA, antes="11", antes_texto="exp. 11", rota="vendas-por-dia",
         conclusao="Ganho. Com 1 CPU de limite, os workers paralelos só dividiam a mesma cota; as rotas baratas saem do degrau de throttling."),
    dict(id="13", rotulo="13-indice-cobrindo-itens", mudanca="Índice `itens_pedido (pedido_id) INCLUDE (quantidade, preco_unitario_centavos)` no lugar do índice do 01",
         fontes="F20", status=APLICADA, antes="12-remedido", antes_texto="exp. 12 remedido (11/11)", rota="vendas-por-dia",
         conclusao="Ganho. `vendas-por-dia` lê só o índice e o planejador deixa de escolher a varredura completa em algumas janelas."),
    dict(id="14", rotulo="14-shared-buffers-256mb", mudanca="`shared_buffers=256MB` (padrão 128 MB)",
         fontes="F21", status=APLICADA, antes="13", antes_texto="exp. 13", rota=None,
         conclusao="Ganho. A tabela `pedidos` e os índices mais usados cabem no cache do PostgreSQL. Custo: memória fixa a mais no banco, acima da faixa de 25–40% da documentação."),
    dict(id="15", rotulo="15-shared-buffers-192mb", mudanca="`shared_buffers=192MB` (dentro dos 40% da documentação)",
         fontes="F21", status=SEM_GANHO, antes="14", antes_texto="exp. 14", rota=None,
         conclusao="Pior que 256 MB. Desfeito: neste ambiente o ganho exige passar da recomendação."),
    dict(id="16", rotulo="16-indice-cobrindo-pedidos", mudanca="Índice `pedidos ((criado_em::date)) INCLUDE (criado_em, id, status)`",
         fontes="F20", status=SEM_GANHO, antes="14", antes_texto="exp. 14", rota="vendas-por-dia",
         conclusao="Sem ganho de vazão (faixas sobrepostas) e um índice maior disputando o cache. Desfeito."),
    dict(id="17", rotulo="17-tamanho-do-pool", mudanca="Pool de conexões da API com `max: 3` no lugar de 20",
         fontes="F9, F27", status=APLICADA, antes="17-antes", antes_texto="pool de 20, mesma sessão (versão até o 16)", rota=None,
         conclusao="Ganho, reproduzido em duas rodadas. Menos consultas ao mesmo tempo gastam menos CPU do banco por requisição; as demais esperam na fila do pool. 2 e 3 empatam em vazão, 3 tem mediana menor; com 1, a CPU do banco fica ociosa. A API passa a ser o próximo limite."),
]

# Rodada final: (rótulo no nome da pasta, nome curto, experimento original correspondente).
RODADA_FINAL = [
    ("controle-inicio", "versão final (controle, início)", None),
    ("00-linha-de-base", "00 linha de base", None),
    ("01-indices-fk", "01 índices nas FKs", "01"),
    ("02-indice-pedidos-status", "02 índice de status", "02"),
    ("03-n-mais-1", "03 N+1", "03"),
    ("04-pool-conexoes", "04 pool de conexões", "04"),
    ("05-indice-vendas-por-dia", "05 índice por dia", "05"),
    ("06-pedidos-late-lookup", "06 late row lookup", "06"),
    ("07-top-produtos-visao-materializada", "07 visão top-produtos", "07"),
    ("08-indice-email", "08 índice de e-mail", "08"),
    ("09-vendas-agregada-no-sql", "09 vendas no SQL", "09"),
    ("10-busca-trigramas", "10 trigramas", "10"),
    ("11-contagem-por-status", "11 contagem por status", "11"),
    ("12-sem-paralelismo", "12 sem paralelismo", "12"),
    ("13-indice-cobrindo-itens", "13 índice cobrindo itens", "13"),
    ("14-shared-buffers-256mb", "14 shared_buffers (final)", "14"),
]

CUSTO = [
    ("custo-base-original", "Original, limites originais"),
    ("custo-00-limites-originais", "Final, limites originais"),
    ("custo-01-metade-cpu", "Final, metade da CPU (1ª rodada)"),
    ("custo-01-metade-cpu-intercalado", "Final, metade da CPU (intercalado)"),
    ("custo-02-um-quarto-cpu", "Final, um quarto da CPU"),
    ("custo-03-metade-cpu-menos-memoria", "Final, metade da CPU e menos memória (1ª rodada)"),
    ("custo-03-metade-cpu-menos-memoria-intercalado", "Final, metade da CPU e menos memória (intercalado)"),
]

# Curva de capacidade (16/11): usuários virtuais medidos em cada versão; pastas curva-<versão>-vus-<nnn>.
CURVA_NIVEIS = [1, 5, 10, 20, 40]
CURVA_VERSOES = [("original", "Aplicação original"), ("final", "Versão final")]

# Experimento 17, tamanho do pool: (nome da rodada, prefixo do rótulo, tamanhos na ordem da tabela).
POOL_RODADAS = [
    ("Rodada 1 (16/11, 20:48–21:08)", "17-pool-max", [20, 10, 5, 2]),
    ("Rodada 2 (16/11, 21:15–21:42)", "17-pool-r2-max", [20, 3, 2, 1]),
]

# ---------------------------------------------------------------- leitura das pastas


def ler_medicao(pasta):
    resumo = (pasta / "resumo.txt").read_text(encoding="utf-8")
    recursos = (pasta / "recursos.txt").read_text(encoding="utf-8")
    contexto = (pasta / "contexto.txt").read_text(encoding="utf-8")
    contrato = (pasta / "contrato.txt").read_text(encoding="utf-8")

    k6 = json.loads((pasta / "resumo-k6.json").read_text(encoding="utf-8"))["metrics"]
    duracao = k6["http_req_duration"].get("values", k6["http_req_duration"])

    tempos = re.search(r"mediana ([\d.]+) ms \| p95 ([\d.]+) ms \| p99 ([\d.]+) ms", resumo)
    m = {
        "pasta": pasta.name,
        "reqs": float(re.search(r"^Requisições/s:\s+([\d.]+)", resumo, re.M).group(1)),
        "mediana": float(tempos.group(1)),
        "p95": float(tempos.group(2)),
        "p99": float(tempos.group(3)),
        "erros": float(re.search(r"^Erros:\s+([\d.]+)%", resumo, re.M).group(1)),
        "media": duracao["avg"],
        "commit": re.search(r"^commit: (\S+)", contexto, re.M).group(1),
        "sem_commit": int(re.search(r"^arquivos alterados sem commit: (\d+)", contexto, re.M).group(1)),
        "contrato": "Contrato mantido" in contrato,
        "rotas": {},
    }
    for linha in resumo.split("Por rota:", 1)[1].splitlines():
        c = linha.split()
        if len(c) == 9 and c[0] in ROTAS and c[3] == c[5] == c[7] == "ms":
            m["rotas"][c[0]] = {"mediana": float(c[2]), "p95": float(c[4]), "p99": float(c[6])}

    # cpu_media do recursos.txt (100% = 1 CPU); o cpu_max não é confiável (ver "Limites" no diário).
    for servico in ("banco", "api"):
        uso = re.search(rf"-{servico}-1\s+\d+\s+([\d.]+)%\s+[\d.]+%\s+([\d.]+) MiB", recursos)
        limite = re.search(rf"^\s*{servico}: cpus=(\d+).*?memoria=(\d+) bytes", contexto, re.M)
        cpus = int(limite.group(1)) / 1e9
        m[servico] = {
            "cpu": float(uso.group(1)),
            "cota": float(uso.group(1)) / cpus,
            "mem": float(uso.group(2)),
            "limite_cpus": cpus,
            "limite_mem": int(limite.group(2)),
        }
    return m


def resolver(prefixos):
    pastas = []
    for prefixo in prefixos:
        achadas = sorted(RESULTADOS.glob(f"{prefixo}-*"))
        if len(achadas) != 1:
            sys.exit(f"esperava 1 pasta começando com {prefixo}, achei {len(achadas)}")
        pastas.append(achadas[0])
    return pastas


def por_rotulo(padrao):
    pastas = sorted(RESULTADOS.glob(padrao))
    if len(pastas) != 3:
        sys.exit(f"esperava 3 pastas para {padrao}, achei {len(pastas)}")
    return pastas


LIDAS = {}


def grupo(pastas):
    medicoes = []
    for pasta in pastas:
        if pasta.name not in LIDAS:
            LIDAS[pasta.name] = ler_medicao(pasta)
        medicoes.append(LIDAS[pasta.name])

    def med(f):
        valores = [f(m) for m in medicoes]
        return statistics.median(valores) if None not in valores else None

    g = {"medicoes": medicoes}
    for chave in ("reqs", "mediana", "p95", "p99"):
        g[chave] = med(lambda m: m[chave])
        g[chave + "_min"] = min(m[chave] for m in medicoes)
        g[chave + "_max"] = max(m[chave] for m in medicoes)
    # Lei de Little (F26): na carga de ciclo fechado sem pausa, usuários ≈ req/s × tempo médio de resposta.
    g["little"] = med(lambda m: m["reqs"] * m["media"] / 1000)
    for servico in ("banco", "api"):
        for chave in ("cota", "mem"):
            g[f"{servico}_{chave}"] = med(lambda m: m[servico][chave])
    for rota in ROTAS:
        for chave in ("mediana", "p95", "p99"):
            g[f"{rota}_{chave}"] = med(lambda m: m["rotas"].get(rota, {}).get(chave))
    commits = {m["commit"] for m in medicoes}
    g["commit"] = commits.pop() if len(commits) == 1 else "/".join(sorted(commits))
    g["limites"] = {(m["banco"]["limite_cpus"], m["banco"]["limite_mem"], m["api"]["limite_cpus"], m["api"]["limite_mem"]) for m in medicoes}
    return g


# ---------------------------------------------------------------- formatação


def num(x, casas=1):
    texto = f"{x:,.{casas}f}"
    return texto.replace(",", "_").replace(".", ",").replace("_", ".")


def variacao(antes, depois):
    razao = depois / antes
    if razao >= 2:
        return f"{num(razao, 1)}×"
    pct = (razao - 1) * 100
    sinal = "+" if pct > 0 else "−" if pct < 0 else ""
    return f"{sinal}{num(abs(pct), 1)}%"


def faixas(antes, depois):
    separadas = depois["reqs_min"] > antes["reqs_max"] or depois["reqs_max"] < antes["reqs_min"]
    return "separadas" if separadas else "sobrepostas"


def links(g):
    return " ".join(f"[{m['pasta'][9:15]}](resultados/{m['pasta']}/resumo.txt)" for m in g["medicoes"])


def mb(bytes_):
    return num(bytes_ / 1024 ** 2, 0)


def custo_hora(limites):
    banco_cpus, banco_mem, api_cpus, api_mem = limites
    return (banco_cpus + api_cpus) * PRECO_VCPU_HORA + (banco_mem + api_mem) / 1024 ** 3 * PRECO_GB_HORA


def dinheiro(x):
    return num(x, 2 if x >= 1 else 3)


# ---------------------------------------------------------------- tabelas


def tabela_experimentos():
    linhas = [
        "| # | Mudança | Fonte | Status | Antes | req/s antes → depois | p95 geral antes → depois | p95 da rota-alvo antes → depois | CPU, % da cota (banco · API) | Memória, MiB (banco · API) | Faixas de req/s | Pastas | Conclusão |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for e in EXPERIMENTOS:
        a = grupo(resolver(MEDICOES[e["antes"]]))
        d = grupo(resolver(MEDICOES[e["id"]]))
        if e["rota"]:
            ra, rd = a[e["rota"] + "_p95"], d[e["rota"] + "_p95"]
            rota = f"`{e['rota']}`: {num(ra)} → {num(rd)} ms ({variacao(ra, rd)})"
        else:
            rota = "— (mudança geral)"
        linhas.append(" | ".join([
            f"| [{e['id']}](notas/diario-de-bordo.md#{e['rotulo']})",
            e["mudanca"],
            e["fontes"],
            e["status"],
            e["antes_texto"],
            f"{num(a['reqs'], 2)} → {num(d['reqs'], 2)} ({variacao(a['reqs'], d['reqs'])})",
            f"{num(a['p95'])} → {num(d['p95'])} ms ({variacao(a['p95'], d['p95'])})",
            rota,
            f"{num(a['banco_cota'])} → {num(d['banco_cota'])} · {num(a['api_cota'])} → {num(d['api_cota'])}",
            f"{num(a['banco_mem'])} → {num(d['banco_mem'])} · {num(a['api_mem'])} → {num(d['api_mem'])}",
            faixas(a, d),
            f"antes: {links(a)}<br>depois: {links(d)}",
            e["conclusao"] + " |",
        ]))
    return "\n".join(linhas)


def rodada_final():
    pontos = []
    for rotulo, nome, exp in RODADA_FINAL:
        pontos.append((rotulo, nome, exp, grupo(por_rotulo(f"*-rodada-final-{rotulo}"))))
    originais = {e["id"]: e for e in EXPERIMENTOS}

    linhas = [
        "| Ponto | Commit | req/s (faixa) | mediana | p95 | p99 | req/s × tempo médio (≈ 20 usuários) | CPU, % da cota (banco · API) | Memória, MiB (banco · API) | Ganho sobre o ponto anterior | Ganho no experimento original | Pastas |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    anterior = None
    for rotulo, nome, exp, g in pontos:
        ganho = variacao(anterior["reqs"], g["reqs"]) if exp else "—"
        if exp:
            e = originais[exp]
            a, d = grupo(resolver(MEDICOES[e["antes"]])), grupo(resolver(MEDICOES[exp]))
            original = variacao(a["reqs"], d["reqs"])
        else:
            original = "—"
        linhas.append(
            f"| {nome} | `{g['commit']}` | {num(g['reqs'], 2)} ({num(g['reqs_min'], 2)}–{num(g['reqs_max'], 2)}) "
            f"| {num(g['mediana'])} ms | {num(g['p95'])} ms | {num(g['p99'])} ms | {num(g['little'], 2)} "
            f"| {num(g['banco_cota'])} · {num(g['api_cota'])} | {num(g['banco_mem'])} · {num(g['api_mem'])} "
            f"| {ganho} | {original} | {links(g)} |"
        )
        if rotulo != "controle-inicio":
            anterior = g

    controle, base, final = pontos[0][3], pontos[1][3], pontos[-1][3]
    resumo = [
        "",
        f"- **Versão final ÷ linha de base:** {num(final['reqs'], 2)} ÷ {num(base['reqs'], 2)} = "
        f"**{num(final['reqs'] / base['reqs'], 1)}×** em req/s; p95 de {num(base['p95'])} ms para {num(final['p95'])} ms.",
        f"- **Controle de deriva** (mesma versão final no início e no fim da rodada): {num(controle['reqs'], 2)} → "
        f"{num(final['reqs'], 2)} req/s ({variacao(controle['reqs'], final['reqs'])}); faixas {faixas(controle, final)}.",
        f"- **Passos com faixa separada da do ponto anterior:** "
        f"{sum(faixas(pontos[i][3], pontos[i + 1][3]) == 'separadas' for i in range(1, len(pontos) - 1))} de {len(pontos) - 2}.",
    ]
    return "\n".join(linhas + resumo), pontos


def tabela_custo():
    linhas = [
        "| Configuração | Limites (banco / API) | Recursos somados | req/s (faixa) | p95 | p99 | US$ por hora | US$ por milhão de req. | Pastas |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    configs, custos = [], {}
    for rotulo, nome in CUSTO:
        g = grupo(por_rotulo(f"*-{rotulo}"))
        if len(g["limites"]) != 1:
            sys.exit(f"limites diferentes entre as medições de {rotulo}")
        limites = next(iter(g["limites"]))
        banco_cpus, banco_mem, api_cpus, api_mem = limites
        hora = custo_hora(limites)
        milhao = hora / (g["reqs"] * 3600) * 1e6
        por_execucao = [hora / (m["reqs"] * 3600) * 1e6 for m in g["medicoes"]]
        configs.append((nome, milhao, min(por_execucao), max(por_execucao)))
        custos[rotulo] = {"grupo": g, "hora": hora, "milhao": milhao}
        linhas.append(
            f"| {nome} | {num(banco_cpus, 3).rstrip('0').rstrip(',')} CPU · {mb(banco_mem)} MB / "
            f"{num(api_cpus, 3).rstrip('0').rstrip(',')} CPU · {mb(api_mem)} MB "
            f"| {num(banco_cpus + api_cpus, 3).rstrip('0').rstrip(',')} CPU · {num((banco_mem + api_mem) / 1024 ** 3, 2)} GB "
            f"| {num(g['reqs'], 2)} ({num(g['reqs_min'], 2)}–{num(g['reqs_max'], 2)}) "
            f"| {num(g['p95'])} ms | {num(g['p99'])} ms | {num(hora, 5)} | {dinheiro(milhao)} | {links(g)} |"
        )
    linhas += [
        "",
        f"Custo por hora = CPUs × {num(PRECO_VCPU_HORA, 5)} + GB × {num(PRECO_GB_HORA, 6)} (US$, F22); "
        "custo por milhão = custo por hora ÷ (req/s × 3.600) × 10⁶, com a mediana de req/s.",
    ]
    return "\n".join(linhas), configs, custos


def curva():
    grupos = {}
    for versao, _ in CURVA_VERSOES:
        for n in CURVA_NIVEIS:
            grupos[versao, n] = grupo(por_rotulo(f"*-curva-{versao}-vus-{n:03d}"))
    controle = grupo(por_rotulo("*-curva-final-vus-020-fim"))

    def erros(g):
        valores = [m["erros"] for m in g["medicoes"]]
        return "0%" if max(valores) == 0 else f"{num(min(valores))}–{num(max(valores))}%"

    def linha(nome, n, g):
        return (f"| {nome} | `{g['commit']}` | {n} | {num(g['reqs'], 2)} ({num(g['reqs_min'], 2)}–{num(g['reqs_max'], 2)}) "
                f"| {num(g['mediana'])} ms | {num(g['p95'])} ms | {num(g['p99'])} ms | {num(g['little'], 2)} "
                f"| {num(g['banco_cota'])} · {num(g['api_cota'])} | {num(g['banco_mem'])} · {num(g['api_mem'])} "
                f"| {erros(g)} | {links(g)} |")

    linhas = [
        "| Versão | Commit | Usuários | req/s (faixa) | mediana | p95 | p99 | req/s × tempo médio (≈ usuários) | CPU, % da cota (banco · API) | Memória, MiB (banco · API) | Erros | Pastas |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for versao, nome in CURVA_VERSOES:
        for n in CURVA_NIVEIS:
            linhas.append(linha(nome, n, grupos[versao, n]))
    linhas.append(linha("Versão final (controle, fim)", 20, controle))

    picos = {versao: max(CURVA_NIVEIS, key=lambda n: grupos[versao, n]["reqs"]) for versao, _ in CURVA_VERSOES}
    inicio = grupos["final", 20]
    linhas += [
        "",
        "- **Pico de req/s:** "
        + "; ".join(f"{nome.lower()}, {num(grupos[v, picos[v]]['reqs'], 2)} req/s com {picos[v]} "
                    f"{'usuário' if picos[v] == 1 else 'usuários'}" for v, nome in CURVA_VERSOES) + ".",
        "- **Versão final ÷ original, em req/s:** "
        + "; ".join(f"{n} {'usuário' if n == 1 else 'usuários'}: {num(grupos['final', n]['reqs'] / grupos['original', n]['reqs'], 0)}×"
                    for n in CURVA_NIVEIS) + ".",
        f"- **Controle de deriva** (versão final com 20 usuários no início e no fim, cada um com preparo próprio): "
        f"{num(inicio['reqs'], 2)} → {num(controle['reqs'], 2)} req/s ({variacao(inicio['reqs'], controle['reqs'])}); "
        f"faixas {faixas(inicio, controle)}.",
        "",
        "Erros: requisições que passaram do limite de 60 s do script de carga (`timeout: '60s'` em `carga/teste-carga.js`). "
        "Ordem das medições em cada versão: 20, 1, 40, 5 e 10 usuários (embaralhada de propósito, F24 §7.1).",
    ]
    return "\n".join(linhas), grupos


def tabela_pool():
    linhas = [
        "| Rodada | `max` | req/s (faixa) | Variação sobre o 20 da mesma rodada | mediana (faixa) | p95 | p99 | CPU, % da cota (banco · API) | CPU do banco por requisição | req/s × tempo médio | Pastas |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    grupos = {}
    for nome, prefixo, tamanhos in POOL_RODADAS:
        vinte = grupo(por_rotulo(f"*-{prefixo}-20"))
        for n in tamanhos:
            g = grupo(por_rotulo(f"*-{prefixo}-{n:02d}"))
            grupos[prefixo, n] = g
            linhas.append(
                f"| {nome} | {n} | {num(g['reqs'], 2)} ({num(g['reqs_min'], 2)}–{num(g['reqs_max'], 2)}) "
                f"| {'—' if n == 20 else variacao(vinte['reqs'], g['reqs']) + ', faixas ' + faixas(vinte, g)} "
                f"| {num(g['mediana'])} ms ({num(g['mediana_min'])}–{num(g['mediana_max'])}) | {num(g['p95'])} ms | {num(g['p99'])} ms "
                f"| {num(g['banco_cota'])} · {num(g['api_cota'])} | {num(g['banco_cota'] * 10 / g['reqs'], 2)} ms | {num(g['little'], 2)} | {links(g)} |"
            )
    original = grupo(por_rotulo("*-17-pool-r2-original"))
    linhas.append(
        f"| Rodada 2 | aplicação original (`{original['commit']}`) | {num(original['reqs'], 2)} ({num(original['reqs_min'], 2)}–{num(original['reqs_max'], 2)}) "
        f"| — | {num(original['mediana'])} ms ({num(original['mediana_min'])}–{num(original['mediana_max'])}) | {num(original['p95'])} ms | {num(original['p99'])} ms "
        f"| {num(original['banco_cota'])} · {num(original['api_cota'])} | — | {num(original['little'], 2)} | {links(original)} |"
    )
    tres = grupos["17-pool-r2-max", 3]
    linhas += [
        "",
        f"- **Versão final (pool de 3) ÷ aplicação original, mesma sessão:** {num(tres['reqs'], 2)} ÷ {num(original['reqs'], 2)} = "
        f"**{num(tres['reqs'] / original['reqs'], 1)}×** em req/s; p95 de {num(original['p95'])} ms para {num(tres['p95'])} ms.",
        "",
        "Com 20 usuários e os limites originais. CPU do banco por requisição = cota usada ÷ req/s. "
        "Em cada rodada, os tamanhos foram medidos em 3 blocos, cada tamanho uma vez por bloco, em ordens embaralhadas fixas; "
        "o registro de cada rodada (tamanho e container da API antes e depois de cada medição, conexões abertas no banco) está em "
        "[`diagnostico/24-tamanho-pool/`](diagnostico/24-tamanho-pool/).",
    ]
    return "\n".join(linhas), tres, original


def resumo_readme(pontos, custos, grupos_curva, pool_final, pool_original):
    base, final = pontos[1][3], pontos[-1][3]
    original, novo = custos["custo-base-original"], custos["custo-00-limites-originais"]
    quarto = custos["custo-02-um-quarto-cpu"]
    razoes = {n: grupos_curva["final", n]["reqs"] / grupos_curva["original", n]["reqs"] for n in CURVA_NIVEIS}
    menor, maior = min(razoes, key=razoes.get), max(razoes, key=razoes.get)
    maximo = max(grupos_curva["final", n]["reqs"] for n in CURVA_NIVEIS)
    picos = [n for n in CURVA_NIVEIS if grupos_curva["final", n]["reqs"] >= 0.99 * maximo]  # empatados com o pico

    def usuarios(n):
        return f"{n} {'usuário' if n == 1 else 'usuários'}"

    def linha(nome, a, d, casas=1, unidade=" ms"):
        return f"| {nome} | {num(a, casas)}{unidade} | {num(d, casas)}{unidade} | {variacao(a, d)} |"

    return "\n".join([
        "| Medida (limites originais: banco 1 CPU · 512 MB, API 0,5 CPU · 256 MB) | Aplicação original | Versão até o experimento 16 (rodada final) | Variação |",
        "| --- | --- | --- | --- |",
        linha("Requisições por segundo", base["reqs"], final["reqs"], 2, ""),
        linha("Tempo de resposta, mediana", base["mediana"], final["mediana"]),
        linha("Tempo de resposta, p95", base["p95"], final["p95"]),
        linha("Tempo de resposta, p99", base["p99"], final["p99"]),
        f"| Custo estimado por milhão de requisições (estudo de custo, 11/11, preços do AWS Fargate) | US$ {dinheiro(original['milhao'])} "
        f"| US$ {dinheiro(novo['milhao'])} | {num(original['milhao'] / novo['milhao'], 0)}× menor |",
        "",
        "Tempos e req/s: mediana de 3 medições de cada versão na rodada final (12/11), na mesma sessão "
        "([tabela completa](experimentos.md#rodada-final-a-cadeia-inteira-numa-sessão-só)). "
        f"Com **um quarto da CPU** (banco 0,25, API 0,125), a versão final ainda fez {num(quarto['grupo']['reqs'], 2)} req/s, "
        f"{num(quarto['grupo']['reqs'] / original['grupo']['reqs'], 0)}× a aplicação original com toda a CPU, "
        f"com custo por hora {variacao(original['hora'], quarto['hora'])} ([estudo de custo](experimentos.md#estudo-de-custo-quanto-recurso-a-versão-final-precisa)).",
        "",
        f"**O ganho depende da carga.** Os {num(final['reqs'] / base['reqs'], 1)}× acima são com 20 usuários, como todas as "
        f"medições do desafio. Na curva de capacidade (16/11, outra sessão), com 1 a 40 usuários, as req/s da versão final "
        f"ficaram entre {num(razoes[menor], 0)}× ({usuarios(menor)}) e {num(razoes[maior], 0)}× ({usuarios(maior)}) as da "
        f"original ({num(razoes[20], 0)}× com 20). A original já satura com 1 usuário. A versão final chega ao pico com "
        f"{' a '.join(str(n) for n in picos)} usuários (~{num(maximo, 0)} req/s) e perde vazão com mais usuários: "
        f"{num(grupos_curva['final', 20]['reqs'], 0)} req/s com 20 e {num(grupos_curva['final', CURVA_NIVEIS[-1]]['reqs'], 0)} "
        f"com {CURVA_NIVEIS[-1]} ([curva de capacidade](experimentos.md#curva-de-capacidade-1-a-40-usuários)).",
        "",
        "**Depois da rodada final: o experimento 17.** A curva mostrou que, com 1 CPU, o banco rende menos quando roda muitas "
        "consultas ao mesmo tempo. Limitar o pool de conexões da API a 3 (antes, 20) aumentou a vazão com os mesmos 20 usuários "
        f"e os mesmos limites. Na mesma sessão (16/11), contra a aplicação original:",
        "",
        "| Medida (mesma sessão, 16/11) | Aplicação original | Versão final com pool de 3 | Variação |",
        "| --- | --- | --- | --- |",
        linha("Requisições por segundo", pool_original["reqs"], pool_final["reqs"], 2, ""),
        linha("Tempo de resposta, mediana", pool_original["mediana"], pool_final["mediana"]),
        linha("Tempo de resposta, p95", pool_original["p95"], pool_final["p95"]),
        linha("Tempo de resposta, p99", pool_original["p99"], pool_final["p99"]),
        f"| Custo estimado por milhão de requisições (mesmos limites, preços do AWS Fargate) | US$ {dinheiro(custo_hora(next(iter(pool_original['limites']))) / (pool_original['reqs'] * 3600) * 1e6)} "
        f"| US$ {dinheiro(custo_hora(next(iter(pool_final['limites']))) / (pool_final['reqs'] * 3600) * 1e6)} "
        f"| {num(pool_final['reqs'] / pool_original['reqs'], 0)}× menor |",
        "",
        "O 134,8× da tabela de cima é da cadeia até o experimento 16 (rodada final, 12/11); a curva de capacidade e o estudo de custo "
        "também são de antes do 17. Detalhes das duas rodadas do 17 no "
        "[experimentos.md](experimentos.md#experimento-17-tamanho-do-pool-em-duas-rodadas).",
    ])


def conferir():
    problemas = [m["pasta"] for m in LIDAS.values() if m["sem_commit"] != 0 or not m["contrato"]]
    if problemas:
        sys.exit("pastas com arquivos sem commit ou contrato quebrado: " + ", ".join(problemas))
    return (f"Conferido por `analise/gerar.py`: {len(LIDAS)} pastas lidas, todas com "
            "`arquivos alterados sem commit: 0` e \"Contrato mantido\".")


# ---------------------------------------------------------------- gráficos (SVG à mão, sem dependências)

# Vermelho × azul em vez de vermelho × verde: o par passa no teste de daltonismo (protanopia ΔE 15,6; o verde dava 5,1).
COR_BASE = "#c0504d"
COR_FINAL = "#2b6cb0"
COR_PASSO = "#a3acb8"
COR_BANCO = "#2b6cb0"
COR_API = "#e0a030"


def esc(texto):
    return texto.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def texto(x, y, conteudo, tamanho=13, cor="#222", ancora="start", peso="normal"):
    return (f'<text x="{x:.1f}" y="{y:.1f}" font-size="{tamanho}" fill="{cor}" text-anchor="{ancora}" '
            f'font-weight="{peso}">{esc(conteudo)}</text>')


def abrir_svg(largura, altura, titulo):
    return [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{largura}" height="{altura}" viewBox="0 0 {largura} {altura}" '
        f'role="img" aria-label="{esc(titulo)}" font-family="Helvetica, Arial, sans-serif">',
        f"<title>{esc(titulo)}</title>",
        '<rect width="100%" height="100%" fill="#ffffff"/>',
    ]


def barras_log(arquivo, titulo, nota, itens, vmin, vmax, marcas, rotulo_marca, rotulo_valor, esquerda=240):
    """Barras horizontais em escala log; itens: (rótulo, valor, mínimo, máximo, cor). A haste é a faixa das 3 medições."""
    largura, direita, topo, passo = 860, 120, 70, 28
    altura = topo + passo * len(itens) + 40
    area = largura - esquerda - direita

    def x(v):
        v = min(max(v, vmin), vmax)
        return esquerda + area * (math.log10(v) - math.log10(vmin)) / (math.log10(vmax) - math.log10(vmin))

    base = topo + passo * len(itens)
    s = abrir_svg(largura, altura, titulo)
    s.append(texto(16, 28, titulo, tamanho=17, peso="bold"))
    s.append(texto(16, 50, nota, tamanho=12, cor="#555"))
    for marca in marcas:
        s.append(f'<line x1="{x(marca):.1f}" y1="{topo - 6}" x2="{x(marca):.1f}" y2="{base}" stroke="#dddddd"/>')
        s.append(texto(x(marca), base + 18, rotulo_marca(marca), tamanho=12, cor="#555", ancora="middle"))
    for i, (rotulo, valor, minimo, maximo, cor) in enumerate(itens):
        y = topo + i * passo
        s.append(texto(esquerda - 8, y + 16, rotulo, ancora="end"))
        s.append(f'<rect x="{esquerda}" y="{y + 5}" width="{x(valor) - esquerda:.1f}" height="16" fill="{cor}"/>')
        s.append(f'<line x1="{x(minimo):.1f}" y1="{y + 13}" x2="{x(maximo):.1f}" y2="{y + 13}" stroke="#222" stroke-width="1.2"/>')
        for ponta in (minimo, maximo):
            s.append(f'<line x1="{x(ponta):.1f}" y1="{y + 8}" x2="{x(ponta):.1f}" y2="{y + 18}" stroke="#222" stroke-width="1.2"/>')
        s.append(texto(max(x(valor), x(maximo)) + 6, y + 17, rotulo_valor(valor), tamanho=12))
    s.append("</svg>")
    (IMG / arquivo).write_text("\n".join(s) + "\n", encoding="utf-8")


def barras_cpu(arquivo, titulo, nota, itens):
    """Duas barras por ponto (banco e API), em % da cota de CPU de cada container."""
    largura, esquerda, direita, topo, passo = 860, 240, 70, 92, 30
    altura = topo + passo * len(itens) + 40
    area = largura - esquerda - direita
    vmax = 110

    def x(v):
        return esquerda + area * min(v, vmax) / vmax

    base = topo + passo * len(itens)
    s = abrir_svg(largura, altura, titulo)
    s.append(texto(16, 28, titulo, tamanho=17, peso="bold"))
    s.append(texto(16, 50, nota, tamanho=12, cor="#555"))
    for i, (nome, cor) in enumerate((("banco (cota de 1 CPU)", COR_BANCO), ("API (cota de 0,5 CPU)", COR_API))):
        s.append(f'<rect x="{esquerda + i * 200}" y="62" width="12" height="12" fill="{cor}"/>')
        s.append(texto(esquerda + i * 200 + 18, 73, nome, tamanho=12))
    for marca in (0, 25, 50, 75, 100):
        traco = "#999999" if marca == 100 else "#dddddd"
        s.append(f'<line x1="{x(marca):.1f}" y1="{topo - 6}" x2="{x(marca):.1f}" y2="{base}" stroke="{traco}"/>')
        s.append(texto(x(marca), base + 18, f"{marca}%", tamanho=12, cor="#555", ancora="middle"))
    for i, (rotulo, banco, api) in enumerate(itens):
        y = topo + i * passo
        s.append(texto(esquerda - 8, y + 17, rotulo, ancora="end"))
        for j, (valor, cor) in enumerate(((banco, COR_BANCO), (api, COR_API))):
            yy = y + 4 + j * 11
            s.append(f'<rect x="{esquerda}" y="{yy}" width="{x(valor) - esquerda:.1f}" height="10" fill="{cor}"/>')
            s.append(texto(x(valor) + 4, yy + 9, f"{num(valor, 0)}%", tamanho=10, cor="#444"))
    s.append("</svg>")
    (IMG / arquivo).write_text("\n".join(s) + "\n", encoding="utf-8")


def linhas_log(arquivo, titulo, nota, series, vmin, vmax, marcas, rotulo_marca, rotulo_valor, referencia=None):
    """Uma linha por versão; x = usuários (escala log), y em escala log. A haste vertical é a faixa das 3 medições.
    series: (nome, cor, forma, pontos {usuários: grupo}, chave, níveis com valor escrito, rótulo acima?)."""
    largura, altura, esquerda, direita, topo, baixo = 860, 460, 80, 200, 104, 64
    base = altura - baixo

    def x(n):  # 30 px de folga para os pontos de 1 usuário não encostarem nos rótulos do eixo y
        return esquerda + 30 + (largura - esquerda - direita - 30) * math.log10(n) / math.log10(CURVA_NIVEIS[-1])

    def y(v):
        v = min(max(v, vmin), vmax)
        return base - (base - topo) * (math.log10(v) - math.log10(vmin)) / (math.log10(vmax) - math.log10(vmin))

    def marcador(cx, cy, forma, cor):
        if forma == "quadrado":
            return f'<rect x="{cx - 5:.1f}" y="{cy - 5:.1f}" width="10" height="10" fill="{cor}" stroke="#ffffff" stroke-width="2"/>'
        return f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="5.5" fill="{cor}" stroke="#ffffff" stroke-width="2"/>'

    s = abrir_svg(largura, altura, titulo)
    s.append(texto(16, 28, titulo, tamanho=17, peso="bold"))
    s.append(texto(16, 50, nota, tamanho=12, cor="#555"))
    for i, (nome, cor, forma, *_) in enumerate(series):
        s.append(marcador(esquerda + 6 + i * 200, 74, forma, cor))
        s.append(texto(esquerda + 18 + i * 200, 78, nome, tamanho=12))
    for marca in marcas:
        s.append(f'<line x1="{esquerda}" y1="{y(marca):.1f}" x2="{largura - direita + 20}" y2="{y(marca):.1f}" stroke="#e4e4e4"/>')
        s.append(texto(esquerda - 8, y(marca) + 4, rotulo_marca(marca), tamanho=12, cor="#555", ancora="end"))
    for n in CURVA_NIVEIS:
        s.append(f'<line x1="{x(n):.1f}" y1="{base}" x2="{x(n):.1f}" y2="{base + 5}" stroke="#999999"/>')
        s.append(texto(x(n), base + 20, str(n), tamanho=12, cor="#555", ancora="middle"))
    s.append(f'<line x1="{esquerda}" y1="{base}" x2="{largura - direita + 20}" y2="{base}" stroke="#999999"/>')
    s.append(texto((esquerda + largura - direita) / 2, base + 44, "usuários virtuais simultâneos (escala logarítmica)",
                   tamanho=12, cor="#555", ancora="middle"))
    s.append(f'<line x1="{x(20):.1f}" y1="{topo - 4}" x2="{x(20):.1f}" y2="{base}" stroke="#bbbbbb" stroke-dasharray="4 4"/>')
    s.append(texto(x(20), topo - 10, "carga das outras medições", tamanho=11, cor="#555", ancora="middle"))
    if referencia:
        valor, rotulo = referencia
        s.append(f'<line x1="{esquerda}" y1="{y(valor):.1f}" x2="{largura - direita + 20}" y2="{y(valor):.1f}" '
                 f'stroke="#888888" stroke-dasharray="6 3"/>')
        s.append(texto(esquerda + 6, y(valor) - 6, rotulo, tamanho=11, cor="#555"))
    for nome, cor, forma, pontos, chave, escritos, acima in series:
        trajeto = " ".join(f"{x(n):.1f},{y(pontos[n][chave]):.1f}" for n in CURVA_NIVEIS)
        s.append(f'<polyline points="{trajeto}" fill="none" stroke="{cor}" stroke-width="2"/>')
        for n in CURVA_NIVEIS:
            g = pontos[n]
            minimo, maximo = y(g[chave + "_min"]), y(g[chave + "_max"])
            s.append(f'<line x1="{x(n):.1f}" y1="{minimo:.1f}" x2="{x(n):.1f}" y2="{maximo:.1f}" stroke="#222" stroke-width="1.2"/>')
            s.append(marcador(x(n), y(g[chave]), forma, cor))
            if n in escritos:
                dy = min(maximo, y(g[chave]) - 6) - 6 if acima else max(minimo, y(g[chave]) + 6) + 16
                s.append(texto(x(n), dy, rotulo_valor(g[chave]), tamanho=12, ancora="middle"))
        s.append(texto(x(CURVA_NIVEIS[-1]) + 44, y(pontos[CURVA_NIVEIS[-1]][chave]) + 4, nome, tamanho=13))
    s.append("</svg>")
    (IMG / arquivo).write_text("\n".join(s) + "\n", encoding="utf-8")


def segundos(ms):
    return f"{num(ms / 1000, 0 if ms >= 1000 else 1)} s"


def tempo(ms):
    return f"{num(ms, 0)} ms" if ms < 1000 else f"{num(ms / 1000, 1)} s"


def graficos(pontos, configs, grupos_curva):
    IMG.mkdir(parents=True, exist_ok=True)
    cadeia = [p for p in pontos if p[0] != "controle-inicio"]

    def cor(rotulo):
        return COR_BASE if rotulo == "00-linha-de-base" else COR_FINAL if rotulo.startswith("14-") else COR_PASSO

    barras_log(
        "vazao-por-mudanca.svg",
        "Requisições por segundo a cada mudança (rodada final, 12/11)",
        "Mediana de 3 medições; a haste é a faixa das 3. Escala logarítmica. Limites originais: banco 1 CPU, API 0,5 CPU.",
        [(nome, g["reqs"], g["reqs_min"], g["reqs_max"], cor(r)) for r, nome, _, g in cadeia],
        1, 1000, [1, 10, 100, 1000], lambda v: num(v, 0), lambda v: num(v, 2),
    )
    barras_log(
        "p95-por-mudanca.svg",
        "Tempo de resposta p95 a cada mudança (rodada final, 12/11)",
        "Mediana de 3 medições; a haste é a faixa das 3. Escala logarítmica; menor é melhor.",
        [(nome, g["p95"], g["p95_min"], g["p95_max"], cor(r)) for r, nome, _, g in cadeia],
        100, 100000, [100, 1000, 10000, 100000], segundos, tempo,
    )
    barras_cpu(
        "cpu-banco-api.svg",
        "Onde está o gargalo: CPU usada em % da cota (rodada final, 12/11)",
        "Mediana de 3 medições do cpu_media. No 08 o banco sai do teto e a API chega ao dela; no 09 o gargalo volta ao banco.",
        [(nome, g["banco_cota"], g["api_cota"]) for _, nome, _, g in cadeia],
    )
    barras_log(
        "custo-por-milhao.svg",
        "Custo estimado por milhão de requisições (estudo de custo, 11/11)",
        "Preços do AWS Fargate (F22) aplicados aos limites de cada configuração; a haste é a faixa das 3 medições. Escala log.",
        [(nome, milhao, minimo, maximo, COR_BASE if nome.startswith("Original") else COR_FINAL)
         for nome, milhao, minimo, maximo in configs],
        0.01, 10, [0.01, 0.1, 1, 10], lambda v: f"US$ {num(v, 2)}", lambda v: f"US$ {dinheiro(v)}",
        esquerda=360,
    )

    def series(chave, escritos, final_acima):
        return [(nome, COR_BASE if v == "original" else COR_FINAL, "quadrado" if v == "original" else "circulo",
                 {n: grupos_curva[v, n] for n in CURVA_NIVEIS}, chave, escritos[v], (v == "final") == final_acima)
                for v, nome in CURVA_VERSOES]

    linhas_log(
        "curva-vazao.svg",
        "Requisições por segundo conforme o número de usuários (curva de capacidade, 16/11)",
        "Mediana de 3 medições; a haste é a faixa das 3. As duas escalas são logarítmicas. Limites originais.",
        series("reqs", {"original": {1, 20, 40}, "final": {1, 10, 20, 40}}, True),
        1, 1000, [1, 10, 100, 1000], lambda v: num(v, 0), lambda v: num(v, 0 if v >= 100 else 2),
    )
    linhas_log(
        "curva-p95.svg",
        "Tempo de resposta p95 conforme o número de usuários (curva de capacidade, 16/11)",
        "Mediana de 3 medições; a haste é a faixa das 3. As duas escalas são logarítmicas; menor é melhor.",
        series("p95", {"original": {1, 5, 20}, "final": {1, 5, 20, 40}}, False),
        5, 100000, [10, 100, 1000, 10000, 100000], lambda v: f"{num(v, 0)} ms" if v < 1000 else f"{num(v / 1000, 0)} s", tempo,
        referencia=(60000, "limite de 60 s por requisição no script de carga"),
    )


# ---------------------------------------------------------------- experimentos.md


def substituir_bloco(conteudo, nome, novo, arquivo=EXPERIMENTOS_MD):
    inicio, fim = f"<!-- gerado:{nome} -->", f"<!-- /gerado:{nome} -->"
    padrao = re.compile(re.escape(inicio) + ".*?" + re.escape(fim), re.S)
    if not padrao.search(conteudo):
        sys.exit(f"marcador {inicio} não encontrado em {arquivo.name}")
    return padrao.sub(lambda _: f"{inicio}\n{novo}\n{fim}", conteudo)


def main():
    experimentos = tabela_experimentos()
    final, pontos = rodada_final()
    custo, configs, custos = tabela_custo()
    capacidade, grupos_curva = curva()
    pool, pool_final, pool_original = tabela_pool()
    verificacao = conferir()
    graficos(pontos, configs, grupos_curva)

    conteudo = EXPERIMENTOS_MD.read_text(encoding="utf-8")
    conteudo = substituir_bloco(conteudo, "experimentos", experimentos)
    conteudo = substituir_bloco(conteudo, "rodada-final", final)
    conteudo = substituir_bloco(conteudo, "custo", custo)
    conteudo = substituir_bloco(conteudo, "curva", capacidade)
    conteudo = substituir_bloco(conteudo, "pool", pool)
    conteudo = substituir_bloco(conteudo, "verificacao", verificacao)
    EXPERIMENTOS_MD.write_text(conteudo, encoding="utf-8")

    readme = README_MD.read_text(encoding="utf-8")
    README_MD.write_text(substituir_bloco(readme, "resumo", resumo_readme(pontos, custos, grupos_curva, pool_final, pool_original), README_MD), encoding="utf-8")
    print(verificacao)
    print(f"escrito: {EXPERIMENTOS_MD.relative_to(RAIZ)}, {README_MD.relative_to(RAIZ)} e "
          f"{len(list(IMG.glob('*.svg')))} gráficos em {IMG.relative_to(RAIZ)}/")


if __name__ == "__main__":
    main()
