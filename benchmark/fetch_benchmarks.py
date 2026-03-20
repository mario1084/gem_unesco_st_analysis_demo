import requests
import pandas as pd
import os
import time

def fetch_wb_benchmark_data(country_codes, years):
    base_url = "http://api.worldbank.org/v2/country/{country}/indicator/{indicator}"
    all_data = []
    
    # Comprehensive Mapping of internal indicators to World Bank API
    wb_indicator_map = {
        # Attendance / Enrollment
        "ATTEND_LVL_PRM": "SE.PRM.NENR", 
        "ATTEND_LVL_PRM_M": "SE.PRM.NENR.MA", 
        "ATTEND_LVL_PRM_F": "SE.PRM.NENR.FE",
        "ATTEND_LVL_SEC": "SE.SEC.NENR", 
        "ATTEND_LVL_SEC_M": "SE.SEC.NENR.MA", 
        "ATTEND_LVL_SEC_F": "SE.SEC.NENR.FE",
        
        # Out of school
        "OOS_LVL_PRM": "SE.PRM.UNER", 
        "OOS_LVL_PRM_M": "SE.PRM.UNER.MA", 
        "OOS_LVL_PRM_F": "SE.PRM.UNER.FE",
        
        # Completion
        "COMP_LVL_PRM": "SE.PRM.CMPT.ZS", 
        "COMP_LVL_PRM_M": "SE.PRM.CMPT.MA.ZS", 
        "COMP_LVL_PRM_F": "SE.PRM.CMPT.FE.ZS",
        "COMP_LVL_LSEC": "SE.SEC.CMPT.LO.ZS", 
        "COMP_LVL_LSEC_M": "SE.SEC.CMPT.LO.MA.ZS", 
        "COMP_LVL_LSEC_F": "SE.SEC.CMPT.LO.FE.ZS",
        
        # Literacy
        "LIT_RATE": "SE.ADT.1524.LT.ZS", 
        "LIT_RATE_M": "SE.ADT.1524.LT.MA.ZS", 
        "LIT_RATE_F": "SE.ADT.1524.LT.FE.ZS",
        
        # Repetition
        "REP_RATE_PRM": "SE.PRM.REPT.ZS", 
        "REP_RATE_PRM_M": "SE.PRM.REPT.MA.ZS", 
        "REP_RATE_PRM_F": "SE.PRM.REPT.FE.ZS",
        "REP_RATE_SEC": "SE.SEC.REPT.ZS", 
        "REP_RATE_SEC_M": "SE.SEC.REPT.MA.ZS", 
        "REP_RATE_SEC_F": "SE.SEC.REPT.FE.ZS",
        
        # Admin / Reference
        "ADMIN_UIS": "SE.PRM.ENRL",
        "POP_WPP": "SP.POP.TOTL"
    }
    
    countries_str = ";".join(country_codes)
    start_year = min(years)
    end_year = max(years)
    
    print("Starting World Bank API (UNESCO Mirror) data fetching...")
    for local_id, wb_code in wb_indicator_map.items():
        print("Fetching data for internal indicator " + local_id + " (WB code: " + wb_code + ")...")
        url = base_url.format(country=countries_str, indicator=wb_code)
        params = {
            "date": str(start_year) + ":" + str(end_year),
            "format": "json",
            "per_page": 1000
        }
        
        try:
            response = requests.get(url, params=params)
            response.raise_for_status()
            data = response.json()
            
            # WB API returns [pagination_info, [data_list]]
            if len(data) == 2 and data[1]:
                df = pd.DataFrame(data[1])
                
                # Flatten the 'country' and 'indicator' dictionaries
                df["country_name"] = df["country"].apply(lambda x: x["value"] if isinstance(x, dict) else x)
                df["country_code_uis"] = df["country"].apply(lambda x: x["id"] if isinstance(x, dict) else x)
                df["uis_indicator_name"] = df["indicator"].apply(lambda x: x["value"] if isinstance(x, dict) else x)
                df["uis_indicator_id"] = wb_code
                
                # Rename key columns to match our standard
                df = df.rename(columns={"date": "survey_year", "value": "uis_value"})
                df["local_indicator_id"] = local_id
                
                all_data.append(df)
                print("  Successfully fetched " + str(len(df)) + " records.")
            else:
                print("  No data found.")
        except Exception as e:
            print("  Error fetching data: " + str(e))
        time.sleep(0.5)
    
    if all_data:
        return pd.concat(all_data, ignore_index=True)
    else:
        return pd.DataFrame()

def main():
    output_dir = "data/benchmark"
    os.makedirs(output_dir, exist_ok=True)
    output_file = os.path.join(output_dir, "uis_benchmarks.csv")
    
    country_codes = ["ARG", "HND", "PRY"]
    years = list(range(2021, 2025))
    
    print("Starting benchmark data fetching process...")
    benchmark_data = fetch_wb_benchmark_data(country_codes, years)
    
    if not benchmark_data.empty:
        final_cols = [
            "country_name", "country_code_uis", "survey_year", 
            "uis_indicator_name", "uis_indicator_id", "uis_value",
            "local_indicator_id"
        ]
        existing_cols = [col for col in final_cols if col in benchmark_data.columns]
        benchmark_data = benchmark_data[existing_cols]
        
        benchmark_data.to_csv(output_file, index=False)
        print("")
        print("Successfully saved comprehensive benchmark data to: " + output_file)
        print("Total benchmark records fetched: " + str(len(benchmark_data)))
    else:
        print("")
        print("No benchmark data was fetched.")

if __name__ == "__main__":
    main()
