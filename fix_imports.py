import os, glob

package_name = 'environmental_monitoring_platform'

def fix_imports(folder):
    for f in glob.glob(os.path.join(folder, '*.dart')):
        with open(f, 'r', encoding='utf-8', errors='replace') as file:
            content = file.read()
        
        content = content.replace("import '../providers/", f"import 'package:{package_name}/providers/")
        content = content.replace("import '../models/", f"import 'package:{package_name}/models/")
        content = content.replace("import '../services/", f"import 'package:{package_name}/services/")
        content = content.replace("import '../widgets/", f"import 'package:{package_name}/widgets/")
        content = content.replace("import '../theme/", f"import 'package:{package_name}/theme/")
        
        with open(f, 'w', encoding='utf-8') as file:
            file.write(content)

fix_imports(r'c:\project\Irfan\environmental_monitoring_platform\frontend\lib\screens\sonnet')
fix_imports(r'c:\project\Irfan\environmental_monitoring_platform\frontend\lib\screens\argon')

# Also in wx_style.dart:
wx_file = r'c:\project\Irfan\environmental_monitoring_platform\frontend\lib\theme\wx_style.dart'
with open(wx_file, 'r', encoding='utf-8', errors='replace') as file:
    content = file.read()
content = content.replace("import '../models/", f"import 'package:{package_name}/models/")
with open(wx_file, 'w', encoding='utf-8') as file:
    file.write(content)

print('Successfully fixed imports!')
