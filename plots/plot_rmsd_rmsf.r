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


# Resolve catalytic site
catalytic <- data.frame(resn = str_extract(tail(args, -5), "[aA-zZ]+"), resi = str_extract(tail(args, -5), "[0-9]+"))
catalytic <- if (nrow(catalytic) != 0) catalytic else data.frame(resn = NaN, resi = NaN)


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


# Get chains
chain.names <- tail(colnames(rmsd.all), -2)


# Loop through table
rmsd.trim <- list()
for (i in 2:ncol(rmsd.all)) {
    colname <- colnames(rmsd.all)[i]

    rmsd.all <- rbind(rep(0, ncol(rmsd.all)), rmsd.all)

    # Choose file name
    if (colname %in% chain.names) {
        chain.indx <- match(colname, chain.names)
        png.name <- paste0("_rmsd_frame_chain_", chain.indx, ".png")
        out.name <- paste0(out.path, name, png.name)
        plot.title <- paste0("RMSD chain ", colname)
    } else {
        out.name <- paste0(out.path, name, "_rmsd_frame_all.png")
        plot.title <- "RMSD All"
    }


    # Plot rmsd graph
    cat("Ploting selection", colname, "rmsd graph.\n")
    plot <- ggplot(rmsd.all, aes_string(x = "frame", y = colname, group = 1)) +
        geom_line(color = "#bfbfbf") +
        geom_smooth(color = "#000033", size = 2) +
        labs(title = plot.title, x = "Frame", y = "RMSD Value") +
        scale_x_continuous(labels = scales::comma_format()) +
        theme_minimal() +
        theme(text = element_text(family = "Times New Roman")) +
        theme(plot.title = element_text(size = 36, hjust = 0.5)) +
        theme(axis.title = element_text(size = 24)) +
        theme(axis.text = element_text(size = 20))

    ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)


    # Remove outliers
    outliers <- boxplot(tail(rmsd.all, 0.9 * length(rmsd.all[[colname]])), plot = FALSE)$out
    if (length(outliers) != 0) {
        rmsd.trim[[i]] <- rmsd.all[-which(rmsd.all[[colname]] %in% outliers),]
    } else {
        rmsd.trim[[i]] <- rmsd.all
    }
    rmsd.trim[[i]][1,]$frame <- min(rmsd.all$frame)


    # Plot rmsd graph without outliers
    out.name <- str_replace(out.name, '.png', '_trim.png')

    cat("Ploting selection", colname, "rmsd graph without outliers.\n")
    plot <- ggplot(rmsd.trim[[i]], aes_string(x = "frame", y = colname, group = 1)) +
        geom_line(color = "#bfbfbf") +
        geom_smooth(color = "#000033", size = 2) +
        labs(title = plot.title, x = "Frame", y = "RMSD Value") +
        scale_x_continuous(labels = scales::comma_format()) +
        theme_minimal() +
        theme(text = element_text(family = "Times New Roman")) +
        theme(plot.title = element_text(size = 36, hjust = 0.5)) +
        theme(axis.title = element_text(size = 24)) +
        theme(axis.text = element_text(size = 20))

    ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
}


# Plot with compare stats
if (args[3] != "False") {
    source(args[3])
    do.call(plot_compare_rmsd_stats, list(rmsd.all, rmsd.trim, args))
}


# Finnish
cat("Done rmsd.\n")
rm(rmsd.all)
rm(rmsd.trim)


# Load residue rmsd
file.name <- paste0(out.path, name, "_residue_rmsd.csv")
if (!file.exists(file.name)) {
    stop("Missing file ", file.name)
}

rmsd.table <- read.table(file.name,
                         header = TRUE,
                         sep = ";",
                         dec = ".",
)


# Format table
rmsd.table$X <- NULL
residues <- str_replace_all(names(rmsd.table), "X", "")
residues <- as.numeric(residues)
rows <- nrow(rmsd.table)


# Create stats table
rmsd.stats.type <- c("total", "first", "middle", "last")
rmsd.stats <- setNames(data.table(matrix(ncol = 5, nrow = length(residues))), c("residue", rmsd.stats.type))
rmsd.stats$residue <- residues


# Take measures for stat table
stat_i <- 1
for (r in residues) {
    table_i <- paste0("X", r)
    rmsd.stats$total[stat_i] = sd(rmsd.table[, table_i])
    rmsd.stats$first[stat_i] = sd(rmsd.table[, table_i][1:(rows / 3)])
    rmsd.stats$middle[stat_i] = sd(rmsd.table[, table_i][((rows / 3)):(2 * rows / 3)])
    rmsd.stats$last[stat_i] = sd(rmsd.table[, table_i][((2 * rows / 3)):rows])
    stat_i <- stat_i + 1
}


# Get catalytic site measures
if (nrow(catalytic) != 0) {
    catalytic.stats <- data.frame(frame = seq_along(rmsd.table[[1]]))

    for (r in catalytic$resi) {
        catalytic.residue <- paste0("X", r)
        if (catalytic.residue %in% colnames(rmsd.table)) {
            catalytic.stats[r] <- rmsd.table[, catalytic.residue]
        }
    }
}

rm(rmsd.table)


# Detect chain splits
distance <- 1
chains.sep <- NULL
residue_ind <- 0
while (length(chains.sep) != length(chain.names) - 1) {
    residue_ind <- 0
    previous <- residues[1]
    chains.sep <- NULL

    for (now in (residues)) {
        if (abs(previous - now) > distance || previous > now) {
            chains.sep <- c(chains.sep, residue_ind)
            residue_ind <- 0
        } else {
            residue_ind <- residue_ind + 1
        }
        previous <- now
    }
    distance <- distance + 1

    if (distance == 1001) {
        warning("Could not split rediues in chains. Using single chain!")
        break
    }
}


# Split residues acccording to chains
chain.number <- 1
residue.chains <- NULL
for (i in chains.sep) {
    residue.chains <- c(residue.chains, rep(chain.number, i))
    chain.number <- chain.number + 1
}
residue.chains <- c(residue.chains, rep(chain.number, (residue_ind + 1)))


# Split stat in chains
chains.stat <- if (chain.number > 1) split(rmsd.stats, residue.chains) else list(rmsd.stats)


# Create names for plot
axis.names <- c("Residue", "Total", "Initial", "Middle", "Final")


# Create data for catalytic labels
catalytic.data <- list()
VectorIntersect <- function(v, z) {
    unlist(lapply(unique(v[v %in% z]), function(x) rep(x, min(sum(v == x), sum(z == x)))))
}
is.contained <- function(v, z) { length(VectorIntersect(v, z)) == length(v) }

for (i in seq_along(chains.stat)) {
    if (is.contained(catalytic$resi, chains.stat[[i]]$residue)) {
        catalytic.data[[i]] <- chains.stat[[i]][chains.stat[[i]]$residue %in% catalytic$resi]
    } else {
        catalytic.data[[i]] <- chains.stat[[i]][NA,]
    }

    catalytic.data[[i]]$label <- with(catalytic.data[[i]], paste0(residue, '\n', catalytic$resn[match(catalytic.data[[i]]$residue, catalytic$resi)]))
    catalytic.data[[i]]$label <- gsub("\nNA", "", catalytic.data[[i]]$label)
}


# For each chain
rmsf.chain.sd <- list()
colors.steps <- c("first" = 'green', "middle" = 'blue', "last" = 'red')
for (i in seq_along(chains.stat)) {

    steps.min_max <- c(+Inf, -Inf)
    for (col_step in c("first", "middle", "last")) {
        range <- range(chains.stat[[i]][[col_step]])
        if (range[2] > steps.min_max[2]) {
            steps.min_max[2] <- range[2]
        }
        if (range[1] - range[2] * 0.06 < steps.min_max[1]) {
            steps.min_max[1] <- range[1] - range[2] * 0.06
        }
    }

    # For each stat
    for (j in 2:ncol(chains.stat[[i]])) {
        colname <- colnames(chains.stat[[i]])[j]

        min_y_value <- min(chains.stat[[i]][[colname]])
        max_y_value <- max(chains.stat[[i]][[colname]])

        # Plot stat graphs
        png.name <- paste0("_rmsf_chain_", i, "_", colname, ".png")
        out.name <- paste0(out.path, name, png.name)

        cat("Ploting", colname, "for chain", i, '\n')
        plot <- ggplot(chains.stat[[i]], aes_string(x = "residue", y = colname, group = 1)) +
            geom_line(color = if (is.na(colors.steps[colname][[1]])) "#000033" else colors.steps[colname][[1]], size = 1) +
            geom_text(data = catalytic.data[[i]], aes_string(x = "residue", y = min_y_value - max_y_value * 0.05, label = "label"), color = "#b30000", size = 5, lineheight = .7) +
            geom_segment(data = catalytic.data[[i]], aes_string(x = "residue", xend = "residue", y = min_y_value - max_y_value * 0.01, yend = colname), color = "#b30000", size = 0.9, linetype = "dashed") +
            scale_x_continuous(breaks = if (length(chains.stat[[i]]$residue) < 5) unique(chains.stat[[i]]$residue) else breaks_pretty()) +
            scale_y_continuous(limits = if (j >= 4) steps.min_max else NULL) +
            labs(title = paste("Chain", i, "RMSF", axis.names[j]), x = "Residue", y = axis.names[j]) +
            theme_minimal() +
            theme(text = element_text(family = "Times New Roman")) +
            theme(plot.title = element_text(size = 36, hjust = 0.5)) +
            theme(axis.title = element_text(size = 24)) +
            theme(axis.text = element_text(size = 20))
        ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
    }


    # Resolve SD steps
    rmsf.chain.sd[[i]] <- select(chains.stat[[i]], residue, first, middle, last)
    rmsf.chain.sd[[i]] <- gather(rmsf.chain.sd[[i]], sd, value, -residue)
    rmsf.chain.sd[[i]]$sd <- factor(rmsf.chain.sd[[i]]$sd, levels = c("first", "middle", "last"))


    # Plot SD steps graphs
    png.name <- paste0("_rmsf_chain_", i, "_steps.png")
    out.name <- paste0(out.path, name, png.name)

    min_y_value <- min(rmsf.chain.sd[[i]]$value)
    max_y_value <- max(rmsf.chain.sd[[i]]$value)

    cat("Ploting standard deviation for chain", i, '\n')
    plot <- ggplot(rmsf.chain.sd[[i]], aes_string(x = "residue", y = "value")) +
        geom_line(aes_string(color = 'sd', group = "sd")) +
        geom_text(data = catalytic.data[[i]], aes_string(x = "residue", y = min_y_value - max_y_value * 0.05, label = "label"), color = "#b30000", size = 5, lineheight = .7) +
        geom_segment(data = catalytic.data[[i]], aes_string(x = "residue", xend = "residue", y = min_y_value - max_y_value * 0.01, yend = colname), color = "#b30000", size = 0.9, linetype = "dashed") +
        scale_x_continuous(breaks = if (length(chains.stat[[i]]$residue) < 5) unique(chains.stat[[i]]$residue) else breaks_pretty()) +
        labs(title = paste("Chain", i, "RMSF Steps"), x = "Residue", y = "Standard Deviation") +
        theme_minimal() +
        theme(text = element_text(family = "Times New Roman")) +
        theme(plot.title = element_text(size = 36, hjust = 0.5)) +
        theme(axis.title = element_text(size = 24), axis.text = element_text(size = 20)) +
        theme(legend.text = element_text(size = 20), legend.position = "top", legend.title = element_blank()) +
        scale_color_manual(labels = c("Initial", "Middle", "Final"), values = c("green", "blue", "red"))

    ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
}


# Plot catalytic site rmsd
if (nrow(catalytic) != 0) {
    color.list <- c('#ff0000', '#cccc00', '#660066', '#4d2600', '#00b300', '#003366', '#003300', '#990033')
    while (length(catalytic$resi) > length(color.list)) {
        color.list <- append(color.list, sample(rainbow(20), 1))
    }
    colors <- setNames(color.list, gsub("\nNA", "", paste0(catalytic$resi, '\n', catalytic$resn)))

    out.name <- paste0(out.path, name, "_catalytic_rmsd.png")

    cat("Ploting catalytic site.\n")
    plot <- ggplot(catalytic.stats, aes(x = frame)) +
        labs(title = 'Catalytic site RMSD', x = "Frame", y = "RMSD Value") +
        scale_x_continuous(labels = scales::comma_format()) +
        theme_minimal() +
        theme(text = element_text(family = "Times New Roman")) +
        theme(plot.title = element_text(size = 36, hjust = 0.5)) +
        theme(axis.title = element_text(size = 24)) +
        theme(axis.text = element_text(size = 20)) +
        theme(legend.text = element_text(size = 15), legend.key.size = unit(1.3, "cm")) +
        theme(legend.title = element_text(size = 15, family = "Times New Roman")) +
        scale_color_manual("Catalytic residues", values = colors)


    for (resi in catalytic$resi) {
        plot <- plot + geom_smooth(aes_(y = as.name(resi), color = gsub("\nNA", "", paste0(resi, '\n', catalytic$resn[match(resi, catalytic$resi)]))), size = 1, se = FALSE)
    }

    ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)

    out.name <- paste0(out.path, name, "_catalytic_rmsd_trim.png")

    cat("Ploting catalytic site without outliers.\n")
    plot <- ggplot(catalytic.stats, aes(x = frame)) +
        labs(title = 'Catalytic site RMSD', x = "Frame", y = "RMSD Value") +
        scale_x_continuous(labels = scales::comma_format()) +
        theme_minimal() +
        theme(text = element_text(family = "Times New Roman")) +
        theme(plot.title = element_text(size = 36, hjust = 0.5)) +
        theme(axis.title = element_text(size = 24)) +
        theme(axis.text = element_text(size = 20)) +
        theme(legend.text = element_text(size = 15), legend.key.size = unit(1.3, "cm")) +
        theme(legend.title = element_text(size = 15, family = "Times New Roman")) +
        scale_color_manual("Catalytic residues", values = colors)


    for (resi in catalytic$resi) {
        # Remove outliers
        outliers <- boxplot(catalytic.stats[[resi]], plot = FALSE)$out
        if (length(outliers) != 0) {
            catalytic.stats.trim <- catalytic.stats[-which(catalytic.stats[[resi]] %in% outliers),]
        } else {
            catalytic.stats.trim <- catalytic.stats
        }
        catalytic.stats.trim[1,]$frame <- min(catalytic.stats$frame)

        plot <- plot + geom_smooth(data = catalytic.stats.trim, aes_(y = as.name(resi), color = gsub("\nNA", "", paste0(resi, '\n', catalytic$resn[match(resi, catalytic$resi)]))), size = 1, se = FALSE)
    }

    ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
}


# Plot with compare stats
if (args[3] != "False") {
    do.call(plot_compare_rmsf_stats, list(chains.stat, args))
}
cat("Done.\n\n")
