library(ggplot2)
library(sf)
library(dplyr)
library(readr)
library(utf8)
library(data.table)
library(rio)
library(flextable)

# Carregar banco de dados com o caminho até o arquivo em sua máquina
dados22 <- read_csv2("C:\\Users\\Uriel Holanda\\Documents\\txt\\UFPB Estatística\\Observatório Social Censo Escolar\\DADOS CENSO ESCOLAR 2022\\Microdados do Censo Escolar da Educação Básica 2022\\dados\\microdados_ed_basica_2022.csv", locale = locale(encoding = "UTF-8"))

# Adaptar a ortografia para português brasileiro incluindo a acentuação
dados22 <- as.data.frame(lapply(dados22, function(x) if (is.character(x)) iconv(x, from = "latin1", to = "UTF-8") else x))


# Aplicando filtros dados 22-------------------------------------------------------

#federação
PBfiltro22 <- dados22 %>%
  filter(SG_UF == "PB")

#encontrando o nome de cada município
unique(PBfiltro22$NO_MUNICIPIO)

#filtrando a cidade em foco
JPfiltro22 <- PBfiltro22 %>%
  filter(NO_MUNICIPIO == "João Pessoa")

#limpando colunas vazias
JPfiltro22 <- JPfiltro22 %>%
  select(where(~ !all(is.na(.))))

#filtrando para que fiquem apenas as escolas públicas de nível básico
escolas_pub22 <- JPfiltro22 %>%
  filter(TP_DEPENDENCIA %in% c(3)) #2: estadual ; 3: municipal

#filtrar bairro para melhor estudo demográfico com base em setor censitário
escolas_banc22 <- escolas_pub22 %>%
  filter(NO_BAIRRO == "BANCARIOS")

#criação de um database com as variáveis escolhidas que são [chegar dicionário censo ou o .txt]:
mat22 <- escolas_pub22 %>%
  select(NU_ANO_CENSO, SG_UF, NO_MUNICIPIO, NO_BAIRRO, NO_ENTIDADE, DS_ENDERECO, QT_MAT_INF, QT_MAT_FUND, QT_MAT_EJA, QT_MAT_ESP, QT_DOC_INF, QT_DOC_FUND, QT_DOC_EJA, QT_DOC_ESP)

