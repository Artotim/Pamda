library(ggplot2)
library(tidyr)
library(tidyverse)
library(extrafont)

#Peptide
peptide = "1\nT 2\nN 3\nS 4\nP 5\nR 6\nR 7\nA 8\nR 9\nS 10\nV"

# Load contact map
contacts.map <- read.table("contact_map.csv", 
                         header = TRUE,
                         sep = ";",
                         dec = ".",
)

# Get contacting residues
contact.residues <- select(contacts.map, frame, atom1, atom2)
contact.residues$atom1 <- as.numeric(regmatches(contact.residues$atom1, regexpr("[[:digit:]]+", contact.residues$atom1)))
contact.residues$atom2 <- as.numeric(regmatches(contact.residues$atom2, regexpr("[[:digit:]]+", contact.residues$atom2)))

# Get chain residues length
chainA.first <- min(contact.residues$atom1)
chainA.last <- max(contact.residues$atom1)
chainA.lenght <- length(c(chainA.first:chainA.last))

chainB.first <- min(contact.residues$atom2)
chainB.last <- max(contact.residues$atom2)
chainB.length <- length(c(chainB.first:chainB.last))


# Create matrix for residue contact
contact.all.hits <- data.frame(matrix(0L, nrow = chainA.lenght, ncol = chainB.length))
rownames(contact.all.hits) <- as.character(c(chainA.first:chainA.last))
colnames(contact.all.hits) <- as.character(c(chainB.first:chainB.last))

for (line in 1:nrow(contact.residues)) {
  row <-  as.character(contact.residues[line, "atom1"])
  col <-  as.character(contact.residues[line, "atom2"])
  
  contact.all.hits[row, col] = contact.all.hits[row, col] + 1
}

contact.all.hits <- contact.all.hits %>% 
  as.data.frame() %>%
  rownames_to_column("chainA") %>%
  pivot_longer(-c(chainA), names_to = "chainB", values_to = "count") %>%
  mutate(chainB= fct_relevel(chainB,colnames(contact.all.hits)))

png("contact_all.png", width = 350, height = 150, units='mm', res = 300)
print({
  ggplot(contact.all.hits, aes(chainB, chainA, fill= count)) + 
    geom_tile() + 
    scale_fill_gradient(low="white", high="red") +
    scale_y_discrete(breaks= pretty_breaks(n=25)) +
    scale_x_discrete(breaks=c(1:10), labels=c(str_split(peptide, " "))) +
    labs(title="Contact per residue", x="Chain B", y = "Chain A") +
    theme_minimal() +
    theme(text = element_text(family="Times New Roman")) +
    theme(plot.title = element_text(size = 36, hjust = 0.5)) +
    theme(axis.title = element_text(size = 24)) +
    theme(axis.text.x = element_text(size = 20), axis.text.y = element_text(size = 12)) +
    labs(fill = "Contacs")
})
dev.off()

# Create matrix for residue contact every 10k step
contact.hits = list()
for (i in 1:20) {
  print(i)
  value = i*10000
  
  if (i != 1) {
    step.contact <- subset(contact.residues, frame > (value-10000) & frame <= value)
  }
  else{
    step.contact <- subset(contact.residues, frame >= (value-10000) & frame <= value)
  }
  
  step.frame <- data.frame(matrix(0L, nrow = chainA.lenght, ncol = chainB.length))
  rownames(step.frame) <- as.character(c(chainA.first:chainA.last))
  colnames(step.frame) <- as.character(c(chainB.first:chainB.last))
  
  for (line in 1:nrow(step.contact)) {
    row <-  as.character(step.contact[line, "atom1"])
    col <-  as.character(step.contact[line, "atom2"])
    
    step.frame[row, col] <- step.frame[row, col] + 1
  }
  
  contact.hits[[i]] <- step.frame
}


# Plot matrix for each step
for (i in 1:length(contact.hits)) {
  filename <- paste("contact_", i-1, "-", i, ".png", sep="")
  plot.title<- paste("Contact per residue ", (i-1)*10, "-", i*10, "k", sep="" )
  
  contact.hits[[i]] <- contact.hits[[i]] %>%
    as.data.frame() %>%
    rownames_to_column("chainA") %>%
    pivot_longer(-c(chainA), names_to = "chainB", values_to = "count") %>%
    mutate(chainB= fct_relevel(chainB,colnames(contact.hits[[i]])))
  
  png(filename, width = 350, height = 150, units='mm', res = 300)
  print({
    ggplot(contact.hits[[i]], aes(chainB, chainA, fill= count)) + 
      geom_tile() + 
      scale_fill_gradient(low="white", high="red",limits=max.range) +
      scale_y_discrete(breaks= pretty_breaks(n=25)) +
      scale_x_discrete(breaks=c(1:10), labels=c(str_split(peptide, " "))) +
      labs(title=plot.title, x="Chain B", y = "Chain A") +
      theme_minimal()+
      theme(text = element_text(family="Times New Roman")) +
      theme(plot.title = element_text(size = 36, hjust = 0.5)) +
      theme(axis.title = element_text(size = 24)) +
      theme(axis.text.x = element_text(size = 20), axis.text.y = element_text(size = 12)) +
      labs(fill = "Contacs")
  })
  dev.off()
}
