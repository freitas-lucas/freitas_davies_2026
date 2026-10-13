#!/usr/bin/env python3
"""
split_partitions.py

Divide um alinhamento em formato PHYLIP (sequencial, estrito, nomes com 10
caracteres) em N partições, com base nas coordenadas definidas em um arquivo
NEXUS de "charsets" (bloco `sets`), e escreve todas as partições em um único
arquivo PHYLIP de saída (um bloco por partição, cada um com seu próprio
cabeçalho "ntax nchar").

Uso:
    python split_partitions.py aln_10P.phy aln_10P_partitions.nex aln_10P_split.phy

Formato de entrada esperado:
  - PHYLIP estrito/sequencial: primeira linha "ntax nchar", depois uma linha
    por táxon com os 10 primeiros caracteres reservados ao nome (padded com
    espaços) seguidos da sequência completa, sem quebras de linha internas.
  - NEXUS com bloco `sets` contendo linhas do tipo:
        charset part1 = 1-2870;
    (coordenadas 1-based, inclusivas, como no NEXUS/RAxML).

Formato de saída:
  - Um único arquivo PHYLIP contendo, para cada partição, um cabeçalho
    "ntax nchar" seguido das sequências de todos os táxons recortadas para
    aquele intervalo de colunas, com uma linha em branco separando os blocos.
"""

import re
import sys
from pathlib import Path


def parse_phylip(path):
    """Lê um PHYLIP sequencial estrito (nomes de 10 caracteres, 1 linha/táxon).

    Retorna (ntax, nchar, lista_de_tuplas(nome, sequencia)) preservando a
    ordem original dos táxons.
    """
    with open(path, "r") as fh:
        lines = [l.rstrip("\n") for l in fh if l.strip() != ""]

    header = lines[0].split()
    ntax, nchar = int(header[0]), int(header[1])

    records = []
    for line in lines[1:1 + ntax]:
        name = line[:10].strip()
        seq = line[10:].strip()
        if len(seq) != nchar:
            raise ValueError(
                f"Táxon '{name}': esperado {nchar} colunas, encontrado {len(seq)}. "
                "Verifique se o PHYLIP é estrito (nomes de 10 caracteres) e sequencial "
                "(sequência inteira em uma única linha)."
            )
        records.append((name, seq))

    if len(records) != ntax:
        raise ValueError(
            f"Esperado {ntax} táxons no cabeçalho, mas {len(records)} linhas de sequência foram lidas."
        )

    return ntax, nchar, records


def parse_nexus_charsets(path):
    """Extrai os charsets do bloco `sets` de um arquivo NEXUS.

    Suporta charsets com um único intervalo contíguo, ex:
        charset part1 = 1-2870;
    Retorna uma lista de tuplas (nome_particao, inicio_1based, fim_1based),
    na ordem em que aparecem no arquivo.
    """
    text = Path(path).read_text()

    pattern = re.compile(
        r"charset\s+(\S+)\s*=\s*([\d\s\-]+?)\s*;",
        re.IGNORECASE,
    )

    charsets = []
    for match in pattern.finditer(text):
        name = match.group(1)
        coords = match.group(2).split()
        if len(coords) != 1 or "-" not in coords[0]:
            raise ValueError(
                f"Charset '{name}' tem coordenadas não suportadas: '{match.group(2)}'. "
                "Este script assume um único intervalo contíguo por partição (ex: 1-2870)."
            )
        start_str, end_str = coords[0].split("-")
        start, end = int(start_str), int(end_str)
        charsets.append((name, start, end))

    if not charsets:
        raise ValueError(f"Nenhum 'charset' encontrado em {path} (bloco 'sets').")

    return charsets


def write_combined_phylip(records, charsets, nchar, out_path):
    """Escreve todas as partições em um único arquivo PHYLIP, um bloco por
    partição, cada um com seu próprio cabeçalho 'ntax nchar_particao'.
    """
    ntax = len(records)

    with open(out_path, "w") as out:
        for i, (name, start, end) in enumerate(charsets):
            if start < 1 or end > nchar or start > end:
                raise ValueError(
                    f"Charset '{name}' ({start}-{end}) fora dos limites do alinhamento "
                    f"(1-{nchar})."
                )
            part_len = end - start + 1

            out.write(f"{ntax} {part_len}\n")
            for taxon_name, seq in records:
                # coordenadas NEXUS são 1-based e inclusivas -> slice Python
                sub_seq = seq[start - 1:end]
                padded_name = f"{taxon_name:<10}"
                out.write(f"{padded_name} {sub_seq}\n")

            # linha em branco entre blocos (exceto após o último)
            if i < len(charsets) - 1:
                out.write("\n")

    return ntax


def main():
    if len(sys.argv) != 4:
        print(
            "Uso: python split_partitions.py <alinhamento.phy> <particoes.nex> <saida.phy>",
            file=sys.stderr,
        )
        sys.exit(1)

    phy_path, nex_path, out_path = sys.argv[1], sys.argv[2], sys.argv[3]

    print(f"Lendo alinhamento PHYLIP: {phy_path}")
    ntax, nchar, records = parse_phylip(phy_path)
    print(f"  -> {ntax} táxons, {nchar} colunas")

    print(f"Lendo partições NEXUS: {nex_path}")
    charsets = parse_nexus_charsets(nex_path)
    print(f"  -> {len(charsets)} partições encontradas:")
    total = 0
    for name, start, end in charsets:
        length = end - start + 1
        total += length
        print(f"     {name}: {start}-{end} ({length} colunas)")

    if total != nchar:
        print(
            f"AVISO: soma das partições ({total}) difere do total de colunas "
            f"do alinhamento ({nchar}).",
            file=sys.stderr,
        )

    print(f"Escrevendo arquivo combinado: {out_path}")
    write_combined_phylip(records, charsets, nchar, out_path)
    print("Concluído.")


if __name__ == "__main__":
    main()
