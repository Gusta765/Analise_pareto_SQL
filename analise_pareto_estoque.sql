-- Define o período de análise com datas fixas
WITH PARAMETRO AS (
    SELECT
        CAST('2021-11-01' AS DATE)  AS DATA_INI
        ,CAST('2021-12-31' AS DATE) AS DATA_FIM
)

-- Calcula o valor total líquido vendido por produto no período
, VENDAS_LIQUIDAS AS (
    SELECT
        B.produto_id                        AS PRODUTO_ID
        ,SUM(COALESCE(A.valor_venda, 0.00)) AS TOTAL_LIQUIDO
    FROM 
        vendasgerais         AS A
    INNER JOIN itensdevendas AS B ON A.id = B.vendas_id
    WHERE 
        CAST(LEFT(A.data, 10) AS DATE) BETWEEN (SELECT DATA_INI FROM PARAMETRO) AND (SELECT DATA_FIM FROM PARAMETRO)
    GROUP BY 
        B.produto_id
)

-- Calcula o total geral de vendas no período
, TOTAL_GERAL AS (
    SELECT 
        SUM(total_liquido) AS TOTAL_LIQUIDO_GERAL
    FROM 
        VENDAS_LIQUIDAS
)

-- Ordena os produtos do mais vendido para o menos vendido
, ORDENADO AS (
    SELECT 
        A.PRODUTO_ID                                                     AS PRODUTO_ID
        ,TOTAL_LIQUIDO                                                   AS TOTAL_LIQUIDO
        ,ROW_NUMBER() OVER (ORDER BY A.total_liquido DESC, A.produto_id) AS ORDEM
    FROM 
        VENDAS_LIQUIDAS AS A
)

-- Aplica a regra de Pareto com cálculo de percentual acumulado de vendas
, PARETO AS (
    SELECT
        A.PRODUTO_ID                                                                                             AS PRODUTO_ID
        ,A.TOTAL_LIQUIDO                                                                                         AS TOTAL_LIQUIDO
        ,B.TOTAL_LIQUIDO_GERAL                                                                                   AS TOTAL_LIQUIDO_GERAL
        ,SUM(A.TOTAL_LIQUIDO) OVER (ORDER BY A.TOTAL_LIQUIDO DESC, A.PRODUTO_ID)                                 AS ACUMULADO_LIQUIDO
        ,(SUM(A.TOTAL_LIQUIDO) OVER (ORDER BY A.TOTAL_LIQUIDO DESC, A.PRODUTO_ID) * 100) / B.TOTAL_LIQUIDO_GERAL AS PERC_ACUMULADO
    FROM 
        ORDENADO    AS A
    CROSS JOIN 
        TOTAL_GERAL AS B
)

-- Seleciona apenas os produtos que representam até 80% das vendas totais
, PRINPAIS_PRODUTOS AS (
    SELECT
        PRODUTO_ID                AS PRODUTO_ID
        ,TOTAL_LIQUIDO            AS TOTAL_LIQUIDO
        ,ACUMULADO_LIQUIDO        AS ACUMULADO_LIQUIDO
        ,ROUND(PERC_ACUMULADO, 2) AS PERC_ACUMULADO
    FROM 
        PARETO
    WHERE
        PERC_ACUMULADO <= 80.00
    ORDER BY 
        TOTAL_LIQUIDO DESC
)

-- Recupera informações de estoque e dias de reposição dos produtos principais
, ESTOQUE_PRODUTOS AS (
    SELECT 
        produto_id          AS PRODUTO_ID
        ,quantidade_estoque AS QUANTIDADE_ESTOQUE
        ,dias_reposicao     AS DIAS_REPOSICAO
    FROM 
        estoque_leadtime
    WHERE
        produto_id IN (SELECT PRODUTO_ID FROM PRINPAIS_PRODUTOS)
)

-- Calcula a demanda média diária dos produtos analisados (base de 60 dias)
, DEMANDA_PRODUTOS AS (
    SELECT
        B.produto_id                 AS PRODUTO_ID
        ,SUM(B.item_quantidade) / 60 AS DEMANDA_DIA
    FROM
        vendasgerais  AS A
    JOIN 
        itensdevendas AS B 
        ON A.id = B.vendas_id
    WHERE 
        B.produto_id IN (SELECT PRODUTO_ID FROM PRINPAIS_PRODUTOS)
        AND CAST(LEFT(A.data, 10) AS DATE) BETWEEN (SELECT DATA_INI FROM PARAMETRO) AND (SELECT DATA_FIM FROM PARAMETRO)
    GROUP BY 
        B.produto_id
)

-- Verifica se há pedidos pendentes para os produtos
, PEDIDOS_PRODUTOS AS (
    SELECT 
        PRODUTO_ID        AS PRODUTO_ID
        ,STATUS           AS STATUS
        ,SUM(qtde_pedida) AS QUANTIDADE_PENDENTE 
    FROM 
        pedidos_pendentes
    GROUP BY 
        PRODUTO_ID     
)

-- Consulta final com recomendação de ação por produto
SELECT
    B.PRODUTO_ID                      AS PRODUTO_ID           -- ID do produto
    ,QUANTIDADE_ESTOQUE / DEMANDA_DIA AS DIAS_ESTOQUE         -- Quantos dias de estoque restam
    ,DIAS_REPOSICAO                   AS DIAS_REPOSICAO       -- Tempo de reposição do fornecedor
    ,COALESCE(QUANTIDADE_PENDENTE, 0) AS QUANTIDADE_PENDENTE  -- Quantidade já pedida, mas ainda não entregue
    ,CASE 
        -- Caso o estoque cubra menos dias do que o lead time, é necessário comprar
        WHEN QUANTIDADE_ESTOQUE / DEMANDA_DIA <= DIAS_REPOSICAO THEN 'Comprar'
        -- Caso exista pedido pendente e esteja atrasado, acionar fornecedor
        WHEN C.STATUS = 'Em atraso'                             THEN 'Cobrar Entrega'
        -- Caso contrário, situação estável
        ELSE 'Ok'
    END                                AS ACAO
FROM 
    DEMANDA_PRODUTOS AS A
JOIN 
    ESTOQUE_PRODUTOS AS B ON A.PRODUTO_ID = B.produto_id
LEFT JOIN 
    PEDIDOS_PRODUTOS AS C ON A.PRODUTO_ID = C.PRODUTO_ID
