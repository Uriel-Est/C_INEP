# Carregar pacotes necessários
library(httr)
library(readr)
library(dplyr)
library(archive)
library(stringr)
library(arrow)
library(fs)
library(purrr)

# Função para processar os dados
processar_dados_censo <- function(ano, dir) {
  
  # 1. Definir URL do arquivo ZIP
  url <- paste0(
    "https://download.inep.gov.br/dados_abertos/microdados_censo_escolar_", 
    ano, 
    ".zip"
  )
  
  # 2. Criar diretório de extração temporária e caminho final
  temp <- tempfile()
  temp_extract <- tempfile()
  dir_input <- file.path(dir, "input")
  dir.create(dir_input, recursive = TRUE, showWarnings = FALSE)
  
  # 3. Fazer download
  tryCatch({
    GET(
      url = url,
      write_disk(temp, overwrite = TRUE),
      config(ssl_verifypeer = FALSE)
    )
    message("✔️ Download concluído para ", ano)
  }, error = function(e) {
    stop("❌ Erro no download: ", e$message)
  })
  
  # 4. Extrair ZIP
  tryCatch({
    archive_extract(temp, dir = temp_extract)
    message("✔️ Arquivo extraído para ", ano)
  }, error = function(e) {
    stop("❌ Erro na extração: ", e$message)
  })
  
  # 5. Localizar apenas o CSV de educação básica
  arquivos_csv <- dir(temp_extract, pattern = "\\.csv$", recursive = TRUE, full.names = TRUE, ignore.case = TRUE)
  arquivos_ed_basica <- arquivos_csv[str_detect(arquivos_csv, "ed_basica")]
  
  if (length(arquivos_ed_basica) == 0) stop("❌ Arquivo de educação básica não encontrado para ", ano)
  
  # 6. Ler CSV e salvar Parquet
  tryCatch({
    df <- read.csv2(arquivos_ed_basica[1], fileEncoding = "Latin1")
    parquet_path <- file.path(dir_input, paste0("dados_censo_escolar_inep_", ano, ".parquet"))
    write_parquet(df, parquet_path)
    message("📁 Parquet salvo: ", parquet_path)
  }, error = function(e) {
    stop("❌ Erro ao processar CSV de ", ano, ": ", e$message)
  })
  
  # 7. Limpeza completa
  unlink(temp_extract, recursive = TRUE)
  unlink(temp)
  message("🧹 Diretórios temporários e arquivos extras removidos.")
  
  message("✅ Processamento finalizado para ", ano)
}

#-------------------------------------------------------
# Executar para múltiplos anos
dir <- "./"
anos <- 2007:2024

walk(anos, function(ano) {
  tryCatch({
    processar_dados_censo(ano, dir)
    Sys.sleep(3)
  }, error = function(e) {
    message("⚠️ Falha ao processar o ano ", ano, ": ", e$message)
  })
})


