"""
Github flavored markdown
~~~~~~~~~~~~~~~~~~~~~~~~

https://github.github.com/gfm

Unlike other extensions, GFM provides a self-contained subclass of ``Markdown``
with parser and renderer already set.
User may also use the parser and renderer as bases for further extension.

Example usage::

    from marko.ext.gfm import gfm
    print(gfm(text))

"""
import re

from marko import Markdown
from marko.helpers import MarkoExtension

from . import elements


class GFMRendererMixin:
    tagfilter = re.compile(
        r"<(title|texarea|style|xmp|iframe|noembed|noframes|script|plaintext)",
        flags=re.I,
    )
    tagfilter_no_open = re.compile(
        r"(?<!^)( *)<(title|texarea|style|xmp|iframe|noembed|noframes|script|plaintext)",
        flags=re.I,
    )

    def render_paragraph(self, element):
        children = self.render_children(element)
        template = '<input{} disabled="" type="checkbox">{}'
        if hasattr(element, "checked"):
            children = template.format(
                ' checked=""' if element.checked else "", children
            )
        if element._tight:
            return children
        else:
            return f"<p>{children}</p>\n"

    def render_strikethrough(self, element):
        return "<del>{}</del>".format(self.render_children(element))

    def render_inline_html(self, element):
        return self.tagfilter.sub(r"&lt;\1", element.children)

    def render_html_block(self, element):
        return self.tagfilter_no_open.sub(r"\1&lt;\2", element.body)

    def render_table(self, element):
        header, body = element.children[0], element.children[1:]
        theader = "<thead>\n{}</thead>".format(self.render(header))
        tbody = ""
        if body:
            tbody = "\n<tbody>\n{}</tbody>".format(
                "".join(self.render(row) for row in body)
            )
        return f"<table>\n{theader}{tbody}</table>"

    def render_table_row(self, element):
        return "<tr>\n{}</tr>\n".format(self.render_children(element))

    def render_table_cell(self, element):
        tag = "th" if element.header else "td"
        align = ""
        if element.align:
            align = f' align="{element.align}"'
        return "<{tag}{align}>{children}</{tag}>\n".format(
            tag=tag, children=self.render_children(element), align=align
        )

    def render_url(self, element):
        return self.render_link(element)


GFM = MarkoExtension(
    elements=[
        elements.Paragraph,
        elements.ListItem,
        elements.InlineHTML,
        elements.Strikethrough,
        elements.Url,
        elements.Table,
        elements.TableRow,
        elements.TableCell,
    ],
    renderer_mixins=[GFMRendererMixin],
)


gfm = Markdown(extensions=[GFM])


def make_extension():
    return GFM
