# Carregar pacotes necessários
library(httr)       # Para fazer o download
library(readr)      # Para ler o CSV
library(dplyr)      # Para manipular os dados
library(archive)    # Para extrair o ZIP
library(stringr)    # Para converter o CSV em .parquet
library(arrow)      # Para salvar e ler em .parquet
library(fs)         # Para lidar com caminhos e arquivos

# Função para processar os dados
processar_dados_censo <- function(ano, dir) {
  
  # 1. Definir URL do arquivo ZIP
  url <- paste0(
    "https://download.inep.gov.br/dados_abertos/microdados_censo_escolar_", 
    ano, 
    ".zip"
  )
  
  # 2. Criar diretório temporário e caminho do arquivo
  temp <- tempfile()
  dir_input <- paste0(dir, "input/", as.character(ano))
  dir.create(dir_input, recursive = TRUE, showWarnings = FALSE) # Criar pasta se não existir
  
  # 3. Fazer download (com tratamento de erro)
  tryCatch(
    {
      GET(
        url = url,
        write_disk(temp),
        config(ssl_verifypeer = F) # Ignora erro de SSL
      )
      message("Download concluído com sucesso!")
    },
    error = function(e) {
      stop("Erro no download: ", e$message)
    }
  )
  
  # 4. Extrair arquivo ZIP
  tryCatch(
    {
      archive_extract(temp, dir = dir_input)
      message("Arquivo extraído com sucesso!")
    },
    error = function(e) {
      stop("Erro na extração: ", e$message)
    }
  )
  
  # 5. Localizar arquivos CSV
  arquivos.csv <- dir(dir_input, pattern = "\\.csv$", recursive = T, full.names = T)
  if (length(arquivos.csv) == 0) stop("Nenhum arquivo CSV encontrnado após extração.")
  
  # 6. Converter cada CSV em Parquet e salvar na mesma pasta
  for (csv_path in arquivos.csv) {
    nome_base <- str_remove(basename(csv_path), "\\.csv$")
    parquet_path <- file.path(dir_input, paste0(nome_base, ".parquet"))
    
    tryCatch({
      df <- read.csv2(csv_path, fileEncoding = "Latin1")
      write_parquet(df, parquet_path)
      message("Parquet salvo: ", parquet_path)
    }, error = function(e) {
      warning("Error no arquivo ", csv_path, ": ", e$message)
    })
    
  }
  
  message("Todos os arquivos foram convertidos em Parquet.")
  ## A primeira etapa acaba aqui salvando o .csv extraido pelo archive_extract e salvando em .parquet
}

#-------------------------------------------------------
# Exemplo de uso:
#dir <- "C:/Users/Uriel Holanda/Documents/txt/UFPB Estatística/Observatório Social Censo Escolar/"
dir <- "./"

processar_dados_censo(2022, "./")

# Executar para 2022 (se o link existir)
dados_2022 <- processar_dados_censo(2022, dir)

# Se 2022 falhar, teste com 2021:
# dados_2021 <- processar_dados_censo(2021, dir)