#!/usr/bin/env bash
# Leaves the repo in the middle of `git rebase main` on feature/discount, stopped on a
# content conflict in pricing.py. Main added a tax_rate parameter to total(); the feature
# branch added a discount parameter to the same function. Both are wanted. Each side has its
# own test file, so the right resolution makes both tests pass.
#
# During a rebase "ours" is main and "theirs" is the user's commit - taking either side
# wholesale drops one of the two features.
set -eu

git init -q -b main .
git config user.email dev@example.com
git config user.name "Dana Reyes"
git config commit.gpgsign false

cat > pricing.py <<'EOF'
def total(items):
    return sum(price * qty for price, qty in items)
EOF
git add -A
git commit -q -m "Add pricing.total"

# ---- feature branch: discount (two commits) ----
git checkout -q -b feature/discount

cat > pricing.py <<'EOF'
def total(items, discount=0.0):
    subtotal = sum(price * qty for price, qty in items)
    return subtotal * (1 - discount)
EOF
cat > test_discount.py <<'EOF'
from pricing import total


def test_discount():
    assert total([(10, 2)], discount=0.5) == 10.0


if __name__ == "__main__":
    test_discount()
    print("ok")
EOF
git add -A
git commit -q -m "Support a discount in total()"

cat > README.md <<'EOF'
# pricing

`total(items, discount=0.0)` returns the order total after a fractional discount.
EOF
git add -A
git commit -q -m "Document the discount parameter"

# ---- main: tax ----
git checkout -q main

cat > pricing.py <<'EOF'
def total(items, tax_rate=0.0):
    subtotal = sum(price * qty for price, qty in items)
    return subtotal * (1 + tax_rate)
EOF
cat > test_tax.py <<'EOF'
from pricing import total


def test_tax():
    assert total([(10, 2)], tax_rate=0.5) == 30.0


if __name__ == "__main__":
    test_tax()
    print("ok")
EOF
git add -A
git commit -q -m "Support a tax rate in total()"

# ---- replay the feature onto main; this stops on the pricing.py conflict ----
git checkout -q feature/discount
git rebase main >/dev/null 2>&1 || true
