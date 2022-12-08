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

csv.out.path <- paste0(args[1], "energies/")
plot.out.path <- paste0(args[1], "graphs/energies/")
name <- args[2]


# Load table
file.name <- paste0(csv.out.path, name, "_all_energies.csv")
if (!file.exists(file.name)) {
    stop("Missing file ", file.name)
}

energy.all <- read.table(file.name,
                         header = TRUE,
                         sep = ";",
                         dec = ".",
)


# Format table
energy.all$Time <- NULL


# Iterate over each column
for (i in 2:ncol(energy.all)) {
    colname <- colnames(energy.all)[i]


    # Plot graphs
    png.name <- paste0("_all_", colname, "_energy", ".png")
    out.name <- paste0(plot.out.path, name, png.name)

    cat("Ploting", colname, "energy.", '\n')
    plot <- ggplot(energy.all, aes_string(x = "Frame", y = colname, group = 1)) +
        geom_line(color = "#bfbfbf") +
        geom_smooth(color = "#0072B2", size = 2, se = FALSE, span = 0.2) +
        labs(title = paste("All", colname, "Energy"), x = "Frame", y = paste(colname, "Energy", "(kcal/mol)")) +
        scale_y_continuous(breaks = breaks_pretty(n = 5)) +
        scale_x_continuous(breaks = set_frame_breaks(breaks_pretty(), range(energy.all$Frame)), labels = scales::comma_format()) +
        theme_minimal() +
        theme(text = element_text(family = "Times New Roman")) +
        theme(plot.title = element_text(size = 36, hjust = 0.5)) +
        theme(axis.title = element_text(size = 24)) +
        theme(axis.text = element_text(size = 20))

    ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
}


rm(energy.all)


# Check for interactions tables
interactions <- tail(args, -2)


for (interaction in interactions) {

    file.name <- paste0(csv.out.path, name, "_", interaction, "_interaction_energies.csv")

    if (!file.exists(file.name)) {
        stop("Missing file ", file.name)
    }

    # Loads table
    energy.interaction <- read.table(file.name,
                                     header = TRUE,
                                     sep = ";",
                                     dec = ".",
    )


    # Format table
    energy.interaction$Time <- NULL


    # Iterate over each column
    for (i in 2:ncol(energy.interaction)) {
        colname <- colnames(energy.interaction)[i]


        # Plot graphs
        png.name <- paste0("_", interaction, "_interaction_", colname, "_energy", ".png")
        out.name <- paste0(plot.out.path, name, png.name)

        cat("Ploting", colname, "interaction energy.", '\n')
        plot <- ggplot(energy.interaction, aes_string(x = "Frame", y = colname, group = 1)) +
            geom_line(color = "#bfbfbf") +
            geom_smooth(color = "#0072B2", size = 2, se = FALSE, span = 0.2) +
            labs(title = paste("Chains", interaction, "Interaction", colname, "Energy"), x = "Frame", y = paste(colname, "Energy", "(kcal/mol)")) +
            scale_y_continuous(breaks = breaks_pretty(n = 5)) +
            scale_x_continuous(breaks = set_frame_breaks(breaks_pretty(), range(energy.interaction$Frame)), labels = scales::comma_format()) +
            theme_minimal() +
            theme(text = element_text(family = "Times New Roman")) +
            theme(plot.title = element_text(size = 32, hjust = 0.5)) +
            theme(axis.title = element_text(size = 24)) +
            theme(axis.text = element_text(size = 20))

        ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
    }
}


cat("Done.\n\n")
