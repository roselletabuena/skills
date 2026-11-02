#!/usr/bin/env bash
# A small calculator with ten commits. Commit 6 ("Tidy calc.sh arithmetic") quietly changes
# multiplication into addition, so `./calc.sh 3 4` prints 7 instead of 12. Most commits touch
# README.md, and the user has an UNCOMMITTED edit to README.md - so checking out old commits
# fails until the tree is stashed or a worktree is used. The tag v1.0 marks a good commit.
set -eu

git init -q -b main .
git config user.email dev@example.com
git config user.name "Dana Reyes"
git config commit.gpgsign false

cat > test.sh <<'EOF'
#!/usr/bin/env bash
# exit 0 if calc.sh multiplies correctly
[ "$(./calc.sh 3 4)" = "12" ]
EOF
chmod +x test.sh

commit() { git add -A && git commit -q -m "$1"; }

# 1
cat > calc.sh <<'EOF'
#!/usr/bin/env bash
echo $(( $1 * $2 ))
EOF
chmod +x calc.sh
printf '# calc\n\nMultiplies two integers.\n' > README.md
commit "Add calc.sh"
git tag v1.0

# 2
printf '\n## Usage\n\n    ./calc.sh 3 4\n' >> README.md
commit "Document usage"

# 3
printf '# Changelog\n\n- 1.0: first release\n' > CHANGELOG.md
commit "Add changelog"

# 4
cat > calc.sh <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "--help" ]; then
  echo "usage: calc.sh A B"
  exit 0
fi
echo $(( $1 * $2 ))
EOF
commit "Add --help flag"

# 5
printf '\nRun ./test.sh to check it.\n' >> README.md
commit "Mention test script in README"

# 6 - THE REGRESSION, disguised as a tidy-up
cat > calc.sh <<'EOF'
#!/usr/bin/env bash
# Print the result of combining two integers.
if [ "${1:-}" = "--help" ]; then
  echo "usage: calc.sh A B"
  exit 0
fi
echo $(( $1 + $2 ))
EOF
commit "Tidy calc.sh arithmetic"

# 7
printf -- '- 1.1: --help flag\n' >> CHANGELOG.md
commit "Update changelog"

# 8
printf '\n## Examples\n\n    ./calc.sh 2 5\n    ./calc.sh 6 7\n' >> README.md
commit "Expand README examples"

# 9
cat > calc.sh <<'EOF'
#!/usr/bin/env bash
# Print the result of combining two integers.
if [ "${1:-}" = "--help" ]; then
  echo "usage: calc.sh A B"
  exit 0
fi
if [ "${1:-}" = "--version" ]; then
  echo "calc 1.1"
  exit 0
fi
echo $(( $1 + $2 ))
EOF
commit "Add --version flag"

# 10
printf '\n[![ci](badge.svg)](ci)\n' >> README.md
commit "Add CI badge to README"

# the user's uncommitted work, in a file the old commits also change
printf '\nTODO: mention overflow behaviour for large inputs.\n' >> README.md
