import glob
import os

import click
import yamale


@ click.command()
@ click.argument('schema', type=click.Path(exists=True))
@ click.option('--directory', multiple=True, type=click.Path(exists=True, file_okay=False, dir_okay=True))
@ click.option('--file', multiple=True, type=click.Path(exists=True, file_okay=True, dir_okay=False))
@ click.option('--recursive', is_flag=True, default=False)
@ click.option('--quiet', is_flag=True, default=False)
def main(directory=None, file=None, schema=None, recursive=False, quiet=False):
  'Program entry point.'

  yamale_schema = yamale.make_schema(schema)
  search = "**/*.yaml" if recursive else "*.yaml"
  has_errors = []

  files = list(file)
  for d in directory:
    files = files + glob.glob(os.path.join(d, search), recursive=recursive)

  for document in files:
    yamale_data = yamale.make_data(document)
    try:
      yamale.validate(yamale_schema, yamale_data)
      if quiet:
        pass
      else:
        print(f'✅  {document} -> {os.path.basename(schema)}')
    except ValueError as e:
      has_errors.append(document)
      print(e)
      print(f'❌ {document} -> {os.path.basename(schema)}')

  if len(has_errors) > 0:
    raise SystemExit(f"❌ Errors found in {len(has_errors)} documents.")


if __name__ == '__main__':
  main()
