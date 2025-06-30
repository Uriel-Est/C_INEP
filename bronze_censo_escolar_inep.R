# Carregar pacotes necessários
library(httr)       # Para fazer o download
library(readr)      # Para ler o CSV
library(dplyr)      # Para manipular os dados
library(archive)    # Para extrair o ZIP
library(stringr)    # Para converter o CSV em .parquet
library(arrow)      # Para salvar e ler em .parquet
library(fs)         # Para lidar com caminhos e arquivos
library(purrr)      # Para baixar múltiplos anos de uma só vez

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
  arquivos.csv <- dir(dir_input, pattern = "\\.csv$", recursive = T, full.names = T, ignore.case = T)
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
  
  #7. Remover arquivos CSV (mantendo apenas os .parquet)
  file_delete(arquivos.csv)
  message("🧹 Arquivos CSV removidos. Apenas .parquet permanecem.")
  
  message("Processo finalizado com sucesso.")
  ## A primeira etapa acaba aqui salvando o .csv extraido pelo archive_extract e salvando em .parquet
}

#-------------------------------------------------------
# Exemplo de uso:
#dir <- "C:/Users/Uriel Holanda/Documents/txt/UFPB Estatística/Observatório Social Censo Escolar/"
dir <- "./"

processar_dados_censo(2024, dir)

# Executar para 2022 (se o link existir)
dados_2024 <- processar_dados_censo(2024, dir)

anos <- 2007:2024
walk(anos, function(ano) {
  tryCatch({
    processar_dados_censo(ano, dir)
    Sys.sleep(3)  # pausa entre os downloads
  }, error = function(e) {
    message("⚠️ Falha ao processar o ano ", ano, ": ", e$message)
  })
})

#-------------------------------------------------------
