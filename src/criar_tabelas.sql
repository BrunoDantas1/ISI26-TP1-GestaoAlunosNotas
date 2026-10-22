CREATE TABLE notas_completas (
    username        VARCHAR(50),
    uc              VARCHAR(10),
    nota            NUMERIC(4,1),
    data_avaliacao  VARCHAR(10),
    epoca           VARCHAR(20),
    uc_nome         VARCHAR(100),
    ects            INTEGER,
    ano_uc          INTEGER,
    nome_completo   VARCHAR(100),
    email_anon      VARCHAR(100),
    nacionalidade   VARCHAR(5),
    estado          VARCHAR(20)
);

CREATE TABLE medias_alunos (
    username        VARCHAR(50),
    nome_completo   VARCHAR(100),
    media           NUMERIC(5,2),
    n_ucs           INTEGER,
    nota_max        NUMERIC(4,1),
    estado_final    VARCHAR(20)
);