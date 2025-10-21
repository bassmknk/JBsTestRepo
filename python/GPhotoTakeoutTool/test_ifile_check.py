from pathlib import Path
from exif import Image
import json
import re

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

def extract_exif_data(image_path):
# https://exif.readthedocs.io/en/latest/index.html
  """Extracts and prints EXIF data from an image file."""
  try:
      with open(image_path, 'rb') as image_file:
          my_image = Image(image_file)
  except FileNotFoundError:
      print(f"Error: The file '{image_path}' was not found.")
      return
  except Exception as e:
      print(f"An error occurred: {e}")
      return

  if my_image.has_exif:
      print(f"EXIF data for '{image_path}':")
      for key in my_image.list_all():
          if key in ('_exif_ifd_pointer', '_gps_ifd_pointer'):
              continue # Skip internal tag pointers
          try:
              value = my_image.get(key)
              print(f"  {key}: {value}")
          except Exception as e:
              print(f"  {key}: [Error accessing data - {e}]")
  else:
      print(f"'{image_path}' has no EXIF data.")

   

## Main 
# Get all files and folders in the current directory
directory = '.'
directory_path = Path(directory)
all_files = [f for f in directory_path.iterdir() if f.is_file()]
for file_path in all_files:
    # Check if the path is a file and has a lowercase .json suffix
    # for files that match get file data
    if file_path.suffix.lower() in ('.json'):

      ## Shit for lang ass file names
      #print(f"File path is: {file_path}  - {len(str(file_path))}")
      base_name_match = re.match(r'^(.*?)(\..*json)$', file_path.name, re.IGNORECASE)
      base_name = base_name_match.group(1)
      #print(f"Base Name Match Value: {base_name} \t - {len(str(base_name))}")
      for check_file in all_files:
          if check_file.name.startswith(base_name) and check_file != file_path:
              print(f"Matching file for base name: {check_file}   - {len(str(check_file))}")

      #file_json_data = get_jfile_data(file_path)
      # check if there is a file that matches the title key
      #title_value = Path(file_json_data["title"])
      #print(f"Title Value is: {title_value}")
      #if title_value.is_file():
      #   extract_exif_data(file_path)
