clear all
set more off
capture log close
version 18
pwd
global root "`c(pwd)'"
global raw "$root/01_raw"
global scripts "$root/02_scripts"
global results "$root/03_results"
global figures "$root/figures"
foreach folder in "$raw" "$scripts" "$results" "$figures" {
	capture confirm file "`folder'/nul"
	if _rc != 0 {
		mkdir "`folder'"
		display "Creating missing directory: `folder'"
	}
} //automatic file creation

/*log files*/
log using "$results/revolution_outcome.log", text replace //start recording
display "--Starting Analysis--"
display "Date: $S_DATE | Time: $S_TIME"

import delimited "https://raw.githubusercontent.com/isaac-nguyen-02/data-for-revolution-project/refs/heads/main/data_for_paper_on_revolution.csv", clear
label variable country "Country"
label variable year_of_rev "Year of Revolution"
label variable ref_year "Reference Year"

label variable immediate_outcome "Immediate Outcome"
label define outcome_define 0 "Failure" 1 "Success"
label value immediate_outcome outcome_define

label variable gdp_per_cap "GDP per capita (PPP current international $)"
label variable factionalized_elite "Factionalized Elite"
label variable public_service "Public Service"
label variable security_apparatus "Security Apparatus"
label variable external_intervention "External Intervention"

label variable revolt_widespread "Is the revolt widespread?"
label define widespread_define 0 "No" 1 "Yes"
label value revolt_widespread widespread_define

gen ln_gdp = ln(gdp_per_cap)
label variable ln_gdp "Natural Logarithm of GDP per capita"

isid country year_of_rev
misstable summarize

gen income_group = .
replace income_group = 1 if gdp_per_cap < 1086
replace income_group = 2 if gdp_per_cap >= 1086  & gdp_per_cap < 4256
replace income_group = 3 if gdp_per_cap >= 4256  & gdp_per_cap < 13205
replace income_group = 4 if gdp_per_cap >= 13205
label define income_lbl 1 "Low Income" 2 "Lower-Middle" 3 "Upper-Middle" 4 "High Income"
label values income_group income_lbl
egen avg_outcome = mean(immediate_outcome), by(income_group)

collect clear
quietly collect, tags(cmdset[GDP_PC]): summarize gdp_per_cap, detail
quietly collect, tags(cmdset[FE]): summarize factionalized_elite, detail
quietly collect, tags(cmdset[SA]): summarize security_apparatus, detail
quietly collect, tags(cmdset[PS]): summarize public_service, detail
quietly collect, tags(cmdset[EI]): summarize external_intervention, detail

collect layout (cmdset) (result[N mean p50 sd min max freq])

collect label levels results N "Obs." mean "Mean" p50 "Median" sd "Std. Dev." min "Min" max "Max"

collect label levels cmdset ///
	GDP_PC "GDP per capita (PPP Current International $)" ///
	FE "Factionalized Elite Index" ///
	SA "Security Apparatus Index" ///
	PS "Public Service Index" ///
	EI "External Intervention Index" ///

collect style cell result[N], nformat(%10.0fc)

collect style cell result[mean p50 sd min max], nformat(%12.2fc)

collect title "Table 1: Summary Statistics of the Variables"

collect note "Source: Data for GDP per capita is from the World Bank, or the CIA Factbook where World Bank data is not available. The indice are taken from the Fragile State Index dataset. Data range is from 2007 to 2024"

collect preview
collect export "$results/table1_summary_stats.docx", replace

table (immediate_outcome), statistic(frequency) statistic(percent) ///
	title("Table 2: Summary statistics on Immediate Outcome of Revolutions") ///
	note("Source: Goldstone et al. (2022) and compiled by the author to adjust for recent events as well as definition")
collect export "$results/table2_statistic_on_outcome.docx", replace

table (revolt_widespread), statistic(frequency) statistic(percent) ///
	title("Table 3: Summary statistics on how widespread each revolt was") ///
	note("Source: compiled by the author")
collect export "$results/table3_statistic_on_widespread.docx", replace
	
graph matrix ln_gdp security_apparatus public_service external_intervention factionalized_elite revolt_widespread, ///
	msymbol(circle) mcolor(black%40) msize(medium) ///
	diagonal("Natural Log GDP p.c." "Security Apparatus" "Public Service" "External Intervention" "Factionalized Elite" "Revolt Widespread") ///
	title("Figure 1: Scatterplot Matrix: Key Variables")
graph export "$figures/fig1_scatter_matrix.pdf", replace as(pdf)

	
twoway ///
	(kdensity immediate_outcome if income_group == 1, lcolor(maroon) lwidth(medthick) lpattern (solid)) ///
     (kdensity immediate_outcome if income_group == 2, lcolor(navy) lwidth(medthick) lpattern(dash))  ///
     (kdensity immediate_outcome if income_group == 3, lcolor(forest_green) lwidth(medthick) lpattern(shortdash)) ///
         (kdensity immediate_outcome if income_group == 4, lcolor (black) lwidth(medthick) lpattern(dot)) ///
     , title("Figure 2: Revolutionary Outcome by Income Group") xtitle("Outcome") legend(order(2 "Lower-Middle Income" 3 "Upper-Middle Income" 4 "High Income"))
graph export "$figures/fig2_kde_outcome_by_incomegroup.pdf", replace as(pdf)

twoway histogram gdp_per_cap,                        ///
     fraction                                        ///
     bin(30)                                         ///
     color(maroon%40)                                ///
     lcolor(maroon)                                  ///
     lwidth(thin)                                    ///
     xtitle("GDP per Capita")                    ///
     ytitle("Fraction of Observations")              ///
     title("Distribution of GDP per Capita")     ///
		scheme(s2color) ///
		name(pane1A, replace) nodraw
	 
twoway histogram ln_gdp,                        ///
     fraction                                        ///
     bin(30)                                         ///
     color(maroon%40)                                ///
     lcolor(maroon)                                  ///
     lwidth(thin)                                    ///
     xtitle("Log GDP per Capita")                    ///
     ytitle("Fraction of Observations")              ///
     title("Distribution of Natural Log GDP per Capita")     ///
     scheme(s2color) ///
	 name(pane1B, replace) nodraw
	 
graph combine pane1A pane1B, ///
	rows(1) cols(1) ///
	title("Figure 3: Comparison of distribution between raw GDP p.c and its natural log") ///
	note("Source: World Bank Open Data, with CIA Factbook filling in where data is not available.")
	
graph export "$figures/fig3_combine_comparison_gdp.pdf", replace as(pdf)
	 
twoway histogram factionalized_elite, ///
	fraction ///
	bin(30) ///
	color(blue%40) ///
	lcolor(blue) ///
	lwidth(thin) ///
	xtitle("Factionalized Elite Indicator") ///
	ytitle("Fraction of Observations") ///
	title("Distribution of the Factionalized Elite Indicator") ///
	scheme(s2color) ///
	name(pane1A, replace) nodraw
	
twoway histogram security_apparatus, ///
	fraction ///
	bin(30) ///
	color(red%40) ///
	lcolor(red) ///
	lwidth(thin) ///
	xtitle("Security Apparatus Indicator") ///
	ytitle("Fraction of Observations") ///
	title("Distribution of the Security Apparatus Indicator") ///
	scheme(s2color) ///
	name(pane1B, replace) nodraw
	
twoway histogram public_service, ///
	fraction ///
	bin(30) ///
	color(green%40) ///
	lcolor(green) ///
	lwidth(thin) ///
	xtitle("Public Service Indicator") ///
	ytitle("Fraction of Observations") ///
	title("Distribution of the Public Service Indicator") ///
	scheme(s2color) ///
	name(pane1C, replace) nodraw
	
twoway histogram external_intervention, ///
	fraction ///
	bin(30) ///
	color(orange%40) ///
	lcolor(orange) ///
	lwidth(thin) ///
	xtitle("External Intervention Indicator") ///
	ytitle("Fraction of Observations") ///
	title("Distribution of the External Intervention Indicator") ///
	scheme(s2color) ///
	name(pane1D, replace) nodraw

graph combine pane1A pane1B pane1C pane1D, ///
	rows(2) cols(2) ///
	title("Figure 4: Comparison of distributions of the Fragile State Index Indicators") ///
	note("Source: Fragile State Index")
graph export "$figures/fig4_combine_comparison_fragile.pdf", replace as(pdf)

/*REGRESSION TIME*/
firthlogit immediate_outcome ln_gdp factionalized_elite security_apparatus external_intervention revolt_widespread public_service
/* Initial:      Penalized log likelihood = -19.475925
Rescale:      Penalized log likelihood = -19.475925
Iteration 0:  Penalized log likelihood = -19.475925  
Iteration 1:  Penalized log likelihood =   -12.7656  (not concave)
Iteration 2:  Penalized log likelihood = -12.748177  
Iteration 3:  Penalized log likelihood = -12.714915  (not concave)
Iteration 4:  Penalized log likelihood = -12.705881  (not concave)
Iteration 5:  Penalized log likelihood = -12.695966  (not concave)
Iteration 6:  Penalized log likelihood = -12.693438  
Iteration 7:  Penalized log likelihood = -12.608639  
Iteration 8:  Penalized log likelihood = -12.608403  
Iteration 9:  Penalized log likelihood = -12.608402  

                                                        Number of obs =     40
                                                        Wald chi2(6)  =   7.79
Penalized log likelihood = -12.608402                   Prob > chi2   = 0.2536

---------------------------------------------------------------------------------------
    immediate_outcome | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
----------------------+----------------------------------------------------------------
               ln_gdp |  -1.875834   .7861591    -2.39   0.017    -3.416678   -.3349907
  factionalized_elite |  -.1447827   .3103471    -0.47   0.641    -.7530518    .4634865
   security_apparatus |  -.4706898   .4472806    -1.05   0.293    -1.347344    .4059639
external_intervention |   .2440116    .258712     0.94   0.346    -.2630546    .7510778
    revolt_widespread |  -.2112268   .8111168    -0.26   0.795    -1.800987    1.378533
       public_service |  -.1263151   .3187969    -0.40   0.692    -.7511457    .4985154
                _cons |   21.01548   8.868879     2.37   0.018     3.632798    38.39816
---------------------------------------------------------------------------------------
*/ 
*This model is pretty much unusable. We now do some tweaks: we remove variables that are least significant. We end up with:

firthlogit immediate_outcome ln_gdp security_apparatus
/*
Initial:      Penalized log likelihood = -24.053872
Rescale:      Penalized log likelihood = -24.053872
Iteration 0:  Penalized log likelihood = -24.053872  
Iteration 1:  Penalized log likelihood =  -17.17818  
Iteration 2:  Penalized log likelihood = -17.137017  (not concave)
Iteration 3:  Penalized log likelihood = -17.135793  
Iteration 4:  Penalized log likelihood = -17.127941  
Iteration 5:  Penalized log likelihood = -17.122547  
Iteration 6:  Penalized log likelihood = -17.122314  
Iteration 7:  Penalized log likelihood = -17.122312  

                                                        Number of obs =     40
                                                        Wald chi2(2)  =   8.17
Penalized log likelihood = -17.122312                   Prob > chi2   = 0.0169

------------------------------------------------------------------------------------
 immediate_outcome | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------------+----------------------------------------------------------------
            ln_gdp |  -2.047286   .7164036    -2.86   0.004    -3.451411   -.6431608
security_apparatus |  -.6440921    .314915    -2.05   0.041    -1.261314   -.0268701
             _cons |    23.2207   8.247985     2.82   0.005     7.054944    39.38645
------------------------------------------------------------------------------------
*/


predict p_hat
predict xb, xb
label variable xb "Fitted Values (Log-Odds)"
gen p_hat_pr = invlogit(xb)
label variable p_hat_pr "Probability of Success of Revolution"
gen e_hat_pearson = (immediate_outcome - p_hat_pr) / sqrt(p_hat_pr * (1-p_hat_pr))
label variable e_hat_pearson "Pearson Residual"

twoway (scatter e_hat_pearson p_hat_pr, msize(small) mcolor(navy%40)), ///
	yline(0, lpattern(dash) lcolor(red) lwidth(medium)) ///
	title("Figure 5: Pearson Residuals vs Predicted Probabilities") ///
    ytitle("Pearson Residuals") ///
    xtitle("Predicted Probability")
graph export "$figures/fig5_residual_heteroskedasticity.pdf", replace as(pdf) 

qnorm e_hat_pearson,                                                          ///
      title("Figure 6: Normal Quantile Plot of Residuals")                     ///
      xtitle("Theoretical Quantiles") ytitle("Residual Quantiles")   ///
      msize(tiny) mcolor(navy%50)                                     ///
      name(qnorm_plot, replace)
graph export "$figures/fig6_residual_normal.pdf", replace as(pdf)  
	  
gen predicted = (p_hat_pr >= 0.5)
label variable predicted "Predicted Outcome of the Revolution"
label value predicted outcome_define
list country year_of_rev immediate_outcome predicted
/*    +--------------------------------------------------+
     |         country   year_o~v   immedi~e   predic~d |
     |--------------------------------------------------|
  1. |         Myanmar       2007    Failure    Success |
  2. |            Iran       2009    Failure    Failure |
  3. |         Moldova       2009    Success    Success |
  4. |      Kyrgyzstan       2010    Success    Success |
  5. |         Tunisia       2010    Success    Success |
     |--------------------------------------------------|
  6. |           Egypt       2011    Success    Success |
  7. |           Libya       2011    Success    Failure |
  8. |           Syria       2011    Success    Success |
  9. |         Bahrain       2011    Failure    Failure |
 10. |           Yemen       2011    Success    Success |
     |--------------------------------------------------|
 11. |         Ukraine       2014    Success    Success |
 12. |       Hong Kong       2014    Failure    Failure |
 13. |    Burkina Faso       2014    Success    Success |
 14. |       Venezuela       2015    Failure    Failure |
 15. | North Macedonia       2015    Success    Failure |
     |--------------------------------------------------|
 16. |       Guatemala       2015    Success    Success |
 17. |     South Korea       2016    Success    Success |
 18. |           Sudan       2018    Success    Success |
 19. |         Armania       2018    Success    Success |
 20. |       Hong Kong       2019    Failure    Failure |
     |--------------------------------------------------|
 21. |         Algeria       2019    Failure    Failure |
 22. |         Bolivia       2019    Success    Success |
 23. |           Chile       2019    Failure    Success |
 24. |         Lebanon       2019    Failure    Failure |
 25. |            Iraq       2019    Failure    Failure |
     |--------------------------------------------------|
 26. |         Belarus       2020    Failure    Failure |
 27. |      Kyrgyzstan       2020    Success    Success |
 28. |        Thailand       2020    Failure    Failure |
 29. |            Cuba       2021    Failure    Success |
 30. |        Eswatini       2021    Failure    Success |
     |--------------------------------------------------|
 31. |              US       2021    Failure    Failure |
 32. |         Myanmar       2021    Failure    Failure |
 33. |       Sri Lanka       2022    Success    Failure |
 34. |            Iran       2022    Failure    Failure |
 35. |      Bangladesh       2024    Success    Success |
     |--------------------------------------------------|
 36. |       Venezuela       2024    Failure    Success |
 37. |         Georgia       2024    Failure    Failure |
 38. |           Iran        2025    Failure    Failure |
 39. |           Nepal       2025    Success    Success |
 40. |         Georgia       2025    Failure    Failure |
     +--------------------------------------------------+
*/
tab immediate_outcome predicted, row
/*
           | Predicted Outcome of
 Immediate |    the Revolution
   Outcome |   Failure    Success |     Total
-----------+----------------------+----------
   Failure |        16          5 |        21 
           |     76.19      23.81 |    100.00 
-----------+----------------------+----------
   Success |         3         16 |        19 
           |     15.79      84.21 |    100.00 
-----------+----------------------+----------
     Total |        19         21 |        40 
           |     47.50      52.50 |    100.00 
*/

log close
