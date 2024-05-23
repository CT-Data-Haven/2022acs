from pathlib import Path

year = 2022
cws_year = 2021
cities = ["bridgeport", "hartford", "new_haven", "stamford"]
fetch_data = f"fetch_data/acs_basic_{year}_fetch_all.rds"


def r_with_args(script):
    cmd = f"Rscript {script} {year} {cws_year}"
    return cmd


rule testvars:
    shell:
        "Rscript utils/pkgs_utils.R {year} {cws_year}"


rule readme:
    input:
        'Snakefile',
    output:
        "README.md",
    script:
        "README.Rmd"


# rule run_R:
#     input:
#         script = 'scripts/{script}.R',
#     shell:
#         r_with_args("{input.script}")
rule download_meta:
    output:
        reg_puma = 'utils/reg_puma_list.rds',
        # flag = '.meta_downloaded.json',
        # headings = 'utils/indicator_headings.txt',
    script:
        'scripts/00a_download_meta.sh'

rule meta:
    input:
        # rules.download_meta.output.flag,
        rules.download_meta.output.reg_puma,
        script = 'scripts/00_make_meta.R',
    output:
        web=f"utils/{year}_website_meta.rds",
        # reg_puma="utils/reg_puma_list.rds",
    shell:
        r_with_args("{input.script}")


rule fetch:
    input:
        rules.download_meta.output.reg_puma,
        script = 'scripts/01_fetch_acs_data.R',
    output:
        acs=f"fetch_data/acs_basic_{year}_fetch_all.rds",
    shell:
        r_with_args("{input.script}")


rule calc_cws:
    input:
        script = 'scripts/02_calc_cws_data.R',
    output:
        cws_basic=f"output_data/cws_basic_indicators_{cws_year}.rds",
    shell:
        r_with_args("{input.script}")


rule calc_acs_towns:
    input:
        rules.fetch.output.acs,
        'utils/indicator_headings.txt',
        script = 'scripts/03_calc_acs_towns.R',
    output:
        acs_csv=f"output_data/acs_town_basic_profile_{year}.csv",
        acs_town=f"output_data/acs_town_basic_profile_{year}.rds",
        town_distro=f"to_distro/town_acs_basic_distro_{year}.csv",
    shell:
        r_with_args("{input.script}")


rule calc_acs_nhoods:
    input:
        rules.fetch.output.acs,
        'utils/indicator_headings.txt',
        script = 'scripts/04_calc_acs_nhoods.R',
    output:
        acs_city=f"output_data/acs_nhoods_by_city_{year}.rds",
        # can't use expand and params together?
        cities_distro=expand(
            "to_distro/{city}_acs_basic_neighborhood_{yr}.csv", city=cities, yr=year
        ),
    shell:
        r_with_args("{input.script}")


rule prep_distro:
    input:
        'utils/indicator_headings.txt',
        rules.meta.output.web,
        rules.calc_acs_towns.output.acs_town,
        rules.calc_cws.output.cws_basic,
        script = 'scripts/05_assemble_for_distro.R',
    output:
        website_csv = f"website/5year{year}town_profile_expanded_CWS.csv",
    shell:
        r_with_args("{input.script}")


rule release:
    input:
        town = rules.calc_acs_towns.output.acs_town,
        nhood = rules.calc_acs_nhoods.output.acs_city,
        script = 'scripts/upload_gh_release.sh',
    output:
        flag = '.uploaded.json',
    shell:
        'bash {input.script} {input.town} {input.nhood}'


#### MAIN RULES -----
rule distro:
    input:
        rules.calc_acs_nhoods.output.acs_city,
        rules.prep_distro.output,
        rules.release.output,


rule all:
    input:
        rules.readme.output,
        rules.distro.input,
        rules.calc_acs_towns.output.acs_town,
        rules.release.output.flag,
        # expand('scripts/{script}.R', script = glob_wildcards('scripts/{script}.R').script)
    default_target: True


#### CLEANUP -----
rule clean:
    shell:
        "rm -f output_data/* to_distro/* fetch_data/* website/* utils/*.rds"
