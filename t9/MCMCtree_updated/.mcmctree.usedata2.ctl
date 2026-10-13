          seed = -1
       seqfile = Matrix.phy
      treefile = Pori_Cauchy_SM_SpiPori_573.tre
      mcmcfile = mcmc.txt
       outfile = out.txt

         ndata = 5
       seqtype = 2    * 0: nucleotides; 1:codons; 2:AAs
usedata = 2 /lfs1i3/projects/b36at/porifera_inBV_from_paper/mv10/in.BV 3
         clock = 2    * 1: global clock; 2: independent rates; 3: correlated rates
       RootAge = '<1.0'  * safe constraint on root age, used if no fossil for root.

         model = AA    * 0:JC69, 1:K80, 2:F81, 3:F84, 4:HKY85
    aaRatefile = LG
         alpha = 0.5    * alpha for gamma rates at sites
         ncatG = 5    * No. categories in discrete gamma

     cleandata = 0    * remove sites with ambiguity data (1:yes, 0:no)?

       BDparas = 1 1 0.1 multiplicative  * birth, death, sampling, multiplicative/conditional

   rgene_gamma = 2 20 1   * gammaDir prior for rate for genes
  sigma2_gamma = 1 10 1   * gammaDir prior for sigma^2     (for clock=2 or 3)

      finetune = 1: .1 .1 .1 .1 .1 .1 * auto (0 or 1): times, musigma2, rates, mixing, paras, FossilErr

         print = 1   * 0: no mcmc sample; 1: everything except branch rates 2: everything
         mode  = dynamic
        burnin = 0.05
      sampfreq = 100
       nsample = 20000
    checkpoint = 3 0.01 mcmctree.ckpt1 * flag(0: none;  1: save;  2: resume;  3: auto-resume append) prob filename
        n_runs = 5   * number of independent MCMC runs to run in parallel

   chunk_size  = 1000
   target_rhat = 1.01
   target_ess  = 200

