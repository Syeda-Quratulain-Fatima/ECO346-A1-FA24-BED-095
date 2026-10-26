source("scripts/00_prepare.R")
library(scales)

# ---- band table: count and weighted mean per age band ----
bands <- d %>%
  group_by(band, mid) %>%
  summarise(n = n(),
            wmean = sum(hhweight * earn_annual) / sum(hhweight),
            .groups = "drop") %>%
  mutate(thin = n < 30,
         wmean_rs = round(wmean))

options(scipen = 999)
print(bands, n = 10)

dir.create("output", showWarnings = FALSE)
write_csv(bands %>% select(band, n, wmean_rs), "output/band_table_R.csv")

peak <- bands %>% slice_max(wmean, n = 1)

# ---- figure ----
set.seed(346)
p3 <- ggplot(d, aes(age, earn_annual)) +
  geom_jitter(width = 0.4, height = 0, alpha = 0.4,
              colour = "grey40", size = 1.6) +
  geom_line(data = bands, aes(x = mid, y = wmean, group = 1),
            colour = "firebrick", linewidth = 0.8) +
  geom_point(data = bands, aes(x = mid, y = wmean, shape = thin),
             colour = "firebrick", size = 3.5, stroke = 1.2) +
  scale_shape_manual(values = c(`FALSE` = 16, `TRUE` = 1), guide = "none") +
  annotate("text", x = peak$mid + 2, y = peak$wmean,
           label = paste0("Highest band: ages ", peak$band,
                          "\nRs ", comma(peak$wmean_rs)),
           hjust = 1, vjust = -0.8, fontface = "bold", colour = "firebrick") +
  scale_y_log10(limits = c(1e4, 1e7), breaks = 10^(4:7),
                labels = c("10,000", "100,000", "1,000,000", "10,000,000")) +
  scale_x_continuous(limits = c(14, 65), breaks = seq(15, 65, by = 5)) +
  labs(title = paste0("Urban Balochistan earnings rise until the late 20s, plateau into the 40s, then edge up;\n",
                      "the highest band mean (", peak$band, ") rests on only ", peak$n, " earners"),
       x = "Age (years)",
       y = "Annual earnings (Rs, log scale)",
       caption = paste0("Source: PSLM 2019-20 person file. Sample: earners aged 15-64, ",
                        "Balochistan urban (n = ", nrow(d), "). Weighted by hhweight.\n",
                        "Red markers: weighted mean earnings by 5-year age band, plotted at band midpoint; ",
                        "hollow markers: fewer than 30 earners in the band.")) +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 12, hjust = 0.5),
        plot.caption = element_text(size = 8, hjust = 0),
        plot.margin = margin(10, 20, 10, 10))

p3
ggsave("figures/relationship.svg", p3, width = 8, height = 5.5)