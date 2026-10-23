# Interactive mode: preview and download the same RTF the batch program writes.
# Run with shiny::runApp(system.file("examples", "shiny-preview", package = "tlfstack"))
library(shiny)
library(tlfstack)

data <- list(adsl = ex_adsl, adae = ex_adae, bds = ex_adlb[ex_adlb$PARAMCD == "ALT", ],
             adtte = ex_adtte)
types <- tlf_table_types()
choices <- stats::setNames(types$type, types$label)

ui <- fluidPage(
  titlePanel("tlfstack preview"),
  sidebarLayout(
    sidebarPanel(
      selectInput("type", "Output", choices = choices),
      textInput("title", "Title", "Preview"),
      downloadButton("download", "Download RTF")
    ),
    mainPanel(tableOutput("preview"), verbatimTextOutput("notes"))
  )
)

server <- function(input, output, session) {
  built <- reactive(tlf_build_table(input$type, data))
  titles <- reactive(tlf_titles(input$title,
                                type = types$class[types$type == input$type]))
  output$preview <- renderTable(built()$df)
  output$notes <- renderText(paste(built()$footnotes, collapse = "\n"))
  output$download <- downloadHandler(
    filename = function() paste0(input$type, ".rtf"),
    content = function(file) tlf_rtf_table(built(), file, titles = titles())
  )
}

shinyApp(ui, server)
