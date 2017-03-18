# Cython definitions

cdef extern from 'other.h':
    int a

ctypedef struct types_collection:
    pass

ctypedef union misc:
    pass

# types
cdef types():
    long a
    int b
    char *c
    double d
    float e
    short f
    unsigned int g
    enum h


# functions
cdef int fun(long x):
    char* s

public inline cdef fun():
    pass

cpdef fun():
    pass

# function with long return type
cdef int**[] fun2():
    pass

# cdef class
cdef class MyClass:
    pass

# Some usual Python stuff

literals = [1, 1.2, 1.3e10, "abc", 'def', """ghi""", '''jkl''', {1: 2}]

def py_func():
    pass

