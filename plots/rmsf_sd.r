library(data.table)
library(stringr)

# load table
rmsd.table <- read.table("residue_rmsd.csv", 
                     header = TRUE,
                     sep = ";",
                     dec = ".",
                     )

# Format table
rmsd.table$X = NULL
residues = str_replace_all(c(names(rmsd.table)), "X", "")
residues = as.numeric(residues)
rows = nrow(rmsd.table)

# Format stats table
rmsd.stats.type <- c("mean", "sd_total", "sd_first", "sd_middle", "sd_last")
rmsd.stats <- setNames(data.table(matrix(ncol = 6, nrow = length(residues))), c("residue", rmsd.stats.type))
rmsd.stats$residue <- c(residues)

# Take measures 
stat_i = 1
for (r in residues){
  table_i = paste("X", r, sep='')
  rmsd.stats$mean[stat_i] = mean(rmsd.table[,table_i])
  rmsd.stats$sd_total[stat_i] = sd(rmsd.table[,table_i])
  rmsd.stats$sd_first[stat_i] = sd(rmsd.table[,table_i][1:(rows/3)])
  rmsd.stats$sd_middle[stat_i] = sd(rmsd.table[,table_i][((rows/3)):(2*rows/3)])
  rmsd.stats$sd_last[stat_i] = sd(rmsd.table[,table_i][((2*rows/3)):rows])
  stat_i= stat_i + 1
}


# Detect chain number
residue_ind = 0
previous = residues[1]
chains.sep = c()
for (now in (residues)) {
  if (abs(previous-now) > 1){
    chains.sep= c(chains.sep,i)
    residue_ind = 0
  } else {
    residue_ind = residue_ind + 1
  }
  previous = now
}


chain = 1
residue.chains = c()
for (i in chains.sep) { 
  residue.chains = c(residue.chains, rep(chain,i))
  chain = chain +1
}
residue.chains = c(residue.chains, rep(chain,(residue_ind+1)))

# Split stat in chains
chains.stat = split(rmsd.stats, c(residue.chains))

# Write stats csv
for (i in 1:chain) {
  file.name = paste("rmsf_chain",i,".csv", sep='')
  write.table(chains.stat[[i]], file.name, sep=';', dec=',', row.names=FALSE)
}