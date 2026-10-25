source("scripts/00_prepare.R")
library(scales)

# ---- weighted quantile ----
wq <- function(x, w, p) {
  o  <- order(x)
  x  <- x[o]
  w  <- w[o]
  cw <- cumsum(w) / sum(w)
  x[which(cw >= p)[1]]
}

# ---- numbers for Q2 ----
n_earners <- nrow(d)
med_w    <- wq(d$earn_annual, d$hhweight, 0.5)
med_u    <- median(d$earn_annual)
p10      <- wq(d$earn_annual, d$hhweight, 0.10)
p90      <- wq(d$earn_annual, d$hhweight, 0.90)
ratio    <- p90 / p10
excluded <- sum(d$earn_annual < 1e4 | d$earn_annual > 1e7)

options(scipen = 999)
c(n_earners = n_earners, med_w = med_w, med_u = med_u,
  p10 = p10, p90 = p90, ratio = ratio, excluded = excluded)

# ---- histogram ----
dd <- d %>%
  filter(earn_annual >= 1e4, earn_annual <= 1e7) %>%
  mutate(logearn = log10(earn_annual))

p2 <- ggplot(dd, aes(x = logearn, weight = hhweight)) +
  geom_histogram(aes(y = after_stat(density)),
                 breaks = seq(4, 7, by = 0.1),
                 fill = "grey70", colour = "white") +
  geom_vline(xintercept = log10(c(med_w, p90)), linetype = "dashed") +
  annotate("text", x = log10(med_w), y = Inf, hjust = 1.05, vjust = 2,
           label = paste0("Median: Rs ", comma(med_w))) +
  annotate("text", x = log10(p90), y = Inf, hjust = -0.05, vjust = 2,
           label = paste0("90th percentile: Rs ", comma(p90))) +
  scale_x_continuous(breaks = 4:7, limits = c(4, 7),
                     labels = c("10,000", "100,000", "1,000,000", "10,000,000")) +
  labs(title = paste0("Half of urban Balochistan earners make Rs ", comma(med_w),
                      " or less;\nabout 1 in 10 make Rs ", comma(p90), " or more"),
       x = "Annual earnings (Rs, log scale)",
       y = "Density per log10 unit",
       caption = paste0("Source: PSLM 2019-20 person file. Sample: earners aged 15-64, ",
                        "Balochistan urban (n = ", nrow(d), "). Weighted by hhweight. ",
                        nrow(d) - nrow(dd), " earners outside Rs 10,000-10,000,000 excluded.")) +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 12, hjust = 0.5),        plot.caption = element_text(size = 8, hjust = 0))

p2
ggsave("figures/distribution.svg", p2, width = 8, height = 5)