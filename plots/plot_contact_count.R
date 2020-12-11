library(ggplot2)
library(extrafont)

contact.count <- read.table("contact_count.csv", 
                           header = TRUE,
                           sep = ";",
                           dec = ",",
)

png("contact_count.png", width = 350, height = 150, units='mm', res = 300)
print({
  ggplot(contact.count, aes(x=frame, y=contacts, group = 1))+ 
    geom_line(color="#000033") +
    labs(title="Contacts per Frame",x="Frame", y ="Contacts")+
    theme_minimal() +
    theme(text = element_text(family="Times New Roman")) +
    theme(plot.title = element_text(size = 36, hjust = 0.5)) +
    theme(axis.title = element_text(size = 24))+
    theme(axis.text = element_text(size = 20))
})
dev.off()  