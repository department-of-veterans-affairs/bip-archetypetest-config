#!/bin/sh

git init
git add *
git add .gitignore
git commit -m "First commit"
git remote add origin https://github.ec.va.gov/EPMO/bip-archetypetest-config.git
git push -u origin development
