library(tidyr)
library(dplyr)
library(ggplot2)
library(extrafont)
library(scales)

# Plot all rmsd
rmsd.all <- read.table("rmsd.csv", 
                         header = TRUE,
                         sep = ";",
                         dec = ",",
)

colnames(rmsd.all) = c("Frame", "RMSD")
rmsd.all$Frame = c(1:199999)

png("rmsd_frames.png", width = 350, height = 150, units='mm', res = 300)
print({
  ggplot(rmsd.all, aes(x=Frame, y=RMSD, group = 1))+ 
    geom_line(color="#000033") +
    labs(title="RMSD",x="Frame", y ="RMSD Value")+
    theme_minimal() +
    theme(text = element_text(family="Times New Roman")) +
    theme(plot.title = element_text(size = 36, hjust = 0.5)) +
    theme(axis.title = element_text(size = 24))+
    theme(axis.text = element_text(size = 20))
})
dev.off()  


# Plot rmsf measures
axis.names <- c("Residue", "Mean", "SD Total", "SD Initial", "SD Middle", "SD Final")

for (i in 1:chain) {
  rmsf.chain <- read.table(paste("rmsf_chain",i,".csv", sep=''), 
                           header = TRUE,
                           sep = ";",
                           dec = ",",
  )

  for (j in 2:ncol(rmsf.chain)) {
    colname <- colnames(rmsf.chain)[j]
    file.name <- paste("rmsf_chain", i, "_", colname, ".png", sep="")
    
    png(file.name, width = 350, height = 150, units='mm', res = 300)
    print({
      ggplot(rmsf.chain, aes_string(x="residue", y=colname, group = 1))+
        geom_line(color="#000033") +
        labs(title=paste("RMSD", axis.names[j]),x="Residue", y = axis.names[j])+
        scale_x_continuous(breaks= pretty_breaks()) +
        theme_minimal() +
        theme(text = element_text(family="Times New Roman")) +
        theme(plot.title = element_text(size = 36, hjust = 0.5)) +
        theme(axis.title = element_text(size = 24))+
        theme(axis.text = element_text(size = 20))
    })
    dev.off()
    
  }
  
  
  # Plot SD steps
  file.name <- paste("rmsf_chain", i, "_sdCompare.png", sep="")
  
  rmsf.chain.sd <- select(rmsf.chain, residue, sd_first, sd_middle, sd_last)
  rmsf.chain.sd <- gather(rmsf.chain.sd, sd, value, -residue)
  rmsf.chain.sd$sd <- factor(rmsf.chain.sd$sd, levels = c("sd_first", "sd_middle", "sd_last"))
  
  png(file.name, width = 350, height = 150, units='mm', res = 300)
  print({
    ggplot(rmsf.chain.sd, aes_string(x="residue", y="value", group ="sd"))+
      geom_line(aes(color=sd)) +
      labs(title=paste("RMSD", axis.names[j]),x="Residue", y = axis.names[j]) +
      scale_x_continuous(breaks= pretty_breaks()) +  
      theme_minimal() +
      theme(text = element_text(family="Times New Roman")) +
      theme(plot.title = element_text(size = 36, hjust = 0.5)) +
      theme(axis.title = element_text(size = 24), axis.text = element_text(size = 20)) +
      theme(legend.text = element_text(size = 20), legend.position="top", legend.title=element_blank()) + 
      scale_color_manual(labels=c("Initial","Middle","Final"), values=c("green","blue","red"))
  })
  dev.off()
  
}



