import requests
import pandas as pd
import os
import io
import time

def fetch_oecd_finance(country_codes, start_year, end_year):
    print("Fetching OECD DAC/CRS Finance data via OECD SDMX API...")
    # SDMX API endpoint for CRS (Creditor Reporting System)
    # Structure: .../OECD.DCD.FSD,DSD_CRS@DF_CRS,1.5/{ACTION}.{DONOR}.{RECIPIENT}.{SECTOR}.{MEASURE}...
    # 110 = Education, 100 = Official Development Assistance, D = Disbursements, Q = Constant Prices, USD
    
    recipients = "+".join(country_codes)
    url = f"https://sdmx.oecd.org/public/rest/data/OECD.DCD.FSD,DSD_CRS@DF_CRS,1.5/.DAC.{recipients}.110.100._T._T.D.Q._T..USD"
    
    params = {
        "startPeriod": start_year,
        "endPeriod": end_year,
        "dimensionAtObservation": "AllDimensions"
    }
    
    headers = {"Accept": "application/vnd.sdmx.data+csv; charset=utf-8"}
    try:
        response = requests.get(url, params=params, headers=headers)
        response.raise_for_status()
        df = pd.read_csv(io.StringIO(response.text))
        
        if not df.empty:
            # Standardize columns
            df = df.rename(columns={
                "RECIPIENT": "country_code_uis",
                "TIME_PERIOD": "survey_year",
                "OBS_VALUE": "uis_value"
            })
            df["uis_indicator_id"] = "DC.ODA.EDUC.CD.CONST"
            df["uis_indicator_name"] = "ODA to Education (Constant USD)"
            df["local_indicator_id"] = "FIN_CRS"
            
            final_cols = ["country_code_uis", "survey_year", "uis_indicator_name", "uis_indicator_id", "uis_value", "local_indicator_id"]
            existing_cols = [c for c in final_cols if c in df.columns]
            df = df[existing_cols]
            print(f"  Successfully fetched {len(df)} OECD Finance records.")
            return df
    except Exception as e:
        print(f"  Error fetching OECD Finance data: {e}")
    return pd.DataFrame()


def fetch_oecd_pisa(country_codes):
    print("Fetching PISA data via OECD SDMX API...")
    # DSD_PISA endpoint
    countries = "+".join(country_codes)
    url = f"https://sdmx.oecd.org/public/rest/data/OECD.EDU.GPS,DSD_EAG_PISA@DF_PISA,1.0/{countries}...._T..."
    
    headers = {"Accept": "application/vnd.sdmx.data+csv; charset=utf-8"}
    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        df = pd.read_csv(io.StringIO(response.text))
        
        if not df.empty:
            df = df.rename(columns={
                "REF_AREA": "country_code_uis",
                "TIME_PERIOD": "survey_year",
                "OBS_VALUE": "uis_value"
            })
            df["uis_indicator_id"] = "PISA.SCORE"
            df["uis_indicator_name"] = "PISA Mean Score"
            df["local_indicator_id"] = "LEARN_PISA"
            
            final_cols = ["country_code_uis", "survey_year", "uis_indicator_name", "uis_indicator_id", "uis_value", "local_indicator_id"]
            existing_cols = [c for c in final_cols if c in df.columns]
            df = df[existing_cols]
            print(f"  Successfully fetched {len(df)} OECD PISA records.")
            return df
    except Exception as e:
        print(f"  Error fetching OECD PISA data: {e}")
    return pd.DataFrame()


def fetch_erce_pisad(country_codes):
    """
    Fallback to World Bank API for ERCE and PISA-D equivalents.
    While ERCE and PISA-D source data is LLECE/OECD, World Bank harmonizes some of this into Learning Poverty indicators.
    """
    print("Fetching ERCE/PISA-D related harmonized data via World Bank API...")
    url = "http://api.worldbank.org/v2/country/{}/indicator/{}"
    countries_str = ";".join(country_codes)
    
    indicators = {
        "LEARN_ERCE_PROXY": "SE.PRM.PROF.LLECE.RE.ZS", # LLECE Reading proficiency
        "LEARN_PISAD_PROXY": "SE.LPV.PRIM.OOS" # proxy
    }
    
    all_data = []
    for local_id, wb_code in indicators.items():
        params = {"format": "json", "per_page": 1000}
        try:
            response = requests.get(url.format(countries_str, wb_code), params=params)
            response.raise_for_status()
            data = response.json()
            if len(data) == 2 and data[1]:
                df = pd.DataFrame(data[1])
                df["country_code_uis"] = df["country"].apply(lambda x: x["id"] if isinstance(x, dict) else x)
                df["survey_year"] = df["date"]
                df["uis_value"] = df["value"]
                df["uis_indicator_id"] = wb_code
                df["uis_indicator_name"] = df["indicator"].apply(lambda x: x["value"] if isinstance(x, dict) else x)
                df["local_indicator_id"] = local_id
                df = df[df["uis_value"].notnull()]
                if not df.empty:
                    all_data.append(df)
                    print(f"  Successfully fetched {len(df)} records for {local_id}.")
        except Exception as e:
            print(f"  Error fetching {local_id}: {e}")
        time.sleep(0.5)
        
    if all_data:
        return pd.concat(all_data, ignore_index=True)
    return pd.DataFrame()

def main():
    output_dir = "data/benchmark"
    os.makedirs(output_dir, exist_ok=True)
    output_file = os.path.join(output_dir, "learning_finance_benchmarks.csv")
    
    country_codes = ["ARG", "HND", "PRY"]
    
    print("Starting Learning and Finance benchmark fetching...")
    df_finance = fetch_oecd_finance(country_codes, 2021, 2024)
    df_pisa = fetch_oecd_pisa(country_codes)
    df_erce = fetch_erce_pisad(country_codes)
    
    combined = pd.concat([df for df in [df_finance, df_pisa, df_erce] if not df.empty], ignore_index=True)
    
    if not combined.empty:
        combined.to_csv(output_file, index=False)
        print(f"\nSuccessfully saved Learning and Finance benchmarks to: {output_file}")
        print(f"Total benchmark records fetched: {len(combined)}")
    else:
        print("\nNo Learning or Finance benchmarks were fetched.")

if __name__ == "__main__":
    main()
