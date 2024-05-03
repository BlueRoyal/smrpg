#!/bin/bash

# Überprüfen, ob wir auf dem Master-Branch sind und kein Pull Request
if [ "$TRAVIS_PULL_REQUEST" == "false" ] && [ "$TRAVIS_BRANCH" == "master" ]; then
  # Git-Konfiguration
  git config --global user.email "$GIT_USER_EMAIL"
  git config --global user.name "$GIT_USER_NAME"

  # Erzeugen eines Tags
  export GIT_TAG=build-$TRAVIS_BUILD_NUMBER
  git tag $GIT_TAG -a -m "Generated tag from TravisCI for build $TRAVIS_BUILD_NUMBER"
  git push origin $GIT_TAG

  # Erzeugen der Release-Beschreibung
  BODY="New Release"
  RESPONSE=$(curl -H "Authorization: token $GITHUB_TOKEN" -H "Content-Type: application/json" --data "{ \"tag_name\": \"$GIT_TAG\", \"target_commitish\": \"master\", \"name\": \"$GIT_TAG\", \"body\": \"$BODY\", \"draft\": false, \"prerelease\": false }" https://api.github.com/repos/BlueRoyal/smrpg/releases)
  UPLOAD_URL=$(echo $RESPONSE | jq -r .upload_url | sed -e "s/{?name,label}//")

  # Upload des Artefakts
  curl -H "Authorization: token $GITHUB_TOKEN" -H "Content-Type: application/octet-stream" --data-binary @path/to/your/file.tar.gz "${UPLOAD_URL}?name=file.tar.gz&label=Release file"
fi
