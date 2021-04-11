#!/bin/bash
read -p "Commit description: " desc
rm -r public
hugo
docker restart nginx
git add . && \
git add -u && \
git commit -m "$desc" && \
git push origin main