function viewdeps

[deps dirs] = calcdeps;
deps = deps - diag(diag(deps));
bg = biograph(deps, dirs);
view(bg);
