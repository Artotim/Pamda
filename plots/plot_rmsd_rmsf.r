dir.create(Sys.getenv("R_LIBS_USER"), recursive = TRUE)  # create personal library
.libPaths(Sys.getenv("R_LIBS_USER"))  # add to the path
if (!require('ggplot2')) install.packages('ggplot2', lib = Sys.getenv("R_LIBS_USER"), repos = "https://cloud.r-project.org/"); library('ggplot2')
if (!require('tidyr')) install.packages('tidyr', lib = Sys.getenv("R_LIBS_USER"), repos = "https://cloud.r-project.org/"); library('tidyr')
if (!require('dplyr')) install.packages('dplyr', lib = Sys.getenv("R_LIBS_USER"), repos = "https://cloud.r-project.org/"); library('dplyr')
if (!require('scales')) install.packages('scales', lib = Sys.getenv("R_LIBS_USER"), repos = "https://cloud.r-project.org/"); library('scales')
if (!require('data.table')) install.packages('data.table', lib = Sys.getenv("R_LIBS_USER"), repos = "https://cloud.r-project.org/"); library('data.table')
if (!require('stringr')) install.packages('stringr', lib = Sys.getenv("R_LIBS_USER"), repos = "https://cloud.r-project.org/"); library('stringr')
if (!require('extrafont')) {
    install.packages('extrafont', lib = Sys.getenv("R_LIBS_USER"), repos = "https://cloud.r-project.org/")
    library('extrafont')
    font_import(prompt = FALSE)
    loadfonts()
}
library('ggplot2')
library('tidyr')
library('dplyr')
library('scales')
library('data.table')
library('stringr')
library('extrafont')


set_frame_breaks <- function(original_func, data_range) {
    function(x) {
        original_result <- original_func(x)
        original_result <- c(data_range[1], head(tail(original_result, -2), -2), data_range[2])
    }
}


# Resolve file names
args <- commandArgs(trailingOnly = TRUE)

csv.out.path <- paste0(args[1], "rms/")
plot.out.path <- paste0(args[1], "graphs/rms/")
name <- args[2]


# Resolve highlight residues
highlight <- data.frame(
    resn = str_replace_all(str_extract(tail(args, -2), ":[aA-zZ]+:"), ":", ""),
    resi = str_extract(tail(args, -2), "[0-9]+"),
    chain = str_extract(tail(args, -2), "^[aA-zZ]+"))
highlight <- if (nrow(highlight) != 0) highlight else data.frame(resn = NaN, resi = NaN, chain = NaN)


# Load all RMSD
file.name <- paste0(csv.out.path, name, "_all_rmsd.csv")
if (!file.exists(file.name)) {
    stop("Missing file ", file.name)
}

rmsd.all <- read.table(file.name,
                       header = TRUE,
                       sep = ";",
                       dec = ".",
)


# Loop through table to genrate plots
for (i in 2:ncol(rmsd.all)) {
    colname <- colnames(rmsd.all)[i]

    # Choose file name
    png.name <- paste0("_", colname, "_rmsd", ".png")
    out.name <- paste0(plot.out.path, name, png.name)
    plot.title <- paste(str_to_title(str_replace_all(colname, "_", " ")), "RMSD")

    # Plot rmsd graph
    cat("Ploting", str_replace_all(colname, "_", " "), "RMSD graph.\n")
    plot <- ggplot(rmsd.all, aes_string(x = "frame", y = colname, group = 1)) +
        geom_line(color = "#bfbfbf") +
        geom_smooth(color = "#000033", size = 2, se = FALSE, span = 0.2) +
        labs(title = plot.title, x = "Frame", y = "RMSD (Å)") +
        scale_x_continuous(breaks = set_frame_breaks(breaks_pretty(), range(rmsd.all$frame)), labels = scales::comma_format()) +
        theme_minimal() +
        theme(text = element_text(family = "Times New Roman")) +
        theme(plot.title = element_text(size = 36, hjust = 0.5)) +
        theme(axis.title = element_text(size = 24)) +
        theme(axis.text = element_text(size = 20))

    ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
}


# Finnish
cat("Done RMSD.\n")
rm(rmsd.all)


# Load residue RMSD SD
file.name <- paste0(csv.out.path, name, "_residue_rmsd_sd.csv")
if (!file.exists(file.name)) {
    stop("Missing file ", file.name)
}

rmsd.sd.table <- read.table(file.name,
                            header = TRUE,
                            sep = ";",
                            dec = ".",
)


# Format table
rmsd.sd.table[c('residue_chain', 'residue_number')] <- str_split_fixed(rmsd.sd.table$residue, ':', 2)
rmsd.sd.table$residue_number <- as.numeric(rmsd.sd.table$residue_number)
rmsd.sd.table.divided <- split(rmsd.sd.table, rmsd.sd.table$residue_chain)


# Generate names and colors for plots
axis.names <- c("Residue", "", "Init", "Middle", "Final")
colors.steps <- c("init_rmsd_sd" = 'green', "middle_rmsd_sd" = 'blue', "final_rmsd_sd" = 'red')


# For each chain
for (chain in names(rmsd.sd.table.divided)) {

    # Create data for highlight labels
    highlight.data <- data.frame(matrix(ncol = 8, nrow = 0, dimnames = list(NULL, c(colnames(rmsd.sd.table), "label"))))
    for (row in seq_len(nrow(highlight))) {
        residue <- paste0(highlight[row,]$chain, ":", highlight[row,]$resi)

        if (residue %in% rmsd.sd.table.divided[[chain]]$residue) {
            data <- rmsd.sd.table[rmsd.sd.table$residue == residue,]
            data$label <- paste0(highlight[row,]$resi, '\n', highlight[row,]$resn)

            highlight.data <- rbind(highlight.data, data)
            highlight.data$label <- gsub("\nNA", "", highlight.data$label)
        }
    }
    if (nrow(highlight.data) == 0) highlight.data[1,] <- matrix(NaN, ncol = 5, nrow = 1)


    # Plot total rmsd sd
    min_y_value <- min(rmsd.sd.table.divided[[chain]]$total_rmsd_sd)
    max_y_value <- max(rmsd.sd.table.divided[[chain]]$total_rmsd_sd)

    # Plot stat graphs
    png.name <- paste0("_chain_", chain, "_total_rmsd_sd.png")
    out.name <- paste0(plot.out.path, name, png.name)

    cat("Ploting RMSD SD for chain", chain, '\n')
    plot <- ggplot(rmsd.sd.table.divided[[chain]], aes_string(x = "residue_number", y = "total_rmsd_sd", group = 1)) +
        geom_line(color = "#000033", size = 1) +
        geom_text(data = highlight.data, aes_string(x = "residue_number", y = min_y_value - max_y_value * 0.05, label = "label"), color = "#800000", size = 5, lineheight = .7) +
        geom_segment(data = highlight.data, aes_string(x = "residue_number", xend = "residue_number", y = min_y_value - max_y_value * 0.01, yend = "total_rmsd_sd"), color = "#800000", size = 1, linetype = "dashed") +
        scale_x_continuous(breaks = if (length(rmsd.sd.table.divided[[chain]]$residue) < 5) unique(rmsd.sd.table.divided[[chain]]$residue) else breaks_pretty()) +
        labs(title = paste("Chain", chain, "no fit RMSD SD total"), x = "Residue", y = "RMSD Standard Deviation (Å)") +
        theme_minimal() +
        theme(text = element_text(family = "Times New Roman")) +
        theme(plot.title = element_text(size = 36, hjust = 0.5)) +
        theme(axis.title = element_text(size = 24)) +
        theme(axis.text = element_text(size = 20))
    ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)


    # Resolve SD steps
    rmsd.sd.chain.steps <- select(rmsd.sd.table.divided[[chain]], residue_number, init_rmsd_sd, middle_rmsd_sd, final_rmsd_sd)
    rmsd.sd.chain.steps <- gather(rmsd.sd.chain.steps, sd, value, -residue_number)
    rmsd.sd.chain.steps$sd <- factor(rmsd.sd.chain.steps$sd, levels = c("init_rmsd_sd", "middle_rmsd_sd", "final_rmsd_sd"))


    # Plot SD steps graphs
    png.name <- paste0("_chain_", chain, "_portions_rmsd_sd.png")
    out.name <- paste0(plot.out.path, name, png.name)

    min_y_value <- min(rmsd.sd.chain.steps$value)
    max_y_value <- max(rmsd.sd.chain.steps$value)

    cat("Ploting RMSD SD steps for chain", chain, '\n')
    plot <- ggplot(rmsd.sd.chain.steps, aes_string(x = "residue_number", y = "value")) +
        geom_line(aes_string(color = 'sd', group = "sd")) +
        geom_text(data = highlight.data, aes_string(x = "residue_number", y = min_y_value - max_y_value * 0.05, label = "label"), color = "#800000", size = 5, lineheight = .7) +
        geom_segment(data = highlight.data, aes_string(x = "residue_number", xend = "residue_number", y = min_y_value - max_y_value * 0.01, yend = "total_rmsd_sd"), color = "#800000", size = 1, linetype = "dashed") +
        scale_x_continuous(breaks = if (length(rmsd.sd.chain.steps$residue) < 5) unique(rmsd.sd.chain.steps$residue) else breaks_pretty()) +
        labs(title = paste("Chain", chain, "no fit RMSD SD per portions"), x = "Residue", y = "RMSD Standard Deviation (Å)") +
        theme_minimal() +
        theme(text = element_text(family = "Times New Roman")) +
        theme(plot.title = element_text(size = 36, hjust = 0.5)) +
        theme(axis.title = element_text(size = 24), axis.text = element_text(size = 20)) +
        theme(legend.text = element_text(size = 20), legend.position = "top", legend.title = element_blank()) +
        scale_color_manual(labels = c("Init", "Middle", "Final"), values = c("green", "blue", "red"))

    ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
}


# Finnish
cat("Done RMSD SD.\n")
rm(rmsd.sd.table)
rm(rmsd.sd.table.divided)


# Load RMSF
file.name <- paste0(csv.out.path, name, "_residue_rmsf.csv")
if (!file.exists(file.name)) {
    stop("Missing file ", file.name)
}

rmsf.table <- read.table(file.name,
                         header = TRUE,
                         sep = ";",
                         dec = ".",
)


# Format table
rmsf.table[c('residue_chain', 'residue_number')] <- str_split_fixed(rmsf.table$residue, ':', 2)
rmsf.table$residue_number <- as.numeric(rmsf.table$residue_number)
rmsf.table.divided <- split(rmsf.table, rmsf.table$residue_chain)


# For each chain
for (chain in names(rmsf.table.divided)) {

    # Create data for highlight labels
    highlight.data <- data.frame(matrix(ncol = 5, nrow = 0, dimnames = list(NULL, c(colnames(rmsf.table), "label"))))
    for (row in seq_len(nrow(highlight))) {
        residue <- paste0(highlight[row,]$chain, ":", highlight[row,]$resi)

        if (residue %in% rmsf.table.divided[[chain]]$residue) {
            data <- rmsf.table[rmsf.table$residue == residue,]
            data$label <- paste0(highlight[row,]$resi, '\n', highlight[row,]$resn)

            highlight.data <- rbind(highlight.data, data)
            highlight.data$label <- gsub("\nNA", "", highlight.data$label)
        }
    }
    if (nrow(highlight.data) == 0) highlight.data[1,] <- matrix(NaN, ncol = 5, nrow = 1)

    min_y_value <- min(rmsf.table.divided[[chain]]$rmsf)
    max_y_value <- max(rmsf.table.divided[[chain]]$rmsf)

    # Plot stat graphs
    png.name <- paste0("_chain_", chain, "_residues_rmsf.png")
    out.name <- paste0(plot.out.path, name, png.name)

    cat("Ploting RMSF for chain", chain, '\n')
    plot <- ggplot(rmsf.table.divided[[chain]], aes_string(x = "residue_number", y = "rmsf", group = 1)) +
        geom_line(color = "#000033", size = 1) +
        geom_text(data = highlight.data, aes_string(x = "residue_number", y = min_y_value - max_y_value * 0.05, label = "label"), color = "#800000", size = 5, lineheight = .7) +
        geom_segment(data = highlight.data, aes_string(x = "residue_number", xend = "residue_number", y = min_y_value - max_y_value * 0.01, yend = "rmsf"), color = "#800000", size = 1, linetype = "dashed") +
        scale_x_continuous(breaks = if (length(rmsf.table.divided[[chain]]$residue) < 5) unique(rmsf.table.divided[[chain]]$residue) else breaks_pretty()) +
        labs(title = paste("Chain", chain, "RMSF"), x = "Residue index", y = "RMSF (Å)") +
        theme_minimal() +
        theme(text = element_text(family = "Times New Roman")) +
        theme(plot.title = element_text(size = 36, hjust = 0.5)) +
        theme(axis.title = element_text(size = 24)) +
        theme(axis.text = element_text(size = 20))
    ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
}


# Finnish
cat("Done rmsf.\n")
rm(rmsf.table)
rm(rmsf.table.divided)


# Plot highlight data rmsd
if (nrow(highlight[(!is.na(highlight$resi)),]) != 0) {

    # Load residue rmsd
    file.name <- paste0(csv.out.path, name, "_residue_rmsd.csv")
    if (!file.exists(file.name)) {
        stop("Missing file ", file.name)
    }

    residue.table <- read.table(file.name,
                                header = TRUE,
                                sep = ";",
                                dec = ".",
    )


    # Use only residues in table
    highlight.present <- highlight[which(paste0(highlight$chain, ".", highlight$resi) %in% colnames(residue.table)),]


    # Create colors list
    colors.list <- c()
    colors <- c('#ff0000', '#cccc00', '#804000', '#660066', '#0059b3', '#00b300', '#003300', '#990033')
    while (length(highlight.present$resi) > length(colors.list)) {
        if (length(colors.list) >= length(colors)) {
            colors.list <- append(colors.list, sample(rainbow(20), 1))
        } else {
            colors.list <- append(colors.list, colors[length(colors.list) + 1])
        }
    }
    colors.list <- setNames(colors.list, gsub("\nNA", "", paste0(highlight.present$chain, ":", highlight.present$resi, '\n', highlight.present$resn)))

    # Plot SD steps graphs
    out.name <- paste0(plot.out.path, name, "_highlight_rmsd.png")

    cat("Ploting highlight residues rmsd separated.\n")
    plot <- ggplot(residue.table, aes(x = frame)) +
        labs(title = 'Residues RMSD', x = "Frame", y = "RMSD (Å)") +
        scale_x_continuous(breaks = set_frame_breaks(breaks_pretty(), range(residue.table$frame)), labels = scales::comma_format()) +
        theme_minimal() +
        theme(text = element_text(family = "Times New Roman")) +
        theme(plot.title = element_text(size = 36, hjust = 0.5)) +
        theme(axis.title = element_text(size = 24)) +
        theme(axis.text = element_text(size = 20)) +
        theme(legend.text = element_text(size = 17), legend.key.size = unit(1.3, "cm"), legend.text.align = .5) +
        theme(legend.title = element_text(size = 17, family = "Times New Roman")) +
        scale_color_manual("Residues", values = colors.list)

    for (row in seq_len(nrow(highlight.present))) {
        residue <- paste0(highlight.present[row,]$chain, ".", highlight.present[row,]$resi)
        plot <- plot + geom_smooth(aes_(y = as.name(residue),
                                    color = gsub("\nNA", "", paste0(str_replace(residue, "\\.", ":"), '\n', highlight.present[row,]$resn))),
                                   size = 1.3, se = FALSE, span = 0.2)
    }

    ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
}


cat("Done.\n\n")
