library(tidyverse)
library(hms)
library(posterior)
library(HDInterval)
library(ggpmisc)

read_mcmctree_out <- function(path) {
  lines <- readLines(path, warn = FALSE)
  
  header <- "Posterior mean (95% Equal-tail CI) (95% HPD CI) HPD-CI-width"
  start <- grep(header, lines, fixed = TRUE)
  
  if (length(start) != 1) {
    stop("Could not find the posterior-summary table in: ", path)
  }
  
  number <- "[-+]?(?:\\d*\\.\\d+|\\d+\\.?)(?:[eE][-+]?\\d+)?"
  
  pattern <- paste0(
    "^\\s*(\\S+)\\s+",
    "(", number, ")\\s+",
    "\\(\\s*(", number, ")\\s*,\\s*(", number, ")\\)\\s+",
    "\\(\\s*(", number, ")\\s*,\\s*(", number, ")\\)\\s+",
    "(", number, ")\\s*$"
  )
  
  summary_lines <- character()
  started <- FALSE
  
  for (line in lines[(start + 1):length(lines)]) {
    if (grepl(pattern, line, perl = TRUE)) {
      summary_lines <- c(summary_lines, line)
      started <- TRUE
    } else if (started) {
      break
    }
  }
  
  if (!length(summary_lines)) {
    stop("The posterior-summary table is empty in: ", path)
  }
  
  matches <- regexec(pattern, summary_lines, perl = TRUE)
  values <- regmatches(summary_lines, matches)
  
  tibble::tibble(
    variable = vapply(values, `[[`, character(1), 2),
    mean = as.numeric(vapply(values, `[[`, character(1), 3)),
    q2.5 = as.numeric(vapply(values, `[[`, character(1), 4)),
    q97.5 = as.numeric(vapply(values, `[[`, character(1), 5)),
    hpd_low = as.numeric(vapply(values, `[[`, character(1), 6)),
    hpd_high = as.numeric(vapply(values, `[[`, character(1), 7))
  )
}

# Test 1 - Identical MCMC draws
mcmc_dynamic1 <- read_tsv("t1/MCMCtree_updated/mcmc.txt", show_col_types = FALSE)
mcmc_classic1 <- read_tsv("t1/MCMCtree/mcmc.txt", show_col_types = FALSE)
print(all.equal(as.data.frame(mcmc_dynamic1), as.data.frame(mcmc_classic1) |> head(nrow(mcmc_dynamic1))))

# Test 2 - Identical MCMC draws
mcmc_dynamic2 <- read_tsv("t2/MCMCtree_updated/mcmc.txt", show_col_types = FALSE)
mcmc_classic2 <- read_tsv("t2/MCMCtree/mcmc.txt", show_col_types = FALSE)
print(all.equal(as.data.frame(mcmc_dynamic2), as.data.frame(mcmc_classic2) |> head(nrow(mcmc_dynamic2))))

# Tests 3 and 4 - Reduced manual steps from 2 to 1; identical MCMC draws
mcmc_dynamic34 <- read_tsv("t34/MCMCtree_updated/run1/mcmc.txt", show_col_types = FALSE)
mcmc_classic34 <- read_tsv("t34/MCMCtree/mcmc.txt", show_col_types = FALSE)
print(all.equal(as.data.frame(mcmc_dynamic34), as.data.frame(mcmc_classic34) |> head(nrow(mcmc_dynamic34))))

# Tests 5 - Reduced manual steps from 3 to 1; identical MCMC draws
mcmc_dynamic5 <- read_tsv("t5/MCMCtree_updated/run1/mcmc.txt", show_col_types = FALSE)
mcmc_classic5 <- read_tsv("t5/MCMCtree/mcmc.txt", show_col_types = FALSE)
print(all.equal(as.data.frame(mcmc_dynamic5), as.data.frame(mcmc_classic5) |> head(nrow(mcmc_dynamic5))))

# Test 6 - Runtime, 54.7% faster
runtime_dynamic6 <- system("grep Time t6/MCMCtree_updated/run1/out.txt", intern = TRUE) |> 
  str_remove("Time used:\\s*") |> parse_hms() |> as.numeric()
runtime_classic6 <- system("grep Time t6/MCMCtree/out.txt", intern = TRUE) |> 
  str_remove("Time used:\\s*") |> parse_hms() |> as.numeric()
(runtime_dynamic6 - runtime_classic6) / runtime_classic6 * 100

# Test 7 - Runtime, 4.3% slower
runtime_dynamic7 <- system("grep Time t7/MCMCtree_updated/run1/out.txt", intern = TRUE) |> 
  str_remove("Time used:\\s*") |> parse_hms() |> as.numeric()
runtime_classic7 <- system("grep Time t7/MCMCtree/out.txt", intern = TRUE) |> 
  str_remove("Time used:\\s*") |> parse_hms() |> as.numeric()
(runtime_dynamic7 - runtime_classic7) / runtime_classic7 * 100

# Test 8 - Runtime, 79.5% faster
runtime_dynamic8 <- system("grep Time t8/MCMCtree_updated/run1/out.txt", intern = TRUE) |> 
  str_remove("Time used:\\s*") |> parse_hms() |> as.numeric()
runtime_classic8 <- system("grep Time t8/MCMCtree/out.txt", intern = TRUE) |> 
  str_remove("Time used:\\s*") |> parse_hms() |> as.numeric()
(runtime_dynamic8 - runtime_classic8) / runtime_classic8 * 100

# Test 9 - Runtime, 8.06% faster
runtime_dynamic9 <- system("grep Time t9/MCMCtree_updated/run1/out.txt", intern = TRUE) |> 
  str_remove("Time used:\\s*") |> parse_hms() |> as.numeric()
runtime_classic9 <- system("grep Time t9/MCMCtree/out.txt", intern = TRUE) |> 
  str_remove("Time used:\\s*") |> parse_hms() |> as.numeric()
(runtime_dynamic9 - runtime_classic9) / runtime_classic9 * 100

# Additional MCMC checks with test 6
# Check if Rhat/ESS calculated by MCMCtree matches Rhat/ESS from R posterior library
# Get MCMC stats using R functions
files <- c("t6/MCMCtree_updated/run1/mcmc.txt",
           "t6/MCMCtree_updated/run2/mcmc.txt",
           "t6/MCMCtree_updated/run3/mcmc.txt",
           "t6/MCMCtree_updated/run4/mcmc.txt",
           "t6/MCMCtree_updated/run5/mcmc.txt")

samples_per_run <- 9000
burnin_fraction <- 0.25
burnin_samples <- floor(samples_per_run * burnin_fraction)

runs <- lapply(files, function(f) {
  read_tsv(f, show_col_types = FALSE) |>
    slice(2251:9000) |>
    select(starts_with("t_n"), lnL)
}
)

variables <- names(runs[[1]])
n_iter <- 6750

draw_array <- array(NA_real_, dim = c(n_iter, length(runs), length(variables)),
                    dimnames = list(iteration = NULL,
                                    chain = paste0("chain", seq_along(runs)),
                                    variable = variables))

for (i in seq_along(runs)) {
  draw_array[, i, ] <- data.matrix(runs[[i]][seq_len(n_iter), variables])
}

draws <- as_draws_array(draw_array)

summary_r <- summarise_draws(draws, 
                             rhat, 
                             mean,
                             ~quantile2(.x, probs = c(0.025, 0.975)),
                             ~hdi(.x, credMass = 0.95) |> setNames(c("hpd_low", "hpd_high")),
                             ess_bulk) |>
  mutate(data = "r")

# Get MCMC stats from MCMCtree
summary_mcmctree_rhat_ess <- read_tsv("t6/MCMCtree_updated/adaptive_stats_by_parameter.txt") |>
  filter(chunk == 9) |> select(variable = parameter, rhat, ess_bulk = ess)

mcmctree_results <- read_mcmctree_out("t6/MCMCtree_updated/combined_out.txt")

summary_mcmctree <- summary_mcmctree_rhat_ess |>
  left_join(mcmctree_results) |> 
  filter(str_detect(variable, "t_n|ln")) |> 
  mutate(data = "mcmctree")

# Compare MCMCtree and R MCMC stats
both_runs <- summary_r |> 
  bind_rows(summary_mcmctree)

# ESS
both_runs |>
  select(variable, ess_bulk, data) |>
  pivot_wider(names_from = data, values_from = ess_bulk) |>
  ggplot(aes(x = r, y = mcmctree)) +
  geom_abline(slope = 1, intercept = 0, linetype = 2) +
  geom_point() +
  coord_equal() +
  scale_x_log10() +
  scale_y_log10() +
  labs(x = "ESS (R)", y = "ESS (MCMCtree)") +
  theme_bw()


both_runs |>
  select(variable, ess_bulk, data) |>
  pivot_wider(names_from = data, values_from = ess_bulk) |>
  mutate(relative_difference =
           100 * (mcmctree - r) / r) |>
  summarise(median_relative_difference = median(relative_difference),
            mean_relative_difference = mean(relative_difference),
            max_absolute_difference = max(abs(relative_difference)),
            q95_absolute_difference = quantile(abs(relative_difference), 0.95))

both_runs |>
  select(variable, ess_bulk, data) |>
  pivot_wider(names_from = data, values_from = ess_bulk) |>
  mutate(relative_difference = 100 * (mcmctree - r) / r) |>
  arrange(desc(abs(relative_difference))) |>
  select(variable, r, mcmctree, relative_difference)



# Rhat
both_runs |>
  select(variable, rhat, data) |>
  pivot_wider(names_from = data, values_from = rhat) |>
  ggplot(aes(x = r, y = mcmctree)) +
  geom_abline(slope = 1, intercept = 0, linetype = 2) +
  geom_point() +
  coord_equal() +
  scale_x_log10() +
  scale_y_log10() +
  labs(x = expression(hat(R)~"(R)"),
       y = expression(hat(R)~"(MCMCtree)")) +
  theme_bw()


both_runs |>
  select(variable, rhat, data) |>
  pivot_wider(names_from = data, values_from = rhat) |>
  mutate(relative_difference =
           100 * (mcmctree - r) / r) |>
  summarise(median_relative_difference = median(relative_difference),
            mean_relative_difference = mean(relative_difference),
            max_absolute_difference = max(abs(relative_difference)),
            q95_absolute_difference = quantile(abs(relative_difference), 0.95))

both_runs |>
  select(variable, rhat, data) |>
  pivot_wider(names_from = data, values_from = rhat) |>
  mutate(relative_difference = 100 * (mcmctree - r) / r) |>
  arrange(desc(abs(relative_difference))) |>
  select(variable, r, mcmctree, relative_difference)

