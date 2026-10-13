          seed = -1
       seqfile = ConcatAlign.phy
      treefile = tree1normal.tre
      mcmcfile = mcmc.txt
       outfile = out.txt

         ndata = 1
       seqtype = 2    * 0: nucleotides; 1:codons; 2:AAs
       usedata = 2    * 0: no data; 1:seq like; 2:normal approximation; 3:out.BV (in.BV)
         clock = 2    * 1: global clock; 2: independent rates; 3: correlated rates

         model = 2    * 0:poisson, 1:proportional,2:Empirical,3:Empirical+F,
		      * 6:FromCodon, 8:REVaa_0,9:REVaa(nr=189)
         alpha = 0.5    * alpha for gamma rates at sites
         ncatG = 5    * No. categories in discrete gamma
    aaRatefile = ../../lg.dat   * Path to the file with the LG matrix
     cleandata = 0    * remove sites with ambiguity data (1:yes, 0:no)?

       BDparas = 1 1 0.1 m   * birth, death, sampling

   rgene_gamma = 2 54    * gammaDir prior for rate for genes, based on branch lengths and rate 
  sigma2_gamma = 1 10   * gammaDir prior for sigma^2     (for clock=2 or 3), based on dos reis 2015


         print = 1       * 0: no mcmc sample; 1: everything except branch rates 2: everything
        burnin = 100000
      sampfreq = 1000 
       nsample = 20000

*** Note: Make your window wider (100 columns) before running the program.
