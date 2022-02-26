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


plot_compare_rmsd_stats <- function(rmsd.all, rmsd.trim, args) {

    # Resolve file names
    out.path <- args[1]
    out.path <- paste0(out.path, "rmsd/")

    name <- args[2]

    compare.path <- args[4]


    # Load all rmsd
    file.name <- compare.path
    if (!file.exists(file.name)) {
        stop("Missing file ", file.name)
    }

    rmsd.compare.all <- read.table(file.name,
                                 header = TRUE,
                                 sep = ";",
                                 dec = ".",
    )

    # Get chains
    compare.chain.names <- tail(colnames(rmsd.compare.all), -2)


    # Loop through table
    rmsd.compare.trim <- list()
    colors <- c('compare' = '#ccccff', 'Docked' = '#00004d')
    for (i in 2:ncol(rmsd.compare.all)) {
        colname <- colnames(rmsd.compare.all)[i]

        rmsd.compare.all <- rbind(rep(0, ncol(rmsd.compare.all)), rmsd.compare.all)

        # Choose file name
        if (colname %in% compare.chain.names) {
            chain.indx <- match(colname, compare.chain.names)
            png.name <- paste0("_compare_rmsd_frame_chain_", chain.indx, ".png")
            out.name <- paste0(out.path, name, png.name)
            plot.title <- paste0("RMSD chain ", colname)
        } else {
            out.name <- paste0(out.path, name, "_compare_rmsd_frame_all.png")
            plot.title <- "RMSD All"
        }


        # Plot rmsd graph
        cat("Ploting selection", colname, "rmsd graph with compare stats.\n")
        plot <- ggplot(rmsd.all, aes_string(x = "frame", y = colname, group = 1)) +
            geom_line(color = "#bfbfbf") +
            geom_smooth(data = rmsd.compare.all, aes_(y = as.name(colname), color = "compare"), size = 1.5, se = FALSE) +
            geom_smooth(aes_(color = "Docked"), size = 2, se = FALSE) +
            labs(title = plot.title, x = "Frame", y = "RMSD Value") +
            scale_x_continuous(labels = scales::comma_format()) +
            theme_minimal() +
            theme(text = element_text(family = "Times New Roman")) +
            theme(plot.title = element_text(size = 36, hjust = 0.5)) +
            theme(axis.title = element_text(size = 24)) +
            theme(axis.text = element_text(size = 20)) +
            theme(legend.text = element_text(size = 14), legend.key.size = unit(1, "cm")) +
            theme(legend.title = element_blank(), legend.key = element_rect(fill = 'white', color = 'white')) +
            scale_color_manual(values = colors, breaks = c("Docked", "compare"))

        ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)


        # Remove outliers
        outliers <- boxplot(tail(rmsd.compare.all, 0.9 * length(rmsd.compare.all[[colname]])), plot = FALSE)$out
        if (length(outliers) != 0) {
            rmsd.compare.trim[[i]] <- rmsd.compare.all[-which(rmsd.compare.all[[colname]] %in% outliers),]
        } else {
            rmsd.compare.trim[[i]] <- rmsd.compare.all
        }
        rmsd.compare.trim[[i]][1,]$frame <- min(rmsd.compare.all$frame)


        # Plot rmsd graph without outliers
        out.name <- str_replace(out.name, '.png', '_trim.png')

        cat("Ploting selection", colname, "rmsd graph without outliers and with compare stats.\n")
        plot <- ggplot(rmsd.trim[[i]], aes_string(x = "frame", y = colname, group = 1)) +
            geom_line(color = "#bfbfbf") +
            geom_smooth(data = rmsd.compare.trim[[i]], aes_(y = as.name(colname), color = "compare"), size = 1.5, se = FALSE) +
            geom_smooth(aes_(color = "Docked"), size = 2, se = FALSE) +
            labs(title = plot.title, x = "Frame", y = "RMSD Value") +
            scale_x_continuous(labels = scales::comma_format()) +
            theme_minimal() +
            theme(text = element_text(family = "Times New Roman")) +
            theme(plot.title = element_text(size = 36, hjust = 0.5)) +
            theme(axis.title = element_text(size = 24)) +
            theme(axis.text = element_text(size = 20)) +
            theme(legend.text = element_text(size = 14), legend.key.size = unit(1, "cm")) +
            theme(legend.title = element_blank(), legend.key = element_rect(fill = 'white', color = 'white')) +
            scale_color_manual(values = colors, breaks = c("Docked", "compare"))

        ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
    }
}


plot_compare_rmsf_stats <- function(chains.stat, args) {
    # Resolve file names
    out.path <- args[1]
    out.path <- paste0(out.path, "rmsd/")

    name <- args[2]

    compare.path <- args[5]

    # Resolve catalytic site
    catalytic <- data.frame(resn = str_extract(tail(args, -5), "[aA-zZ]+"), resi = str_extract(tail(args, -5), "[0-9]+"))
    catalytic <- if (dim(catalytic)[1] != 0) catalytic else data.frame(resn = NaN, resi = NaN)


    # Load residue rmsd
    file.name <- compare.path
    if (!file.exists(file.name)) {
        stop("Missing file ", file.name)
    }

    rmsd.compare.all <- read.table(args[4],
                                 header = TRUE,
                                 sep = ";",
                                 dec = ".",
    )

    # Get chains
    compare.chain.names <- tail(colnames(rmsd.compare.all), -2)
    rm(rmsd.compare.all)

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
    while (length(chains.sep) != length(compare.chain.names) - 1) {
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
    chains.compare.stat <- if (chain.number > 1) split(rmsd.stats, residue.chains) else list(rmsd.stats)


    # Create names for plot
    axis.names <- c("Residue", "Total", "Initial", "Middle", "Final")


    # For each chain
    rmsf.chain.compare.sd <- list()
    chains.compare.trim <- list()
    colors <- c('compare' = '#ccccff', 'Docked' = '#00004d')
    for (i in seq_along(chains.compare.stat)) {

        steps.min_max <- c(+Inf, -Inf)
        for (col_step in c("first", "middle", "last")) {
            outliers <- boxplot(chains.compare.stat[[i]][[col_step]], plot = FALSE)$out
            if (length(outliers) != 0) {
                range <- range(chains.compare.stat[[i]][[col_step]][!(chains.compare.stat[[i]][[col_step]] %in% outliers)])
            } else {
                range <- range(chains.compare.stat[[i]][[col_step]])
            }

            if (range[2] > steps.min_max[2]) {
                steps.min_max[2] <- range[2]
            }
            if (range[1] - range[2] * 0.06 < steps.min_max[1]) {
                steps.min_max[1] <- range[1] - range[2] * 0.06
            }
        }

        # For each stat
        for (j in 2:ncol(chains.compare.stat[[i]])) {
            colname <- colnames(chains.compare.stat[[i]])[j]


            # Plot stat graphs
            png.name <- paste0("_compare_rmsf_chain_", i, "_", colname, ".png")
            out.name <- paste0(out.path, name, png.name)

            outliers <- boxplot(chains.compare.stat[[i]][[colname]], plot = FALSE)$out
            if (length(outliers) != 0) {
                chains.compare.trim[[i]] <- chains.compare.stat[[i]][-which(chains.compare.stat[[i]][[colname]] %in% outliers),]
            } else {
                chains.compare.trim[[i]] <- chains.compare.stat[[i]]
            }


            min_y_value <- min(chains.compare.trim[[i]][[colname]])
            min_y_value <- if (min(chains.stat[[i]][[colname]]) < min_y_value) min(chains.stat[[i]][[colname]]) else min_y_value
            max_y_value <- max(chains.compare.trim[[i]][[colname]])


            cat("Ploting", colname, "for chain", i, 'with compare stats.\n')
            plot <- ggplot(chains.stat[[i]], aes_string(x = "residue", y = colname, group = 1)) +
                geom_line(data = chains.compare.trim[[i]], aes_(color = "compare"), size = 1) +
                geom_line(aes_(color = "Docked"), size = 1) +
                geom_text(data = catalytic.data[[i]], aes_string(x = "residue", y = min_y_value - max_y_value * 0.05, label = "label"), color = "#b30000", size = 5, lineheight = .7) +
                geom_segment(data = catalytic.data[[i]], aes_string(x = "residue", xend = "residue", y = min_y_value - max_y_value * 0.01, yend = colname), color = "#b30000", size = 0.9, linetype = "dashed") +
                scale_x_continuous(breaks = if (length(chains.compare.stat[[i]]$residue) < 5) unique(chains.compare.stat[[i]]$residue) else breaks_pretty()) +
                scale_y_continuous(limits = if (j >= 4) steps.min_max else NULL) +
                labs(title = paste("Chain", i, "RMSF", axis.names[j]), x = "Residue", y = axis.names[j]) +
                theme_minimal() +
                theme(text = element_text(family = "Times New Roman")) +
                theme(plot.title = element_text(size = 36, hjust = 0.5)) +
                theme(axis.title = element_text(size = 24)) +
                theme(axis.text = element_text(size = 20)) +
                theme(legend.text = element_text(size = 12), legend.key.size = unit(1, "cm")) +
                theme(legend.title = element_blank(), legend.key = element_rect(fill = 'white', color = 'white')) +
                scale_color_manual(values = colors, breaks = c("Docked", "compare"))

            ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
        }


        # Resolve SD steps
        rmsf.chain.compare.sd[[i]] <- select(chains.compare.stat[[i]], residue, first, middle, last)
        rmsf.chain.compare.sd[[i]] <- gather(rmsf.chain.compare.sd[[i]], sd, value, -residue)
        rmsf.chain.compare.sd[[i]]$sd <- factor(rmsf.chain.compare.sd[[i]]$sd, levels = c("first", "middle", "last"))

        outliers <- boxplot(rmsf.chain.compare.sd[[i]]$value, plot = FALSE)$out
        if (length(outliers) != 0) {
            rmsf.chain.compare.sd.trim <- rmsf.chain.compare.sd[[i]][-which(rmsf.chain.compare.sd[[i]]$value %in% outliers),]
        } else {
            rmsf.chain.compare.sd.trim <- rmsf.chain.compare.sd[[i]]
        }

        # Plot SD steps graphs
        png.name <- paste0("_compare_rmsf_chain_", i, "_steps.png")
        out.name <- paste0(out.path, name, png.name)

        min_y_value <- min(rmsf.chain.compare.sd.trim$value)
        max_y_value <- max(rmsf.chain.compare.sd.trim$value)

        cat("Ploting standard deviation for chain", i, 'with compare stats.\n')
        plot <- ggplot(rmsf.chain.compare.sd.trim, aes_string(x = "residue", y = "value")) +
            geom_line(aes_string(color = 'sd', group = "sd")) +
            geom_text(data = catalytic.data[[i]], aes_string(x = "residue", y = min_y_value - max_y_value * 0.05, label = "label"), color = "#b30000", size = 5, lineheight = .7) +
            geom_segment(data = catalytic.data[[i]], aes_string(x = "residue", xend = "residue", y = min_y_value - max_y_value * 0.01, yend = colname), color = "#b30000", size = 0.9, linetype = "dashed") +
            scale_x_continuous(breaks = if (length(chains.compare.stat[[i]]$residue) < 5) unique(chains.compare.stat[[i]]$residue) else breaks_pretty()) +
            labs(title = paste("Chain", i, "RMSF SD Steps"), x = "Residue", y = "Standard Deviation") +
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

        out.name <- paste0(out.path, name, "_compare_catalytic_rmsd.png")

        cat("Ploting catalytic site for compare stats.\n")
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

        out.name <- paste0(out.path, name, "_compare_catalytic_rmsd_trim.png")

        cat("Ploting catalytic site without outliers for compare stats.\n")
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
}
