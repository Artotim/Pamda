dir.create(Sys.getenv("R_LIBS_USER"), recursive = TRUE)  # create personal library
.libPaths(Sys.getenv("R_LIBS_USER"))  # add to the path
if (!require('ggplot2')) install.packages('ggplot2', lib = Sys.getenv("R_LIBS_USER"), repos = "https://cloud.r-project.org/"); library('ggplot2')
if (!require('scales')) install.packages('scales', lib = Sys.getenv("R_LIBS_USER"), repos = "https://cloud.r-project.org/"); library('scales')
if (!require('extrafont')) {
    library('extrafont')
    font_import(prompt = FALSE)
    loadfonts()
}
library('ggplot2')
library('stringr')
library('extrafont')
library('scales')


set_frame_breaks <- function(original_func, data_range) {
    function(x) {
        original_result <- original_func(x)
        original_result <- c(data_range[1], head(tail(original_result, -2), -2), data_range[2])
    }
}


# Resolve file names
args <- commandArgs(trailingOnly = TRUE)

csv.out.path <- paste0(args[1], "sasa/")
plot.out.path <- paste0(args[1], "graphs/sasa/")
name <- args[2]


# Load SASA file
file.name <- paste0(csv.out.path, name, "_all_sasa.csv")
if (!file.exists(file.name)) {
    stop("Missing file ", file.name)
}


sasa.all <- read.table(file.name,
                       header = TRUE,
                       sep = ";",
                       dec = ".",
)


# Check for SASA hgl file
file.name <- paste0(csv.out.path, name, "_hgl_sasa.csv")
if (file.exists(file.name)) {

    sasa.hgl <- read.table(file.name,
                           header = TRUE,
                           sep = ";",
                           dec = ".",
    )

    sasa.all <- merge(x = sasa.all, y = sasa.hgl, by = "frame")
    rm(sasa.hgl)
}


# Create colors for legend
colors.list <- c("SASA" = "#F67451", "BSA" = "#A838A8")


# Create plots for each selection
for (i in 2:ncol(sasa.all)) {

    if ((i %% 2) != 0) next

    sasa_colname <- colnames(sasa.all)[i]
    bsa_colname <- colnames(sasa.all)[i + 1]

    sel_name <- str_replace(str_replace(sasa_colname, "SASA_", ""), "\\.", ":")
    plot.title <- paste(str_to_title(str_replace_all(sel_name, "_", " ")), "SASA and BSA")

    png.name <- paste0("_", str_replace_all(sel_name, ":", ""), "_sasa_bsa_area.png")
    out.name <- paste0(plot.out.path, name, png.name)

    cat("Ploting sasa for selection", str_replace_all(sel_name, "_", " "), ".\n")

    plot <- ggplot(sasa.all, aes(frame)) +
        geom_line(aes_string(y = sasa_colname), color = "#bfbfbf") +
        geom_smooth(aes_(y = sasa.all[[sasa_colname]], color = "SASA"), size = 2, se = FALSE, span = 0.2) +
        geom_line(aes_string(y = bsa_colname), color = "#bfbfbf") +
        geom_smooth(aes_(y = sasa.all[[bsa_colname]], color = "BSA"), size = 2, se = FALSE, span = 0.2) +
        labs(title = paste(plot.title, "Area"), x = "Frame", y = "Area in Å") +
        scale_x_continuous(breaks = set_frame_breaks(breaks_pretty(), range(sasa.all$frame)), labels = scales::comma_format()) +
        theme_minimal() +
        theme(text = element_text(family = "Times New Roman")) +
        theme(plot.title = element_text(size = 32, hjust = 0.5)) +
        theme(axis.title = element_text(size = 24)) +
        theme(axis.text = element_text(size = 22)) +
        theme(legend.text = element_text(size = 16), legend.key.size = unit(1.1, "cm"), legend.text.align = .5) +
        theme(legend.title = element_blank()) +
        scale_color_manual(values = colors.list)

    ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)


    # Calculate percentage to plot
    total_area <- rowSums(sasa.all[i:(i + 1)])
    sasa.percentage <- data.frame(
        SASA = sasa.all[[sasa_colname]] / total_area,
        BSA = sasa.all[[bsa_colname]] / total_area
    )

    png.name <- paste0("_", str_replace_all(sel_name, ":", ""), "_sasa_bsa_percentage.png")
    out.name <- paste0(plot.out.path, name, png.name)

    plot <- ggplot(sasa.percentage, aes(x = sasa.all$frame)) +
        geom_line(aes(y = SASA), color = "#bfbfbf") +
        geom_smooth(aes(y = SASA, color = "SASA"), size = 2, se = FALSE, span = 0.2) +
        geom_line(aes(y = BSA), color = "#bfbfbf") +
        geom_smooth(aes(y = BSA, color = "BSA"), size = 2, se = FALSE, span = 0.2) +
        labs(title = paste(plot.title, "Percentage"), x = "Frame", y = "Area in percentage") +
        scale_x_continuous(breaks = set_frame_breaks(breaks_pretty(), range(sasa.all$frame)), labels = scales::comma_format()) +
        scale_y_continuous(limits = c(-0.009, 1.009), labels = label_percent()) +
        theme_minimal() +
        theme(text = element_text(family = "Times New Roman")) +
        theme(plot.title = element_text(size = 32, hjust = 0.5)) +
        theme(axis.title = element_text(size = 24)) +
        theme(axis.text = element_text(size = 22)) +
        theme(legend.text = element_text(size = 16), legend.key.size = unit(1.1, "cm"), legend.text.align = .5) +
        theme(legend.title = element_blank()) +
        scale_color_manual(values = colors.list)

    ggsave(out.name, plot, width = 350, height = 150, units = 'mm', dpi = 320, limitsize = FALSE)
}


cat("Done.\n")
