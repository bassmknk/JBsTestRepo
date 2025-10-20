#!/usr/bin/env python

import re
from pathlib import Path
import json

def find_json_matches(directory='.'):
    """
    Finds .json files that have the same base filename as other files
    in the same directory, with any additional characters.

    Args:
        directory (str or Path): The directory to search. Defaults to the current directory.

    Returns:
        dict: A dictionary where keys are the base filenames and values are a
              list of matching files (e.g., ['file.jpg', 'file_metadata.json']).
    """
    directory_path = Path(directory)
    if not directory_path.is_dir():
        print(f"Error: Directory not found at '{directory_path}'")
        return {}

    all_files = [f for f in directory_path.iterdir() if f.is_file()]
    file_map = {}

    for file_path in all_files:
        if file_path.suffix.lower() == '.json':
            # Handle .json files
            base_name_match = re.match(r'^(.*?)(\..*json)$', file_path.name, re.IGNORECASE)
            if base_name_match:
                base_name = base_name_match.group(1)
                # Find all other files with the same base name
                matches = [p for p in all_files if p.name.startswith(base_name) and p != file_path]
                if matches:
                    file_map[base_name] = [file_path] + matches
        else:
            # Handle other files by getting their base name
            base_name_no_ext = file_path.stem
            # Check if a corresponding .json file exists
            for json_file in all_files:
                if json_file.suffix.lower() == '.json' and json_file.name.startswith(base_name_no_ext):
                    if base_name_no_ext not in file_map:
                        file_map[base_name_no_ext] = [file_path]
                    file_map[base_name_no_ext].append(json_file)

    # Clean up duplicates and ensure a consistent structure
    for key, files in file_map.items():
        unique_files = list(set(files))
        if len(unique_files) > 1:
            file_map[key] = unique_files
        else:
            del file_map[key]
            
    return file_map

def get_jfile_data(jfile):
  try:
    with open(jfile, 'r') as file:
      data = json.load(file)
    return data
  except FileNotFoundError:
    print(f"Error: The file '{filename}' was not found.")
    return None
  except json.JSONDecodeError:
    print(f"Error: Failed to decode JSON from '{filename}'.")
    return None

def get_exif_data()

## Main work here
current_dir = Path.cwd()
matching_files = find_json_matches(current_dir)

if matching_files:
    for base_name, files in matching_files.items():
        # print(f"Base name '{base_name}' has the following matching files:")
        for file in files:
            if file.name.endswith(".json"):
                file_json_data = get_jfile_data(file.name)
                print(f"Title value for {file.name} is {file_json_data["title"]}")
else:
    print("No matching files found.")

