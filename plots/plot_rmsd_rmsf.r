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


# Resolve file names
args <- commandArgs(trailingOnly = TRUE)
out.path <- args[1]
out.path <- paste0(out.path, "rmsd/")

name <- args[2]


# Load residue rmsd
file.name <- paste0(out.path, name, "_residue_rmsd.csv")
if (!file.exists(file.name)) {
    stop(cat("Missing file", file.name))
}

rmsd.table <- read.table(file.name,
                         header = TRUE,
                         sep = ";",
                         dec = ".",
)


# Format table
rmsd.table$X = NULL
residues <- str_replace_all(names(rmsd.table), "X", "")
residues <- as.numeric(residues)
rows <- nrow(rmsd.table)


# Create stats table
rmsd.stats.type <- c("mean", "sd_total", "sd_first", "sd_middle", "sd_last")
rmsd.stats <- setNames(data.table(matrix(ncol = 6, nrow = length(residues))), c("residue", rmsd.stats.type))
rmsd.stats$residue <- residues


# Take measures for stat table
stat_i <- 1
for (r in residues) {
    table_i <- paste0("X", r)
    rmsd.stats$mean[stat_i] = mean(rmsd.table[, table_i])
    rmsd.stats$sd_total[stat_i] = sd(rmsd.table[, table_i])
    rmsd.stats$sd_first[stat_i] = sd(rmsd.table[, table_i][1:(rows / 3)])
    rmsd.stats$sd_middle[stat_i] = sd(rmsd.table[, table_i][((rows / 3)):(2 * rows / 3)])
    rmsd.stats$sd_last[stat_i] = sd(rmsd.table[, table_i][((2 * rows / 3)):rows])
    stat_i <- stat_i + 1
}
rm(rmsd.table)


# Detect chain number
residue_ind <- 0
previous <- residues[1]
chains.sep <- NULL
for (now in (residues)) {
    if (abs(previous - now) > 1) {
        chains.sep <- c(chains.sep, residue_ind)
        residue_ind <- 0
    } else {
        residue_ind <- residue_ind + 1
    }
    previous <- now
}

chain <- 1
residue.chains <- NULL
for (i in chains.sep) {
    residue.chains <- c(residue.chains, rep(chain, i))
    chain <- chain + 1
}
residue.chains <- c(residue.chains, rep(chain, (residue_ind + 1)))


# Split stat in chains
chains.stat <- split(rmsd.stats, residue.chains)


# Create names for plot
axis.names <- c("Residue", "Mean", "SD Total", "SD Initial", "SD Middle", "SD Final")


# For each chain
for (i in 1:chain) {
    # For each stat
    for (j in 2:ncol(chains.stat[[i]])) {
        colname <- colnames(chains.stat[[i]])[j]

        # Plot stat graphs
        png.name <- paste0("_rmsf_chain_", i, "_", colname, ".png")
        out.name <- paste0(out.path, name, png.name)

        cat("Ploting", colname, "for chain", i)
        plot <- ggplot(chains.stat[[i]], aes_string(x = "residue", y = colname, group = 1)) +
            geom_line(color = "#000033") +
            labs(title = paste("RMSD", axis.names[j]), x = "Residue", y = axis.names[j]) +
            scale_x_continuous(breaks = pretty_breaks()) +
            theme_minimal() +
            theme(text = element_text(family = "Times New Roman")) +
            theme(plot.title = element_text(size = 36, hjust = 0.5)) +
            theme(axis.title = element_text(size = 24)) +
            theme(axis.text = element_text(size = 20))
        ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
    }


    # Resolve SD steps
    rmsf.chain.sd <- select(chains.stat[[i]], residue, sd_first, sd_middle, sd_last)
    rmsf.chain.sd <- gather(rmsf.chain.sd, sd, value, -residue)
    rmsf.chain.sd$sd <- factor(rmsf.chain.sd$sd, levels = c("sd_first", "sd_middle", "sd_last"))


    # Plot SD steps graphs
    png.name <- paste0("_rmsf_chain_", i, "_sd_steps.png")
    out.name <- paste0(out.path, name, png.name)

    cat("Ploting standar deviation for chain", i)
    plot <- ggplot(rmsf.chain.sd, aes_string(x = "residue", y = "value", group = "sd")) +
        geom_line(aes(color = sd)) +
        labs(title = "RMSD SD Steps", x = "Residue", y = "Standard Deviation") +
        scale_x_continuous(breaks = pretty_breaks()) +
        theme_minimal() +
        theme(text = element_text(family = "Times New Roman")) +
        theme(plot.title = element_text(size = 36, hjust = 0.5)) +
        theme(axis.title = element_text(size = 24), axis.text = element_text(size = 20)) +
        theme(legend.text = element_text(size = 20), legend.position = "top", legend.title = element_blank()) +
        scale_color_manual(labels = c("Initial", "Middle", "Final"), values = c("green", "blue", "red"))

    ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
}


# Load all rmsd
file.name <- paste0(out.path, name, "_all_rmsd.csv")
if (!file.exists(file.name)) {
    stop(cat("Missing file", file.name))
}

rmsd.all <- read.table(file.name,
                       header = TRUE,
                       sep = ";",
                       dec = ".",
)


# Format rmsd table
colnames(rmsd.all) <- c("Frame", "RMSD")
rmsd.all$Frame = seq_along(rmsd.all$Frame)


# Plot rmsd graph
out.name <- paste0(out.path, name, "_rmsd_frames.png")

print("Ploting rmsd graph.")
plot <- ggplot(rmsd.all, aes(x = Frame, y = RMSD, group = 1)) +
    geom_line(color = "#e6e6e6") +
    geom_smooth(color = "#000033", size = 2) +
    labs(title = "RMSD", x = "Frame", y = "RMSD Value") +
    scale_x_continuous(labels = scales::comma_format()) +
    theme_minimal() +
    theme(text = element_text(family = "Times New Roman")) +
    theme(plot.title = element_text(size = 36, hjust = 0.5)) +
    theme(axis.title = element_text(size = 24)) +
    theme(axis.text = element_text(size = 20))

ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)


# Remove outliers
outliers <- boxplot(rmsd.all$RMSD, plot = FALSE)$out
rmsd.trim <- rmsd.all[-which(rmsd.all$RMSD %in% outliers),]


# Plot rmsd graph without outliers
out.name <- paste0(out.path, name, "_rmsd_frames_trim.png")

print("Ploting rmsd graph without outliers.")
plot <- ggplot(rmsd.trim, aes(x = Frame, y = RMSD, group = 1)) +
    geom_line(color = "#e6e6e6") +
    geom_smooth(color = "#000033", size = 2) +
    labs(title = "RMSD", x = "Frame", y = "RMSD Value") +
    scale_x_continuous(labels = scales::comma_format()) +
    theme_minimal() +
    theme(text = element_text(family = "Times New Roman")) +
    theme(plot.title = element_text(size = 36, hjust = 0.5)) +
    theme(axis.title = element_text(size = 24)) +
    theme(axis.text = element_text(size = 20))

ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
print("Done.")
