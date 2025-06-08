# 📦 Análise de Pareto para Estoque e Gestão de Reposição

Este script SQL aplica a **regra de Pareto (80/20)** para identificar os produtos que mais contribuem para o faturamento em um período específico, cruzando com dados de **estoque, demanda diária e lead time** para gerar **recomendações inteligentes de compra**.

---

## 💼 Valor para o Negócio

- **Priorização de Produtos**: Descubra quais itens representam 80% das vendas e devem receber atenção prioritária.
- **Gestão Eficiente de Estoques**: Evite rupturas de estoque e excessos, garantindo equilíbrio entre disponibilidade e capital investido.
- **Tomada de Decisão Proativa**: Receba insights automatizados sobre quais produtos devem ser comprados ou cobrados de fornecedores.
- **Redução de perdas**: Produtos com alta demanda e baixo estoque são destacados para ação imediata.

---

## 📊 Fundamento Analítico: Regra de Pareto (80/20)

A **Análise de Pareto**, baseada no Princípio de Vilfredo Pareto, indica que aproximadamente **20% dos produtos geram 80% do faturamento**.

Neste script:

- Calculamos o **faturamento acumulado por produto**.
- Ordenamos os produtos do maior para o menor.
- Classificamos os produtos até atingir **80% do total vendido**.

Isso permite que o gestor foque no que realmente impacta o negócio.

---

## 🔢 Lógica e Estrutura do Script

O código foi estruturado usando **CTEs (Common Table Expressions)** para garantir clareza, modularidade e fácil manutenção. Veja as principais etapas:

### 1. `PARAMETRO`  
Define o período de análise (ex: últimos 60 dias).

### 2. `VENDAS_LIQUIDAS`  
Calcula o valor líquido vendido por produto no período.

### 3. `TOTAL_GERAL`  
Soma o valor total de vendas para cálculo do percentual acumulado.

### 4. `ORDENADO` + `PARETO`  
Ordena os produtos e calcula o percentual acumulado de contribuição.

### 5. `PRINPAIS_PRODUTOS`  
Filtra os produtos que acumulam até 80% das vendas.

### 6. `ESTOQUE_PRODUTOS`  
Consulta o estoque atual e o lead time (dias de reposição).

### 7. `DEMANDA_PRODUTOS`  
Calcula a demanda média diária dos produtos com base nas vendas.

### 8. `PEDIDOS_PRODUTOS`  
Verifica pedidos pendentes para considerar o que já está em trânsito.

### 9. `SELECT FINAL`  
Retorna:
- Dias de estoque restantes
- Lead time
- Quantidade pendente
- Ação recomendada: `Comprar`, `Cobrar Entrega`, ou `Ok`

---

## ✅ Exemplo de Saída

| PRODUTO_ID | DIAS_ESTOQUE | DIAS_REPOSICAO | QUANTIDADE_PENDENTE | AÇÃO             |
|------------|--------------|----------------|----------------------|------------------|
| 1001       | 12.4         | 10             | 0                    | Comprar          |
| 1002       | 35.6         | 20             | 10                   | Ok               |
| 1003       | 5.8          | 8              | 5                    | Cobrar Entrega   |

---

## ⚙️ Requisitos

Este script considera as seguintes tabelas:

- `vendasgerais`
- `itensdevendas`
- `estoque_leadtime`
- `pedidos_pendentes`

As colunas esperadas estão descritas dentro do código.

---

## ✍️ Autor

[**Gustavo Barbosa**](https://www.linkedin.com/in/gustavo-barbosa-868976236/)  

🔗 [GitHub](https://github.com/seu-usuario) | 📧 gustavobarbosa7744@gmail.com

---

## 🧠 Dica Final

> Este script pode ser facilmente adaptado para outros contextos como **gestão de compras, previsão de demanda, logística ou recomendação de estoque mínimo**. Seu design modular com CTEs permite expansão e manutenção com facilidade.

