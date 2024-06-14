#!/bin/sh

## Update to the location of the EIP repository
EIPS_REPO=~/Src/EIPs


EIPS_DIR=$EIPS_REPO/EIPS
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if [ x"update" = x"$1" ]; then
  if [ ! -d $EIPS_DIR ]; then
    echo "EIP repository not found, cloning"
    git clone https://github.com/ethereum/EIPs.git $EIPS_REPO
  fi

  echo "Updating EIP repository"
  cd $EIPS_DIR
  git pull

  echo "Updating EIP index"
  cd $SCRIPT_DIR

  find $EIPS_DIR -name  "*.md" -exec basename {} .md \; | \
    sed -e 's/eip-//' | \
    sort -n | \
    xargs -i{} yq --front-matter="extract" 'select(.status!="Moved") | "#" + .eip + " - " + .title + "\\\0icon\\\x1f" + .status + "\\\x1finfo\\\x1f" + .eip + "\\n"' $EIPS_DIR/eip-{}.md | \
    xargs echo -en | \
    sed 's/^ //
      s/\x1fDraft/\x1fdocument/
      s/\x1fReview/\x1fcontact-new/
      s/\x1fLast Call/\x1fcall-start/
      s/\x1fFinal/\x1fmedia-playback-start/
      s/\x1fLiving/\x1fmedia-playlist-repeat/
      s/\x1fStagnant/\x1fmedia-playback-pause/
      s/\x1fWithdrawn/\x1fedit-clear/' > eip-index
else
  ## Running in ROFI mode
  echo -en "\0prompt\x1fEIP Search\0no-custom\x1ftrue\n"

  if [ ! -f $SCRIPT_DIR/eip-index ]; then
    echo "EIP Index is not available"
    echo "If needed change the EIPS_DIR variable in the script"
    echo "Then call ./eips.rofi.sh update"
    echo "Ideally add the previous command to cron to keep the index up to date"
  else
    if [ -z "$ROFI_INFO" ]; then
      cat $SCRIPT_DIR/eip-index
    else
      coproc ( xdg-open "https://eips.ethereum.org/EIPS/eip-$ROFI_INFO"  > /dev/null  2>&1 )

      ## The previous line can be replaced with other command to open the selected EIP
      ## Rofi recommends using coproc to allow the rofi window to close while the command executes
      ## As an example, the following two lines would open the EIP's file locally on a terminal using glow

      # EIP_FILE=$EIPS_DIR/eip-$ROFI_INFO.md
      # coproc ( rofi-sensible-terminal -e glow -p $EIP_FILE )
    fi
  fi
fi
