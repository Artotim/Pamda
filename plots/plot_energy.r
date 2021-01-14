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


# Resolve file names
args <- commandArgs(trailingOnly = TRUE)
out.path <- args[1]
out.path <- paste0(out.path, "energies/")

name <- args[2]


# Load table
file.name <- paste0(out.path, name, "_all_energies.csv")
if (!file.exists(file.name)) {
    stop("Missing file ", file.name)
}

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
    png.name <- paste0("_all_", colname, "_energy", ".png")
    out.name <- paste0(out.path, name, png.name)

    cat("Ploting", colname, "energy.", '\n')
    plot <- ggplot(energy.all, aes_string(x = "Frame", y = colname, group = 1)) +
        geom_line(color = "#e6e6e6") +
        geom_smooth(color = "#0072B2", size = 2) +
        labs(title = paste("All", colname, "Energy"), x = "Frame", y = colname) +
        scale_y_continuous(breaks = breaks_pretty(n = 5)) +
        scale_x_continuous(labels = scales::comma_format()) +
        theme_minimal() +
        theme(text = element_text(family = "Times New Roman")) +
        theme(plot.title = element_text(size = 36, hjust = 0.5)) +
        theme(axis.title = element_text(size = 24)) +
        theme(axis.text = element_text(size = 20))

    ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
}


# Iterate over each column to plot whithout outliers
for (i in 2:ncol(energy.all)) {
    colname <- colnames(energy.all)[i]

    outliers <- boxplot(energy.all[[colname]], plot = FALSE)$out
    if (length(outliers) != 0) {
        energy.trim <- energy.all[-which(energy.all[[colname]] %in% outliers),]
    } else {
        energy.trim <- energy.all
    }

    # Plot graphs
    png.name <- paste0("_all_", colname, "_energy_trim", ".png")
    out.name <- paste0(out.path, name, png.name)

    cat("Ploting", colname, "energy without outliers.", '\n')
    plot <- ggplot(energy.trim, aes_string(x = "Frame", y = colname, group = 1)) +
        geom_line(color = "#e6e6e6") +
        geom_smooth(color = "#0072B2", size = 2) +
        labs(title = paste("All", colname, "Energy"), x = "Frame", y = colname) +
        scale_y_continuous(breaks = breaks_pretty(n = 5)) +
        scale_x_continuous(labels = scales::comma_format()) +
        theme_minimal() +
        theme(text = element_text(family = "Times New Roman")) +
        theme(plot.title = element_text(size = 36, hjust = 0.5)) +
        theme(axis.title = element_text(size = 24)) +
        theme(axis.text = element_text(size = 20))

    ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
}


# Check for interaction table
rm(energy.all)
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
        png.name <- paste0("_interaction_", colname, "_energy", ".png")
        out.name <- paste0(out.path, name, png.name)

        cat("Ploting", colname, "interaction energy.", '\n')
        plot <- ggplot(energy.interaction, aes_string(x = "Frame", y = colname, group = 1)) +
            geom_line(color = "#e6e6e6") +
            geom_smooth(color = "#0072B2", size = 2) +
            labs(title = paste("Interaction", colname, "Energy"), x = "Frame", y = colname) +
            scale_y_continuous(breaks = breaks_pretty(n = 5)) +
            scale_x_continuous(labels = scales::comma_format()) +
            theme_minimal() +
            theme(text = element_text(family = "Times New Roman")) +
            theme(plot.title = element_text(size = 36, hjust = 0.5)) +
            theme(axis.title = element_text(size = 24)) +
            theme(axis.text = element_text(size = 20))

        ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
    }

    # Iterate over each column to plot whithout ouliers
    for (i in 2:ncol(energy.interaction)) {
        colname <- colnames(energy.interaction)[i]

        outliers <- boxplot(energy.interaction[[colname]], plot = FALSE)$out
        if (length(outliers) != 0) {
            energy.trim <- energy.interaction[-which(energy.interaction[[colname]] %in% outliers),]
        } else {
            energy.trim <- energy.interaction
        }

        # Plot graphs
        png.name <- paste0("_interaction_", colname, "_energy_trim", ".png")
        out.name <- paste0(out.path, name, png.name)

        cat("Ploting", colname, "interaction energy without outliers.", '\n')
        plot <- ggplot(energy.trim, aes_string(x = "Frame", y = colname, group = 1)) +
            geom_line(color = "#e6e6e6") +
            geom_smooth(color = "#0072B2", size = 2) +
            labs(title = paste("Interaction", colname, "Energy"), x = "Frame", y = colname) +
            scale_y_continuous(breaks = breaks_pretty(n = 5)) +
            scale_x_continuous(labels = scales::comma_format()) +
            theme_minimal() +
            theme(text = element_text(family = "Times New Roman")) +
            theme(plot.title = element_text(size = 36, hjust = 0.5)) +
            theme(axis.title = element_text(size = 24)) +
            theme(axis.text = element_text(size = 20))

        ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
    }
}
cat("Done.\n")
