#!/bin/sh

git init
git add *
git add .gitignore
git commit -m "First commit"
git remote add origin https://github.com/department-of-veterans-affairs/bip-archetypetest-config.git
git push -u origin development
