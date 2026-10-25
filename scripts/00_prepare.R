library(tidyverse)

person <- read_csv("data/pslm_person_subset.csv")
hh     <- read_csv("data/pslm_hh_subset.csv")

anyDuplicated(hh$hhid)          # should print 0

d <- person %>%
  left_join(hh %>% select(hhid, hhweight, prov_code, urban_rural), by = "hhid") %>%
  filter(prov_code == 4, urban_rural == 2,
         age >= 15, age <= 64,
         earn_annual > 0)

nrow(d)                          # number of earners
sum(is.na(d$hhweight))           # should print 0

d <- d %>%
  mutate(band = cut(age, breaks = seq(15, 65, by = 5), right = FALSE,
                    labels = c("15-19","20-24","25-29","30-34","35-39",
                               "40-44","45-49","50-54","55-59","60-64")),
         mid  = 15 + 5 * floor((age - 15) / 5) + 2)

d %>% count(band, mid)
