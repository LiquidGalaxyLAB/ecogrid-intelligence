import os

def clean_lines(filepath):
    cleaned = []
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            if ': ' in line:
                parts = line.split(': ', 1)
                if parts[0].strip().isdigit():
                    cleaned.append(parts[1])
                    continue
            cleaned.append(line)
    return cleaned

lines_p1 = clean_lines('lib/core/utils/kml_utils_p1.txt')
lines_p2 = clean_lines('lib/core/utils/kml_utils_p2.txt')

with open('lib/core/utils/kml_utils.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines_p1)
    f.writelines(lines_p2)
