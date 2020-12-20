dir.create(Sys.getenv("R_LIBS_USER"), recursive = TRUE)  # create personal library
.libPaths(Sys.getenv("R_LIBS_USER"))  # add to the path
if (!require('ggplot2')) install.packages('Cairo', lib = Sys.getenv("R_LIBS_USER"), repos = "https://cloud.r-project.org/"); library('ggplot2')
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


# Resolve file names
args <- commandArgs(trailingOnly = TRUE)
out.path <- args[1]
out.path <- paste0(out.path, "energies/")

name <- args[2]


# Load table
file.name <- paste0(out.path, name, "_all_energies.csv")
energy.all <- read.table(file.name,
                         header = TRUE,
                         sep = ";",
                         dec = ".",
)


# Format table
energy.all$Time = NULL
energy.all$Frame = seq_along(energy.all$Frame)


# Iterate over each column
for (i in 2:ncol(energy.all)) {
  colname <- colnames(energy.all)[i]


  # Plot graphs
  pdf.name <- paste0("_all_", colname, "_energy", ".pdf")
  out.name <- paste0(out.path, name, pdf.name)

  plot <- ggplot(energy.all, aes_string(x = "Frame", y = colname, group = 1)) +
    geom_line(color = "#e6e6e6") +
    geom_smooth(color = "#0072B2", size = 2) +
    labs(title = paste("All", colname, "Energy"), x = "Frame", y = colname) +
    scale_y_continuous(breaks = breaks_pretty(n = 5)) +
    scale_x_continuous(labels = scales::comma_format()) +
    theme_minimal() +
    theme(text = element_text(family = "Times")) +
    theme(plot.title = element_text(size = 36, hjust = 0.5)) +
    theme(axis.title = element_text(size = 24)) +
    theme(axis.text = element_text(size = 20))

  ggsave(out.name, plot, width = 350, height = 150, units = 'mm')
}


# Iterate over each column to plot whithout ouliers
for (i in 2:ncol(energy.all)) {
  colname <- colnames(energy.all)[i]

  outliers <- boxplot(energy.all[[colname]], plot = FALSE)$out
  energy.trim <- energy.all[-which(energy.all[[colname]] %in% outliers),]

  # Plot graphs
  pdf.name <- paste0("_all_", colname, "_energy_trim", ".pdf")
  out.name <- paste0(out.path, name, pdf.name)

  plot <- ggplot(energy.trim, aes_string(x = "Frame", y = colname, group = 1)) +
    geom_line(color = "#e6e6e6") +
    geom_smooth(color = "#0072B2", size = 2) +
    labs(title = paste("All", colname, "Energy"), x = "Frame", y = colname) +
    scale_y_continuous(breaks = breaks_pretty(n = 5)) +
    scale_x_continuous(labels = scales::comma_format()) +
    theme_minimal() +
    theme(text = element_text(family = "Times")) +
    theme(plot.title = element_text(size = 36, hjust = 0.5)) +
    theme(axis.title = element_text(size = 24)) +
    theme(axis.text = element_text(size = 20))

  ggsave(out.name, plot, width = 350, height = 150, units = 'mm')
}


# Check for interaction table
file.name <- paste0(out.path, name, "_interaction_energies.csv")

if (file.exists(file.name)) {

  # Loads table
  energy.interaction <- read.table(file.name,
                                   header = TRUE,
                                   sep = ";",
                                   dec = ".",
  )


  # Format table
  energy.interaction$Time = NULL
  energy.interaction$Frame = seq_along(energy.interaction$Frame)


  # Iterate over each column
  for (i in 2:ncol(energy.interaction)) {
    colname <- colnames(energy.interaction)[i]


    # Plot graphs
    pdf.name <- paste0("_interaction_", colname, "_energy", ".pdf")
    out.name <- paste0(out.path, name, pdf.name)

    plot <- ggplot(energy.interaction, aes_string(x = "Frame", y = colname, group = 1)) +
      geom_line(color = "#e6e6e6") +
      geom_smooth(color = "#0072B2", size = 2) +
      labs(title = paste("All", colname, "Energy"), x = "Frame", y = colname) +
      scale_y_continuous(breaks = breaks_pretty(n = 5)) +
      scale_x_continuous(labels = scales::comma_format()) +
      theme_minimal() +
      theme(text = element_text(family = "Times")) +
      theme(plot.title = element_text(size = 36, hjust = 0.5)) +
      theme(axis.title = element_text(size = 24)) +
      theme(axis.text = element_text(size = 20))

    ggsave(out.name, plot, width = 350, height = 150, units = 'mm')
  }

  # Iterate over each column to plot whithout ouliers
  for (i in 2:ncol(energy.interaction)) {
    colname <- colnames(energy.interaction)[i]

    outliers <- boxplot(energy.interaction[[colname]], plot = FALSE)$out
    energy.trim <- energy.interaction[-which(energy.interaction[[colname]] %in% outliers),]

    # Plot graphs
    pdf.name <- paste0("_interaction_", colname, "_energy_trim", ".pdf")
    out.name <- paste0(out.path, name, pdf.name)

    plot <- ggplot(energy.trim, aes_string(x = "Frame", y = colname, group = 1)) +
      geom_line(color = "#e6e6e6") +
      geom_smooth(color = "#0072B2", size = 2) +
      labs(title = paste("All", colname, "Energy"), x = "Frame", y = colname) +
      scale_y_continuous(breaks = breaks_pretty(n = 5)) +
      scale_x_continuous(labels = scales::comma_format()) +
      theme_minimal() +
      theme(text = element_text(family = "Times")) +
      theme(plot.title = element_text(size = 36, hjust = 0.5)) +
      theme(axis.title = element_text(size = 24)) +
      theme(axis.text = element_text(size = 20))

    ggsave(out.name, plot, width = 350, height = 150, units = 'mm')
  }
}
