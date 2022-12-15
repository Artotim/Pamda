dir.create(Sys.getenv("R_LIBS_USER"), recursive = TRUE)  # create personal library
.libPaths(Sys.getenv("R_LIBS_USER"))  # add to the path
if (!require('ggplot2')) install.packages('ggplot2', lib = Sys.getenv("R_LIBS_USER"), repos = "https://cloud.r-project.org/"); library('ggplot2')
if (!require('tidyr')) install.packages('tidyr', lib = Sys.getenv("R_LIBS_USER"), repos = "https://cloud.r-project.org/"); library('tidyr')
if (!require('tidyverse')) install.packages('tidyverse', lib = Sys.getenv("R_LIBS_USER"), repos = "https://cloud.r-project.org/"); library('tidyverse')
if (!require('stringr')) install.packages('stringr', lib = Sys.getenv("R_LIBS_USER"), repos = "https://cloud.r-project.org/"); library('stringr')
if (!require('extrafont')) {
    install.packages('extrafont', lib = Sys.getenv("R_LIBS_USER"), repos = "https://cloud.r-project.org/")
    library('extrafont')
    font_import(prompt = FALSE)
    loadfonts()
}
library('ggplot2')
library('tidyr')
library('tidyverse')
library('stringr')
library('extrafont')


# Resolve file names
args <- commandArgs(trailingOnly = TRUE)

csv.out.path <- paste0(args[1], "contacts/")
plot.out.path <- paste0(args[1], "graphs/contacts/")
name <- args[2]


# Resolve highlight residues
highlight <- data.frame(
    resn = str_replace_all(str_extract(tail(args, -2), ":[aA-zZ]+:"), ":", ""),
    resi = str_extract(tail(args, -2), "[0-9]+"),
    chain = str_extract(tail(args, -2), "^[aA-zZ]+"))


# Load contact map
file.name <- paste0(csv.out.path, name, "_contacts_map.csv")
if (!file.exists(file.name)) {
    stop("Missing file ", file.name)
}

contacts.map <- read.table(file.name,
                           header = TRUE,
                           sep = ";",
                           dec = ".",
)


# Organize chains in same columns
chains <- unique(c(as.character(contacts.map[[6]]), as.character(contacts.map[[11]])))

if (grepl("nonbond", name, fixed = TRUE)) {
    contacts.map.ordered <- contacts.map
} else {
    contacts.map.ordered <- contacts.map[FALSE,]
    for (row_idx in 1:nrow(contacts.map)) {
        row <- contacts.map[row_idx,]
        if (contacts.map[row_idx,][6] != chains[1]) {
            row[2:6] <- contacts.map[row_idx,][7:11]
            row[7:11] <- contacts.map[row_idx,][2:6]
        }

        contacts.map.ordered <- rbind(contacts.map.ordered, row)
    }
}
rm(contacts.map)


# Define main chain by size
if (max(contacts.map.ordered[4]) - min(contacts.map.ordered[4]) >= max(contacts.map.ordered[9]) - min(contacts.map.ordered[9])) {
    chain1_idx <- 4
    chain2_idx <- 9
} else {
    chain1_idx <- 9
    chain2_idx <- 4
}


# Get contacting residues
chain1_resid <- colnames(contacts.map.ordered)[chain1_idx]
chain2_resid <- colnames(contacts.map.ordered)[chain2_idx]
contact.residues <- contacts.map.ordered[c("frame", chain1_resid, chain2_resid)]


# Set count equal to 1 per frame for saline bridges
if (grepl("sbridges", name, fixed = TRUE)) {
    contact.residues <- unique(contact.residues)
}


# Get chain residues length
chain1_first <- min(contact.residues[chain1_resid])
chain1_last <- max(contact.residues[chain1_resid])
chain1_length <- length(chain1_first:chain1_last)
chain1_name <- as.character(contacts.map.ordered[chain1_idx + 2][1,])

chain2_first <- min(contact.residues[chain2_resid])
chain2_last <- max(contact.residues[chain2_resid])
chain2_length <- length(chain2_first:chain2_last)
chain2_name <- as.character(contacts.map.ordered[chain2_idx + 2][1,])


# Create matrix for residue contact
contact.all.hits <- data.frame(matrix(0L, nrow = chain1_length, ncol = chain2_length))
rownames(contact.all.hits) <- as.character(chain1_first:chain1_last)
colnames(contact.all.hits) <- as.character(chain2_first:chain2_last)

for (line in seq_len(nrow(contact.residues))) {
    row <- as.character(contact.residues[line, chain1_resid])
    col <- as.character(contact.residues[line, chain2_resid])

    contact.all.hits[row, col] <- contact.all.hits[row, col] + 1
}


# Transform matrix
contact.all.hits <- contact.all.hits %>%
    as.data.frame() %>%
    rownames_to_column("chain1") %>%
    pivot_longer(-chain1, names_to = "chain2", values_to = "count") %>%
    mutate(chain2 = fct_relevel(chain2, colnames(contact.all.hits)))
colnames(contact.all.hits) <- c(chain1_name, chain2_name, "count")


# Get subset with matchs
all.subset <- contact.all.hits[!(contact.all.hits$count == 0),]


# Create data for highlight labels
highlight <- highlight[which(highlight$chain == chain1_name),]
highlight <- if (nrow(highlight) != 0) highlight else data.frame(resn = NaN, resi = NaN, chain = NaN)

for (i in highlight$resi) {
    if (!(i %in% all.subset[[chain1_name]]) && !is.na(i)) {
        append.resi <- data.frame(chain1 = i, chain2 = chain2_first, count = 0)
        colnames(append.resi) <- colnames(all.subset)
        all.subset <- rbind(all.subset, append.resi)
    }
}

highlight$label <- with(highlight, paste0(resi, '\n', resn))
highlight$label <- gsub("\nNA", "", highlight$label)

all.subset[[chain1_name]] <- ordered(all.subset[[chain1_name]], levels = str_sort(unique(all.subset[[chain1_name]]), numeric = TRUE))
all.subset$count[all.subset$count == 0] <- NA


# Get chain1 labels
chain1_labels <- unique(str_sort(all.subset[[chain1_name]], numeric = TRUE))
if (length(chain1_labels) > 40) {
    chain1_labels[c(FALSE, TRUE)] <- ""
}


# Get chain2 labels info
if (length(unique(contact.residues[[chain2_resid]])) <= 20) {
    chain2_residues <- ''
    for (i in unique(str_sort(all.subset[[chain2_name]], numeric = TRUE))) {
        resid <- as.character(contacts.map.ordered[[10]][match(i, contact.residues[[chain2_resid]])])
        chain2_residues <- paste0(chain2_residues, i, "\n", resid, " ")
    }
    chain2_labels <- str_split(chain2_residues, " ")
} else {
    chain2_labels <- unique(str_sort(all.subset[[chain2_name]], numeric = TRUE))
}
chain2_contacts_len <- length(unique(all.subset[[chain2_name]]))


# Get interactions name for plot titles
interaction.name <- paste(str_replace(tail(str_split(name, '_')[[1]], 2), "_", " "), collapse = " ")
interaction.name <- str_replace(interaction.name, 'nonbond', "Non-bonded")
interaction.name <- str_replace(interaction.name, 'hbonds', "Hydrogen Bonds")
interaction.name <- str_replace(interaction.name, 'sbridges', "Salt Bridges")


# Plot all graph
out.name <- paste0(plot.out.path, name, "_contacts_map.png")

cat("Ploting", interaction.name, "contact map.\n")
plot <- ggplot(all.subset, aes_string(chain2_name, chain1_name)) +
    geom_raster(aes(fill = count)) +
    geom_hline(yintercept = highlight$resi, color = "#b30000", size = 0.7, linetype = "dashed") +
    geom_text(data = highlight, aes_string(x = chain2_contacts_len + 0.7, y = "resi", label = "label"), color = "#b30000", size = 3.3, lineheight = 1) +
    geom_vline(xintercept = seq(1.5, chain2_contacts_len - 0.5, 1), lwd = 0.5, colour = "black") +
    scale_fill_gradient(low = "white", high = "red", limits = c(0, max(all.subset$count)), na.value = "transparent") +
    scale_y_discrete(breaks = unique(str_sort(all.subset[[chain1_name]], numeric = TRUE)), labels = chain1_labels) +
    scale_x_discrete(breaks = unique(str_sort(all.subset[[chain2_name]], numeric = TRUE)), labels = chain2_labels) +
    labs(title = paste("Chains", interaction.name, "Map"), x = paste("Chain", chain2_name, "residues"), y = paste("Chain", chain1_name, "residues")) +
    coord_cartesian(clip = 'off') +
    theme_minimal() +
    theme(text = element_text(family = "Times New Roman")) +
    theme(plot.title = element_text(size = 32, hjust = 0.5)) +
    theme(axis.title = element_text(size = 24)) +
    theme(axis.text.x = element_text(size = 16), axis.text.y = element_text(size = 14)) +
    theme(panel.grid.major.x = element_blank()) +
    theme(legend.title = element_text(size = 16), legend.text = element_text(size = 14)) +
    labs(fill = "Contacts No. \nin Trajectory")

ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)


# Function to get frame ranges per step

get_step_range <- function(step, first_frame, last_frame, frame_range) {
    if (first_frame == 1) first_frame <- 0
    range_init <- (step - 1) * frame_range + first_frame
    if (step > 1 || (step == 1 && first_frame == 0)) range_init <- range_init + 1
    range_end <- step * frame_range + first_frame
    if (range_end > last_frame) range_end <- last_frame

    return(c(range_init, range_end))
}


# Resolve step number
first_frame <- min(contact.residues$frame)
last_frame <- max(contact.residues$frame)
frames <- last_frame - first_frame
frame_range <- ceiling(frames / 10)


# Create matrix for residue contact every step
contact.hits <- list()
for (i in 1:10) {
    cat("Preparing step", i, '\n')

    step_range <- get_step_range(i, first_frame, last_frame, frame_range)
    step.contact <- subset(contact.residues, frame >= step_range[1] & frame <= step_range[2])

    step.frame <- data.frame(matrix(0L, nrow = chain1_length, ncol = chain2_length))
    rownames(step.frame) <- as.character(chain1_first:chain1_last)
    colnames(step.frame) <- as.character(chain2_first:chain2_last)

    for (line in seq_len(nrow(step.contact))) {
        row <- as.character(step.contact[line, chain1_resid])
        col <- as.character(step.contact[line, chain2_resid])

        step.frame[row, col] <- step.frame[row, col] + 1
    }

    contact.hits[[i]] <- step.frame
}


# Transform every matrix
max.range <- c(0, 0)
for (i in seq_along(contact.hits)) {
    contact.hits[[i]] <- contact.hits[[i]] %>%
        as.data.frame() %>%
        rownames_to_column("chain1") %>%
        pivot_longer(-chain1, names_to = "chain2", values_to = "count") %>%
        mutate(chain2 = fct_relevel(chain2, colnames(contact.hits[[i]])))
    colnames(contact.hits[[i]]) <- c(chain1_name, chain2_name, "count")

    # Resolve range for scale maps
    range <- range(contact.hits[[i]]$count)
    if (range[2] > max.range[2]) {
        max.range[2] <- range[2]
    }
}


# Plot graph
for (i in seq_along(contact.hits)) {

    # Prepare step subset
    step.subset <- contact.hits[[i]][!(contact.hits[[i]]$count == 0),]
    step.subset$count[step.subset$count == 0] <- NA

    for (res in append(as.character(highlight$resi), as.character(unique(all.subset[[chain1_name]])))) {
        if (!(res %in% step.subset[[chain1_name]]) && !is.na(res)) {
            append.resi <- data.frame(chain1 = res, chain2 = chain2_first, count = 0)
            colnames(append.resi) <- colnames(all.subset)
            step.subset <- rbind(step.subset, append.resi)
        }
    }
    for (res in as.character(unique(all.subset[[chain2_name]]))) {
        if (!(res %in% step.subset[[chain2_name]])) {
            append.resi <- data.frame(chain1 = chain1_first, chain2 = res, count = 0)
            colnames(append.resi) <- colnames(all.subset)
            step.subset <- rbind(step.subset, append.resi)
        }
    }

    #Define plot name and title
    png.name <- paste0("_contacts_map_step_", sprintf("%02d", i), ".png")
    out.name <- paste0(plot.out.path, name, png.name)

    step_range <- get_step_range(i, first_frame, last_frame, frame_range)

    plot.title.prefix <- paste("Chains", interaction.name, "Map\nFrames: ")
    if (step_range[2] >= 1000) {
        plot.title <- paste0(plot.title.prefix, round(step_range[1] / 1000, 1), "-", round(step_range[2] / 1000, 1), 'k')
    } else {
        plot.title <- paste0(plot.title.prefix, step_range[1], "-", step_range[2])
    }

    cat("Ploting", interaction.name, "contact map for step", i, '\n')
    plot <- ggplot(step.subset, aes_string(chain2_name, chain1_name)) +
        geom_raster(aes(fill = count)) +
        geom_hline(yintercept = highlight$resi, color = "#b30000", size = 0.7, linetype = "dashed") +
        geom_text(data = highlight, aes_string(x = chain2_contacts_len + 0.7, y = "resi", label = "label"), color = "#b30000", size = 3.3, lineheight = 1) +
        geom_vline(xintercept = seq(1.5, chain2_contacts_len - 0.5, 1), lwd = 0.5, colour = "black") +
        scale_fill_gradient(low = "white", high = "red", limits = max.range, na.value = "transparent") +
        scale_y_discrete(breaks = unique(str_sort(all.subset[[chain1_name]], numeric = TRUE)), labels = chain1_labels) +
        scale_x_discrete(breaks = unique(str_sort(all.subset[[chain2_name]], numeric = TRUE)), labels = chain2_labels) +
        labs(title = plot.title, x = paste("Chain", chain2_name, "residues"), y = paste("Chain", chain1_name, "residues")) +
        coord_cartesian(clip = 'off') +
        theme_minimal() +
        theme(text = element_text(family = "Times New Roman")) +
        theme(plot.title = element_text(size = 28, hjust = 0.5)) +
        theme(axis.title = element_text(size = 24)) +
        theme(axis.text.x = element_text(size = 20), axis.text.y = element_text(size = 12)) +
        theme(panel.grid.major.x = element_blank()) +
        theme(plot.background = element_rect(fill = 'white', colour = 'white')) +
        theme(legend.title = element_text(size = 16), legend.text = element_text(size = 14)) +
        labs(fill = "Contacts No. \nin Range")

    ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
}


cat("Done.\n\n")
