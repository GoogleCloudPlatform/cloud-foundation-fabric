"""
Extra elements
"""
import itertools
import re

from marko import block, inline, patterns


class Paragraph(block.Paragraph):
    _task_list_item_pattern = re.compile(r"(\[[\sxX]\])\s+\S")
    override = True

    def __init__(self, lines):
        super().__init__(lines)
        m = self._task_list_item_pattern.match(self.inline_body)
        if m:
            self.checked = m.group(1)[1:-1].lower() == "x"
            self.inline_body = self.inline_body[m.end(1) :]


class InlineHTML(inline.InlineHTML):
    pattern = re.compile(
        r"(<%s(?:%s)* */?>"  # open tag
        r"|</%s *>"  # closing tag
        r"|<!--(?:>|->|[\s\S]*?-->)"  # HTML comment
        r"|<\?[\s\S]*?\?>"  # processing instruction
        r"|<![A-Z]+ +[\s\S]*?>"  # declaration
        r"|<!\[CDATA\[[\s\S]*?\]\]>)"  # CDATA section
        % (patterns.tag_name, patterns.attribute, patterns.tag_name)
    )


class Strikethrough(inline.InlineElement):
    pattern = re.compile(r"(?<!~)(~|~~)([^~]+)\1(?!~)")
    priority = 5
    parse_children = True
    parse_group = 2


class _MatchObj:
    def __init__(self, match, start_shift=0, end_shift=0):
        self._match = match
        self._start_shift = start_shift
        self._end_shift = end_shift

    def start(self, n=0):
        start = self._match.start() + self._start_shift
        if n == 0:
            return start
        return max(start, self._match.start(n))

    def end(self, n=0):
        end = self._match.end() + self._end_shift
        if n == 0:
            return end
        return min(end, self._match.end(n))

    def group(self, n=0):
        start = max(self.start(n) - self._match.start(n), 0) or None
        end = min(self.end(n) - self._match.end(n), 0) or None
        return self._match.group(n)[start:end]

    def __getattr__(self, name):
        return getattr(self._match, name)


class Url(inline.AutoLink):
    www_pattern = re.compile(
        r"(?:^|(?<=[\s*_~(\uff00-\uffef]))(www\.([\w.\-]*?\.[\w.\-]+)[^<\s]*)"
    )
    email_pattern = r"[\w.\-+]+@[\w.\-]*?\.[\w.\-]*[a-zA-Z0-9]"
    bare_pattern = re.compile(
        r"(?:^|(?<=[\s*_~(\uff00-\uffef]))((?:https?|ftp)://([\w.\-]*?\.[\w.\-]+)"
        r"[^<\s]*|%s(?=[\s.<]|\Z))" % email_pattern
    )
    priority = 5

    def __init__(self, match):
        super().__init__(match)
        if self.www_pattern.match(self.dest):
            self.dest = "http://" + self.dest

    @classmethod
    def find(cls, text, *, source):
        for match in itertools.chain(
            cls.www_pattern.finditer(text), cls.bare_pattern.finditer(text)
        ):
            domain = match.group(2)
            if domain:
                parts = domain.split(".")
                if len(parts) < 2 or any("_" in p for p in parts[-2:]):
                    continue
            link_text = match.group()
            if link_text[-1] in ("?", "!", ".", ",", ":", "*", "_", "~"):
                match = _MatchObj(match, end_shift=-1)
            elif link_text[-1] == ")" and link_text.count(")") > link_text.count("("):
                shift = link_text.count(")") - link_text.count("(")
                match = _MatchObj(match, end_shift=-shift)
            else:
                m = re.search(r"&[a-zA-Z]+;$", link_text)
                if m:
                    match = _MatchObj(match, end_shift=-len(m.group()))
            yield match


class ListItem(block.ListItem):
    pattern = re.compile(r" {,3}(\d{1,9}[.)]|[*\-+])[ \t\n\r\f]")
    override = True


class Table(block.BlockElement):
    """A table element."""

    _num_of_cols = None
    _prefix = ""

    @classmethod
    def match(cls, source):
        source.anchor()
        if TableRow.match(source) and not TableRow._is_delimiter:
            if not TableRow.splitter.search(source.next_line()):
                return False
            source.pos = source.match.end()
            num_of_cols = len(TableRow._cells)
            if (
                TableRow.match(source)
                and TableRow._is_delimiter
                and num_of_cols == len(TableRow._cells)
            ):
                cls._num_of_cols = num_of_cols
                source.reset()
                return True
        source.reset()
        return False

    @classmethod
    def parse(cls, source):
        rv = cls()
        rv._num_of_cols = cls._num_of_cols
        rv.children = []
        with source.under_state(rv):
            TableRow.match(source)
            header = TableRow(TableRow.parse(source))
            rv.children.append(header)
            TableRow.match(source)
            delimiters = TableRow._cells
            source.consume()
            for d, th in zip(delimiters, header.children):
                stripped_d = d.strip()
                th.header = True
                if stripped_d[0] == ":" and stripped_d[-1] == ":":
                    th.align = "center"
                elif stripped_d[0] == ":":
                    th.align = "left"
                elif stripped_d[-1] == ":":
                    th.align = "right"
            while not source.exhausted:
                for e in source.parser._build_block_element_list():
                    if issubclass(e, (Table, block.Paragraph)):
                        continue
                    if e.match(source):
                        break
                else:
                    if TableRow.match(source):
                        rv.children.append(TableRow(TableRow.parse(source)))
                        continue
                break
        return rv


class TableRow(block.BlockElement):
    """A table row element."""

    splitter = re.compile(r"\s*(?<!\\)\|\s*")
    delimiter = re.compile(r":?-+:?")
    virtual = True
    _cells = None
    _is_delimiter = False

    def __init__(self, cells):
        self.children = cells

    @classmethod
    def match(cls, source):
        line = source.next_line()
        if not line or not re.match(r" {,3}\S", line):
            return False
        parts = cls.splitter.split(line.strip())
        if parts and not parts[0]:
            parts.pop(0)
        if parts and not parts[-1]:
            parts.pop()
        if len(parts) < 1:
            return False
        cls._cells = parts
        cls._is_delimiter = all(cls.delimiter.match(cell) for cell in parts)
        return True

    @classmethod
    def parse(cls, source):
        source.consume()
        parent = source.state
        cells = cls._cells[:]
        if len(cells) < parent._num_of_cols:
            cells.extend("" for _ in range(parent._num_of_cols - len(cells)))
        elif len(cells) > parent._num_of_cols:
            cells = cells[: parent._num_of_cols]
        cells = [TableCell(cell) for cell in cells]
        if parent.children:
            for head, cell in zip(parent.children[0].children, cells):
                cell.align = head.align
        return cells


class TableCell(block.BlockElement):
    """A table cell element."""

    virtual = True

    def __init__(self, text):
        self.inline_body = text.strip().replace("\\|", "|")
        self.header = False
        self.align = None
