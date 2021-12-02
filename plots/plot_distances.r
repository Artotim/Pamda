dir.create(Sys.getenv("R_LIBS_USER"), recursive = TRUE)  # create personal library
.libPaths(Sys.getenv("R_LIBS_USER"))  # add to the path
if (!require('ggplot2')) install.packages('ggplot2', lib = Sys.getenv("R_LIBS_USER"), repos = "https://cloud.r-project.org/"); library('ggplot2')
if (!require('extrafont')) {
  library('extrafont')
  font_import(prompt = FALSE)
  loadfonts()
}
library('ggplot2')
library('stringr')
library('extrafont')


# Resolve file names
args <- commandArgs(trailingOnly = TRUE)
out.path <- args[1]
out.path <- paste0(out.path, "distances/")

name <- args[2]


# Load distance file
file.name <- paste0(out.path, name, "_all_distances.csv")
if (!file.exists(file.name)) {
  stop("Missing file ", file.name)
}


distance.all <- read.table(file.name,
                       header = TRUE,
                       sep = ";",
                       dec = ".",
)

for (i in 2:ncol(distance.all)) {
  colname <- colnames(distance.all)[i]
  pairs <- sort(strsplit(colname, 'to')[[1]])
  pair1 <- str_replace(pairs[1], '\\.', ':')
  pair2 <- str_replace(pairs[2], '\\.', ':')

  cat("Ploting distance between", pair1, "and", paste0(pair2, ".\n"))

  png.name <- paste0("_pair", i-1 , "_distance.png")
  out.name <- paste0(out.path, name, png.name)

  plot <- ggplot(distance.all, aes_string(x = 'frame', y = colname)) +
    geom_line(color = "#e6e6e6") +
    geom_smooth(color = "#009933", size = 2) +
    labs(title = paste("Distance\n",pair1, "to", pair2), x = "Frame", y = "Distance in Å") +
    scale_x_continuous(labels = scales::comma_format()) +
    theme_minimal() +
    theme(text = element_text(family = "Times New Roman")) +
    theme(plot.title = element_text(size = 36, hjust = 0.5)) +
    theme(axis.title = element_text(size = 24)) +
    theme(axis.text = element_text(size = 22))

  ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)


  # Remove outliers
  outliers <- boxplot(distance.all[[colname]], plot = FALSE)$out
  if (length(outliers) != 0) {
    distance.trim <- distance.all[-which(distance.all[[colname]] %in% outliers),]
  } else {
    distance.trim <- distance.all
  }
  distance.trim[1,]$frame <- min(distance.all$frame)

  cat("Ploting distance between", pair1, "and", pair2, "without outliers.\n")

  png.name <- paste0("_pair", i-1 , "_distance_trim.png")
  out.name <- paste0(out.path, name, png.name)

  plot <- ggplot(distance.trim, aes_string(x = 'frame', y = colname)) +
    geom_line(color = "#e6e6e6") +
    geom_smooth(color = "#009933", size = 2) +
    labs(title = paste("Distance\n",pair1, "to", pair2), x = "Frame", y = "Distance in Å") +
    scale_x_continuous(labels = scales::comma_format()) +
    theme_minimal() +
    theme(text = element_text(family = "Times New Roman")) +
    theme(plot.title = element_text(size = 36, hjust = 0.5)) +
    theme(axis.title = element_text(size = 24)) +
    theme(axis.text = element_text(size = 22))

  ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
}
cat("Done.\n")
