# README
Repository with data from Freitas &amp; Davies (2026)

All datasets used to test the updated version of MCMCtree are available in this repository. The table below lists each test alongside the folder where its results are stored.
Test | Folder | Dataset | Source | Test | Results |
|---------|---------|--------|------|---------|---------|
#1 | t1 | Globin | Yang et al. (1994) | Classic mode with new control file | Identical MCMC draws |
#2 | t2 | Globin | Yang et al. (1994) | Run new version with original control file | Identical MCMC draws |
#3 | t34 | Primates | Yang and Rannala (2006) | Checkpointing | Identical MCMC draws |
#4 | t34 | Primates | Yang and Rannala (2006) | Partitioned nucleotide data | Reduced manual steps from 2 to 1; identical MCMC draws |
#5 | t5 | Metazoa | dos Reis et al. (2015) | Partitioned amino acid data | Reduced manual steps from 3 to 1; identical MCMC draws |
#6 | t6 | Metazoa | dos Reis et al. (2015) | Runtime (stopped at convergence) | 54.7% faster |
#7 | t7 | Mammals | Álvarez-Carretero (2022) | Runtime (no convergence i.e. full run) | 4.3% slower |
#8 | t8 | Metazoa | Carlisle et al. (2024) | Runtime (stopped at convergence) | 79.5% faster |
#9 | t9 | Porifera | Rossi et al. (2026) | Runtime (no convergence i.e. full run) | 8.1% faster |
