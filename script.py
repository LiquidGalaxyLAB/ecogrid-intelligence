import os
import re

repos = {
    'ai': 'lib/domain/repository/ai_repository.dart',
    'climate': 'lib/domain/repository/climate_repository.dart',
    'cvs': 'lib/domain/repository/cvs_repository.dart',
    'plant': 'lib/domain/repository/power_plant_repository.dart',
    'lg': 'lib/service/lg_service.dart'
}

base_dir = 'lib/domain/usecases'

def snake_to_camel(snake_str):
    components = snake_str.split('_')
    return components[0] + ''.join(x.title() for x in components[1:])

def parse_repo(repo_path):
    with open(repo_path, 'r', encoding='utf-8') as f:
        content = f.read()
    return content

def get_method_signature(repo_content, method_name):
    pattern = r'(?:\n|^)([\w<>, \n\?]+?)\s+' + method_name + r'\s*\((.*?)\)'
    match = re.search(pattern, repo_content, re.DOTALL)
    if match:
        ret_type = match.group(1).strip().split('\n')[-1].strip()
        ret_type = re.sub(r'///.*', '', ret_type).strip()
        if ret_type.startswith('abstract '): ret_type = ret_type[9:]
        args = match.group(2)
        return ret_type, args
    return None, None

def build_call_method(ret_type, method_name, args, target_obj):
    sig_args = args
    invocation_args = []
    clean_args = re.sub(r'=.*?(?=[,}])', '', args)
    
    in_named = False
    parts = re.split(r'([{}])', clean_args)
    for p in parts:
        if p == '{': in_named = True
        elif p == '}': in_named = False
        else:
            if not p.strip(): continue
            params = p.split(',')
            for param in params:
                param = param.strip()
                if not param: continue
                words = param.split()
                param_name = words[-1]
                if in_named:
                    invocation_args.append(f"{param_name}: {param_name}")
                else:
                    invocation_args.append(param_name)
                    
    invocation = ", ".join(invocation_args)
    call_str = f"  {ret_type} call({sig_args}) {{\n"
    call_str += f"    return {target_obj}.{method_name}({invocation});\n"
    call_str += "  }"
    return call_str

for feature, repo_path in repos.items():
    repo_content = parse_repo(repo_path)
    services_dir = os.path.join(base_dir, feature, 'services')
    
    if not os.path.exists(services_dir):
        continue
        
    for file in os.listdir(services_dir):
        if not file.endswith('_usecase.dart'): continue
        
        base_name = file.replace('_usecase.dart', '')
        method_name = snake_to_camel(base_name)
        
        ret_type, args = get_method_signature(repo_content, method_name)
        
        if ret_type is not None:
            file_path = os.path.join(services_dir, file)
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
            target_obj = 'service' if feature == 'lg' else 'repository'
            call_method = build_call_method(ret_type, method_name, args, target_obj)
            
            new_content = re.sub(r'// TODO:.*', call_method, content)
            
            imports = [
                "import 'package:ecogrid_intelligence/domain/model/plant_context_payload.dart';",
                "import 'package:dartz/dartz.dart';",
                "import 'package:ecogrid_intelligence/core/exception/failures.dart';",
                "import 'package:ecogrid_intelligence/domain/model/climate_data.dart';",
                "import 'package:ecogrid_intelligence/domain/model/power_plant.dart';",
                "import 'package:ecogrid_intelligence/domain/model/region.dart';",
                "import 'package:ecogrid_intelligence/domain/model/cvs_result.dart';",
                "import 'package:ecogrid_intelligence/core/enums/risk_level.dart';",
                "import 'package:ecogrid_intelligence/domain/model/lg_settings.dart';"
            ]
            
            import_block = ""
            for imp in imports:
                if imp not in new_content:
                    import_block += imp + "\n"
            
            new_content = import_block + "\n" + new_content
            
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
        else:
            print(f"Could not find method {method_name} for {file}")
            
print("Done")
