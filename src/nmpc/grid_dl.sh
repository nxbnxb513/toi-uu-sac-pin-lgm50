#!/usr/bin/env bash
# Tai cac artifact <tien to>* cua mot run vao <dich>/<runid>/<ten artifact>/ (moi artifact mot thu muc,
# ke ca khi chi co mot artifact). Dung: grid_dl.sh <runid> <tien to> <dich>
id="$1"; pre="$2"; dst="$3"
gh api "repos/$GITHUB_REPOSITORY/actions/runs/$id/artifacts?per_page=100" --paginate -q '.artifacts[] | select(.expired | not) | .name' \
  | grep "^$pre" | sort -u | while read -r a; do
    gh run download "$id" -R "$GITHUB_REPOSITORY" -n "$a" -D "$dst/$id/$a" > /dev/null || echo "khong tai duoc $id/$a"
  done
echo "run $id: $(ls "$dst/$id" 2>/dev/null | wc -l) artifact $pre"
