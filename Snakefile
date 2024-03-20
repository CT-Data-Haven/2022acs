from pathlib import Path

YEAR = 2022
CWS_YEAR = 2021
cities = ['bridgeport', 'hartford', 'new_haven', 'stamford']
pkgs = 'utils/pkgs_utils.R'

rule testvars:
    shell:
        'Rscript utils/pkgs_utils.R {YEAR} {CWS_YEAR}'

rule readme:
    output:
        'README.md'
    script:
        'README.Rmd'

rule meta:
    params:
        year = YEAR
    output:
        web = 'utils/{params.year}_website_meta.rds',
        reg_puma = 'utils/reg_puma_list.rds'
    script:
        'scripts/00_make_meta.R'

rule fetch:
    params:
        year = YEAR
    input:
        pkgs,
        rules.meta.output.web, 
    output: 
        acs = 'fetch_data/acs_basic_{params.year}_fetch_all.rds'
    script: 
        'scripts/01_fetch_acs_data.R'

rule calc_cws:
    params:
        cws_year = CWS_YEAR
    input:
        pkgs,
    output:
        cws_basic = 'output_data/cws_basic_indicators_{params.cws_year}.rds',
    script:
        'scripts/02_calc_cws_data.R'

rule calc_acs_towns:
    params:
        year = YEAR
    input:
        pkgs,
        rules.fetch.output.acs,
        # 'utils/indicator_headings.txt', # copied from somewhere else
    output:
        acs_csv = 'output_data/acs_town_basic_profile_{params.year}.csv',
        acs_town = 'output_data/acs_town_basic_profile_{params.year}.rds',
        town_distro = 'to_distro/town_acs_basic_distro_{params.year}.csv'
    script:
        'scripts/03_calc_acs_towns.R'

rule calc_acs_nhoods:
    params:
        year = YEAR
    input:
        pkgs,
        rules.fetch.output.acs,
        # 'utils/indicator_headings.txt',
    output:
        acs_city = 'output_data/acs_nhoods_by_city_{params.year}.rds',
        # can't use expand and params together?
        cities_distro = expand('to_distro/{city}_acs_basic_neighborhood_{year}.csv', city = cities, year = YEAR) 
    script:
        'scripts/04_calc_acs_nhoods.R'

rule prep_distro:
    params:
        year = YEAR
    input:
        rules.meta.output.web,
        rules.calc_acs_towns.output.acs_town,
        rules.calc_cws.output.cws_basic,
    output:
        'website/5year{params.year}town_profile_expanded_CWS.csv'
    script:
        'scripts/05_assemble_for_distro.R'

rule release:
    input:
        rules.calc_acs_towns.output.acs_town,
    script:
        'utils/upoad_gh_release.sh'


#### MAIN RULES -----
rule distro:
    input:
        rules.calc_acs_nhoods.output.acs_city,
        rules.prep_distro.output

rule all:
    input:
        rules.readme.output,
        rules.distro.input,
        rules.calc_acs_towns.output.acs_town
    default_target:
        True


#### CLEANUP -----
rule clean:
    shell:
        'rm -f output_data/* to_distro/* fetch_data/* website/* utils/*.rds'
