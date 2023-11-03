from functools import wraps
import shutil

__all__ = ['copymode', 'copystat', 'copy', 'copy2', 'move', 'copytree', 'rmtree', 'disk_usage', 'chown', 'rmtree']

def str_src_dest(f):
    @wraps(f)
    def _f(src, dst, *args, **kwargs): return f(str(src), str(dst), *args, **kwargs)
    return _f

def str_path(f):
    @wraps(f)
    def _f(path, *args, **kwargs): return f(str(path), *args, **kwargs)
    return _f

src_dests = ['copymode', 'copystat', 'copy', 'copy2', 'move', 'copytree']
for o in src_dests: globals()[o] = str_src_dest(getattr(shutil,o))

paths = ['rmtree', 'disk_usage', 'chown', 'rmtree']
for o in paths: globals()[o] = str_path(getattr(shutil,o))

