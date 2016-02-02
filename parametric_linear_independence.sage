# Make sure current directory is in path.  
# That's not true while doctesting (sage -t).
if '' not in sys.path:
    sys.path = [''] + sys.path

from igp import *

### Removed from parametric.sage ###
##############################
# linearly independent in Q
##############################
def affine_linear_form_of_symbolicrnfelement(number):
    sym_frac_poly = number.sym()
    if sym_frac_poly.denominator() != 1:
        raise NotImplementedError, "%s is a fraction of polynomials. Not implemented." % sym_frac_poly
    poly = sym_frac_poly.numerator()
    coef = [poly.monomial_coefficient(v) for v in poly.parent().gens()]
    return coef + [poly.constant_coefficient()]

def update_dependency(dependency, parallel_space):
    """
    Update the dependency list given a new parallel relation f // g.

    Inputs:

        - `dependency` is a list [E1, E2, ..., En],
        where Ei is a subspace over Q of affine linear forms in \Q^{k+1},
        such that for any l1, l2 in Ei, it is known that l1 // l2.
        (For any li in Ei, lj in Ej, it is unknown whether l1 // l2.)

        - `parallel_space` is the vector space over Q generated by f and g, f // g.


    EXAMPLES::

        sage: V = VectorSpace(QQ,5)
        sage: E1 = V.subspace([V([1,0,0,0,0]), V([0,0,1,0,0])])
        sage: E2 = V.subspace([V([0,1,0,0,0]), V([0,0,0,1,0])])
        sage: pair1 = V.subspace([V([1,1,0,0,0]), V([0,0,0,0,1])])
        sage: dependency = update_dependency([E1, E2], pair1)
        sage: dependency
        [Vector space of degree 5 and dimension 2 over Rational Field
         Basis matrix:
         [1 0 0 0 0]
         [0 0 1 0 0], Vector space of degree 5 and dimension 2 over Rational Field
         Basis matrix:
         [0 1 0 0 0]
         [0 0 0 1 0], Vector space of degree 5 and dimension 2 over Rational Field
         Basis matrix:
         [1 1 0 0 0]
         [0 0 0 0 1]]
        sage: pair2 = V.subspace([V([1,0,0,0,0]), V([0,1,0,0,0])])
        sage: update_dependency(dependency, pair2)
        [Vector space of degree 5 and dimension 5 over Rational Field
        Basis matrix:
         [1 0 0 0 0]
         [0 1 0 0 0]
         [0 0 1 0 0]
         [0 0 0 1 0]
         [0 0 0 0 1]]
        sage: update_dependency([E1, E2], pair2)
        [Vector space of degree 5 and dimension 4 over Rational Field
         Basis matrix:
         [1 0 0 0 0]
         [0 1 0 0 0]
         [0 0 1 0 0]
         [0 0 0 1 0]]

    Update dependency sequentially:

        sage: V = VectorSpace(QQ,7)
        sage: m = matrix.identity(QQ, 7)
        sage: e = [V(m[i]) for i in range(7)]
        sage: dep_pairs = [V.subspace([e[0]+e[3], 3*e[0]]), \
        ....: V.subspace([e[6], 2*e[2]-3*e[1]]), \
        ....: V.subspace([2*e[6], e[4]-3*e[1]])]
        sage: dependency = []
        sage: for dep_pair in dep_pairs:
        ....:     dependency = update_dependency(dependency, dep_pair)
        sage: dependency
        [Vector space of degree 7 and dimension 2 over Rational Field
         Basis matrix:
         [1 0 0 0 0 0 0]
         [0 0 0 1 0 0 0], Vector space of degree 7 and dimension 3 over Rational Field
         Basis matrix:
         [   0    1    0    0 -1/3    0    0]
         [   0    0    1    0 -1/2    0    0]
         [   0    0    0    0    0    0    1]]
    """
    parallel = parallel_space
    new_dependency = []
    s = None
    while len(new_dependency) < len(dependency):
        if not s is None:
            dependency = new_dependency
            new_dependency = []
        for s in dependency:
            if s.intersection(parallel).dimension() > 0:
                parallel += s
            else:
                new_dependency.append(s)
    new_dependency.append(parallel)
    return new_dependency

def update_independency(independency, simultaneously_independency):
    """
    `independency` is a list [S1, S2, ...]
    Si is a set of pairs (X1, Y1), (X2, Y2) such that Xj _|_ Yj simultaneously.
    Xj, Yj are either some Ek (parallel subspace) or an affine linear form.
    Ei _|_ Ej means for any f in Ei, g in Ej such that ker f = ker g = {0},
    we have f _|_ g.
    """
    sim_ind = simultaneously_independency
    new_independency = []
    for s in independency:
        if s.intersection(sim_ind):
            sim_ind.update(s)
        else:
            new_independency.append(s)
    new_independency.append(sim_ind)
    return new_independency

def construct_independency(independent_pairs, dependency, seen_linear_forms):
    """
    EXAMPLES:

        sage: V = VectorSpace(QQ,7)
        sage: m = matrix.identity(QQ, 7)
        sage: e = [V(m[i]) for i in range(7)]

    Imagine e[0] =1, e[1] = sqrt(2), e[2] = sqrt(3), e[3] = 2,
            e[4] = 2 * sqrt(3), e[5] = sqrt(5), e[6] = sqrt(3)-3*sqrt(2).

    Define 3 dep_pairs:

        sage: dep_pairs = []
        sage: dep_pairs = [V.subspace([e[0], e[3]]), \
        ....:             V.subspace([e[6], 2*e[2]-3*e[1]]), \
        ....:             V.subspace([e[2], e[4]]) ]
        sage: dependency = []
        sage: for dep_pair in dep_pairs: \
        ....:     dependency = update_dependency(dependency, dep_pair)
        sage: dependency
        [Vector space of degree 7 and dimension 2 over Rational Field
         Basis matrix:
         [1 0 0 0 0 0 0]
         [0 0 0 1 0 0 0], Vector space of degree 7 and dimension 2 over Rational Field
         Basis matrix:
         [   0    1 -2/3    0    0    0    0]
         [   0    0    0    0    0    0    1], Vector space of degree 7 and dimension 2 over Rational Field
         Basis matrix:
         [0 0 1 0 0 0 0]
         [0 0 0 0 1 0 0]]

    Define 19 ind_pairs:

        sage: ind_pairs = [V.subspace([e[0], e[1]]), \
        ....:              V.subspace([e[0], e[2]]), \
        ....:              V.subspace([e[0], e[4]]), \
        ....:              V.subspace([e[0], e[5]]), \
        ....:              V.subspace([e[0], e[6]]), \
        ....:              V.subspace([e[1], e[2]]), \
        ....:              V.subspace([e[1], e[3]]), \
        ....:              V.subspace([e[1], e[4]]), \
        ....:              V.subspace([e[1], e[5]]), \
        ....:              V.subspace([e[1], e[6]]), \
        ....:              V.subspace([e[2], e[3]]), \
        ....:              V.subspace([e[2], e[5]]), \
        ....:              V.subspace([e[2], e[6]]), \
        ....:              V.subspace([e[3], e[4]]), \
        ....:              V.subspace([e[3], e[5]]), \
        ....:              V.subspace([e[3], e[6]]), \
        ....:              V.subspace([e[4], e[5]]), \
        ....:              V.subspace([e[4], e[6]]), \
        ....:              V.subspace([e[5], e[6]])   ]

    Define `seen_linear_forms` as the set of the generators of `ind_pairs`:

        sage: seen_linear_forms = set(e)


        sage: independency, zero_kernel = \
        ....:     construct_independency(ind_pairs, dependency, seen_linear_forms)

        sage: len(independency)
        8

    Only need 8 pairs to represent the above independency (which had 19 pairs):

        sage: get_independent_pairs_from_independency(independency)
        [((1, 0, 0, 0, 0, 0, 0), (0, 1, 0, 0, 0, 0, 0)),
         ((0, 1, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 1, 0)),
         ((1, 0, 0, 0, 0, 0, 0), (0, 0, 1, 0, 0, 0, 0)),
         ((1, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 1, 0)),
         ((1, 0, 0, 0, 0, 0, 0), (0, 1, -2/3, 0, 0, 0, 0)),
         ((0, 0, 1, 0, 0, 0, 0), (0, 0, 0, 0, 0, 1, 0)),
         ((0, 1, 0, 0, 0, 0, 0), (0, 0, 1, 0, 0, 0, 0)),
         ((0, 1, -2/3, 0, 0, 0, 0), (0, 0, 0, 0, 0, 1, 0))]

     With the additional conditions that the following forms have kernel = {0}.
        sage: zero_kernel
        {(0, 0, 0, 0, 0, 0, 1),
         (0, 0, 0, 0, 1, 0, 0),
         (0, 0, 0, 1, 0, 0, 0),
         (0, 0, 1, 0, 0, 0, 0),
         (0, 1, -2/3, 0, 0, 0, 0),
         (1, 0, 0, 0, 0, 0, 0)}
    """
    independency = []
    zero_kernel = set([]) # zero_kernel = seen_linear_forms?
    for t in seen_linear_forms:
        to_add = True
        for d in dependency:
            if t in d:
                to_add = False
                break
        if to_add:
            vector_space = VectorSpace(QQ,len(t))
            dependency += [vector_space.subspace([vector_space(t)])]
    for ind_pair_1 in independent_pairs:
        for ind_pair_2 in independent_pairs:
            if ind_pair_1 < ind_pair_2:
                i = ind_pair_1.intersection(ind_pair_2)
                if i.dimension() > 0:
                    to_add = True
                    for d in dependency:
                        if i.gen(0) in d:
                            to_add = False
                            break
                    if to_add:
                        dependency += [i]
    for ind_pair in independent_pairs:
        simultaneously_independency, intersections = construct_simultaneously_independency(ind_pair, dependency)
        independency = update_independency(independency, simultaneously_independency)
        zero_kernel.update(intersections)
    return independency, zero_kernel

def construct_simultaneously_independency(ind_pair, dependency):
    """
    EXAMPLE_1:

        sage: V = VectorSpace(QQ,5)
        sage: E1 = V.subspace([V([1,0,0,0,0]), V([0,0,1,0,0])])
        sage: E2 = V.subspace([V([0,1,0,0,0]), V([0,0,0,1,0])])
        sage: E3 = V.subspace([V([1,1,0,0,0]), V([0,0,0,0,1])])
        sage: dependency = [E1, E2, E3]
        sage: ind_pair = V.subspace([V([1,0,0,0,0]), V([0,1,0,0,0])])
        sage: sim_ind, intersections = \
        ....:     construct_simultaneously_independency(ind_pair, dependency)
        sage: sim_ind == set([(E1, E2), (E1, E3), (E2, E3)])
        True
        sage: intersections
        {(0, 1, 0, 0, 0), (1, 0, 0, 0, 0), (1, 1, 0, 0, 0)}

    EXAMPLE_2:

    Imagine e[0] =1, e[1] = sqrt(2), e[2] = sqrt(3), e[3] = 2,
            e[4] = 2 * sqrt(3), e[5] = sqrt(5), e[6] = sqrt(3)-3*sqrt(2).

    Use the same dep_pairs as in the last example of update_dependency()
    to get the input value for dependency.
    Define 4 pairs of independent relations as follows.

        sage: V = VectorSpace(QQ,7)
        sage: dependency = [ \
        ....:     V.subspace([V([1,0,0,0,   0,0,0]), \
        ....:                 V([0,0,0,1,   0,0,0])]), \
        ....:     V.subspace([V([0,1,0,0,-1/3,0,0]),\
        ....:                 V([0,0,1,0,-1/2,0,0]),\
        ....:                 V([0,0,0,0,   0,0,1])]) ]

    Define ind_pair whose generators are already in dependency:

        sage: ind_pair = V.subspace([V([1,0,0,0,0,0,0]), V([0,0,0,0,0,0,1])])
        sage: sim_ind, intersections = \
        ....:     construct_simultaneously_independency(ind_pair, dependency)
        sage: sim_ind
        {(Vector space of degree 7 and dimension 2 over Rational Field
          Basis matrix:
          [1 0 0 0 0 0 0]
          [0 0 0 1 0 0 0], Vector space of degree 7 and dimension 3 over Rational Field
          Basis matrix:
          [   0    1    0    0 -1/3    0    0]
          [   0    0    1    0 -1/2    0    0]
          [   0    0    0    0    0    0    1])}
        sage: intersections
        {(0, 0, 0, 0, 0, 0, 1), (1, 0, 0, 0, 0, 0, 0)}

    Define other ind_pairs whose generators are not all in dependency: 

        sage: ind_pair =  V.subspace([V([0,0,0,0,0,1,0]), V([0,0,0,0,0,0,1])])
        sage: construct_simultaneously_independency(ind_pair, dependency)
        ({(Vector space of degree 7 and dimension 3 over Rational Field
           Basis matrix:
           [   0    1    0    0 -1/3    0    0]
           [   0    0    1    0 -1/2    0    0]
           [   0    0    0    0    0    0    1], (0, 0, 0, 0, 0, 1, 0))},
         {(0, 0, 0, 0, 0, 0, 1)})

        sage: ind_pair = V.subspace([V([0,0,0,0,5,0,0]), V([1,0,0,0,0,0,0])])
        sage: construct_simultaneously_independency(ind_pair, dependency)
        ({(Vector space of degree 7 and dimension 2 over Rational Field
           Basis matrix:
           [1 0 0 0 0 0 0]
           [0 0 0 1 0 0 0], (0, 0, 0, 0, 1, 0, 0))}, {(1, 0, 0, 0, 0, 0, 0)})

        sage: ind_pair = V.subspace([V([0,0,0,0,0,1,0]), V([0,9,8,0,0,0,0])])
        sage: construct_simultaneously_independency(ind_pair, dependency)
        ({((0, 1, 8/9, 0, 0, 0, 0), (0, 0, 0, 0, 0, 1, 0))}, set())

    Try again with generators of ind_pairs being added to 'dependency'.
    (This is what construct_independency() does first.) 

        sage: ind_pair = V.subspace([V([0,0,0,0,5,0,0]), V([1,0,0,0,0,0,0])])
        sage: construct_simultaneously_independency(ind_pair, \
        ....:     dependency + [V.subspace([V([0,0,0,0,5,0,0])])])
        ({(Vector space of degree 7 and dimension 2 over Rational Field
           Basis matrix:
           [1 0 0 0 0 0 0]
           [0 0 0 1 0 0 0],
           Vector space of degree 7 and dimension 1 over Rational Field
           Basis matrix:
           [0 0 0 0 1 0 0])},
         {(1, 0, 0, 0, 0, 0, 0)})
    """
    intersecting = []
    intersections = []
    for s in dependency:
        i = s.intersection(ind_pair)
        if i.dimension() > 0:
            intersecting.append(s)
            if s.dimension() > 1: # valid condition?
                intersections.append(i.gen(0))
    # NOTE: if construct_independency() was called, generators of ind_pair must be in `dependency`.
    # Then len(intersecting) > 1, the first two cases won't happen.
    if len(intersecting) == 0:
        return set([(ind_pair.gen(0), ind_pair.gen(1))]), set(intersections)
    elif len(intersecting) == 1:
        dependent_space = intersecting[0]
        # find orth_vec in (dependent_space + ind_pair) that is orthogonal to dependent_space
        orth_vec = find_orthogonal_vector(dependent_space, dependent_space + ind_pair)
        return set([(dependent_space, orth_vec)]), set(intersections)
    else:
        sim_ind_list = [(intersecting[i], intersecting[j]) for i in range(len(intersecting)) for j in range(i+1, len(intersecting))]
        return set(sim_ind_list), set(intersections)

def find_orthogonal_vector(s1, s2):
    s3 = s1.complement()
    orth_vec = s2.intersection(s3).gen(0)
    return orth_vec

def get_independent_pairs_from_independency(independency):
    independent_pairs = []
    for sim_ind in independency:
        s1, s2 = list(sim_ind)[0]
        t1 = s1.gen(0)
        t2 = s2.gen(0)
        vector_space = VectorSpace(QQ,len(t1))
        pair_space = vector_space.subspace([t1, t2])
        independent_pairs.append((pair_space.gen(0), pair_space.gen(1)))
    return independent_pairs
