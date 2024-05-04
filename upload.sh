#!/bin/bash

echo "Starting the upload script..."

if [ "$TRAVIS_PULL_REQUEST" == "false" ] && [ "$TRAVIS_BRANCH" == "master" ]; then
    echo "We are on the master branch and it's not a pull request."

    # Git-Konfiguration
    echo "Configuring git with provided user email and name."
    git config --global user.email "$GIT_USER_EMAIL"
    git config --global user.name "$GIT_USER_NAME"

    git remote set-url origin https://$GITHUB_TOKEN@github.com/$GIT_USER_NAME/smrpg.git
    
    # Erzeugen eines Tags
    export GIT_TAG="build-${TRAVIS_BUILD_NUMBER}-SM${SMVERSION}"
    echo "Creating and pushing tag: $GIT_TAG"
    git tag $GIT_TAG -a -m "Generated tag from TravisCI for build $TRAVIS_BUILD_NUMBER with SMVERSION $SMVERSION"
    git push origin $GIT_TAG || { echo "Failed to push git tag to repository."; exit 1; }

    # Erzeugen der Release-Beschreibung
    BODY="New Release"
    RESPONSE=$(curl -H "Authorization: token $GITHUB_TOKEN" -H "Content-Type: application/json" --data "{\"tag_name\": \"$GIT_TAG\", \"target_commitish\": \"master\", \"name\": \"$GIT_TAG\", \"body\": \"$BODY\", \"draft\": false, \"prerelease\": false}" https://api.github.com/repos/$GIT_USER_NAME/smrpg/releases)
    echo "Basedir: $BASEDIR"
    echo "GitHub API Response: $RESPONSE"

    UPLOAD_URL=$(echo $RESPONSE | jq -r .upload_url | sed -e "s/{?name,label}//")
    UPLOAD_URL="${UPLOAD_URL}?name=$(basename "$ARCHIVE_PATH")&label=Release%20file"
    
    # Stelle sicher, dass der Pfad zum Archiv korrekt ist
    ARCHIVE_PATH="$BASEDIR/smrpg-rev$GITREVCOUNT.tar.gz"
    if [ -f "$ARCHIVE_PATH" ]; then
        echo "Uploading artifact from $ARCHIVE_PATH..."
        curl -v -H "Authorization: token $GITHUB_TOKEN" -H "Content-Type: application/octet-stream" --data-binary @"$ARCHIVE_PATH" "$UPLOAD_URL"
    else
        echo "File does not exist: $ARCHIVE_PATH"
        exit 1
    fi
else
    echo "This script only runs on master branch and when it's not a pull request."
fi
