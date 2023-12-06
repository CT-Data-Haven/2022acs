YR := 2022
CWS_YR := 2021
RUN_R = Rscript $< $(YR) $(CWS_YR)
KNIT = Rscript -e "rmarkdown::render('$<', output_format = rmarkdown::github_document(html_preview = FALSE))"

.PHONY: testvars
testvars:
	Rscript utils/pkgs_utils.R $(YR) $(CWS_YR)

.PHONY: all
all: README.md distro output_data/acs_town_basic_profile_$(YR).rds

.PHONY: distro
distro: output_data/acs_nhoods_by_city_$(YR).rds website/5year$(YR)town_profile_expanded_CWS.csv

#### METADATA ----
# writes website_meta, downloads reg_puma_list
utils/$(YR)_website_meta.rds utils/reg_puma_list.rds &: scripts/00_make_meta.R
	$(RUN_R)
	
README.md: README.Rmd
	$(KNIT)

#### OUTPUT ----
fetch_data/acs_basic_$(YR)_fetch_all.rds: scripts/01_fetch_acs_data.R
	$(RUN_R)

output_data/cws_basic_indicators_$(CWS_YR).rds: scripts/02_calc_cws_data.R
	$(RUN_R)

output_data/acs_town_basic_profile_$(YR).rds output_data/acs_town_basic_profile_$(YR).csv to_distro/town_acs_basic_distro_$(YR).csv &: scripts/03_calc_acs_towns.R 
	$(RUN_R)

output_data/acs_nhoods_by_city_$(YR).rds $(wildcard to_distro/*_acs_basic_neighborhood_$(YR).csv) &: scripts/04_calc_acs_nhoods.R
	$(RUN_R)

website/5year$(YR)town_profile_expanded_CWS.csv: scripts/05_assemble_for_distro.R
	$(RUN_R)

#### SCRIPTS ----
scripts/%.R: utils/pkgs_utils.R

scripts/01_fetch_acs_data.R: utils/reg_puma_list.rds

scripts/03_calc_acs_towns.R: fetch_data/acs_basic_$(YR)_fetch_all.rds utils/indicator_headings.txt

scripts/04_calc_acs_nhoods.R: fetch_data/acs_basic_$(YR)_fetch_all.rds utils/indicator_headings.txt

scripts/05_assemble_for_distro.R: utils/$(YR)_website_meta.rds \
  output_data/acs_town_basic_profile_$(YR).rds \
	output_data/cws_basic_indicators_$(CWS_YR).rds \
	utils/indicator_headings.txt

#### RELEASE ----
.PHONY: release
release: utils/upload_gh_release.sh

utils/upload_gh_release.sh:
	bash $@

#### CLEANUP ----
.PHONY: clean
clean:
	rm -f output_data/* to_distro/* fetch_data/* website/* utils/*.rds
