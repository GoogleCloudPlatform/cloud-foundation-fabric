import sys,os,re,typing,itertools,operator,functools,math,warnings,functools,io,enum

from operator import itemgetter,attrgetter
from warnings import warn
from typing import Iterable,Generator,Sequence,Iterator,List,Set,Dict,Union,Optional,Tuple
from functools import partial,reduce
from pathlib import Path

try:
    from types import WrapperDescriptorType,MethodWrapperType,MethodDescriptorType
except ImportError:
    WrapperDescriptorType = type(object.__init__)
    MethodWrapperType = type(object().__str__)
    MethodDescriptorType = type(str.join)
from types import BuiltinFunctionType,BuiltinMethodType,MethodType,FunctionType,SimpleNamespace

NoneType = type(None)
string_classes = (str,bytes)

def is_iter(o):
    "Test whether `o` can be used in a `for` loop"
    #Rank 0 tensors in PyTorch are not really iterable
    return isinstance(o, (Iterable,Generator)) and getattr(o,'ndim',1)

def is_coll(o):
    "Test whether `o` is a collection (i.e. has a usable `len`)"
    #Rank 0 tensors in PyTorch do not have working `len`
    return hasattr(o, '__len__') and getattr(o,'ndim',1)

def all_equal(a,b):
    "Compares whether `a` and `b` are the same length and have the same contents"
    if not is_iter(b): return a==b
    return all(equals(a_,b_) for a_,b_ in itertools.zip_longest(a,b))

def noop (x=None, *args, **kwargs):
    "Do nothing"
    return x

def noops(self, x=None, *args, **kwargs):
    "Do nothing (method)"
    return x

def any_is_instance(t, *args): return any(isinstance(a,t) for a in args)

def isinstance_str(x, cls_name):
    "Like `isinstance`, except takes a type name instead of a type"
    return cls_name in [t.__name__ for t in type(x).__mro__]

def array_equal(a,b):
    if hasattr(a, '__array__'): a = a.__array__()
    if hasattr(b, '__array__'): b = b.__array__()
    if isinstance_str(a, 'ndarray') and isinstance_str(b, 'ndarray'): return (a==b).all()
    return all_equal(a,b)

def df_equal(a,b): return a.equals(b) if isinstance_str(a, 'NDFrame') else b.equals(a)

def equals(a,b):
    "Compares `a` and `b` for equality; supports sublists, tensors and arrays too"
    if (a is None) ^ (b is None): return False
    if any_is_instance(type,a,b): return a==b
    if hasattr(a, '__array_eq__'): return a.__array_eq__(b)
    if hasattr(b, '__array_eq__'): return b.__array_eq__(a)
    cmp = (array_equal   if isinstance_str(a, 'ndarray') or isinstance_str(b, 'ndarray') else
           array_equal   if isinstance_str(a, 'Tensor')  or isinstance_str(b, 'Tensor') else
           df_equal      if isinstance_str(a, 'NDFrame') or isinstance_str(b, 'NDFrame') else
           operator.eq   if any_is_instance((str,dict,set), a, b) else
           all_equal     if is_iter(a) or is_iter(b) else
           operator.eq)
    return cmp(a,b)

def ipython_shell():
    "Same as `get_ipython` but returns `False` if not in IPython"
    try: return get_ipython()
    except NameError: return False

def in_ipython():
    "Check if code is running in some kind of IPython environment"
    return bool(ipython_shell())

def in_colab():
    "Check if the code is running in Google Colaboratory"
    return 'google.colab' in sys.modules

def in_jupyter():
    "Check if the code is running in a jupyter notebook"
    if not in_ipython(): return False
    return ipython_shell().__class__.__name__ == 'ZMQInteractiveShell'

def in_notebook():
    "Check if the code is running in a jupyter notebook"
    return in_colab() or in_jupyter()

IN_IPYTHON,IN_JUPYTER,IN_COLAB,IN_NOTEBOOK = in_ipython(),in_jupyter(),in_colab(),in_notebook()

def remove_prefix(text, prefix):
    "Temporary until py39 is a prereq"
    return text[text.startswith(prefix) and len(prefix):]

def remove_suffix(text, suffix):
    "Temporary until py39 is a prereq"
    return text[:-len(suffix)] if text.endswith(suffix) else text

