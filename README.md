# TP01: Gestão de Alunos e Notas (Processo ETL)

Trabalho Prático I de **Integração de Sistemas de Informação (ISI)**, 2026/27
Licenciatura em Engenharia de Sistemas Informáticos, Escola Superior de Tecnologia, IPCA

## Autor

| | |
| --- | --- |
| **Nome** | Bruno Dantas |
| **N.º de aluno** | 27958 |
| **Trabalho** | Individual |
| **Docente** | Óscar Ribeiro |
| **Repositório** | https://github.com/BrunoDantas1/ISI26-TP1-GestaoAlunosNotas.git |

## Descrição do trabalho

Processo ETL que integra dados de alunos (API REST em JSON), notas (CSV) e unidades curriculares (XML). Limpa e valida os dados, cruza-os, carrega-os no PostgreSQL, exporta resultados em CSV, envia por email a lista de reprovados e apresenta indicadores num dashboard Node-RED.

O processo está dividido em três transformações do Kettle, orquestradas por um job:

```text
t1_alunos_api   : API (JSON)  ->  limpeza  ->  alunos_limpos.csv
t2_notas_ucs    : notas.csv   ->  limpeza  ->  notas_limpas.csv
t3_resultados   : alunos + notas + UCs (XML)  ->  PostgreSQL + CSV
j_principal     : t1 -> t2 -> t3 -> email   (com ramo de erro)
```

## Ficheiros entregues


### Relatório

| Ficheiro | Descrição |
| --- | --- |
| `relatorio.pdf` | Relatório final do trabalho |

### Ficheiros fonte

| Ficheiro | Descrição |
| --- | --- |
| `t1_alunos_api.ktr` | Transformação: obtém os alunos pela API Random User, normaliza, valida o email e anonimiza. Gera `alunos_limpos.csv` |
| `t2_notas_ucs.ktr` | Transformação: limpa e valida `notas.csv`, remove duplicados. Gera `notas_limpas.csv` |
| `t3_resultados.ktr` | Transformação: cruza notas, UCs e alunos, calcula o estado e as médias e carrega o PostgreSQL |
| `j_principal.kjb` | Job que executa t1, t2 e t3 por ordem, envia o email e trata os erros |
| `src/criar_tabelas.sql` | Script que cria as tabelas `notas_completas` e `medias_alunos` |
| `flow_nodered.json` | Flow do Node-RED com o dashboard |

### Ficheiros de dados de entrada

| Ficheiro | Descrição |
| --- | --- |
| `notas.csv` | 204 registos de notas, com erros introduzidos de propósito |
| `ucs.xml` | Seis unidades curriculares (código, nome, ECTS, ano) |
| API Random User | `https://randomuser.me/api/?results=50&seed=isi2026&nat=br,es,fr,gb` |

### Ficheiros de dados gerados (`data/output`)

| Ficheiro | Descrição |
| --- | --- |
| `alunos_api.csv` | Alunos em bruto, como vêm da API |
| `alunos_limpos.csv` | 50 alunos limpos, com email anonimizado |
| `notas_limpas.csv` | 195 notas limpas e sem duplicados |
| `notas_completas.csv` | Notas com os dados da UC, do aluno e o estado (194 linhas) |
| `reprovados.csv` | Avaliações Reprovado (enviado por email em anexo) |
| `erros_notas.csv` | Notas vazias ou fora do intervalo 0–20 |
| `erros_alunos.csv` | Alunos com email inválido |
| `erros_orfaos.csv` | Notas cujo username não existe nos alunos |

### Base de dados

Base `isi_notas` (PostgreSQL 18) com as tabelas `notas_completas` e `medias_alunos`, criadas por `src/criar_tabelas.sql`.

## Como executar

### Ferramentas necessárias

| Ferramenta | Versão |
| --- | --- |
| Pentaho Data Integration (Kettle/Spoon) | 10.2, com Java 11 |
| PostgreSQL e pgAdmin 4 | PostgreSQL 18 |
| Driver JDBC PostgreSQL | `postgresql-42.7.14` (copiar para a pasta `lib` do Kettle) |
| Node-RED | com `node-red-dashboard` e `node-red-contrib-postgresql` |
| Conta Gmail | palavra-passe de aplicação, para o envio de email |

### 1. Criar a base de dados

```bash
psql -U postgres -c "CREATE DATABASE isi_notas;"
psql -U postgres -d isi_notas -f src/criar_tabelas.sql
```

### 2. Configurar o Kettle

1. Abrir o Spoon e criar a ligação `isi_notas` ao PostgreSQL (servidor `localhost`, porta `5432`).
2. Confirmar que os caminhos dos ficheiros nos passos (entrada, `data/output`) apontam para as pastas do teu computador. Estão definidos diretamente nos passos.
3. Configurar o passo **Mail resumo** do job com o servidor SMTP do Gmail (porta 587, TLS) e a palavra-passe de aplicação.
4. **Fechar os CSV abertos no Excel**, porque o Excel bloqueia os ficheiros e o Kettle não consegue escrevê-los.

### 3. Executar o job

Pelo Spoon: abrir `j_principal.kjb` e carregar em **Run**. Todas as entradas devem ficar a verde.

### 4. Verificar os dados

No pgAdmin ou com `psql`, na base `isi_notas`:

```sql
SELECT COUNT(*) FROM notas_completas;                        -- 194
SELECT estado, COUNT(*) FROM notas_completas GROUP BY estado; -- 162 Aprovado / 32 Reprovado
SELECT * FROM medias_alunos ORDER BY media DESC;             -- 50 alunos
```

### 5. Dashboard

```bash
npm install node-red-dashboard node-red-contrib-postgresql   # na pasta ~/.node-red
node-red
```

1. Abrir http://localhost:1880 e importar `flow_nodered.json`.
2. No nó `postgresql`, configurar a ligação à base `isi_notas` com **SSL desativado** (o PostgreSQL local não tem SSL).
3. Fazer **Deploy** e abrir o dashboard em http://localhost:1880/ui.

## Vídeo de demonstração

https://drive.google.com/file/d/1FSuroS-DaTBrt3Jyl7owjVdktuPK33Ls/view
