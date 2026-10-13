          seed = -1
       seqfile = dummy.txt
      treefile = tree.txt
      mcmcfile = mcmc.txt
       outfile = out.txt

         ndata = 4
       seqtype = 0    * 0: nucleotides; 1:codons; 2:AAs
       usedata = 2  * 0: no data (prior); 1:exact likelihood;
                             * 2:approximate likelihood; 3:out.BV (in.BV)
         clock = 3      * 1: global clock; 2: independent rates; 3: correlated rates

         model = 4    * 0:JC69, 1:K80, 2:F81, 3:F84, 4:HKY85
         alpha = 0.5  * alpha for gamma rates at sites
         ncatG = 5    * No. categories in discrete gamma

     cleandata = 0    * remove sites with ambiguity data (1:yes, 0:no)?

       BDparas = 1 1 0.1 multiplicative    * birth, death, sampling

   rgene_gamma = 2 40   * gammaDir prior for rate for genes
  sigma2_gamma = 1 10    *s gammaDir prior for sigma^2     (for clock=2 or 3)

         print = 1   * 0: no mcmc sample; 1: everything except branch rates 2: everything
        burnin = 150000
      sampfreq = 400
       nsample = 20000
        n_runs = 2

    burnin_per = 0.018404908   * -1: classic burnin/nsample; >=0: adaptive chunks discard this fraction for diagnostics/summaries
    chunk_size = 125 * adaptive mode: samples added per chain before checking convergence/ESS
   target_rhat = 1.01 * adaptive mode: stop after all parameters have Rhat <= target_rhat
    target_ess = 200  * adaptive mode: stop after combined post-burnin ESS reaches target_ess for all parameters
   max_samples = 20375 * adaptive mode: maximum samples per chain
