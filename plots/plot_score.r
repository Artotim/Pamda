dir.create(Sys.getenv("R_LIBS_USER"), recursive = TRUE)  # create personal library
.libPaths(Sys.getenv("R_LIBS_USER"))  # add to the path
if (!require('ggplot2')) install.packages('ggplot2', lib = Sys.getenv("R_LIBS_USER"), repos = "https://cloud.r-project.org/"); library('ggplot2')
if (!require('extrafont')) {
    install.packages('extrafont', lib = Sys.getenv("R_LIBS_USER"), repos = "https://cloud.r-project.org/")
    library('extrafont')
    font_import(prompt = FALSE)
    loadfonts()
}
library('ggplot2')
library('extrafont')


# Resolve file names
args <- commandArgs(trailingOnly = TRUE)
out.path <- args[1]
out.path <- paste0(out.path, "score/")

name <- args[2]


# Load contact map
file.name <- paste0(out.path, name, "_score.csv")
if (!file.exists(file.name)) {
    stop("Missing file ", file.name)
}

score.table <- read.table(file.name,
                          header = TRUE,
                          sep = ";",
                          dec = ".",
)


# Format table
score.table$SCORE. = NULL
steps <- head(sub(".*?(\\d+).*", "\\1", score.table$description)[-1], -1)
score.table$description = as.numeric(c(args[3], steps, args[4]))


# Plot rmsd graph
out.name <- paste0(out.path, name, "_score.png")

cat("Ploting score.\n")
plot <- ggplot(score.table, aes(x = description, y = total_score, group = 1)) +
    geom_line(color = "#e6e600", size = 2) +
    labs(title = "Score", x = "Frame", y = "Score") +
    scale_x_continuous(labels = scales::comma_format()) +
    theme_minimal() +
    theme(text = element_text(family = "Times New Roman")) +
    theme(plot.title = element_text(size = 36, hjust = 0.5)) +
    theme(axis.title = element_text(size = 24)) +
    theme(axis.text = element_text(size = 20))

ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
cat("Done.\n\n")
