# Carregar os pacotes
library(conflicted)
library(ggplot2)
library(sf)
library(dplyr)
library(readr)
library(utf8)
library(data.table)
library(rio)


# Lista para carregar os múltiplos bancos de dados de uma vez
file_paths <- list(
  "C:\\Users\\Uriel Holanda\\Documents\\txt\\UFPB Estatística\\Observatório Social Censo Escolar\\DADOS CENSO ESCOLAR 2023\\microdados_censo_escolar_2023\\dados\\microdados_ed_basica_2023.csv",
  "C:\\Users\\Uriel Holanda\\Documents\\txt\\UFPB Estatística\\Observatório Social Censo Escolar\\DADOS CENSO ESCOLAR 2022\\Microdados do Censo Escolar da Educação Básica 2022\\dados\\microdados_ed_basica_2022.csv",
  "C:\\Users\\Uriel Holanda\\Documents\\txt\\UFPB Estatística\\Observatório Social Censo Escolar\\DADOS CENSO ESCOLAR 2021\\microdados_ed_basica_2021\\dados\\microdados_ed_basica_2021.csv",
  "C:\\Users\\Uriel Holanda\\Documents\\txt\\UFPB Estatística\\Observatório Social Censo Escolar\\DADOS CENSO ESCOLAR 2020\\microdados_ed_basica_2020\\dados\\microdados_ed_basica_2020.csv",
  "C:\\Users\\Uriel Holanda\\Documents\\txt\\UFPB Estatística\\Observatório Social Censo Escolar\\DADOS CENSO ESCOLAR 2019\\microdados_ed_basica_2019\\dados\\microdados_ed_basica_2019.csv",
  "C:\\Users\\Uriel Holanda\\Documents\\txt\\UFPB Estatística\\Observatório Social Censo Escolar\\DADOS CENSO ESCOLAR 2018\\microdados_ed_basica_2018\\dados\\microdados_ed_basica_2018.csv"
)

# Obter a cidade e o bairro do usuário

# cidade = readline("Digite a cidade: ")
# bairro = readline("Digite o bairro: ")

cidade = "João Pessoa"
bairro = "BANCÁRIOS"


# Tentando automatizar ----------------------------------------------------
# Função para a cada ano e armazenar os resultados em uma lista
processar_dados <- function(file_path, cidade, bairro) {
  # Carregar os dados
  dados <- read_csv2(file_path, locale = locale(encoding = "UTF-8"))
  # Converter os caracteres especiais
  dados <- as.data.frame(lapply(dados, function(x) if (is.character(x)) iconv(x, from = "latin1", to = "UTF-8") else x))
  # Filtrar as escolas municipais e estaduais
  dados_publicos <- dados %>%
    filter(TP_DEPENDENCIA %in% c(2, 3)) # 2: estadual, 3: municipal [filtrar apenas municipal a posteriori]
  # Filtrar por cidade e bairro
  dados_bairros <- dados_publicos %>%
    filter(NO_BAIRRO == bairro)
  # Selecionar as variáveis de quantidade de matrículas
  dados_matriculas <- dados_bairros %>%
    select(NU_ANO_CENSO, SG_UF, NO_MUNICIPIO, NO_BAIRRO, NO_ENTIDADE, DS_ENDERECO, 
           QT_MAT_INF, QT_MAT_FUND, QT_MAT_MED, QT_MAT_PROF, QT_MAT_EJA, TP_SITUACAO_FUNCIONAMENTO)
  # Linh 1: variáveis de característica e definição para cada escola individual para fins de análise espacial
  # Linh 2: variáveis de matrícula [filtrar para apenas nível fundamental]
   return(dados_matriculas)
}

# Aplicar a função a cada arquivo e armazenar os resultados em uma lista 
cinep_ano <- mapply(processar_dados, file_paths, MoreArgs = list(cidade = cidade, bairro = bairro), SIMPLIFY = F)

#teste
print(head(cinep_ano[[1]]))

