source("scripts/00_prepare.R")
library(svglite)

p <- ggplot(d, aes(age, earn_annual)) + geom_point()
p

dir.create("figures", showWarnings = FALSE)
ggsave("figures/default.svg", p)