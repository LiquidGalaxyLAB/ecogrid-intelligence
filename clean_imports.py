import re

log_path = r"C:\Users\shivh\.gemini\antigravity-ide\brain\95c7a088-6ee9-4e2f-bbd2-e5c4e91b184c\.system_generated\tasks\task-127.log"

with open(log_path, 'r', encoding='utf-8') as f:
    log_content = f.read()

# Pattern: ... - lib\domain\usecases\...\start_orbit_usecase.dart:7:8 - unused_import
# Group 1: file path, Group 2: line number
pattern = r"Try removing the import directive - (lib\\domain\\usecases\\[^\:]+):(\d+):\d+ - unused_import"
matches = re.findall(pattern, log_content)

# Group by file
files_to_fix = {}
for match in matches:
    file_path = match[0]
    line_num = int(match[1])
    if file_path not in files_to_fix:
        files_to_fix[file_path] = set()
    files_to_fix[file_path].add(line_num)

for file_path, lines_to_remove in files_to_fix.items():
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        # We need to remove these lines (1-indexed)
        # However, if we remove lines one by one, the indices change.
        # Best is to build a new list of lines.
        new_lines = []
        for i, line in enumerate(lines):
            if (i + 1) not in lines_to_remove:
                new_lines.append(line)
                
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
    except Exception as e:
        print(f"Error processing {file_path}: {e}")

print("Cleaned unused imports.")
