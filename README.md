# Modelo de IA para Detecção de Ataques de Pânico

Este projeto apresenta o desenvolvimento de um *aplicativo móvel* voltado à **detecção precoce de ataques de pânico** em usuários previamente diagnosticados. A solução integra **técnicas de machine learning** com a **coleta de sinais fisiológicos** para identificar possíveis episódios em tempo real e emitir alertas ou recomendações personalizadas.

---

## 📌 Principais Pontos

- **Coleta de Dados**  
  Os sinais monitorados — como frequência cardíaca, variabilidade da frequência cardíaca (HRV) e padrões de movimento — são captados por sensores de smartwatch. Neste protótipo, utilizamos o *Samsung Galaxy Fit 3* para demonstrar a viabilidade da abordagem.

- **Geração de Dados Sintéticos**  
  Para ampliar o volume e a diversidade do conjunto de treinamento, empregamos a API gratuita de IA da OpenAI. Esses *dados sintéticos* simulam diferentes perfis e intensidades de ataques de pânico, ajudando o modelo a generalizar melhor para casos reais.

- **Arquitetura do Modelo**  
  Adotamos a **Regressão Logística** — um algoritmo de classificação que estima a probabilidade de ocorrência de um evento (neste caso, um ataque de pânico) com base em variáveis de entrada. O treinamento foi realizado com a biblioteca *scikit‑learn*, amplamente utilizada em projetos de machine learning por sua simplicidade e eficiência.

- **Validação e Métricas**  
  Avaliamos o desempenho do modelo utilizando as seguintes métricas:
  - *Acurácia*: proporção de previsões corretas sobre o total de amostras.  
  - *Precision* (Precisão): fração de verdadeiros positivos entre todas as previsões positivas, importante para minimizar alarmes falsos.  
  - *Recall* (Sensibilidade): fração de verdadeiros positivos entre todos os casos realmente positivos, essencial para não deixar de identificar um ataque.  
  - *F1‑Score*: média harmônica entre precisão e recall, fornecendo um único indicador balanceado.
  
  Em todas as métricas avaliadas, **não foram observados sinais de _overfitting_ ou _data leakage_**.
---

## ℹ️ Explicações para Quem Não Conhece

- **Machine Learning**: área da Inteligência Artificial em que algoritmos aprendem padrões a partir de dados, em vez de serem programados manualmente para cada regra.  
- **Dados Sintéticos**: amostras geradas artificialmente para complementar bases reais, usadas quando os dados originais são escassos ou sensíveis.  
- **Regressão Logística**: modelo estatístico que, apesar do nome, é usado para *classificação binária* (sim ou não), retornando a probabilidade de cada classe.  
- **Métricas de Avaliação**: critérios numéricos que indicam quão bem o modelo está funcionando; cada métrica reflete um aspecto diferente, como balancear falsos positivos vs. falsos negativos.

---

> Com essas correções e acréscimos de contexto, a documentação fica mais clara, acessível e adequada tanto para especialistas quanto para iniciantes interessados no tema.
