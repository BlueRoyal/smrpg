#!/bin/bash

# Bash immediate exit and verbosity
set -ev

# Define the base directory and ensure all paths are relative to this
BASEDIR=$(pwd)

# from smlib travis tests
SMPATTERN="http:.*sourcemod-.*-linux\..*"
SMURL="http://www.sourcemod.net/smdrop/$SMVERSION/"
SMPACKAGE=$(lynx -dump "$SMURL" | grep -o "$SMPATTERN" | tail -1)

# get sourcemod package and copy plugin code into scripting folder
if [ ! -d "$BASEDIR/build" ]; then
  mkdir "$BASEDIR/build"
  cd "$BASEDIR/build"
  wget "$SMPACKAGE"
  tar -xzf "$(basename "$SMPACKAGE")"
  rm addons/sourcemod/scripting/*.sp
  cp -R "$BASEDIR/scripting/" addons/sourcemod/

  # get dependency libraries.
  git clone -b transitional_syntax --single-branch https://github.com/bcserv/smlib.git
  cp -R smlib/scripting/include/ addons/sourcemod/scripting/

  git clone https://github.com/Impact123/AutoExecConfig.git
  cp AutoExecConfig/autoexecconfig.inc addons/sourcemod/scripting/include/

  git clone https://github.com/Drifter321/DHooks2.git
  cp DHooks2/sourcemod/scripting/include/dhooks.inc addons/sourcemod/scripting/include/

  git clone https://github.com/Drixevel/Chat-Processor.git
  cp Chat-Processor/scripting/include/chat-processor.inc addons/sourcemod/scripting/include/
  
  git clone https://bitbucket.org/minimoney1/simple-chat-processor.git
  cp simple-chat-processor/scripting/include/scp.inc addons/sourcemod/scripting/include/
  
  git clone https://github.com/BlueRoyal/ColorVariables.git
  cp ColorVariables/addons/sourcemod/scripting/includes/colorvariables.inc addons/sourcemod/scripting/include/

  git clone https://github.com/peace-maker/mapzonelib.git
  cp mapzonelib/scripting/include/mapzonelib.inc addons/sourcemod/scripting/include/
fi

cd "$BASEDIR"

# setup the auto version file to have the git revision in the version convar.
git fetch --unshallow
GITREVCOUNT=$(git rev-list --count HEAD)

echo -e "#if defined _smrpg_version_included\n#endinput\n#endif\n#define _smrpg_version_included\n\n" > "$BASEDIR/build/addons/sourcemod/scripting/include/smrpg/smrpg_autoversion.inc"
echo -e "#define SMRPG_VERSION \"1.0-$GITREVCOUNT\"\n" >> "$BASEDIR/build/addons/sourcemod/scripting/include/smrpg/smrpg_autoversion.inc"

# setup package folders
PACKAGEDIR="$BASEDIR/package"
if [ ! -d "$PACKAGEDIR" ]; then
  mkdir -p "$PACKAGEDIR/plugins/upgrades"
fi

cp -R "$BASEDIR/configs/" "$PACKAGEDIR/"
cp -R "$BASEDIR/gamedata/" "$PACKAGEDIR/"
cp -R "$BASEDIR/scripting/" "$PACKAGEDIR/"
cp -R "$BASEDIR/translations/" "$PACKAGEDIR/"

# compile the plugins
cd "$BASEDIR/build/addons/sourcemod/scripting/"
chmod +x spcomp

# compile base plugins
for f in *.sp; do
  if [ "$f" != "smrpg_chattags.sp" ]; then
    echo -e "\nCompiling $f..."
    smxfile=$(echo $f | sed -e 's/\.sp$/\.smx/')
    ./spcomp "$f" -o"$PACKAGEDIR/plugins/$smxfile" -E
  fi
done

# compile both versions of chattags for both chat processors..
echo -e "\nCompiling smrpg_chattags.sp for Chat Processor..."
./spcomp smrpg_chattags.sp -o"$PACKAGEDIR/plugins/smrpg_chattags_cp.smx" -E

echo -e "\nCompiling smrpg_chattags.sp for Simple Chat Processor..."
./spcomp smrpg_chattags.sp -o"$PACKAGEDIR/plugins/smrpg_chattags_scp.smx" -E USE_SIMPLE_PROCESSOR=

# compile all upgrades
for f in upgrades/*.sp; do
  if [ "$f" != "upgrades/smrpg_upgrade_example.sp" ]; then
    echo -e "\nCompiling upgrade $f..."
    smxfile=$(echo $f | sed -e 's/\.sp$/\.smx/')
    ./spcomp "$f" -o"$PACKAGEDIR/plugins/$smxfile" -E
  fi
done

# put the files into a nice archive
cd "$PACKAGEDIR"
ARCHIVE="smrpg-rev$GITREVCOUNT.tar.gz"
tar -zcvf "../$ARCHIVE" *
echo "Current directory content after setting BASEDIR:"
ls "$BASEDIR"

