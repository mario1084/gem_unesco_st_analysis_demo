# Stack Status

## Canonical status

The active demo stack is complete for the intended reconstruction.

### Household annual reconstruction window
- `Argentina`: `EPH 2021-2024`
- `Honduras`: `EPHPM 2021-2024`
- `Paraguay`: `EPHC 2021-2024`

### Learning layer
- `ERCE 2019`
- `PISA 2022`
- `PISA-D 2016`
- `UIS learning API 2021-2024`

### Admin and reference layer
- `UIS admin 2021-2024`
- `WPP API 2021-2024`

### Finance layer
- `OECD DAC/CRS 2021-2024`

## Demo interpretation

- `WIDE`-style household indicators are reconstructed as annual country-year series over `2021-2024`.
- Learning, admin, population, and finance layers remain source-native and are integrated at their own canonical source year.
- This repository is a technical reconstruction demo, not a claim of full production equivalence with UNESCO internal pipelines.

## Out of active scope

- `MICS` and `DHS` were archived from the staging workspace and do not enter this demo repo.
- `IPUMS International` remains outside the demo because approval was pending at staging time.

## Method documents

- `docs/gem_methodology.md`
- `docs/gem_method_harmonization.md`
- `docs/gem_method_indicator.md`

## Next implementation steps

1. Finalize `config/crosswalk.csv`
2. Finalize `config/indicator_registry.csv`
3. Implement household harmonization in `R/harmonization/`
4. Implement annual indicator estimation in `R/indicators/`
5. Generate publication-ready outputs in `data/output/` and `results/`
