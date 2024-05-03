#!/bin/bash

echo "Starting the upload script..."

# Überprüfen, ob wir auf dem Master-Branch sind und kein Pull Request
if [ "$TRAVIS_PULL_REQUEST" == "false" ] && [ "$TRAVIS_BRANCH" == "master" ]; then
  echo "We are on the master branch and it's not a pull request."
  
  # Git-Konfiguration
  echo "Configuring git with provided user email and name."
  git config --global user.email "$GIT_USER_EMAIL"
  git config --global user.name "$GIT_USER_NAME"

  # Erzeugen eines Tags
  export GIT_TAG=build-$TRAVIS_BUILD_NUMBER
  echo "Creating and pushing tag: $GIT_TAG"
  git tag $GIT_TAG -a -m "Generated tag from TravisCI for build $TRAVIS_BUILD_NUMBER"
  git push origin $GIT_TAG

  # Erzeugen der Release-Beschreibung
  BODY="New Release"
  echo "Creating release on GitHub..."
  RESPONSE=$(curl -H "Authorization: token $GITHUB_TOKEN" -H "Content-Type: application/json" --data "{ \"tag_name\": \"$GIT_TAG\", \"target_commitish\": \"master\", \"name\": \"$GIT_TAG\", \"body\": \"$BODY\", \"draft\": false, \"prerelease\": false }" https://api.github.com/repos/BlueRoyal/smrpg/releases)
  echo "GitHub API Response: $RESPONSE"
  
  UPLOAD_URL=$(echo $RESPONSE | jq -r .upload_url | sed -e "s/{?name,label}//")
  echo "Extracted upload URL: $UPLOAD_URL"

  # Upload des Artefakts
  echo "Uploading artifact..."
  curl -v -H "Authorization: token $GITHUB_TOKEN" -H "Content-Type: application/octet-stream" --data-binary @output/file.tar.gz "${UPLOAD_URL}?name=file.tar.gz&label=Release file"
else
  echo "This script only runs on master branch and when it's not a pull request."
fi
