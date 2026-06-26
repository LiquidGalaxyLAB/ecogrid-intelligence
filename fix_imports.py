import os
import re

files_to_fix = [
    r"c:\Users\shivh\Projects\ecogrid_intelligence\lib\domain\usecases\lg\services\connect_lg_usecase.dart",
    r"c:\Users\shivh\Projects\ecogrid_intelligence\lib\domain\usecases\lg\services\disconnect_lg_usecase.dart",
    r"c:\Users\shivh\Projects\ecogrid_intelligence\lib\domain\usecases\lg\services\fly_to_region_usecase.dart",
    r"c:\Users\shivh\Projects\ecogrid_intelligence\lib\domain\usecases\lg\services\reboot_lg_usecase.dart"
]

for file in files_to_fix:
    with open(file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    imports = []
    body = []
    for line in lines:
        if line.strip().startswith('import '):
            imports.append(line)
        else:
            body.append(line)
            
    # remove duplicate imports
    imports = list(dict.fromkeys(imports))
    
    with open(file, 'w', encoding='utf-8') as f:
        f.writelines(imports)
        f.write('\n')
        f.writelines(body)
