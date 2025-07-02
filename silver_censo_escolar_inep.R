library(dplyr)
library(arrow)
library(fs)
library(purrr)
library(stringr)
library(ggplot2)

# Criar um diretório silver
dir.create("input_silver", showWarnings = F, recursive = T)
dir_input <- "./input"
dir_output <- "./input_silver"

# Ler os parquet da camada bronze:
arquivos <- dir_ls(dir_input, regexp = "dados_censo_escolar_inep_\\d{4}\\.parquet$")

# Função para processar e salvar por ano
agregar_municipio <- function(caminho) {
  ano <- str_extract(caminho, "\\d{4}") #Extrair ano
  df <- read_parquet(caminho)           #Ler .parquet
  # Verificar se varíavel municipal existe
  if (!"CO_MUNICIPIO" %in% names(df)) {
    message("⚠️ Coluna CO_MUNICIPIO não encontrada em ", caminho)
    return(NULL)
  }
  # Agregar por Muncípio
  df_agregado <- df %>%
    group_by(CO_MUNICIPIO) %>%
    summarise(across(where(is.numeric), ~ sum(.x, na.rm = T)), .groups = "drop")
  # Caminho de saída
  saida <- file.path(dir_output, paste0("dados_censo_escolar_inep_", ano, ".parquet"))
  # Salvar
  write_parquet(df_agregado, saida)
  message("Arquivo agregado salvo: ", saida)
}

walk(arquivos, agregar_municipio)

# Testagem: 
#A) 
list.files("input_silver", pattern = "\\.parquet$")
#B)
df_teste <- read_parquet("input_silver/dados_censo_escolar_inep_2022.parquet")
glimpse(df_teste)
#C)
df_teste %>% summarise(n_munic = n_distinct(CO_MUNICIPIO))
#D)
df_teste %>%
  ggplot(aes(x = QT_DOC_BAS)) +
  geom_histogram(bins = 30, fill = "skyblue", color = "white") +
  labs(title = "Distribuição de docentes por município")