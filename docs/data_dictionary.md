# Data Dictionary

## Active source families

- `EPH`: Argentina household survey core
- `EPHPM`: Honduras household survey core
- `EPHC`: Paraguay household survey core
- `ERCE`: learning assessment layer
- `PISA`: OECD learning assessment layer
- `PISA-D`: PISA for Development layer
- `UIS learning API`: published UIS learning indicators
- `UIS admin`: published UIS administrative indicators
- `WPP API`: population denominators and age structures
- `OECD DAC/CRS`: finance and aid layer

## Household harmonized variables

- `country_code`: ISO3 country code
- `source_program`: household survey source family (`EPH`, `EPHPM`, `EPHC`)
- `survey_year`: annual source year used for indicator construction
- `wave_id`: within-source wave or release identifier
- `household_id_h`: harmonized household identifier within `country-year-source`
- `person_id_h`: harmonized person identifier within `country-year-source`
- `weight_h`: final expansion factor promoted into the harmonized file
- `age_h`: harmonized age in completed years
- `sex_h`: harmonized binary/official sex coding used for publication disaggregation
- `location_h`: harmonized territorial publication grouping (`urban/rural` or closest verified proxy)
- `attending_currently_h`: current attendance status used for attendance and out-of-school indicators
- `current_level_h`: current education level attended
- `highest_level_completed_h`: highest completed education level
- `highest_grade_completed_h`: highest completed grade/year within the completed level
- `literacy_h`: literacy status or documented literacy proxy
- `repetition_h`: repetition status when structurally available
- `exception_flag`: binary flag for comparability/publication issues
- `exception_note`: human-readable caveat linked to the exception log

## Source-native imported objects

- `$L_{ERCE_{c,d,g,t}}$`: ERCE learning layer by country, domain, grade, year
- `$L_{PISA_{c,d,t}}$`: PISA learning layer by country, domain, year
- `$L_{PISAD_{c,d,t}}$`: PISA-D learning layer by country, domain, year
- `$L_{UIS_{c,k,t}}$`: UIS learning API series by country, indicator, year
- `$A_{UIS_{c,k,t}}$`: UIS administrative series by country, indicator, year
- `$Pop_{WPP_{c,a,t}}$`: WPP population series by country, age/group, year
- `$F_{CRS_{c,t}}$`: OECD DAC/CRS finance series by recipient country and year
