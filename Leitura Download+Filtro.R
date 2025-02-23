# Carregar pacotes necessários
library(httr)       # Para fazer o download
library(readr)      # Para ler o CSV
library(dplyr)      # Para manipular os dados
library(archive)    # Para extrair o ZIP

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
  dir_input <- paste0(dir, "input/")
  dir.create(dir_input, recursive = TRUE, showWarnings = FALSE) # Criar pasta se não existir
  
  # 3. Fazer download (com tratamento de erro)
  tryCatch(
    {
      Resposta <- GET(
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
      
      # 5. Encontrar o arquivo CSV extraído
      file_path <- list.files(
        dir_input,
        pattern = "microdados_ed_basica_.*\\.csv", 
        full.names = TRUE
      )
      
      if (length(file_path) == 0) {
        stop("Arquivo CSV não encontrado. Verifique o padrão do nome.")
      }
      
      # 6. Ler e processar os dados
      dados <- read_csv2(
        file_path,
        locale = locale(encoding = "UTF-8")
      ) %>%
        # Converter caracteres para UTF-8
        mutate(across(where(is.character), ~iconv(., from = "latin1", to = "UTF-8"))) %>%
        # Filtrar escolas públicas (Estaduais e Municipais)
        filter(TP_DEPENDENCIA %in% c(2, 3)) %>%
        # Filtrar por bairro "Bancários"
        filter(NO_BAIRRO == "Bancários") %>%
        # Selecionar colunas de interesse
        select(
          NU_ANO_CENSO,       # Sigla da Unidade Federativa [estado]
          NO_MUNICIPIO,       # Nome do Município
          NO_BAIRRO,          # Nome do Bairro
          NO_ENTIDADE,        # Nome da Escola
          QT_MAT_INF,         # Matrículas na Educação Infantil
          QT_MAT_FUND,        # Matrículas no Ensino Fundamental
          QT_MAT_MED,         # Matrículas no Ensino Médio
          QT_MAT_PROF,        # Matrículas no Ensino Profissionalizante
          QT_MAT_EJA,         # Matrículas na EJA
          QT_MAT_ESP,         # Matrículas em Educação Especial
          TP_SITUACAO         # Situação de funcionamento da escola
        )
      
      return(dados)
}

#-------------------------------------------------------
# Exemplo de uso:
dir <- "C:/Users/Uriel Holanda/Documents/txt/UFPB Estatística/Observatório Social Censo Escolar/"

# Executar para 2022 (se o link existir)
dados_2022 <- processar_dados_censo(2022, dir)

# Se 2022 falhar, teste com 2021:
# dados_2021 <- processar_dados_censo(2021, dir)