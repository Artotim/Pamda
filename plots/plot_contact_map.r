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
out.path <- args[1]
out.path <- paste0(out.path, "contact/")

name <- args[2]


# Resolve catalytic site
catalytic <- data.frame(resn = str_extract(tail(args, -2), "[aA-zZ]+"), resi = str_extract(tail(args, -2), "[0-9]+"))
catalytic <- if (length(catalytic != 0)) catalytic else data.frame(resn = NaN, resi = NaN)


# Load contact map
file.name <- paste0(out.path, name, "_contact_map.csv")
if (!file.exists(file.name)) {
    stop("Missing file ", file.name)
}

contacts.map <- read.table(file.name,
                           header = TRUE,
                           sep = ";",
                           dec = ".",
)


# Get contacting residues
protein <- colnames(contacts.map)[4]
peptide <- colnames(contacts.map)[8]
contact.residues <- contacts.map[c("frame", protein, peptide)]


# Get chain residues length
protein.first <- min(contact.residues[protein])
protein.last <- max(contact.residues[protein])
protein.length <- length(protein.first:protein.last)

peptide.first <- min(contact.residues[peptide])
peptide.last <- max(contact.residues[peptide])
peptide.length <- length(peptide.first:peptide.last)


# Get chains info
peptide.chain <- ''
for (i in sort(unique(contact.residues[[peptide]]))) {
    amino <- as.character(contacts.map[[9]][match(i, contact.residues[[peptide]])])
    peptide.chain <- paste0(peptide.chain, i, "\n", amino, " ")
}


# Create matrix for residue contact
contact.all.hits <- data.frame(matrix(0L, nrow = protein.length, ncol = peptide.length))
rownames(contact.all.hits) <- as.character(protein.first:protein.last)
colnames(contact.all.hits) <- as.character(peptide.first:peptide.last)

for (line in seq_len(nrow(contact.residues))) {
    row <- as.character(contact.residues[line, protein])
    col <- as.character(contact.residues[line, peptide])

    contact.all.hits[row, col] <- contact.all.hits[row, col] + 1
}


# Transform matrix
contact.all.hits <- contact.all.hits %>%
    as.data.frame() %>%
    rownames_to_column("protein") %>%
    pivot_longer(-protein, names_to = "peptide", values_to = "count") %>%
    mutate(peptide = fct_relevel(peptide, colnames(contact.all.hits)))


# Get subset with matchs
all.subset <- contact.all.hits[!(contact.all.hits$count == 0),]


# Create data for catalytic labels
for (i in catalytic$resi) {
    if (!(i %in% all.subset$protein) && !is.na(i)) {
        append.resi <- data.frame(protein = i, peptide = min(peptide.first), count = 0)
        all.subset <- rbind(all.subset, append.resi)
    }
}
catalytic$label <- with(catalytic, paste0(resi, '\n', resn))
catalytic$label <- gsub("\nNA", "", catalytic$label)


# Plot all graph
out.name <- paste0(out.path, name, "_contact_map_all.png")

cat("Ploting contact map.\n")
plot <- ggplot(all.subset, aes(peptide, protein)) +
    geom_raster(aes(fill = count)) +
    geom_hline(yintercept = catalytic$resi, color = "#b30000", size = 0.7, linetype = "dashed") +
    geom_text(data = catalytic, aes_string(x = peptide.length + 0.7, y = "resi", label = "label"), color = "#b30000", size = 4, lineheight = 1) +
    geom_vline(xintercept = seq(1.5, peptide.length - 0.5, 1), lwd = 0.5, colour = "black") +
    scale_fill_gradient(low = "white", high = "red") +
    scale_y_discrete(breaks = unique(all.subset$protein)[c(FALSE, TRUE)]) +
    scale_x_discrete(breaks = peptide.first:peptide.last, labels = str_split(peptide.chain, " ")) +
    labs(title = "Contact per residue", x = "Peptide", y = "Convertase") +
    coord_cartesian(clip = 'off') +
    theme_minimal() +
    theme(text = element_text(family = "Times New Roman")) +
    theme(plot.title = element_text(size = 36, hjust = 0.5)) +
    theme(axis.title = element_text(size = 24)) +
    theme(axis.text.x = element_text(size = 20), axis.text.y = element_text(size = 12)) +
    theme(panel.grid.major.x = element_blank()) +
    labs(fill = "Contacts #")

ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)


# Resolve step number
frames <- max(contact.residues$frame)
if (frames > 50000) {
    step <- 10000
} else if (frames > 10000) {
    step <- 5000
} else if (frames > 1000) {
    step <- 500
} else {
    step <- 100
}
iter <- frames / step


# Create matrix for residue contact every step
contact.hits <- list()
for (i in 1:iter) {
    cat("Preparing step", i, '\n')
    value <- i * step

    if (i != 1) {
        step.contact <- subset(contact.residues, frame > (value - step) & frame <= value)
    } else {
        step.contact <- subset(contact.residues, frame >= (value - step) & frame <= value)
    }

    step.frame <- data.frame(matrix(0L, nrow = protein.length, ncol = peptide.length))
    rownames(step.frame) <- as.character(protein.first:protein.last)
    colnames(step.frame) <- as.character(peptide.first:peptide.last)

    for (line in seq_len(nrow(step.contact))) {
        row <- as.character(step.contact[line, protein])
        col <- as.character(step.contact[line, peptide])

        step.frame[row, col] <- step.frame[row, col] + 1
    }

    contact.hits[[i]] <- step.frame
}


# Transform every matrix
max.range <- c(0, 0)
for (i in seq_along(contact.hits)) {
    contact.hits[[i]] <- contact.hits[[i]] %>%
        as.data.frame() %>%
        rownames_to_column("protein") %>%
        pivot_longer(-protein, names_to = "peptide", values_to = "count") %>%
        mutate(peptide = fct_relevel(peptide, colnames(contact.hits[[i]])))

    # Resolve range for scale maps
    range <- range(contact.hits[[i]]$count)
    if (range[2] > max.range[2]) {
        max.range[2] <- range[2]
    }
}


# Plot graph
for (i in seq_along(contact.hits)) {
    png.name <- paste0("_contact_map_", i - 1, "-", i, ".png")
    out.name <- paste0(out.path, name, png.name)

    plot.title <- paste0("Contact per residue ", (i - 1) * 10, "-", i * 10, "k")

    step.subset <- contact.hits[[i]][contact.hits[[i]]$protein %in% all.subset$protein,]
    step.subset$count[step.subset$count == 0] = NA

    for (res in catalytic$resi) {
        if (!(res %in% all.subset$protein) && !is.na(res)) {
            append.resi <- data.frame(protein = res, peptide = min(peptide.first), count = 0)
            step.subset <- rbind(step.subset, append.resi)
        }
    }

    cat("Ploting contact map for step", i, '\n')
    plot <- ggplot(step.subset, aes(peptide, protein)) +
        geom_raster(aes(fill = count)) +
        geom_hline(yintercept = catalytic$resi, color = "#b30000", size = 0.7, linetype = "dashed") +
        geom_text(data = catalytic, aes_string(x = peptide.length + 0.7, y = "resi", label = "label"), color = "#b30000", size = 4, lineheight = 1) +
        geom_vline(xintercept = seq(1.5, peptide.length - 0.5, 1), lwd = 0.5, colour = "black") +
        scale_fill_gradient(low = "white", high = "red", limits = max.range, na.value = "transparent") +
        scale_y_discrete(breaks = unique(all.subset$protein)[c(FALSE, TRUE)]) +
        scale_x_discrete(breaks = peptide.first:peptide.last, labels = str_split(peptide.chain, " ")) +
        labs(title = plot.title, x = "Peptide", y = "Convertase") +
        coord_cartesian(clip = 'off') +
        theme_minimal() +
        theme(text = element_text(family = "Times New Roman")) +
        theme(plot.title = element_text(size = 36, hjust = 0.5)) +
        theme(axis.title = element_text(size = 24)) +
        theme(axis.text.x = element_text(size = 20), axis.text.y = element_text(size = 12)) +
        theme(panel.grid.major.x = element_blank()) +
        labs(fill = "Contacts #")

    ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
}
cat("Done.\n\n")
