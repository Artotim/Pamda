library(ggplot2)
library(extrafont)
font_import()
loadfonts(device = "win")

energy.all <- read.table("all.csv", 
                           header = TRUE,
                           sep = ";",
                           dec = ",",
)
energy.all$Time = NULL
energy.all$Frame = c(1:200000)


for (i in 2:ncol(energy.all)) {
  colname <- colnames(energy.all)[i]
  file.name <- paste("all_", colname, ".png", sep="")
  
  png(file.name, width = 350, height = 150, units='mm', res = 300)
  print({
  ggplot(energy.all, aes_string(x="Frame", y=colname, group = 1))+ 
    geom_line(color="#0072B2") +
    labs(title=paste("All", colname ,"Energy"),x="Frame", y = colname)+
    theme_minimal() +
    theme(text = element_text(family="Times New Roman")) +
    theme(plot.title = element_text(size = 36, hjust = 0.5)) +
    theme(axis.title = element_text(size = 24))+
    theme(axis.text = element_text(size = 20))
  })
  dev.off()
  
}

energy.interaction <- read.table("interaction.csv", 
                         header = TRUE,
                         sep = ";",
                         dec = ",",
)
energy.interaction$Time = NULL
energy.interaction$Frame = c(1:200000)

for (i in 2:ncol(energy.interaction)) {
  colname <- colnames(energy.interaction)[i]
  file.name <- paste("interaction_", colname, ".png", sep="")
  
  png(file.name, width = 350, height = 150, units='mm', res = 300)
  print({
    ggplot(energy.interaction, aes_string(x="Frame", y=colname, group = 1))+ 
      geom_line(color="#0072B2") +
      labs(title=paste("Interaction", colname ,"Energy"),x="Frame", y = colname)+
      theme_minimal() +
      theme(text = element_text(family="Times New Roman")) +
      theme(plot.title = element_text(size = 36, hjust = 0.5)) +
      theme(axis.title = element_text(size = 24))+
      theme(axis.text = element_text(size = 20))
  })
  dev.off()
  
}
