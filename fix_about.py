import re

with open('original_about.dart', 'r', encoding='utf-8') as f:
    orig = f.read()

with open('c:/Users/shivh/Projects/ecogrid_intelligence/lib/presentation/about/about_screen.dart', 'r', encoding='utf-8') as f:
    current = f.read()

# Extract blocks
feature_grid = re.search(r'class _FeaturesGrid extends StatelessWidget \{.*?\n\}\n', orig, flags=re.DOTALL).group(0)
feature = re.search(r'class _Feature \{.*?\n\}\n', orig, flags=re.DOTALL).group(0)
feature_card = re.search(r'class _FeatureCard extends StatelessWidget \{.*?\n\}\n', orig, flags=re.DOTALL).group(0)
card_dec = re.search(r'BoxDecoration _cardDecoration\(ColorScheme cs, bool isDark\) \{.*?\n\}', orig, flags=re.DOTALL).group(0)
section_label = re.search(r'class _SectionLabel extends StatelessWidget \{.*?\n\}\n', orig, flags=re.DOTALL).group(0)

# Make SectionLabel centered
section_label = section_label.replace('return Text(', 'return Center(\n      child: Text(')
# Fix the closing brackets for Center
section_label = section_label.replace('      ),\n    );\n  }', '      ),\n    ),\n    );\n  }')
# A better way to replace the build method of _SectionLabel:
section_label = '''class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
'''

# append to current
with open('c:/Users/shivh/Projects/ecogrid_intelligence/lib/presentation/about/about_screen.dart', 'a', encoding='utf-8') as f:
    f.write('\n' + feature_grid + '\n' + feature + '\n' + feature_card + '\n' + card_dec + '\n' + section_label + '\n')

print("Done fixing")
