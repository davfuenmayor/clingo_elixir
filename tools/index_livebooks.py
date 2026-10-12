#!/usr/bin/env python3
"""Refresh Markdown navigation from the editable topic notebooks."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1] / 'livebooks'
TOPICS = {
    'language': 'ASP language',
    'modeling': 'Modeling problems',
    'planning': 'Planning and scheduling',
    'elixir': 'Elixir integration',
    'extensions': 'Solver extensions and meta-programming',
}


def slug(title):
    return re.sub(r'[^\w\s-]', '', title.lower()).strip().replace(' ', '-')


def main():
    navigation, concepts = [], ['# Concept and API index']
    for topic, label in TOPICS.items():
        navigation += ['## ' + label]
        for path in sorted((ROOT / topic).glob('*.livemd')):
            text = path.read_text()
            title = re.search(r'^# (.+)$', text, re.M)[1]
            relative = str(path.relative_to(ROOT))
            navigation += [f'- [{title}]({relative})']
            concepts += [f'## [{title}]({relative})']
            prose = re.sub(r'^```[^\n]*\n.*?^```', '', text, flags=re.M | re.S)
            concepts += [f'- [{section}]({relative}#{slug(section)})'
                         for section in re.findall(r'^## (.+)$', prose, re.M)]
            calls = set(re.findall(r'\b(?:Clingo(?:\.\w+)*|Control)\.[a-z]\w*[!?]?', text))
            calls = sorted('Clingo.' + call if call.startswith('Control.') else call
                           for call in calls)
            concepts += ['API: ' + ', '.join(f'`{call}`' for call in dict.fromkeys(calls)) + '.']
    readme = ROOT / 'README.md'
    start, end = '<!-- topics:start -->', '<!-- topics:end -->'
    before, remainder = readme.read_text().split(start)
    _, after = remainder.split(end)
    readme.write_text(before + start + '\n\n' + '\n\n'.join(navigation) + '\n\n' + end + after)
    (ROOT / 'CONCEPTS.md').write_text('\n\n'.join(concepts) + '\n')


if __name__ == '__main__':
    main()
