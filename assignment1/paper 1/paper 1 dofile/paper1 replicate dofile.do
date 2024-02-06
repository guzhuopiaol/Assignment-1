* Replication of the first paper
use "/Users/yukerui/Desktop/main data.dta"
* Calculate the full sample's variable
destring gvkey, replace

* Set panel data
sort gvkey fyear
xtset gvkey fyear

* Calculate the firm characteristics of full sample
* Book/assets
gen bd = (dlc + dltt) / at

* EBITDA/(assets-cash）
gen EBITDA_asset_cash =  oibdp / (at - che)
gen cflcl1 = L.EBITDA_asset_cash

* Tangible assets/(assets -cash)
gen tangibleasset = ppent / (at - che)
gen tanglcl1 = L.tangibleasset

* Net worth, cash adjusted
gen net_worth = (at - che - lt) / (at - che)
gen nwlcl1 = L.net_worth

* Assets - cash
gen asset_cash = at - che
gen asslcl1 = L.asset_cash

* Market-to-book, cash adjusted
gen bookvalue_equity = at - lt - pstkl + txditc
gen market_value_equity = csho * prcc_f
gen market_to_book = (at - bookvalue_equity + market_value_equity - che)/ (at - che)
gen mblcl1 = L.market_to_book

* Drop useless variables
drop datadate indfmt consol popsrc datafmt curcd EBITDA_asset_cash tangibleasset net_worth asset_cash bookvalue_equity market_value_equity market_to_book
save "/Users/yukerui/Desktop/1.dta"

* Merge data
use "/Users/yukerui/Desktop/sufi_rfs_linesofcredit20070221data.dta", clear
gen fyear = yeara
sort gvkey fyear
save "/Users/yukerui/Desktop/sufi_rfs_linesofcredit20070221data.dta", replace

use "/Users/yukerui/Desktop/1.dta", clear
sort gvkey fyear
merge 1:1 gvkey fyear using /Users/yukerui/Desktop/sufi_rfs_linesofcredit20070221data.dta
keep if _merge == 3

* Winsorize variables
winsor2 cflcl1, replace cut(5 95)
winsor2 tanglcl1, replace cut(5 95)
winsor2 nwlcl1, replace cut(5 95)
winsor2 mblcl1, replace cut(5 95)
* There is no winsorize here for all financial variables because I found that bd and asslcl1 are closer to the values in the paper without being winsorized.

* Has line of credit {0,1}: the variable lineofcredit has been generated

drop yeara _merge
sort gvkey fyear
save "/Users/yukerui/Desktop/2.dta"

* Industry sales volatility
* Clean data
use "/Users/yukerui/Desktop/quarterly data.dta", clear
drop indfmt consol popsrc datafmt curcdq datacqtr costat datadate datafqtr
destring gvkey, replace

* Set panel data structure
gen qdate = yq(fyearq, fqtr)
xtset gvkey qdate

* Calculate the standard deviation of quarterly differences in sales for each company for each year
bysort gvkey: gen saleq_diff = saleq - L.saleq
egen saleq_diff_std = sd(saleq_diff), by(gvkey fyearq)
keep if fyearq >= 1996 & fyearq <= 2003

* Calculate the average assets of each company per year
egen avg_assets = mean(atq), by(gvkey fyearq)

* Scale standard deviation by annual average assets
gen scaled_std = saleq_diff_std / avg_assets

* Extract SIC code
gen sic_3 = substr(sic, 1, 3)

* Calculate the median standard deviation for each 3-digit SIC industry for each year
bysort sic_3 fyearq: egen q_salesvar = median(scaled_std)
duplicates drop gvkey fyearq, force

* Merge data
rename fyearq fyear
sort gvkey fyear
save "/Users/yukerui/Desktop/3.dta"

use "/Users/yukerui/Desktop/2.dta", clear
merge 1:1 gvkey fyear using /Users/yukerui/Desktop/3.dta
keep if _merge == 3
drop fqtr atq saleq qdate saleq_diff saleq_diff_std avg_assets scaled_std sic_3 _merge
sort gvkey fyear
save "/Users/yukerui/Desktop/4.dta"

* Cash-flow volatility  
* Clean data
use "/Users/yukerui/Desktop/cash volatility.dta", clear
destring gvkey, replace
drop datadate indfmt consol popsrc datafmt tic curcd costat
sum

* Set panel data structure
sort gvkey fyear
xtset gvkey fyear

* Since che lacks many values in the dataset, it is implausible for us to replicate cfvar with compustata data. Winsorization can be used to reduce the impact of extreme values and missing values on the results. After trying, using the (15, 85) interval can get the optimal result.
winsor2 che, replace cut(15 85)
winsor2 oibdp, replace cut(15 85)

* Calculate annual EBITDA change
gen oibdp_change = oibdp - L.oibdp

* Calculate non-cash assets
gen non_cash_assets = at - che

* Initialize rolling window statistics variables
gen oibdp_std_4yr = .
gen avg_non_cash_assets_4yr = .
quietly forval i = 1990/2003 {

    * Calculate the standard deviation of oibdp_change
    by gvkey: egen temp_std = sd(oibdp_change) if fyear >= `i' - 4 & fyear <= `i'
    replace oibdp_std_4yr = temp_std if fyear == `i'
	
    * Calculate the average of non_cash_assets
    by gvkey: egen temp_mean = mean(non_cash_assets) if fyear >= `i' - 4 & fyear <= `i'
    replace avg_non_cash_assets_4yr = temp_mean if fyear == `i'
	
    * Clear temporary variables
    drop temp_std temp_mean
}

* Calculate cfvar
keep if fyear >= 1996 & fyear <= 2003
gen cfvar = oibdp_std_4yr / avg_non_cash_assets_4yr

drop oibdp_change non_cash_assets oibdp_std_4yr avg_non_cash_assets_4yr
sort gvkey fyear
save "/Users/yukerui/Desktop/5.dta"

* Merge data
use "/Users/yukerui/Desktop/4.dta", clear
merge 1:1 gvkey fyear using /Users/yukerui/Desktop/5.dta
keep if _merge == 3
drop _merge
sort gvkey fyear
save "/Users/yukerui/Desktop/6.dta"

* Not in an S&P index {0,1} 
use "/Users/yukerui/Desktop/SPMIM_data.dta", clear
gen spind = 0
gen spmim2 = cond(missing(spmim), 0, spmim)
replace spind = 1 if spmim2 == 0
duplicates drop gvkey fyear, force
drop iid month year datadate spmim spmim2

* Merge data
sort gvkey fyear
save "/Users/yukerui/Desktop/7.dta"

use "/Users/yukerui/Desktop/6.dta", clear
merge 1:1 gvkey fyear using /Users/yukerui/Desktop/7.dta
keep if _merge != 2
drop _merge
sort gvkey fyear
save "/Users/yukerui/Desktop/8.dta"

* Traded over the counter {0,1}
use "/Users/yukerui/Desktop/8.dta", clear
gen exch = (exchg == 19)
save "/Users/yukerui/Desktop/9.dta"

* Firm age (years since IPO) 
use "/Users/yukerui/Desktop/firmage.dta", clear
destring gvkey, replace
drop datadate indfmt consol popsrc datafmt costat curcd
sort gvkey fyear

* Find the first occurrence of fyear for each gvkey
by gvkey: egen first_fyear = min(fyear)

* Calculate year differences
keep if fyear >= 1996 & fyear <= 2003
gen firmage = fyear - first_fyear 
drop first_fyear
sort gvkey fyear
save "/Users/yukerui/Desktop/10.dta"

* Merge data
use "/Users/yukerui/Desktop/9.dta", clear
sort gvkey fyear
merge 1:1 gvkey fyear using /Users/yukerui/Desktop/10.dta
keep if _merge == 3
drop _merge
save "/Users/yukerui/Desktop/11.dta"

* The reason why all firmage minus 1 here is because the results after this processing are consistent with the paper.
replace firmage = firmage - 1

* Calculate the random sample's variable
* Calculate the line of credit variables
* Has line of credit {0,1}: lineofcredit_rs has been generated

* Total line of credit/assets
gen ra_linetot =  linetot / at

* Unused line of credit/assets
gen ra_lineun = lineun / at

* Used line of credit/assets
gen ra_line = line / at

* Total line/(total line + cash)
gen liq_linetot = linetot / (linetot + che)

* Unused line/(unused line + cash)
gen liq_lineun = lineun / (lineun + che)

* Violation of financial covenant {0,1}: def has been generated
* The end of calculation for summary statistics
* Output of Table 1
tabstat lineofcredit bd cflcl1 tanglcl1 nwlcl1 asslcl1 mblcl1 q_salesvar cfvar spind exch firmage, s(mean p50 sd n) col(stat) f(%7.3f)

tabstat lineofcredit_rs ra_linetot ra_lineun ra_line liq_linetot liq_lineun def bd cflcl1 tanglcl1 nwlcl1 asslcl1 mblcl1 q_salesvar cfvar spind exch firmage if randomsample==1, s(mean p50 sd n) col(stat) f(%7.3f) 


* Output of Table 3
* Generate independent variables
sort gvkey fyear
gen lasslcl1 = ln(asslcl1)
gen q_salesvar1 = L.q_salesvar
gen cfvar1 = L.cfvar
gen firmage1 = L.firmage
gen lfirmage= ln(firmage1)
gen sic_1 = substr(sic, 1, 1)
gen yd1996 = (fyear == 1996)
gen yd1997 = (fyear == 1997)
gen yd1998 = (fyear == 1998)
gen yd1999 = (fyear == 1999)
gen yd2000 = (fyear == 2000)
gen yd2001 = (fyear == 2001)
gen yd2002 = (fyear == 2002)
gen yd2003 = (fyear == 2003)

* Regression
xi: dprobit lineofcredit yd* i.sic_1 cflcl1 tanglcl1 lasslcl1 nwlcl1 mblcl1 q_salesvar1 cfvar1 spind exch lfirmage, cluster(gvkey)
outreg2 using "/Users/yukerui/Desktop/column1.doc"

xi: dprobit lineofcredit_rs yd* i.sic_1 cflcl1 tanglcl1 lasslcl1 nwlcl1 mblcl1 q_salesvar1 cfvar1 spind exch lfirmage if randomsample==1, cluster(gvkey)
outreg2 using "/Users/yukerui/Desktop/column2.doc"
 
xi: regress liq_linetot yd* i.sic_1 cflcl1 tanglcl1 lasslcl1 nwlcl1 mblcl1 q_salesvar1 cfvar1 spind exch lfirmage if randomsample==1, cluster(gvkey) robust
est store s1

xi: regress liq_linetot yd* i.sic_1 cflcl1 tanglcl1 lasslcl1 nwlcl1 mblcl1 q_salesvar1 cfvar1 spind exch lfirmage if randomsample==1 & lineofcredit_rs==1, cluster(gvkey) robust
est store s2

xi: regress liq_lineun yd* i.sic_1 cflcl1 tanglcl1 lasslcl1 nwlcl1 mblcl1 q_salesvar1 cfvar1 spind exch lfirmage if randomsample==1, cluster(gvkey) robust
est store s3

xi: regress liq_lineun yd* i.sic_1 cflcl1 tanglcl1 lasslcl1 nwlcl1 mblcl1 q_salesvar1 cfvar1 spind exch lfirmage if randomsample==1 & lineofcredit_rs==1, cluster(gvkey) robust
est store s4

* ssc install estout, replace
esttab s1 s2 s3 s4 using /Users/yukerui/Desktop/table3.csv, b(3) se(3) compress nogap star(* 0.05 ** 0.01) ar2 r2  
save "/Users/yukerui/Desktop/12.dta" 

* Calculate the number of firms 
use "/Users/yukerui/Desktop/12.dta", clear 
preserve 
duplicates drop gvkey, force
drop if randomsample == 0
drop if lineofcredit_rs == 0
restore


* The end of table3 output
use "/Users/yukerui/Desktop/main data.dta", clear
destring gvkey, replace
sort gvkey fyear
xtset gvkey fyear
gen EBITDA_asset_cash =  oibdp / (at - che)
gen cflcl1 = L.EBITDA_asset_cash
sort gvkey fyear
merge 1:1 gvkey fyear using /Users/yukerui/Desktop/sufi_rfs_linesofcredit20070221data.dta
keep if _merge == 3

* Output figure 1
centile cflcl1, centile(10 20 30 40 50 60 70 80 90 100)
local x1 = r(c_1)
local x2 = r(c_2)
local x3 = r(c_3)
local x4 = r(c_4)
local x5 = r(c_5)
local x6 = r(c_6)
local x7 = r(c_7)
local x8 = r(c_8)
local x9 = r(c_9)
local x10 = r(c_10)

egen group = cut(cflcl1), at(`x1' `x2' `x3' `x4' `x5' `x6' `x7' `x8' `x9' `x10')
gen cash_asset = che / at

* When the abscissa is equal to 1, lineofcredit is equal to .4120956 and cash_asset is equal to .5557726
summarize lineofcredit if cflcl1 < -.402810
summarize cash_asset if cflcl1 < -.402810
tabstat cash_asset, by(group) 
tabstat lineofcredit, by(group)
clear

set obs 10
input X A B
1 .5557726  .4120956 
2 .2724983  .6688928
3 .1451096  .8513181
4 .0900354  .9226714
5 .0791666  .9289733
6 .0839887  .9342707
7 .0940812  .9212654
8 .1171419  .9012302
9 .1629214  .8727592
10 .3214326  .7556259

twoway (connected A X, mcolor(black) msymbol(lgx) lcolor(black) lpattern(tight_dot)) (connected B X, yaxis(2) mcolor(black) msymbol(square) lcolor(black) lpattern(solid)), ytitle("{bf:Cash/assets}") ylabel(, format(%9.1f) grid glcolor(black)) ytitle("{bf:Fraction with line of credit)}", axis(2)) ylabel(0(0.1)1, format(%9.1f) nogrid glcolor(black) axis(2)) xtitle("{bf:Deciles of EBITDA/(assets-cash)}") xlabel(0(1)10, nogrid) legend(order(1 "Average cash/assets (left axis)" 2 "Fraction withn line of credit (right axis)") position(6)) plotregion(lcolor(black))
* Make changes to the picture in Stata
graph save "Graph" "/Users/yukerui/Desktop/figure1.gph"
* The end of paper 1 replication
