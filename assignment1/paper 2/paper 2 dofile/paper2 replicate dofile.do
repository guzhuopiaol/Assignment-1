* Repication of paper 2
* Replicate summary statistics
* Clean sufi database
use "/Users/yukerui/Desktop/cstatviolations_nss_20090701.dta", clear
gen year = substr(datadate, length(datadate)-3, 4)
gen day = substr(datadate, length(datadate)-5, 2)
gen month = substr(datadate, 1, 2)
destring year, replace
destring month, replace
destring day, replace
sort gvkey year month day
save "/Users/yukerui/Desktop/cstatviolations_nss_20090701.dta", replace

* Clean item 10 annual data
use "/Users/yukerui/Desktop/item10.dta", clear
drop datadate indfmt consol popsrc datafmt curcd costat
destring gvkey, replace

* Convert annual data to quarterly data
sort gvkey fyear
expand 4 if _n == 1 | (gvkey != gvkey[_n-1] | fyear != fyear[_n-1])
bysort gvkey fyear: gen fqtr = _n
by gvkey fyear: gen pstklq = pstkl[1]
sort gvkey fyear fqtr
save "/Users/yukerui/Desktop/item10.dta", replace

* Clean quarterly data and construct variables
use "/Users/yukerui/Desktop/h2jsxds0dwxhuwxp.dta", clear
destring gvkey, replace
drop if missing(datacqtr)
gen fyear = fyearq
sort gvkey fyear fqtr
merge 1:1 gvkey fyear fqtr using /Users/yukerui/Desktop/item10.dta
table _merge
drop if _merge == 2

* Set panel data
sort gvkey fyear fqtr
gen qdate = yq(fyearq, fqtr)
tsset gvkey qdate

* Calculate capital structure variable
* Net debt issuance (basis points)
gen book_debt = dlttq + dlcq
gen net_debt_issuance = (book_debt - L.book_debt) * 10000 / L.atq

* Net equity issuance (basis points)
gen net_equity_issuance = (sstky - prstkcy) * 1000 / L.atq

* Book debt/assets
gen book_debt_asset = book_debt / atq

* Calculate covenant control variables
* Net worth/assets
gen net_worth = atq - ltq
gen net_worth_assets = net_worth / atq

* Net working capital/assets
gen net_working_capital = actq - lctq
gen net_working_capital_asset = net_working_capital / atq

* Cash/assets
gen cash_asset = cheq / atq

* EBITDA/assets
gen ebitda_asset = oibdpq / L.atq

* Cash flow/assets
gen cash_flow = ibadjq + dpq
gen cash_flow_asset = (ibadjq + dpq) / L.atq

* Net income/assets
gen net_income_asset = niq / L.atq

* Interest expense/assets
gen interest_expense_asset = xintq / L.atq

* Calculate other control variables
* Market-to-book ratio
gen market_value_of_equity = prccq * cshoq
gen book_value_of_equity = atq - ltq - pstklq + txditcq
gen market_to_book = market_value_of_equity / book_value_of_equity

* Tangible assets/assets 
gen tangible_asset = ppentq / atq

* Ln(assets)
gen ln_asset = ln(atq)

* Merge data of sufi
gen year = year(datadate)
gen month = month(datadate)
gen day = day(datadate)
sort gvkey year month day 
drop _merge
merge 1:1 gvkey year month day using /Users/yukerui/Desktop/cstatviolations_nss_20090701.dta, force
drop if _merge == 2
drop _merge
sort gvkey qdate

* Select samples according to the requirements of the paper2
* Select samples from consecutive time periods. Required indicators: {saleq atq ppentq dlttq dlcq ltq cheq lctq actq oibdpq dpq niq xintq prccq cshoq pstklq txditcq}
gen lag_saleq = L.saleq
gen lag_atq = L.atq
gen lag_ppentq = L.ppentq
gen lag_book_debt = L.book_debt
gen lag_net_worth = L.net_worth
gen lag_cheq = L.cheq
gen lag_net_working_capital = L.net_working_capital
gen lag_oibdpq = L.oibdpq
gen lag_cash_flow = L.cash_flow
gen lag_net_income = L.niq
gen lag_interest_expense = L.xintq
gen lag_market_value_of_equity = L.market_value_of_equity
gen lag_book_value_of_equity = L.book_value_of_equity
gen lag_market_to_book = L.market_to_book

drop if missing(saleq, atq, ppentq, book_debt, net_worth, cheq, net_working_capital, oibdpq, cash_flow, niq, xintq, market_value_of_equity, book_value_of_equity, lag_market_to_book) | missing(lag_saleq, lag_atq, lag_ppentq, lag_book_debt, lag_net_worth, lag_cheq, lag_net_working_capital, lag_oibdpq, lag_cash_flow, lag_net_income, lag_interest_expense, lag_market_value_of_equity, lag_book_value_of_equity, lag_market_to_book)


* Select firms for which there are at least four consecutive quarters of available data
* Calculate consecutive quarters for each gvkey
by gvkey: gen consec_quarters = 1 if _n == 1
by gvkey: replace consec_quarters = consec_quarters[_n-1] + 1 if qdate == L.qdate + 1 & _n > 1

* Mark gvkey with at least four consecutive quarters
by gvkey: egen max_consec = max(consec_quarters)
gen at_least_4_consec = max_consec >= 4
keep if at_least_4_consec == 1

* Establish time span
keep if fyearq >= 1996 & fyearq <= 2005

* Winsorize variables
winsor2 net_debt_issuance, replace cut(5 95)
winsor2 net_equity_issuance, replace cut(5 95)
winsor2 book_debt_asset, replace cut(5 95)
winsor2 net_worth_assets, replace cut(5 95)
winsor2 net_working_capital_asset, replace cut(5 95)
winsor2 cash_asset, replace cut(5 95)
winsor2 ebitda_asset, replace cut(5 95)
winsor2 cash_flow_asset, replace cut(5 95)
winsor2 net_income_asset, replace cut(5 95)
winsor2 interest_expense_asset, replace cut(5 95)
winsor2 market_to_book, replace cut(5 95)
winsor2 tangible_asset, replace cut(5 95)
winsor2 ln_asset, replace cut(5 95)

* Summary statistics
tabstat net_debt_issuance net_equity_issuance book_debt_asset net_worth_assets net_working_capital_asset cash_asset ebitda_asset cash_flow_asset net_income_asset interest_expense_asset market_to_book tangible_asset ln_asset, s(mean p50 sd n) col(stat) f(%7.3f)

sort gvkey fyear fqtr
drop indfmt consol datafmt curcdq
save "/Users/yukerui/Desktop/paper2", replace

* Output table3
* Output panel A
* Calculate "has S&P rating" indicator
* I am unable to determine whether "has S&P rating" exists for each quarter. I can only try to define whether each company has "has S&P rating" for each year.
use "/Users/yukerui/Desktop/s&p.dta", clear
destring gvkey, replace
gen year = year(datadate)
gen spind = 0
bysort gvkey year: egen temp = max(cond(missing(splticrm) & missing(spsdrm) & missing(spsticrm), 0, 1))
replace spind = 1 if temp == 1
drop temp
duplicates drop gvkey year spind, force
sort gvkey year
expand 4 if _n == 1 | (gvkey != gvkey[_n-1] | year != year[_n-1])
bysort gvkey year: gen fqtr = _n
by gvkey year: gen spind1 = spind[1]
rename year fyear
sort gvkey fyear fqtr
save "/Users/yukerui/Desktop/sp", replace

* Merge data
use "/Users/yukerui/Desktop/paper2", clear
sort gvkey fyear fqtr
merge 1:1 gvkey fyear fqtr using /Users/yukerui/Desktop/sp.dta
drop if _merge == 2
drop _merge

* Run regression
* Indentify calendar year and quarter 
gen cyear = substr(datacqtr, 1, 4)
destring cyear, replace
gen cqtr = substr(datacqtr, length(datacqtr), 1)
destring cqtr, replace

* Construct calendar year-quarter indicator 
egen cal = group(cyear cqtr)

* Column 1
xtset gvkey qdate
gen lviol = L.viol
xtreg net_debt_issuance viol lviol i.cal i.fqtr, fe vce(cluster gvkey) 
outreg2 using "/Users/yukerui/Desktop/panela1.doc"

* Column 2
* Control variables
gen lln_asset = L.ln_asset
gen ltangible_asset = L.tangible_asset 
gen lmarket_to_book = L.market_to_book
gen lspind = L.spind

* 11 covenant control variables
gen lbook_debt_asset = L.book_debt_asset
gen lnet_worth_assets = L.net_worth_assets
gen lcash_asset = L.cash_asset
gen lebitda_asset= L.ebitda_asset
* Current EBITDA to lagged assets ratio has been generated by ebitda_asset = oibdpq / L.atq
gen lcash_flow_asset = L.cash_flow_asset
* Current cash flow to lagged assets ratio has been generated by cash_flow_asset = (ibadq + dpq) / L.atq
gen lnet_income_asset = L.net_income_asset
* Current net income to lagged assets ratio has been generated by net_income_asset = niq / L.atq
gen linterest_expense_asset = L.interest_expense_asset
* current interest expense to lagged assets ratio has been generated by gen interest_expense_asset = xintq / L.atq

xtreg net_debt_issuance viol lviol lln_asset ltangible_asset lmarket_to_book lspind lbook_debt_asset lnet_worth_assets lcash_asset lebitda_asset ebitda_asset lcash_flow_asset cash_flow_asset lnet_income_asset net_income_asset linterest_expense_asset interest_expense_asset i.cal i.fqtr, fe vce(cluster gvkey)
outreg2 using "/Users/yukerui/Desktop/panela2.doc"

* Column 3
* Covenant control interaction variables
gen interaction1 = lbook_debt_asset * lcash_flow_asset
gen interaction2 = lbook_debt_asset * lebitda_asset
gen interaction3 = lbook_debt_asset * lnet_worth_assets
gen interaction4 = lebitda_asset * linterest_expense_asset

xtreg net_debt_issuance viol lviol lln_asset ltangible_asset lmarket_to_book lspind lbook_debt_asset lnet_worth_assets lcash_asset lebitda_asset ebitda_asset lcash_flow_asset cash_flow_asset lnet_income_asset net_income_asset linterest_expense_asset interest_expense_asset interaction1 interaction2 interaction3 interaction4 i.cal i.fqtr, fe vce(cluster gvkey)
outreg2 using "/Users/yukerui/Desktop/panela3.doc"

* Column 4
* Generate these variables squared and to the third power
foreach var in lbook_debt_asset lnet_worth_assets lcash_asset lebitda_asset ebitda_asset lcash_flow_asset cash_flow_asset lnet_income_asset net_income_asset linterest_expense_asset interest_expense_asset interaction1 interaction2 interaction3 interaction4 {
    gen `var'_s2 = `var'^2
    gen `var'_c3 = `var'^3
	egen `var'_ile = xtile(`var'), nq(5)
}

xtreg net_debt_issuance viol lviol lln_asset ltangible_asset lmarket_to_book lspind lbook_debt_asset lnet_worth_assets lcash_asset lebitda_asset ebitda_asset lcash_flow_asset cash_flow_asset lnet_income_asset net_income_asset linterest_expense_asset interest_expense_asset interaction1 interaction2 interaction3 interaction4 *_s2 *_c3 i.*_ile i.cal i.fqtr, fe vce(cluster gvkey)
outreg2 using "/Users/yukerui/Desktop/panela4.doc"

* Output panel B
* Column 1
gen bnet_debt_issuance = D.net_debt_issuance
reghdfe bnet_debt_issuance viol lviol, absorb(cal fqtr) vce(cluster gvkey) 
outreg2 using "/Users/yukerui/Desktop/panelb1.doc"

xtreg bnet_debt_issuance viol lviol i.cal i.fqtr, vce(cluster gvkey) 

* Column 2
gen blln_asset = D.lln_asset
gen bltangible_asset = D.ltangible_asset 
gen blmarket_to_book = D.lmarket_to_book
gen blspind = D.lspind

gen bbook_debt_asset = book_debt_asset - L2.book_debt_asset
gen blnet_worth_assets = D.lnet_worth_assets
gen blcash_asset = D.lcash_asset
gen blebitda_asset = D.lebitda_asset
gen bebitda_asset = D.ebitda_asset
gen blcash_flow_asset = D.lcash_flow_asset
gen bcash_flow_asset = D.cash_flow_asset
gen blnet_income_asset = D.lnet_income_asset
gen bnet_income_asset = D.net_income_asset
gen blinterest_expense_asset = D.linterest_expense_asset
gen binterest_expense_asset = D.interest_expense_asset

reghdfe bnet_debt_issuance viol lviol blln_asset bltangible_asset blmarket_to_book blspind bbook_debt_asset blnet_worth_assets blcash_asset blebitda_asset bebitda_asset blcash_flow_asset bcash_flow_asset blnet_income_asset bnet_income_asset blinterest_expense_asset binterest_expense_asset, absorb(cal fqtr) vce(cluster gvkey)
outreg2 using "/Users/yukerui/Desktop/panelb2.doc"

* Column 3
gen binteraction1 = interaction1 - L2.interaction1
gen binteraction2 = interaction2 - L2.interaction2
gen binteraction3 = interaction3 - L2.interaction3
gen binteraction4 = D.interaction4 

reghdfe bnet_debt_issuance viol lviol blln_asset bltangible_asset blmarket_to_book blspind bbook_debt_asset blnet_worth_assets blcash_asset blebitda_asset bebitda_asset blcash_flow_asset bcash_flow_asset blnet_income_asset bnet_income_asset blinterest_expense_asset binterest_expense_asset binteraction1 binteraction2 binteraction3 binteraction4, absorb(cal fqtr) vce(cluster gvkey)
outreg2 using "/Users/yukerui/Desktop/panelb3.doc"

* Column 4
foreach var in bbook_debt_asset blnet_worth_assets blcash_asset blebitda_asset bebitda_asset blcash_flow_asset bcash_flow_asset blnet_income_asset bnet_income_asset blinterest_expense_asset binterest_expense_asset binteraction1 binteraction2 binteraction3 binteraction4 {
    gen `var'_s2 = `var'^2
    gen `var'_c3 = `var'^3
	egen `var'_ile = xtile(`var'), nq(5)
}
reghdfe bnet_debt_issuance viol lviol blln_asset bltangible_asset blmarket_to_book blspind bbook_debt_asset blnet_worth_assets blcash_asset blebitda_asset bebitda_asset blcash_flow_asset bcash_flow_asset blnet_income_asset bnet_income_asset blinterest_expense_asset binterest_expense_asset binteraction1 binteraction2 binteraction3 binteraction4 *_s2 *_c3, absorb(cal fqtr *_ile) vce(cluster gvkey)
outreg2 using "/Users/yukerui/Desktop/panelb4.doc"
