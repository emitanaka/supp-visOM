## ----setup, message = FALSE, warning = FALSE, class.source = 'fold-show'------
library(tidyverse)
library(ggtext)
library(patchwork)
library(readxl)
library(nullabor)
library(here)
library(janitor)
library(scales)


## ----data, class.source = 'fold-show'-----------------------------------------
df_full <- read_xlsx(here("data/MaskedCoverage-Fig3.xlsx")) %>% 
  clean_names() %>% 
  add_row(state = c("OR", "WY", "SD", "WV", "DC", "AL")) %>% 
  mutate(row = case_when(
    state %in% c("ME") ~ 1L,
    state %in% c("VT", "NH") ~ 2L,
    state %in% c("WA", "ID", "MT", "ND", "MN", "IL", "WI", "MI", "NY", "RI", "MA") ~ 3L,
    state %in% c("OR", "NV", "WY", "SD", "IA", "IN", "OH", "PA", "NJ", "CT") ~ 4L,
    state %in% c("CA", "UT", "CO", "NE", "MO", "KY", "WV", "VA", "MD", "DE") ~ 5L,
    state %in% c("AZ", "NM", "KS", "AR", "TN", "NC", "SC", "DC") ~ 6L,
    state %in% c("OK", "LA", "MS", "AL", "GA") ~ 7L,
    state %in% c("TX", "FL") ~ 8L,
                         TRUE ~ 0L),
    col = case_when(
      state %in% c("WA", "OR", "CA") ~ 1L,
      state %in% c("ID", "NV", "UT", "AZ") ~ 2L,
      state %in% c("MT", "WY", "CO", "NM") ~ 3L,
      state %in% c("ND", "SD", "NE", "KS", "OK", "TX") ~ 4L,
      state %in% c("MN", "IA", "MO", "AR", "LA") ~ 5L,
      state %in% c("IL", "IN", "KY", "TN", "MS") ~ 6L,
      state %in% c("WI", "OH", "WV", "NC", "AL") ~ 7L,
      state %in% c("MI", "PA", "VA", "SC", "GA") ~ 8L,
      state %in% c("NY", "NJ", "MD", "DC", "FL") ~ 9L,
      state %in% c("VT", "RI", "CT", "DE") ~ 10L,
      state %in% c("ME", "NH", "MA") ~ 11L,
      TRUE ~ 0L
    ))

df_miss <- df_full %>% 
  filter(!is.na(readmission_rate))


## ----mimic-original, fig.height = 8, fig.width = 18, fig.cap = "(ref:mimicary)"----
g1 <- df_miss %>% 
  mutate(y = readmission_rate * 100) %>% 
  ggplot(aes(col, row)) +
  geom_point(aes(size = coverage_obscured, color = y), alpha = 0.8) +
  geom_text(aes(label = percent(y/100, 0.01)), nudge_y = -0.1, size = 2.5) +
  labs(color = "Readmission Rate", size = "Coverage") +
  scale_color_gradient2(low = "#3F6E9A", high = "#AB4C30", midpoint = median(df_miss$readmission_rate * 100), mid = "#ffffe0") +
  theme_void() +
  geom_text(data = df_full, aes(label = state), color = "black", nudge_y = 0.05) +
  scale_size(range = c(3, 30)) +
  scale_y_reverse() +
  theme(plot.margin = margin(r = 30))

g2 <- g1 %+% mutate(df_miss, y = colorectal_cancer_screenings) + 
  scale_color_gradient2(low = "#3F6E9A", high = "#AB4C30", midpoint = median(df_miss$colorectal_cancer_screenings), mid = "#ffffe0") +
  labs(color = "Cancer Screening Rate")

g1 + g2 + plot_layout(guides = "collect") 


## ----fig3-alt, fig.height = 4, fig.width = 8, fig.cap = "(ref:fig3-alt)"------
theme_set(theme_classic())
g1 <- ggplot(df_miss, aes(coverage_obscured * 100, readmission_rate * 100)) +
  geom_point() +
  labs(x = "Coverage (%)", y = "Readmission (%)") +
  geom_smooth(method = loess, formula = y ~ x) +
  annotate("richtext", x = 80, y = 15.3, label.color = NA, fill = "transparent", label = glue::glue("R<sup>2</sup> = {scales::comma(cor(df_miss$coverage_obscured, df_miss$readmission_rate)^2, 0.001)}")) 

g2 <- ggplot(df_miss, aes(coverage_obscured * 100, colorectal_cancer_screenings)) +
  geom_point() +
  labs(x = "Coverage (%)", y = "Cancer Screening (%)") +
  geom_smooth(method = loess, formula = y ~ x) +
  annotate("richtext", x = 80, y = 73, label.color = NA, fill = "transparent", label = glue::glue("R<sup>2</sup> = {scales::comma(cor(df_miss$coverage_obscured, df_miss$colorectal_cancer_screenings)^2, 0.001)}")) 


g1 + g2 


## ----lineup-data--------------------------------------------------------------
set.seed(2021)
lineup_data <- null_permute("colorectal_cancer_screenings") %>% 
  lineup(true = df_miss, n = 20, pos = 3)


## ----lineup-theirs, fig.height = 10, fig.width = 10, fig.cap = "(ref:lineup-theirs)"----
plot_lineup_theirs <- ggplot(lineup_data, aes(col, row)) +
  geom_point(aes(size = coverage_obscured, color = colorectal_cancer_screenings), alpha = 0.8) +
  theme_void() + 
  scale_color_gradient2(low = "#3F6E9A", high = "#AB4C30", midpoint = median(df_miss$colorectal_cancer_screenings), mid = "#ffffe0") +
  scale_size(range = c(1, 5)) +
  scale_y_reverse(expand = c(0.1, 0.2))  +
  guides(color = "none", size = "none") + 
  facet_wrap(~.sample, ncol = 5) +
  scale_x_continuous(expand = c(0.1, 0.1)) + 
  theme(legend.position = "bottom",
        strip.text = element_text(size = 18, margin = margin(t = 3, b = 3)),
        strip.background = element_rect(color = "black", size = 1.5))

plot_lineup_theirs


## ----lineup-ours, fig.height = 10, fig.width = 10, fig.cap = "(ref:lineup-ours)"----
plot_lineup_ours <- ggplot(lineup_data, aes(coverage_obscured * 100, colorectal_cancer_screenings)) +
  geom_point() +  
  geom_smooth(method = loess, formula = y ~ x) +
  facet_wrap(~.sample, ncol = 5) +
  scale_x_continuous(expand = c(0.1, 0.1)) + 
  theme(legend.position = "bottom",
        strip.text = element_text(size = 18, margin = margin(t = 3, b = 3)),
        strip.background = element_rect(color = "black", size = 1.5),
        axis.text = element_blank(),
        axis.title = element_blank(),
        axis.line = element_blank(),
        axis.ticks.length = unit(0, "pt"))

plot_lineup_ours


## ----data-false, class.source="fold-show"-------------------------------------
df_false <- df_miss %>% 
  arrange(coverage_obscured) %>% 
  mutate(colorectal_cancer_screenings = sort(colorectal_cancer_screenings))

lineup_false_data <- null_permute("colorectal_cancer_screenings") %>% 
  lineup(true = df_false, n = 20, pos = 5)


## ----lineup-theirs-false, fig.height = 10, fig.width = 10, fig.cap = "(ref:lineup-theirs-false)"----
plot_lineup_theirs %+% lineup_false_data


## ----lineup-ours-false, fig.height = 10, fig.width = 10, fig.cap = "(ref:lineup-ours-false)"----
plot_lineup_ours %+% lineup_false_data


## ----session-info-------------------------------------------------------------
sessioninfo::session_info()


