#!/bin/bash
read -p "Commit description: " desc
rm -r public
hugo
nginx
git add . && \
git add -u && \
git commit -m "$desc" && \
git push origin main