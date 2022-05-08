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
out.path <- args[1]
out.path <- paste0(out.path, "rmsd/")

name <- args[2]


# Resolve highlight residues
highlight <- data.frame(
    resn = str_replace_all(str_extract(tail(args, -2), ":[aA-zZ]+:"), ":", ""),
    resi = str_extract(tail(args, -2), "[0-9]+"),
    chain = str_extract(tail(args, -2), "^[aA-zZ]+"))
highlight <- if (nrow(highlight) != 0) highlight else data.frame(resn = NaN, resi = NaN, chain = NaN)


# Load all rmsd
file.name <- paste0(out.path, name, "_all_rmsd.csv")
if (!file.exists(file.name)) {
    stop("Missing file ", file.name)
}

rmsd.all <- read.table(file.name,
                       header = TRUE,
                       sep = ";",
                       dec = ".",
)


# Loop through table to genrate plots
chain.names <- tail(colnames(rmsd.all), -2)
for (i in 2:ncol(rmsd.all)) {
    colname <- colnames(rmsd.all)[i]

    # Choose file name
    if (colname %in% chain.names) {
        png.name <- paste0("_chain_", colname, "_rmsd", ".png")
        out.name <- paste0(out.path, name, png.name)
        plot.title <- paste0("RMSD chain ", colname)
    } else {
        out.name <- paste0(out.path, name, "_all_rmsd.png")
        plot.title <- "RMSD All"
    }


    # Plot rmsd graph
    cat("Ploting selection", colname, "rmsd graph.\n")
    plot <- ggplot(rmsd.all, aes_string(x = "frame", y = colname, group = 1)) +
        geom_line(color = "#bfbfbf") +
        geom_smooth(color = "#000033", size = 2) +
        labs(title = plot.title, x = "Frame", y = "RMSD Value") +
        scale_x_continuous(breaks = set_frame_breaks(breaks_pretty(), range(rmsd.all$frame)), labels = scales::comma_format()) +
        theme_minimal() +
        theme(text = element_text(family = "Times New Roman")) +
        theme(plot.title = element_text(size = 36, hjust = 0.5)) +
        theme(axis.title = element_text(size = 24)) +
        theme(axis.text = element_text(size = 20))

    ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)


    # Remove outliers
    outliers <- boxplot(tail(rmsd.all[[colname]], 0.9 * nrow(rmsd.all)), plot = FALSE)$out
    if (length(outliers) != 0) {
        rmsd.trim <- rmsd.all[-which(rmsd.all[[colname]] %in% outliers),]
    } else {
        rmsd.trim <- rmsd.all
    }
    rmsd.trim[1,]$frame <- min(rmsd.all$frame)


    # Plot rmsd graph without outliers
    out.name <- str_replace(out.name, '.png', '_trim.png')

    cat("Ploting selection", colname, "rmsd graph without outliers.\n")
    plot <- ggplot(rmsd.trim, aes_string(x = "frame", y = colname, group = 1)) +
        geom_line(color = "#bfbfbf") +
        geom_smooth(color = "#000033", size = 2) +
        labs(title = plot.title, x = "Frame", y = "RMSD Value") +
        scale_x_continuous(breaks = set_frame_breaks(breaks_pretty(), range(rmsd.trim$frame)), labels = scales::comma_format()) +
        theme_minimal() +
        theme(text = element_text(family = "Times New Roman")) +
        theme(plot.title = element_text(size = 36, hjust = 0.5)) +
        theme(axis.title = element_text(size = 24)) +
        theme(axis.text = element_text(size = 20))

    ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
}


# Finnish
cat("Done rmsd.\n")
rm(rmsd.all)
rm(rmsd.trim)


# Load rmsf
file.name <- paste0(out.path, name, "_all_rmsf.csv")
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


# Generate names and colors for plots
axis.names <- c("Residue", "", "Init", "Middle", "Final")
colors.steps <- c("rmsf_init" = 'green', "rmsf_middle" = 'blue', "rmsf_final" = 'red')


# For each chain
for (chain in names(rmsf.table.divided)) {

    # Get range for steps
    steps.min_max <- c(+Inf, -Inf)
    for (col_step in names(colors.steps)) {
        range <- range(rmsf.table.divided[[chain]][[col_step]])
        if (range[2] > steps.min_max[2]) {
            steps.min_max[2] <- range[2]
        }
        if (range[1] - range[2] * 0.06 < steps.min_max[1]) {
            steps.min_max[1] <- range[1] - range[2] * 0.06
        }
    }


    # Create data for highlight labels
    highlight.data <- data.frame(matrix(ncol = 8, nrow = 0, dimnames = list(NULL, c(colnames(rmsf.table), "label"))))
    for (row in seq_len(nrow(highlight))) {
        residue <- paste0(highlight[row,]$chain, ":", highlight[row,]$resi)

        if (residue %in% rmsf.table.divided[[chain]]$residue) {
            data <- rmsf.table[rmsf.table$residue == residue,]
            data$label <- paste0(highlight[row,]$resi, '\n', highlight[row,]$resn)

            highlight.data <- rbind(highlight.data, data)
            highlight.data$label <- gsub("\nNA", "", highlight.data$label)
        }
    }
    if (nrow(highlight.data) == 0) highlight.data[1,] <- matrix(NaN, ncol = 8, nrow = 1)


    # For each stat
    for (i in 2:ncol(subset(rmsf.table.divided[[chain]], select = -c(residue_chain, residue_number)))) {
        colname <- colnames(rmsf.table)[i]

        min_y_value <- min(rmsf.table.divided[[chain]][[colname]])
        max_y_value <- max(rmsf.table.divided[[chain]][[colname]])

        # Plot stat graphs
        png.name <- paste0("_chain_", chain, "_", colname, ".png")
        out.name <- paste0(out.path, name, png.name)

        cat("Ploting", colname, "for chain", chain, '\n')
        plot <- ggplot(rmsf.table.divided[[chain]], aes_string(x = "residue_number", y = colname, group = 1)) +
            geom_line(color = if (is.na(colors.steps[colname][[1]])) "#000033" else colors.steps[colname][[1]], size = 1) +
            geom_text(data = highlight.data, aes_string(x = "residue_number", y = min_y_value - max_y_value * 0.05, label = "label"), color = "#800000", size = 5, lineheight = .7) +
            geom_segment(data = highlight.data, aes_string(x = "residue_number", xend = "residue_number", y = min_y_value - max_y_value * 0.01, yend = colname), color = "#800000", size = 1, linetype = "dashed") +
            scale_x_continuous(breaks = if (length(rmsf.table.divided[[chain]]$residue) < 5) unique(rmsf.table.divided[[chain]]$residue) else breaks_pretty()) +
            scale_y_continuous(limits = if (i >= 3) steps.min_max else NULL) +
            labs(title = paste("Chain", chain, "RMSF", axis.names[i]), x = "Residue", y = paste("RMSF", axis.names[i])) +
            theme_minimal() +
            theme(text = element_text(family = "Times New Roman")) +
            theme(plot.title = element_text(size = 36, hjust = 0.5)) +
            theme(axis.title = element_text(size = 24)) +
            theme(axis.text = element_text(size = 20))
        ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
    }


    # Resolve SD steps
    rmsf.chain.steps <- select(rmsf.table.divided[[chain]], residue_number, rmsf_init, rmsf_middle, rmsf_final)
    rmsf.chain.steps <- gather(rmsf.chain.steps, sd, value, -residue_number)
    rmsf.chain.steps$sd <- factor(rmsf.chain.steps$sd, levels = c("rmsf_init", "rmsf_middle", "rmsf_final"))


    # Plot SD steps graphs
    png.name <- paste0("_chain_", chain, "_rmsf_steps.png")
    out.name <- paste0(out.path, name, png.name)

    min_y_value <- min(rmsf.chain.steps$value)
    max_y_value <- max(rmsf.chain.steps$value)

    cat("Ploting rmsf steps for chain", chain, '\n')
    plot <- ggplot(rmsf.chain.steps, aes_string(x = "residue_number", y = "value")) +
        geom_line(aes_string(color = 'sd', group = "sd")) +
        geom_text(data = highlight.data, aes_string(x = "residue_number", y = min_y_value - max_y_value * 0.05, label = "label"), color = "#800000", size = 5, lineheight = .7) +
        geom_segment(data = highlight.data, aes_string(x = "residue_number", xend = "residue_number", y = min_y_value - max_y_value * 0.01, yend = colname), color = "#800000", size = 1, linetype = "dashed") +
        scale_x_continuous(breaks = if (length(rmsf.chain.steps$residue) < 5) unique(rmsf.chain.steps$residue) else breaks_pretty()) +
        labs(title = paste("Chain", chain, "RMSF Steps"), x = "Residue", y = "Standard Deviation") +
        theme_minimal() +
        theme(text = element_text(family = "Times New Roman")) +
        theme(plot.title = element_text(size = 36, hjust = 0.5)) +
        theme(axis.title = element_text(size = 24), axis.text = element_text(size = 20)) +
        theme(legend.text = element_text(size = 20), legend.position = "top", legend.title = element_blank()) +
        scale_color_manual(labels = c("Init", "Middle", "Final"), values = c("green", "blue", "red"))

    ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
}


# Finnish
cat("Done rmsf.\n")
rm(rmsf.table)
rm(rmsf.table.divided)


# Plot highlight data rmsd
if (nrow(highlight[(!is.na(highlight$resi)),]) != 0) {

    # Load residue rmsd
    file.name <- paste0(out.path, name, "_residue_rmsd.csv")
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
    color.list <- c()
    colors <- c('#ff0000', '#cccc00', '#660066', '#4d2600', '#00b300', '#003366', '#003300', '#990033')
    while (length(highlight.present$resi) > length(color.list)) {
        if (length(color.list) >= length(colors)) {
            color.list <- append(color.list, sample(rainbow(20), 1))
        } else {
            color.list <- append(color.list, colors[length(color.list) + 1])
        }
    }
    color.list <- setNames(color.list, gsub("\nNA", "", paste0(highlight.present$resi, '\n', highlight.present$resn)))

    # Plot SD steps graphs
    out.name <- paste0(out.path, name, "_highlight_rmsd.png")

    cat("Ploting highlight residues rmsd separated.\n")
    plot <- ggplot(residue.table, aes(x = frame)) +
        labs(title = 'Residues RMSD', x = "Frame", y = "RMSD Value") +
        scale_x_continuous(breaks = set_frame_breaks(breaks_pretty(), range(residue.table$frame)), labels = scales::comma_format()) +
        theme_minimal() +
        theme(text = element_text(family = "Times New Roman")) +
        theme(plot.title = element_text(size = 36, hjust = 0.5)) +
        theme(axis.title = element_text(size = 24)) +
        theme(axis.text = element_text(size = 20)) +
        theme(legend.text = element_text(size = 15), legend.key.size = unit(1.3, "cm"), legend.text.align = .5) +
        theme(legend.title = element_text(size = 15, family = "Times New Roman")) +
        scale_color_manual("Residues", values = color.list)

    for (row in seq_len(nrow(highlight.present))) {
        residue <- paste0(highlight.present[row,]$chain, ".", highlight.present[row,]$resi)
        plot <- plot + geom_smooth(aes_(y = as.name(residue),
                                        color = gsub("\nNA", "", paste0(highlight.present[row,]$resi, '\n', highlight.present[row,]$resn))),
                                   size = 1, se = FALSE)
    }

    ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)

    out.name <- paste0(out.path, name, "_highlight_rmsd_trim.png")

    cat("Ploting highlight residues rmsd separated without outliers.\n")
    plot <- ggplot(residue.table, aes(x = frame)) +
        labs(title = 'Residues RMSD', x = "Frame", y = "RMSD Value") +
        scale_x_continuous(breaks = set_frame_breaks(breaks_pretty(), range(residue.table$frame)), labels = scales::comma_format()) +
        theme_minimal() +
        theme(text = element_text(family = "Times New Roman")) +
        theme(plot.title = element_text(size = 36, hjust = 0.5)) +
        theme(axis.title = element_text(size = 24)) +
        theme(axis.text = element_text(size = 20)) +
        theme(legend.text = element_text(size = 15), legend.key.size = unit(1.3, "cm"), legend.text.align = .5) +
        theme(legend.title = element_text(size = 15, family = "Times New Roman")) +
        scale_color_manual("Residues", values = color.list)


    for (row in seq_len(nrow(highlight.present))) {
        residue <- paste0(highlight.present[row,]$chain, ".", highlight.present[row,]$resi)

        # Remove outliers
        outliers <- boxplot(residue.table[[residue]], plot = FALSE)$out
        if (length(outliers) != 0) {
            residue.table.trim <- residue.table[-which(residue.table[[residue]] %in% outliers),]
        } else {
            residue.table.trim <- residue.table
        }
        residue.table.trim[1,]$frame <- min(residue.table$frame)

        plot <- plot + geom_smooth(data = residue.table.trim,
                                   aes_(y = as.name(residue),
                                        color = gsub("\nNA", "", paste0(highlight.present[row,]$resi, '\n', highlight.present[row,]$resn))),
                                   size = 1, se = FALSE)
    }

    ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
}
cat("Done.\n\n")
