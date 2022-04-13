dir.create(Sys.getenv("R_LIBS_USER"), recursive = TRUE)  # create personal library
.libPaths(Sys.getenv("R_LIBS_USER"))  # add to the path
if (!require('ggplot2')) install.packages('ggplot2', lib = Sys.getenv("R_LIBS_USER"), repos = "https://cloud.r-project.org/"); library('ggplot2')
if (!require('scales')) install.packages('scales', lib = Sys.getenv("R_LIBS_USER"), repos = "https://cloud.r-project.org/"); library('scales')
if (!require('extrafont')) {
    install.packages('extrafont', lib = Sys.getenv("R_LIBS_USER"), repos = "https://cloud.r-project.org/")
    library('extrafont')
    font_import(prompt = FALSE)
    loadfonts()
}
library('ggplot2')
library('scales')
library('extrafont')


set_frame_breaks <- function(original_func, data_range) {
  function(x) {
    original_result <- original_func(x)
    original_result <- c(data_range[1], head(tail(original_result, -2), -2), data_range[2])
  }
}


# Resolve file names
args <- commandArgs(trailingOnly = TRUE)
out.path <- args[1]
out.path <- paste0(out.path, "contact/")

name <- args[2]


# Load table
file.name <- paste0(out.path, name, "_contact_count.csv")
if (!file.exists(file.name)) {
    stop("Missing file ", file.name)
}

contact.count <- read.table(file.name,
                            header = TRUE,
                            sep = ";",
                            dec = ".",
)


# Filter zero values
contact.count <- contact.count[!(contact.count$contacts == 0),]


# Plot graph
out.name <- paste0(out.path, name, "_contact_count.png")

cat("Ploting contact count.\n")
plot <- ggplot(contact.count, aes(x = frame, y = contacts, group = 1)) +
    geom_line(color = "#bfbfbf") +
    geom_smooth(color = "#cc0000", size = 2) +
    labs(title = "Contacts per Frame", x = "Frame", y = "Contacts") +
    scale_y_continuous(breaks = breaks_pretty(n = 10)) +
    scale_x_continuous(breaks = set_frame_breaks(breaks_pretty(), range(contact.count$frame)), labels = scales::comma_format()) +
    theme_minimal() +
    theme(text = element_text(family = "Times New Roman")) +
    theme(plot.title = element_text(size = 36, hjust = 0.5)) +
    theme(axis.title = element_text(size = 24)) +
    theme(axis.text = element_text(size = 20))

ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
cat("Done.\n\n")
