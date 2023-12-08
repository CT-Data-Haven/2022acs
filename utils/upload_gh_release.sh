#!/usr/bin/env bash
YR=2022
# metadata for other projects
# is there already a release called dist? if not, create one
if ! gh release view dist; then
  gh release create dist --title "acs basic profile data"
fi
gh release upload dist "output_data/acs_town_basic_profile_${YR}.rds" --clobber
