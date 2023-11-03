"Parse numpy-style docstrings"

"""
Based on code from numpy, which is:
Copyright (c) 2005-2022, NumPy Developers.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

    * Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above
       copyright notice, this list of conditions and the following
       disclaimer in the documentation and/or other materials provided
       with the distribution.

    * Neither the name of the NumPy Developers nor the names of any
       contributors may be used to endorse or promote products derived
       from this software without specific prior written permission. """

import textwrap, re, copy
from warnings import warn
from collections import namedtuple
from collections.abc import Mapping

__all__ = ['Parameter', 'NumpyDocString', 'dedent_lines']

Parameter = namedtuple('Parameter', ['name', 'type', 'desc'])

def strip_blank_lines(l):
    "Remove leading and trailing blank lines from a list of lines"
    while l and not l[0].strip(): del l[0]
    while l and not l[-1].strip(): del l[-1]
    return l


class Reader:
    """A line-based string reader."""
    def __init__(self, data):
        if isinstance(data, list): self._str = data
        else: self._str = data.split('\n')
        self.reset()

    def __getitem__(self, n): return self._str[n]
    def reset(self): self._l = 0  # current line nr

    def read(self):
        if not self.eof():
            out = self[self._l]
            self._l += 1
            return out
        else: return ''

    def seek_next_non_empty_line(self):
        for l in self[self._l:]:
            if l.strip(): break
            else: self._l += 1

    def eof(self): return self._l >= len(self._str)

    def read_to_condition(self, condition_func):
        start = self._l
        for line in self[start:]:
            if condition_func(line): return self[start:self._l]
            self._l += 1
            if self.eof(): return self[start:self._l+1]
        return []

    def read_to_next_empty_line(self):
        self.seek_next_non_empty_line()
        def is_empty(line): return not line.strip()
        return self.read_to_condition(is_empty)

    def read_to_next_unindented_line(self):
        def is_unindented(line): return (line.strip() and (len(line.lstrip()) == len(line)))
        return self.read_to_condition(is_unindented)

    def peek(self, n=0):
        if self._l + n < len(self._str): return self[self._l + n]
        else: return ''

    def is_empty(self): return not ''.join(self._str).strip()


class ParseError(Exception):
    def __str__(self):
        message = self.args[0]
        if hasattr(self, 'docstring'): message = f"{message} in {self.docstring!r}"
        return message


class NumpyDocString(Mapping):
    """Parses a numpydoc string to an abstract representation """
    sections = { 'Summary': [''], 'Extended': [], 'Parameters': [], 'Returns': [] }

    def __init__(self, docstring, config=None):
        docstring = textwrap.dedent(docstring).split('\n')
        self._doc = Reader(docstring)
        self._parsed_data = copy.deepcopy(self.sections)
        self._parse()
        self['Parameters'] = {o.name:o for o in self['Parameters']}
        if self['Returns']: self['Returns'] = self['Returns'][0]
        self['Summary'] = dedent_lines(self['Summary'], split=False)
        self['Extended'] = dedent_lines(self['Extended'], split=False)

    def __iter__(self): return iter(self._parsed_data)
    def __len__(self): return len(self._parsed_data)
    def __getitem__(self, key): return self._parsed_data[key]

    def __setitem__(self, key, val):
        if key not in self._parsed_data: self._error_location(f"Unknown section {key}", error=False)
        else: self._parsed_data[key] = val

    def _is_at_section(self):
        self._doc.seek_next_non_empty_line()
        if self._doc.eof(): return False
        l1 = self._doc.peek().strip()  # e.g. Parameters
        l2 = self._doc.peek(1).strip()  # ---------- or ==========
        if len(l2) >= 3 and (set(l2) in ({'-'}, {'='}) ) and len(l2) != len(l1):
            snip = '\n'.join(self._doc._str[:2])+'...'
            self._error_location("potentially wrong underline length... \n%s \n%s in \n%s" % (l1, l2, snip), error=False)
        return l2.startswith('-'*len(l1)) or l2.startswith('='*len(l1))

    def _strip(self, doc):
        i = 0
        j = 0
        for i, line in enumerate(doc):
            if line.strip(): break
        for j, line in enumerate(doc[::-1]):
            if line.strip(): break
        return doc[i:len(doc)-j]

    def _read_to_next_section(self):
        section = self._doc.read_to_next_empty_line()

        while not self._is_at_section() and not self._doc.eof():
            if not self._doc.peek(-1).strip(): section += ['']
            section += self._doc.read_to_next_empty_line()
        return section

    def _read_sections(self):
        while not self._doc.eof():
            data = self._read_to_next_section()
            name = data[0].strip()

            if name.startswith('..'): yield name, data[1:]
            elif len(data) < 2: yield StopIteration
            else: yield name, self._strip(data[2:])

    def _parse_param_list(self, content, single_element_is_type=False):
        content = dedent_lines(content)
        r = Reader(content)
        params = []
        while not r.eof():
            header = r.read().strip()
            if ' :' in header:
                arg_name, arg_type = header.split(' :', maxsplit=1)
                arg_name, arg_type = arg_name.strip(), arg_type.strip()
            else:
                if single_element_is_type: arg_name, arg_type = '', header
                else: arg_name, arg_type = header, ''

            desc = r.read_to_next_unindented_line()
            desc = dedent_lines(desc)
            desc = strip_blank_lines(desc)
            params.append(Parameter(arg_name, arg_type, desc))
        return params

    def _parse_summary(self):
        """Grab signature (if given) and summary"""
        if self._is_at_section(): return

        # If several signatures present, take the last one
        while True:
            summary = self._doc.read_to_next_empty_line()
            summary_str = " ".join([s.strip() for s in summary]).strip()
            compiled = re.compile(r'^([\w., ]+=)?\s*[\w\.]+\(.*\)$')
            if compiled.match(summary_str) and not self._is_at_section(): continue
            break

        if summary is not None: self['Summary'] = summary
        if not self._is_at_section(): self['Extended'] = self._read_to_next_section()

    def _parse(self):
        self._doc.reset()
        self._parse_summary()

        sections = list(self._read_sections())
        section_names = {section for section, content in sections}

        has_returns = 'Returns' in section_names
        has_yields = 'Yields' in section_names
        # We could do more tests, but we are not. Arbitrarily.
        if has_returns and has_yields:
            msg = 'Docstring contains both a Returns and Yields section.'
            raise ValueError(msg)
        if not has_yields and 'Receives' in section_names:
            msg = 'Docstring contains a Receives section but not Yields.'
            raise ValueError(msg)

        for (section, content) in sections:
            if not section.startswith('..'):
                section = (s.capitalize() for s in section.split(' '))
                section = ' '.join(section)
                if self.get(section):
                    self._error_location("The section %s appears twice in  %s" % (section, '\n'.join(self._doc._str)))

            if section in ('Parameters', 'Other Parameters', 'Attributes', 'Methods'):
                self[section] = self._parse_param_list(content)
            elif section in ('Returns', 'Yields', 'Raises', 'Warns', 'Receives'):
                self[section] = self._parse_param_list( content, single_element_is_type=True)
            else: self[section] = content

    @property
    def _obj(self):
        if hasattr(self, '_cls'): return self._cls
        elif hasattr(self, '_f'): return self._f
        return None

    def _error_location(self, msg, error=True):
        if error: raise ValueError(msg)
        else: warn(msg)


def dedent_lines(lines, split=True):
    """Deindent a list of lines maximally"""
    res = textwrap.dedent("\n".join(lines))
    if split: res = res.split("\n")
    return res

