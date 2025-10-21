from pathlib import Path
import json
import re

directory='.'
directory_path = Path(directory)
all_files = [f for f in directory_path.iterdir() if f.is_file()]
max_len = 51

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

## Main 
for file_path in all_files:

    if file_path.suffix.lower() == '.json':
        print(f"Checking {file_path}")
        file_json_data = get_jfile_data(file_path)
        image_title_fn = file_json_data["title"] 

        # Googe takout file base names get truncated (max_len)
        # which means the title value in the json file no longer 
        # matches the image filename. This part uses regex to get the
        # truncated image name which matches the json file name
        if len(image_title_fn) > max_len:
            print(f"json title value over max length: {len(str(file_path))} - Using json base filename to match image files")
            #print(f"{image_title_fn}: {len(str(image_title_fn))}")
            base_name_match = re.match(r'^(.*?)(\..*json)$', file_path.name, re.IGNORECASE)
            base_name = base_name_match.group(1)
            #print(f"Base Name Match Value: {base_name} \t - {len(str(base_name))}")
            for check_file in all_files:
                if check_file.name.startswith(base_name) and check_file != file_path:
                    print(f"imgae file matching json filename found: {check_file}")
        # All other title values under max_len in json file  
        if Path(image_title_fn).is_file():
            print(f"Image with title value found: {image_title_fn}")

