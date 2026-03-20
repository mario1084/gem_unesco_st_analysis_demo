import pandas as pd
import requests
import io
import os

def fetch_wide_bulk_data(country_codes, years):
    wide_url = "https://www.datocms-assets.com/41369/1751881236-wide_2025_june.csv"
    
    print("Downloading WIDE bulk data from " + wide_url + "...")
    try:
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        }
        response = requests.get(wide_url, headers=headers)
        response.raise_for_status()
        
        wide_df = pd.read_csv(io.BytesIO(response.content), encoding='latin1', low_memory=False)
        print("  Successfully downloaded WIDE bulk data. Total records: " + str(len(wide_df)))
        
        # Let's inspect the columns
        print("Columns found in CSV: " + str(list(wide_df.columns)))
        
        # Look for country code
        country_col = next((col for col in wide_df.columns if "iso" in col.lower() or "country" in col.lower()), None)
        year_col = next((col for col in wide_df.columns if "year" in col.lower()), None)
        
        if not country_col or not year_col:
            print("Could not find country or year columns.")
            return pd.DataFrame()
            
        print("Using country col: " + country_col + ", year col: " + year_col)

        # Filter by countries
        wide_df = wide_df[wide_df[country_col].isin(country_codes) | wide_df[country_col].str.contains('|'.join(country_codes), case=False, na=False)]
        print("  Records after filtering for countries: " + str(len(wide_df)))
        
        # Filter by years
        wide_df = wide_df[wide_df[year_col].isin(years)]
        print("  Records after filtering for years: " + str(len(wide_df)))
        
        if not wide_df.empty:
            rename_map = {
                country_col: "country_code_uis",
                "country": "country_name",
                year_col: "survey_year",
                "indicator": "uis_indicator_id",
                "ind_name": "uis_indicator_name",
                "value": "uis_value",
                "gender": "sex",
                "urban": "location",
                "wealth": "wealth_quintile"
            }
            
            rename_map = {k: v for k, v in rename_map.items() if k in wide_df.columns}
            wide_df = wide_df.rename(columns=rename_map)
            
            # just return everything we have for now, don't drop columns
            return wide_df
        else:
            return pd.DataFrame()

    except Exception as e:
        print("Error fetching WIDE data: " + str(e))
        return pd.DataFrame()

def main():
    output_dir = "data/benchmark"
    os.makedirs(output_dir, exist_ok=True)
    output_file = os.path.join(output_dir, "wide_benchmarks.csv")
    
    country_codes = ["ARG", "HND", "PRY"]
    years = list(range(2021, 2025))
    
    print("Starting WIDE benchmark data fetching process...")
    wide_data = fetch_wide_bulk_data(country_codes, years)
    
    if not wide_data.empty:
        wide_data.to_csv(output_file, index=False)
        print("")
        print("Successfully saved comprehensive WIDE benchmark data to: " + output_file)
        print("Total benchmark records fetched: " + str(len(wide_data)))
    else:
        print("")
        print("No WIDE benchmark data was fetched.")

if __name__ == "__main__":
    main()
