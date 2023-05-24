#!/usr/bin/env bash

## build and deploy your cloud hyper/cde/lang with one keystoke
## Free,Written By MoeClub.org and linux-live.org,moded and enhanced by minlearn (https://github.com/minlearn/1keydd/) for 1, ddprogress fix in raw/native bash 2, onekeydevdesk remastering and installing (both local install and cloud wgetdd/ncdd) as its recovery 3, and for self-contained git mirror/image hosting (both debian and system img) 4, and for multiple machine type and models supports.
## meant to work/tested under debian family linux with bash > 4, ubuntu less than 20.04
## usage: ci.sh [[-b 0 ] -h 0[,az...]|az|sr|ks|orc|mbp -a 0|1|0,1 -g 0|1|2|0,1,2] -t debianbase|onekeydevdesk|devdeskos[,+lxcxxx/++lxcxxx...]|lxcxxx [-d/-c 1] # no+ lxcxxx: pure standalone pack mode,+: mergemode into 01-core,++: packmode into 01-core
## usage: wget -qO- https://github.com/minlearn/1keydd/raw/master/inst.sh | bash [ -s - [-t debian | your .gz http/https location | port:ip:blkname for nc | port:blkname for nc] [-d]]

# for wget -qO- xxx| bash -s - subsitute manner
[ "$(id -u)" != 0 ] && exec sudo bash -c "`cat -`" -a "$@"
# for bash <(wget -qO- xxx) -t subsitute manner we should:
# [ "$(id -u)" != 0 ] && exec sudo bash -c "`cat "$0"`" -a "$@"
[[ "$EUID" -ne '0' ]] && echo "Error:This script must be run as root!" && exit 1
[[ ! "$(bash --version | head -n 1 | grep -o '[1-9]'| head -n 1)" -ge '4' ]] && echo "Error:bash must be at least 4!" && exit 1
[[ "$(uname -a)" =~ "inux" && "$(uname -a)" =~ "entos" ]] && echo "requires debian or ubuntu" && exit 1
#[[ "$(uname -a)" =~ "inux" && "$(uname -a)" =~ "ebian" && $(echo $(lsb_release -sr) | awk -F '.' '{print($1)}') -ge '11' ]] && echo "requires debian 10 or below,ubt 18 or below" && exit 1
#[[ "$(uname -a)" =~ "inux" && "$(uname -a)" =~ "buntu" && $(echo $(lsb_release -sr) | awk -F '.' '{print($1)}') -ge '20' ]] && echo "requires debian 10 or below,ubt 18 or below" && exit 1
# [[ ! "$(uname -a)" =~ "inux" ]] && echo "unsupported os" && exit 1
# [[ "$(uname)" == "Darwin" ]] && tmpBUILD='1' && read -s -n1 -p "osx detected"

# =================================================================
# globals
# =================================================================

forcemaintainmode='0'                             # 0:all put in maintain,1,just devdeskos in maintain

export autoDEBMIRROR0='https://github.com/minlearn/1keyddhubfree-debianbase/raw/master'
export autoDEBMIRROR1='https://gitee.com/minlearn/1keyddhubfree-debianbase/raw/master'
export FORCEDEBMIRROR=''                          # force apply a fixed mirror/targetddurl selection to force override autoselectdebmirror results based on -t -m args given
export tmpTARGETMODE='0'                          # 0:WGETDD INSTMODE ONLY 1:CLOUDDDINSTALL+BUILD MIXTURE,2,3,nc install mode,defaultly it sholudbe 0
export tmpTARGET=''                               # dummy(for -d only),debianbase,onekeydevdesk,devdeskos,lxcdebtpl,lxcdebiantpl,devdeskosfull,debian,debian10restore

# part I: settings related instmode,most usually are auto informed,not customable
export setNet='0'                                 # auto informed by judging if forcenetcfgstring are feed
export AutoNet=''                                 # auto informed by judging ifsetnet and if netcfgfile has the static keyword, has value 1,2
export FORCE1STNICNAME=''                         # sometimes 1stnicnames are fixed,we force set this to avoid exceptions
export FORCENETCFGSTR=''                          # sometimes gateway and defroute and not in the same subnet,they shoud be manual explict set, azure use the hostname and dsm use the mac
export FORCEMIRRORIMGSIZE=''                      # force apply a fixed mirror/targetddimgsize to force checktarget results based on -s args given
export FORCEMIRRORIMGNOSEG=''                     # force apply the imgfile in both debmirrorsrc and imgmirrorsrc as non-seg git repo style,set to 1 to use common one-piece style
export FORCE1STHDNAME=''                          # sometimes 1sthdname that being installed to are fixed,we force set this to avoid exceptions
export FORCEGRUBTYPE=''                           # do we use this?
export FORCEPOSTDDCTL='0'                         # postddcontrol,0:auto(with autohdexp,autonetcfginject,autoreboot),1:pure dd,without auto hd exp,2:pure dd,without networkcfg injection,3:hold without reboot
export tmpINSTSERIAL='0'                          # 0 with serial console output support
export tmpINSTSSHONLY='0'

# part II: customables related with buildmode,initrfs,01-core,clients,lxcapps
export tmpBUILD='0'                               # 0:linux,1:unix,osx,2,lxc
export tmpBUILDGENE='0'                           # 0:biosmbr,1:biosgpt,2:uefigpt,used both in buildtime(0or1or2,0and1and2) and insttime(0or1or2)
export tmpBUILDPUTPVEINIFS='0'                    # put pve building prodcure inside initramfs? defaultly no
export tmpHOST=''                                 # (blank)0,az,servarica(sr),(kimsurf/ovh/sys)ks,orc,bwg10g512m,mbp,pd
export tmpHOSTMODEL='0'                           # 0:kvm,1:hv,2:xen,>2:bearmetal,auto informed,not customable,0:awlays bothmode,1-98:instonlymode,99,mixed build mode
export HOSTMODLIST='0'
export tmpHOSTARCH='0'                            # 0,x86-64,1,arm64,used both in buildtime（0or1singlearchonlymode，0and1fullarchmode） and insttime（0or1singlearchonlymode）
export custIMGSIZE='10'
export custUSRANDPASS='tdl'
export tmpTGTNICNAME='eth0'
export tmpTGTNICIP='111.111.111.111'              # pve only,input target nic public ip(127.0.0.1 and 127.0.1.1 forbidden,enter to use defaults 111.111.111.111)
export tmpWIFICONNECT='CMCC-Lsl,11111111,wlan0'   # input target wifi connecting settings(in valid hotspotname,hotspotpasswd,wifinicname form,passwd 8-63 long,enter to leave blank)
export GENCLIENTS='y'                             # linux,win,osx
export GENCLIENTSWINOSX='n'
export PACKCLIENTS='n'
export tmpEBDCLIENTURL='t.shalol.com'             # input target ip or domain that will be embeded into client
export GENCONTAINERS=''                           # list for mergemode into 01-core
export PACKCONTAINERS=''                          # list packmode into 01-core

# part III: debug and ci/cd extra addons, debug and ci cant coexists in a single subtitute
export tmpDEBUG='0'                               # 0,debug=manualmode in instmode, or special initramfsgen and localinst boot test in buildmode
export tmpDRYRUNREMASTER='0'                      # 0,use dryrunmode,wont mod grub? exists but dreprecated, we use ctlc sigint to do it
export tmpINSTWITHMANUAL='0'                      # 0,enter manual mode, for debugging purpose,will force hold before reboot to network-console
export tmpBUILDINSTTEST='0'                       # inst test after initramfs gened
export tmpBUILDCI='0'                             # full ci/cd mode,with git and split post addon actions,0，no ci,1,normal ciaddons for 1keyddbuild 2,ciaddons for lxc*build standalone

# =================================================================
# Below are function libs
# =================================================================

function Outbanner(){

  [[ "$1" == 'main' ]] && echo -e "
#############################################################################

 1keydd.com/inst.sh in one screener |  Usage): wget -qO- 1keydd.com/inst.sh|bash
 ---------------------------        |  GH): github.com/minlearn/1keydd
  1) Debian                         |  invocation count:\033[32m `[[ "$tmpTARGETMODE" != '1' && "$tmpBUILD" != '1' ]] && echo -n $(curl --max-time 2 -s https://shellevaluatedcounter.minlearn.org/api/{dsrkafuu:demo}|grep -Eo [0-9]*)`\033[0m
  2) Debianmu (devdeskos)           |  
  3) Debian10r                      |  Credentials after inst done:
 98) Custom/advance mode            |  account:  [\033[32m root/administrator/admin \033[0m]
 99) Manual/pretest/dryrun mode     |  password: [\033[32m 1keydd \033[0m]

#############################################################################
"

  [[ "$1" == 'sub' ]] && echo -e "
#############################################################################

 1keydd.com/inst.sh in one screener |  Usage: wget -qO- 1keydd.com/inst.sh|bash
 ---------------------------        |  GH): github.com/minlearn/1keydd
  *1) custom target                 |  
   2) custom deb mirror             |  
   3) custom first nic name         |  Credentials after inst done:
   4) custom static netcfg          |  account:  [\033[32m root/administrator/admin \033[0m]
   5) custom first hd name          |  password: [\033[32m 1keydd \033[0m] 

#############################################################################
"

}


function CheckDependence(){

  FullDependence='0';
  lostdeplist="";
  lostdeplist="";

  for BIN_DEP in `[[ "$tmpBUILD" -ne '0' ]] && echo "$1" |sed 's/,/\n/g' || echo "$1" |sed 's/,/\'$'\n''/g'`
    do
      if [[ -n "$BIN_DEP" ]]; then
        Founded='1';
        for BIN_PATH in `[[ "$tmpBUILD" -ne '0' ]] && echo "$PATH" |sed 's/:/\n/g' || echo "$PATH" |sed 's/:/\'$'\n''/g'`
          do
            ls $BIN_PATH/$BIN_DEP >/dev/null 2>&1;
            if [ $? == '0' ]; then
              Founded='0';
              break;
            fi
          done
        # detailed log under buildmode
        [[ "$tmpTARGET" == 'devdeskos' && "$tmpTARGETMODE" == '1' && "$tmpBUILD" != '1' ]]  && echo -en "\033[s[ \033[32m ${BIN_DEP:0:10}";
        if [ "$Founded" == '0' ]; then
          [[ "$tmpTARGET" == 'devdeskos' && "$tmpTARGETMODE" == '1' && "$tmpBUILD" != '1' ]]  && echo -en ",ok  \033[0m ]\033[u";
          :;
        else
          FullDependence='1';
          [[ "$tmpTARGET" == 'devdeskos' && "$tmpTARGETMODE" == '1' && "$tmpBUILD" != '1' ]]  && echo -en ",\033[31m miss \033[0m] ";
          # simple log under instmode
          #[[ "$tmpTARGETMODE" == '0' ]] && echo -en "[ \033[32m $BIN_DEP,\033[31m miss \033[0m] ";
          lostdeplist+=" $BIN_DEP" && { \
            [[ $lostdeplist =~ "sudo" ]] && lostpkglist+=" sudo"; \
            [[ $lostdeplist =~ "curl" ]] && lostpkglist+=" curl"; \
            [[ $lostdeplist =~ "ar" ]] && lostpkglist+=" binutils"; \
            [[ $lostdeplist =~ "cpio" ]] && lostpkglist+=" cpio"; \
            [[ $lostdeplist =~ "xzcat" ]] && lostpkglist+=" xz-utils"; \
            [[ $lostdeplist =~ "md5sum" || $lostdeplist =~ "sha1sum" || $lostdeplist =~ "sha256sum" || $lostdeplist =~ "df" ]] && lostpkglist+=" coreutils"; \
            [[ $lostdeplist =~ "losetup" ]] && lostpkglist+=" util-linux"; \
            [[ $lostdeplist =~ "parted" ]] && lostpkglist+=" parted"; \
            [[ $lostdeplist =~ "mkfs.fat" ]] && lostpkglist+=" dosfstools"; \
            [[ $lostdeplist =~ "squashfs" ]] && lostpkglist+=" squashfs-tools"; \
            [[ $lostdeplist =~ "sqlite3" ]] && lostpkglist+=" sqlite3"; \
            [[ $lostdeplist =~ "unzip" ]] && lostpkglist+=" unzip"; \
            [[ $lostdeplist =~ "zip" ]] && lostpkglist+=" zip"; \
            [[ $lostdeplist =~ "7z" ]] && lostpkglist+=" p7zip"; }
        fi
      fi
  done

  [[ "$tmpTARGETMODE" == '0' && "$tmpBUILD" != '1' ]] && [[ ! -f /usr/sbin/grub-reboot ]] && FullDependence='1' && lostdeplist+="grub2-common"  && lostpkglist+=" grub2-common"
  # [[ "$tmpBUILDGENE" == '1' && "$tmpTARGET" == 'devdeskos' && "$tmpTARGETMODE" == '1' ]] && [[ ! -f /usr/lib/grub/x86_64-efi/acpi.mod ]] && FullDependence='1' && lostdeplist+="grub-efi" && lostpkglist+=" grub-efi"

  if [ "$FullDependence" == '1' ]; then
    echo -en "[ \033[32m deps missing! perform autoinstall \033[0m ] ";
    apt-get update -y -qq  >/dev/null 2>&1 && apt-get install -y -qq `echo -n "$lostpkglist"` >/dev/null 2>&1;
    [[ $? == '0' ]] && echo -en "[ \033[32m done. \033[0m ]" || { echo;echo -en "\033[31m $lostdeplist missing !error happen while autoinstall! please running 'apt-get update && apt-get install $lostpkglist ' to install them\033[0m";exit 1; }
  else
    # simple log under instmode
    [[ "$tmpTARGETMODE" == '0' ]] && echo -en "[ \033[32m all,ok \033[0m ]";
  fi
}

SAMPLES=3
BYTES=511999 #1mb
TIMEOUT=1
TESTFILE="/1mtest"

function test_mirror() {

  for s in $(seq 1 $SAMPLES) ; do
    # CheckPass1
    downloaded=$(curl -k -L -r 0-$BYTES --max-time $TIMEOUT --silent --output /dev/null --write-out %{size_download} ${1}${TESTFILE})
    if [ "$downloaded" == "0" ] ; then
      break
    else
      # CheckPass2
      time=$(curl -k -L -r 0-$BYTES --max-time $TIMEOUT --silent --output /dev/null --write-out %{time_total} ${1}${TESTFILE})
      echo $time
    fi
  done

}

function mean() {
  len=$#
  echo $* | tr " " "\n" | sort -n | head -n $(((len+1)/2)) | tail -n 1
}


function SelectDEBMirror(){

  [ $# -ge 1 ] || exit 1

  declare -A MirrorTocheck
  MirrorTocheck=(["Debian0"]="" ["Debian1"]="" ["Debian2"]="")
  
  echo "$1" |sed 's/\ //g' |grep -q '^http://\|^https://\|^ftp://' && MirrorTocheck[Debian0]=$(echo "$1" |sed 's/\ //g');
  echo "$2" |sed 's/\ //g' |grep -q '^http://\|^https://\|^ftp://' && MirrorTocheck[Debian1]=$(echo "$2" |sed 's/\ //g');
  #echo "$3" |sed 's/\ //g' |grep -q '^http://\|^https://\|^ftp://' && MirrorTocheck[Debian2]=$(echo "$3" |sed 's/\ //g');


  for mirror in `[[ "$tmpBUILD" -ne '0' ]] && echo "${!MirrorTocheck[@]}" |sed 's/\ /\n/g' |sort -n |grep "^Debian" || echo "${!MirrorTocheck[@]}" |sed 's/\ /\'$'\n''/g' |sort -n |grep "^Debian"`
    do
      CurMirror="${MirrorTocheck[$mirror]}"

      [ -n "$CurMirror" ] || continue

      mean=$(mean $(test_mirror $CurMirror))
      if [ "$mean" != "-nan" -a "$mean" != "" ] ; then
        printf '%-60s %.5f\\n' $CurMirror $mean
      # else
        # printf '%-60s failed, ignoring\\n' $CurMirror 1>&2
      fi

    done

}


function CheckTarget(){

  if [[ -n "$1" ]]; then
    echo "$1" |grep -q '^http://\|^ftp://\|^https://\|^10000:/dev/\|^/dev/';
    [[ $? -ne '0' ]] && echo 'Invalid generic target given,Only support http://, ftp://, https://, port:/dev/ and /dev/:port schedmas !' && exit 1;

    [[ "$tmpTARGET" =~ "/dev/" ]] && IMGHEADERCHECK="nc" && sleep 3s && echo -e "[ \033[32m nc mode\033[0m ]" || {

      [[ "$tmpTARGET" != "devdeskos" ]] && IMGHEADERCHECK="$(curl -k -IsL "$1")";

      # check imagesize
      [[ "$tmpTARGET" != "devdeskos" ]] && IMGSIZE=20 || IMGSIZE=20
      #[[ "$tmpTARGET" != "devdeskos" ]] && IMGSIZE="$(echo "$IMGHEADERCHECK" | grep 'Content-Length'|awk '{print $2}')" || IMGSIZE=20
      # echo -en "[ \033[32m $IMGSIZEG \033[0m ]"
      [[ "$IMGSIZE" == '' ]] && echo -en " \033[31m Didnt got img size,or img too small,is there sth wrong? exit! \033[0m " && exit 1;

      # check imagetype
      [[ "$tmpTARGET" != "devdeskos" ]] && IMGTYPECHECK="$(echo "$IMGHEADERCHECK"|grep -E -o '200|302'|head -n 1)" || IMGTYPECHECK='git-segs';
      #directurl style,just force unzip 1
      [[ "$IMGTYPECHECK" == '200' && "$tmpTARGET" != 'devdeskos' ]] && UNZIP='1' && sleep 3s && echo -en "[ \033[32m x-gzip \033[0m ]";
      [[ "$IMGTYPECHECK" == '200' && "$tmpTARGET" == 'devdeskos' ]] && UNZIP='1' && sleep 3s && echo -en "[ \033[32m git-segs \033[0m ]";
      # refurl style,(we only check one ref level,2 or 3 level ref is not considered)
      [[ "$IMGTYPECHECK" == '302' ]] && {
        IMGTYPECHECKPASS_REF="$(echo "$IMGHEADERCHECK"|grep -E -o 'github|raw|qcow2|gzip|x-gzip'|head -n 1)";
        # github tricks,cause it has raw word in its typecheck info
        [[ "$IMGTYPECHECKPASS_REF" == 'github' ]] && UNZIP='1' && sleep 3s && echo -en "[ \033[32m github \033[0m ]";
        [[ "$IMGTYPECHECKPASS_REF" == 'raw' ]] && UNZIP='0' && sleep 3s && echo -en "[ \033[32m raw \033[0m ]";
        [[ "$IMGTYPECHECKPASS_REF" == 'qcow2' ]] && UNZIP='0' && sleep 3s && echo -en "[ \033[32m qcow2 \033[0m ]";
        [[ "$IMGTYPECHECKPASS_REF" == 'gzip' ]] && UNZIP='1' && sleep 3s && echo -en "[ \033[32m gzip \033[0m ]";
        [[ "$IMGTYPECHECKPASS_REF" == 'x-gzip' ]] && UNZIP='1' && sleep 3s && echo -en "[ \033[32m x-gzip \033[0m ]";
        [[ "$IMGTYPECHECKPASS_REF" == 'gunzip' ]] && UNZIP='1' && sleep 3s && echo -en "[ \033[32m gunzip \033[0m ]";
        # cause IMGTYPECHECKPASS_REF is forced to 1 level only,we simply failover the blank "more undetermined results in level 1 and all results in more levels" and force unzip to 1
        [[ "$IMGTYPECHECKPASS_REF" == '' ]] && UNZIP='1' && sleep 3s && echo -en "[ \033[32m x-gzip \033[0m ]";
      }
      [[ "$IMGTYPECHECK" == '' ]] && echo -en " \033[31m Img url are neither 301/302 refs nor git raw url, exit! \033[0m " && { [[ "$tmpTARGET" == "debian10r" ]] && echo -en " \033[31m debian10r image src may in maintain mode for 10-60m! \033[0m " && forcemaintainmode='1'; } && exit 1;
      # cause we dont check full refs levels,we cant use this
      #[[ "$IMGTYPECHECK" == '302' && "$IMGTYPECHECKPASS_REF" == '' ]] && echo -en " \033[31m Img url are neither 301/302 refs nor git raw url, exit! \033[0m " && exit 1;
      [[ "$UNZIP" == '' ]] && echo -en " \033[31m Didnt got a unzip mode, you may input a incorrect url,or the bad network traffic caused it,exit! \033[0m " && exit 1;


    }

  else
    echo 'Please input vaild image URL! ';
    exit 1;
  fi

}

download_file() {
  local url="$1"
  local file="$2"
  local seg="$3"
  local code="$4"

  local retry=0

  verify_file() {

    if [ -s "$file" -a -n "$code" ]; then
      ( echo "${code}  ${file}" | md5sum -c --quiet )
      return $?
    fi

    return 1
  }

  download_file_to_path() {
    if verify_file; then
      return 0
    fi

    if [ $retry -ge 3 ]; then
      rm -f "$file"
      echo -en "[ \033[31m `basename $url`,failed!! \033[0m ]"

      exit 1
    fi

    ( (for i in `seq -w 000 $seg`;do wget -qO- --no-check-certificate $url"_"$i; done) > $file )
    if [ "$?" != "0" ] && ! verify_file; then
      retry=$(expr $retry + 1)
      download_file_to_path
    else
      echo -en "[ \033[32m `basename $url`,ok!! \033[0m ]"
    fi
  }

  download_file_to_path
}


function getbasics(){

  compositemode="$1"
  instcheck=$([ "$tmpHOSTARCH" == '1' -a "$tmpHOSTARCH" != '' ]  && echo -n binary-arm64 || echo -n binary-amd64)/instcheck.dat
  installmodechoosevmlinuz=$([ "$tmpHOSTARCH" == '1' -a "$tmpHOSTARCH" != '' ]  && echo -n binary-arm64 || echo -n binary-amd64)/tallbar/vmlinuz$([ "$tmpHOSTARCH" == '1' -a "$tmpHOSTARCH" != '' ]  && echo -n _arm64)
  installmodechoosevmlinuz2=vmlinuz$([ "$tmpHOSTARCH" == '1' -a "$tmpHOSTARCH" != '' ]  && echo -n _arm64)
  installmodechoosevmlinuzcode=`wget --no-check-certificate -qO- "${IMGMIRROR/xxxxxx/1keydd}"/_build/onekeydevdesk/"$instcheck"|grep "$installmodechoosevmlinuz2":|awk -F ':' '{ print $2}'`
  installmodechoosetdlcore=$([ "$tmpHOSTARCH" == '1' -a "$tmpHOSTARCH" != '' ]  && echo -n binary-arm64 || echo -n binary-amd64)/tallbar/tdlcore$([ "$tmpHOSTARCH" == '1' -a "$tmpHOSTARCH" != '' ]  && echo -n _arm64).xz
  installmodechoosetdlcore2=tdlcore$([ "$tmpHOSTARCH" == '1' -a "$tmpHOSTARCH" != '' ]  && echo -n _arm64).xz
  installmodechoosetdlcorecode=`wget --no-check-certificate -qO- "${IMGMIRROR/xxxxxx/1keydd}"/_build/onekeydevdesk/"$instcheck"|grep "$installmodechoosetdlcore2":|awk -F ':' '{ print $2}'`

  # when down was used,only targetmode 0 occurs
  [[ "$1" == 'down' ]] && {

    [[ ! -f $topdir/$downdir/onekeydevdesk/$installmodechoosevmlinuz2 || ! -s $topdir/$downdir/onekeydevdesk/$installmodechoosevmlinuz2 ]] && download_file ${IMGMIRROR/xxxxxx/1keydd}/_build/onekeydevdesk/$installmodechoosevmlinuz $topdir/$downdir/onekeydevdesk/$installmodechoosevmlinuz2 020 $installmodechoosevmlinuzcode
    [[ ! -f $topdir/$downdir/onekeydevdesk/$installmodechoosetdlcore2 || ! -s $topdir/$downdir/onekeydevdesk/$installmodechoosetdlcore2 ]] && download_file ${IMGMIRROR/xxxxxx/1keydd}/_build/onekeydevdesk/$installmodechoosetdlcore $topdir/$downdir/onekeydevdesk/$installmodechoosetdlcore2 060 $installmodechoosetdlcorecode

  }

  # when copy was used,sometimes targetmode 0 and 1 both occurs
  # [[ "$1" == 'copy' ]] && {

    # [[ ! -f $topdir/$downdir/onekeydevdesk/tdlcore.tar.gz || ! -s $topdir/$downdir/onekeydevdesk/tdlcore.tar.gz ]] && cat $topdir/$downdir/onekeydevdesk/tdlcore.tar.gz_* > $topdir/$downdir/onekeydevdesk/tdlcore.tar.gz && [[ $? -ne '0' ]] && echo "cat failed" && exit 1
    # tdlinitrd.gz only in builddir p/
    # [[ "$tmpTARGETMODE" == "1" ]] && [[ ! -f $topdir/$downdir/onekeydevdesk/tdlinitrd.tar.gz || ! -s $topdir/$downdir/onekeydevdesk/tdlinitrd.tar.gz ]] && (for i in `seq -w 000 038`;do wget -qO- --no-check-certificate $MIRROR/$downdir/onekeydevdesk/binary-amd64/tdlinitrd.tar.gz_$i; done) > $topdir/$downdir/onekeydevdesk/tdlinitrd.tar.gz & pid=`expr $! + 0`;wait $pid;echo -en "[ \033[32m tdlinitrd tarball,done \033[0m ]" && [[ $? -ne '0' ]] && echo "download failed" && exit 1
    # [[ ! -f $kernelimage ]] && cat $kernelimage*  > $kernelimage && [[ $? -ne '0' ]] && echo "cat failed" && exit 1

  # }

}





ipNum()
{
  local IFS='.';
  read ip1 ip2 ip3 ip4 <<<"$1";
  echo $((ip1*(1<<24)+ip2*(1<<16)+ip3*(1<<8)+ip4));
}

SelectMax(){
  ii=0;
  for IPITEM in `route -n |awk -v OUT=$1 '{print $OUT}' |grep '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}'`
    do
      NumTMP="$(ipNum $IPITEM)";
      eval "arrayNum[$ii]='$NumTMP,$IPITEM'";
      ii=$[$ii+1];
    done
  echo ${arrayNum[@]} |sed 's/\s/\n/g' |sort -n -k 1 -t ',' |tail -n1 |cut -d',' -f2;
}

parsenetcfg(){

  # 1): setnet=1
  # 2): setnet!=1 and netcfgfile containes static (autonet=1=still static)
  # 3): setnet!=1 and netcfgfile dont containes static (autonet=2=dhcp)
  [ -n "$FORCENETCFGSTR" ] && setNet='1';
  [[ "$setNet" != '1' ]] && [[ -f '/etc/network/interfaces' ]] && {
    [[ -z "$(sed -n '/iface.*inet static/p' /etc/network/interfaces)" ]] && AutoNet='2' || AutoNet='1';[[ -n "$(sed -n '/iface.*inet manual/p' /etc/network/interfaces)" ]] && [[ -n "$(sed -n '/iface.*inet static/p' /etc/network/interfaces)" ]] && AutoNet='2'
    
    [[ -d /etc/network/interfaces.d ]] && {
      ICFGN="$(find /etc/network/interfaces.d -name '*.cfg' |wc -l)" || ICFGN='0';
      [[ "$ICFGN" -ne '0' ]] && {
        for NetCFG in `ls -1 /etc/network/interfaces.d/*.cfg`
          do 
            [[ -z "$(cat $NetCFG | sed -n '/iface.*inet static/p')" ]] && AutoNet='2' || AutoNet='1';[[ -n "$(cat $NetCFG | sed -n '/iface.*inet manual/p' /etc/network/interfaces)" ]] && [[ -n "$(cat $NetCFG | sed -n '/iface.*inet static/p' /etc/network/interfaces)" ]] && AutoNet='2'
            [[ "$AutoNet" -eq '0' ]] && break;
          done
      }
    }
  }


  [[ -n "$custWORD" ]] && myPASSWORD="$(openssl passwd -1 "$custWORD")";
  [[ -z "$myPASSWORD" ]] && myPASSWORD='$1$4BJZaD0A$y1QykUnJ6mXprENfwpseH0';

  # we have force1stnicname
  if [[ -n "$FORCE1STNICNAME" ]]; then
    IFETH="$FORCE1STNICNAME"
  else
    IFETH="auto"
  fi

  [[ "$setNet" == '1' ]] && {

    # NAME:myvps,IPV4:10.211.55.105,CIDR:24,MAC:001C42171017,MASK:255.255.255.0,GATE:10.211.55.1,STATICROUTE:default,DNS1:8.8.8.8,DNS2:1.1.1.1

    #NAME=`echo "$FORCENETCFGSTR" | awk -F ',' '{ print $1}' | awk -F ':' '{ print $2}'`
    IPV4=`echo "$FORCENETCFGSTR" | awk -F ',' '{ print $1}'`
    #CIDR=`echo "$FORCENETCFGSTR" | awk -F ',' '{ print $3}' | awk -F ':' '{ print $2}'`
    #MAC=`echo "$FORCENETCFGSTR" | awk -F ',' '{ print $4}' | awk -F ':' '{ print $2}'`
    MASK=`echo "$FORCENETCFGSTR" | awk -F ',' '{ print $2}'`
    GATE=`echo "$FORCENETCFGSTR" | awk -F ',' '{ print $3}'`
    #STATICROUTE=`echo "$FORCENETCFGSTR" | awk -F ',' '{ print $7}' | awk -F ':' '{ print $2}'`
    #DNS1=`echo "$FORCENETCFGSTR" | awk -F ',' '{ print $8}' | awk -F ':' '{ print $2}'`
    #DNS2=`echo "$FORCENETCFGSTR" | awk -F ',' '{ print $9}' | awk -F ':' '{ print $2}'`


  } || {
    DEFAULTNET="$(ip route show |grep -o 'default via [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.*' |head -n1 |sed 's/proto.*\|onlink.*//g' |awk '{print $NF}')";
    [[ -n "$DEFAULTNET" ]] && IPSUB="$(ip addr |grep ''${DEFAULTNET}'' |grep 'global' |grep 'brd' |head -n1 |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}/[0-9]\{1,2\}')";
    IPV4="$(echo -n "$IPSUB" |cut -d'/' -f1)";
    CIDR="$(echo -n "$IPSUB" |grep -o '/[0-9]\{1,2\}')";
    GATE="$(ip route show |grep -o 'default via [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}' |head -n1 |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}')";
    [[ -n "$CIDR" ]] && MASK="$(echo -n '128.0.0.0/1,192.0.0.0/2,224.0.0.0/3,240.0.0.0/4,248.0.0.0/5,252.0.0.0/6,254.0.0.0/7,255.0.0.0/8,255.128.0.0/9,255.192.0.0/10,255.224.0.0/11,255.240.0.0/12,255.248.0.0/13,255.252.0.0/14,255.254.0.0/15,255.255.0.0/16,255.255.128.0/17,255.255.192.0/18,255.255.224.0/19,255.255.240.0/20,255.255.248.0/21,255.255.252.0/22,255.255.254.0/23,255.255.255.0/24,255.255.255.128/25,255.255.255.192/26,255.255.255.224/27,255.255.255.240/28,255.255.255.248/29,255.255.255.252/30,255.255.255.254/31,255.255.255.255/32' |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}'${CIDR}'' |cut -d'/' -f1)";
  }

  [[ -n "$GATE" ]] && [[ -n "$MASK" ]] && [[ -n "$IPV4" ]] || {
    echo "\`ip command\` Failed to get gate,mask,IPV4 settings, will try using \`route command\`."


    [[ -z $IPV4 ]] && IPV4="$(ifconfig |grep 'Bcast' |head -n1 |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}' |head -n1)";
    [[ -z $GATE ]] && GATE="$(SelectMax 2)";
    [[ -z $MASK ]] && MASK="$(SelectMax 3)";

    [[ -n "$GATE" ]] && [[ -n "$MASK" ]] && [[ -n "$IPV4" ]] || {
      echo "Error! get netcfg auto settings failed. please speficty static netcfg settings";
      exit 1;
    }
  }

  # buildmode, set auto net hints
  [[ "$setNet" == '0' || "$AutoNet" == '1' || "$tmpTARGETMODE" == '1' ]] && echo -en "[ \033[32m auto dhcp mode \033[0m ]" || echo -en "[ \033[32m static netcfg mode \033[0m ]"
  echo -en "[ \033[32m $IPV4,$GATE,$MASK \033[0m ]"

}


parsegrub(){


  #maybe we can force FORCEGRUBTYPE first, just in the plan

  [[ ! -d /boot ]] && [[ "$tmpBUILD" != "1" ]] && [[ "$tmpTARGETMODE" != "1" ]] && echo -ne "Error! \nNo boot directory mounted.\n" && exit 1;
  [[ -z `find /boot -name grub.cfg -o -name grub.conf` ]] && [[ "$tmpBUILD" != "1" ]] && [[ "$tmpTARGETMODE" != "1" ]] && echo -ne "Error! \nNo grubcfg files in the boot directory.\n" && exit 1;

  # try lookingfor the full working grub(file+dir+ver); simple case : only one grub gen(bios) and grub cfg
  if [[ "$tmpBUILDGENE" != "2" ]] && [[ "$tmpBUILD" != "1" ]] && [[ "$tmpTARGETMODE" != "1" ]]; then
     WORKINGGRUB=`find /boot/grub* -maxdepth 1 -mindepth 1 -name grub.cfg -o -name grub.conf`
     [[ -z "$GRUBDIR" ]] && [[ `echo $WORKINGGRUB|wc -l` == 1 ]] && GRUBTYPE='0' && GRUBDIR=${WORKINGGRUB%/*}/ && GRUBFILE=${WORKINGGRUB##*/}
  fi
  # try lookingfor the full working grub(file+dir+ver); complicated cases : one(efi) or two grub gen(bios and efi) coexists and one or two grub cfgs
  if [[ "$tmpBUILDGENE" == "2" ]] && [[ "$tmpBUILD" != "1" ]] && [[ "$tmpTARGETMODE" != "1" ]]; then
    WORKINGGRUB=`find /boot -name grub.cfg -o -name grub.conf`
    # we must use echo "$WORKINGGRUB" but not $WORKINGGRUB or lines will be ingored
    [[ -z "$GRUBDIR" ]] && [[ `echo "$WORKINGGRUB"|wc -l` == 1 ]] && GRUBTYPE='1' && GRUBDIR=${WORKINGGRUB%/*}/ && GRUBFILE=${WORKINGGRUB##*/};
    # we must use grep -vq && but not grep -q ||,or ...
    # it seems that grep -vq are not portable(results may vary though under same stuation)
    [[ -z "$GRUBDIR" ]] && [[ `echo "$WORKINGGRUB"|wc -l` == 2 ]] && GRUBTYPE='2' && echo "$WORKINGGRUB" | while read line; do cat $line | grep -Eo -q configfile || { GRUBDIR=${line%/*}/;GRUBFILE=${line##*/}; };done
  fi
  # if above both failed,force a brute way
  [ -z "$GRUBDIR" -o -z "$GRUBFILE" ] && GRUBDIR='' && GRUBFILE='' && {
    [[ -f '/boot/grub/grub.cfg' ]] && GRUBTYPE='0' && GRUBDIR='/boot/grub' && GRUBFILE='grub.cfg';
    [[ -z "$GRUBDIR" ]] && [[ -f '/boot/grub2/grub.cfg' ]] && GRUBTYPE='0' && GRUBDIR='/boot/grub2' && GRUBFILE='grub.cfg';
    [[ -z "$GRUBDIR" ]] && [[ -f '/boot/grub/grub.conf' ]] && GRUBTYPE='3' && GRUBDIR='/boot/grub' && GRUBFILE='grub.conf';
  }

  # all failed,so we give up
  [ -z "$GRUBDIR" -o -z "$GRUBFILE" ] && echo -ne "Error! \nNo working grub.\n" && exit 1;


  [[ ! -f $GRUBDIR/$GRUBFILE ]] && echo "Error! No working grub file $GRUBFILE. " && exit 1;

  [[ ! -f $GRUBDIR/$GRUBFILE.old ]] && [[ -f $GRUBDIR/$GRUBFILE.bak ]] && mv -f $GRUBDIR/$GRUBFILE.bak $GRUBDIR/$GRUBFILE.old;
  mv -f $GRUBDIR/$GRUBFILE $GRUBDIR/$GRUBFILE.bak;
  [[ -f $GRUBDIR/$GRUBFILE.old ]] && cat $GRUBDIR/$GRUBFILE.old >$GRUBDIR/$GRUBFILE || cat $GRUBDIR/$GRUBFILE.bak >$GRUBDIR/$GRUBFILE;


  [[ "$GRUBTYPE" == '0' || "$GRUBTYPE" == '1' || "$GRUBTYPE" == '2' ]] && {

    # we also offer a efi here
    mkdir -p $remasteringdir/boot # $remasteringdir/boot/grub/i386-pc $remasteringdir/boot/EFI/boot/x86_64-efi

    READGRUB=''$remasteringdir'/boot/grub.read'
    cat $GRUBDIR/$GRUBFILE |sed -n '1h;1!H;$g;s/\n/%%%%%%%/g;$p' |grep -om 1 'menuentry\ [^{]*{[^}]*}%%%%%%%' |sed 's/%%%%%%%/\n/g' >$READGRUB
    LoadNum="$(cat $READGRUB |grep -c 'menuentry ')"
    if [[ "$LoadNum" -eq '1' ]]; then
      cat $READGRUB |sed '/^$/d' >$remasteringdir/boot/grub.new;
    elif [[ "$LoadNum" -gt '1' ]]; then
      CFG0="$(awk '/menuentry /{print NR}' $READGRUB|head -n 1)";
      CFG2="$(awk '/menuentry /{print NR}' $READGRUB|head -n 2 |tail -n 1)";
      CFG1="";
      for tmpCFG in `awk '/}/{print NR}' $READGRUB`
        do
          [ "$tmpCFG" -gt "$CFG0" -a "$tmpCFG" -lt "$CFG2" ] && CFG1="$tmpCFG";
        done
      [[ -z "$CFG1" ]] && {
        echo "Error! read $GRUBFILE. ";
        exit 1;
      }

      sed -n "$CFG0,$CFG1"p $READGRUB >$remasteringdir/boot/grub.new;
      [[ -f $remasteringdir/boot/grub.new ]] && [[ "$(grep -c '{' $remasteringdir/boot/grub.new)" -eq "$(grep -c '}' $remasteringdir/boot/grub.new)" ]] || {
        echo -ne "\033[31m Error! \033[0m Not configure $GRUBFILE. \n";
        exit 1;
      }
    fi
    [ ! -f $remasteringdir/boot/grub.new ] && echo "Error! $GRUBFILE. " && exit 1;
    sed -i "/menuentry.*/c\menuentry\ \'COLXC \[cooperlxclinux\ withrecoveryandhypervinside\]\'\ --class debian\ --class\ gnu-linux\ --class\ gnu\ --class\ os\ --unrestricted\ \{" $remasteringdir/boot/grub.new
    sed -i "/echo.*Loading/d" $remasteringdir/boot/grub.new;

    CFG00="$(awk '/menuentry /{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)";
    CFG11=()
    for tmptmpCFG in `awk '/}/{print NR}' $GRUBDIR/$GRUBFILE`
    do
      [ "$tmptmpCFG" -gt "$CFG00" ] && CFG11+=("$tmptmpCFG");
    done
    # all routed to grub-reboot logic
    [[ "$LoadNum" -eq '1' ]] && INSERTGRUB="$(expr ${CFG11[0]} + 1)" || INSERTGRUB="$(awk '/submenu |menuentry /{print NR}' $GRUBDIR/$GRUBFILE|head -n 2|tail -n 1)"
    echo -en "[ \033[32m found at line: $INSERTGRUB \033[0m ]"
  }

  [[ "$GRUBTYPE" == '3' ]] && {
    CFG0="$(awk '/title[\ ]|title[\t]/{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)";
    CFG1="$(awk '/title[\ ]|title[\t]/{print NR}' $GRUBDIR/$GRUBFILE|head -n 2 |tail -n 1)";
    [[ -n $CFG0 ]] && [ -z $CFG1 -o $CFG1 == $CFG0 ] && sed -n "$CFG0,$"p $GRUBDIR/$GRUBFILE >$remasteringdir/boot/grub.new;
    [[ -n $CFG0 ]] && [ -z $CFG1 -o $CFG1 != $CFG0 ] && sed -n "$CFG0,$[$CFG1-1]"p $GRUBDIR/$GRUBFILE >$remasteringdir/boot/grub.new;
    [[ ! -f $remasteringdir/boot/grub.new ]] && echo "Error! configure append $GRUBFILE. " && exit 1;
    sed -i "/title.*/c\title\ \'DebianNetboot \[buster\ amd64\]\'" $remasteringdir/boot/grub.new;
    sed -i '/^#/d' $remasteringdir/boot/grub.new;
    INSERTGRUB="$(awk '/title[\ ]|title[\t]/{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)"
  }

  [[ -n "$(grep 'linux.*/\|kernel.*/' $remasteringdir/boot/grub.new |awk '{print $2}' |tail -n 1 |grep '^/boot/')" ]] && Type='InBoot' || Type='NoBoot';

  LinuxKernel="$(grep 'linux.*/\|kernel.*/' $remasteringdir/boot/grub.new |awk '{print $1}' |head -n 1)";
  [[ -z "$LinuxKernel" ]] && echo "Error! read grub config! " && exit 1;
  LinuxIMG="$(grep 'initrd.*/' $remasteringdir/boot/grub.new |awk '{print $1}' |tail -n 1)";
  [ -z "$LinuxIMG" ] && sed -i "/$LinuxKernel.*\//a\\\tinitrd\ \/" $remasteringdir/boot/grub.new && LinuxIMG='initrd';

  # we have force1stnicname and ln -s tricks instead
  # if [[ "$setInterfaceName" == "1" ]]; then
  #   Add_OPTION="net.ifnames=0 biosdevname=0";
  # else
  #   Add_OPTION="";
  # fi

  # if [[ "$setIPv6" == "1" ]]; then
  #   Add_OPTION="$Add_OPTION ipv6.disable=1";
  # fi

  # $([[ "$tmpINSTEMBEDVNC" == '1' ]] && echo DEBIAN_FRONTEND=gtk) is not needed,will be forced in debug mode
  BOOT_OPTION="console=ttyS0,115200n8 console=tty0 debian-installer/framebuffer=false $([[ "$tmpINSTSSHONLY" == '1' ]] && echo DEBIAN_FRONTEND=text) $([[ "$tmpINSTWITHMANUAL" == '1' ]] && echo rescue/enable=true) auto=true $Add_OPTION hostname=debian domain= -- quiet";

  [[ "$Type" == 'InBoot' ]] && {
    sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/boot\/vmlinuz_1keyddinst $BOOT_OPTION" $remasteringdir/boot/grub.new;
    sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/boot\/initrfs_1keyddinst.img" $remasteringdir/boot/grub.new;
  }

  [[ "$Type" == 'NoBoot' ]] && {
    sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/vmlinuz_1keyddinst $BOOT_OPTION" $remasteringdir/boot/grub.new;
    sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/initrfs_1keyddinst.img" $remasteringdir/boot/grub.new;
  }

  sed -i '$a\\n' $remasteringdir/boot/grub.new;

  # the final boot dir will inst to
  [[ "$tmpBUILD" != "1" ]] && [[ "$tmpTARGETMODE" != "1" || "$tmpBUILDINSTTEST" == '1' ]] && insttotmp=`df -P "$GRUBDIR"/"$GRUBFILE" | grep /dev/`
  [[ "$tmpBUILDGENE" != "2" ]] && [[ "$tmpBUILD" != "1" ]] && [[ "$tmpTARGETMODE" != "1" || "$tmpBUILDINSTTEST" == '1' ]] && instto="/boot"

  [[ "$tmpBUILDGENE" == "2" ]] && [[ "$GRUBTYPE" == "1" ]] && [[ "$tmpBUILD" != "1" ]] && [[ "$tmpTARGETMODE" != "1" || "$tmpBUILDINSTTEST" == '1' ]] && [[ `find /boot/efi -name grub.cfg -o -name grub.conf|wc -l` == 1 ]] && instto=${insttotmp##*[[:space:]]}
  [[ "$tmpBUILDGENE" == "2" ]] && [[ "$GRUBTYPE" == "1" ]] && [[ "$tmpBUILD" != "1" ]] && [[ "$tmpTARGETMODE" != "1" || "$tmpBUILDINSTTEST" == '1' ]] && [[ `find /boot/efi -name grub.cfg -o -name grub.conf|wc -l` == 0 ]] && instto="/boot"

  [[ "$tmpBUILDGENE" == "2" ]] && [[ "$GRUBTYPE" == "2" ]] && [[ "$tmpBUILD" != "1" ]] && [[ "$tmpTARGETMODE" != "1" || "$tmpBUILDINSTTEST" == '1' ]] && instto="$GRUBDIR"
  [[ "$instto" == "" ]] && [[ "$tmpBUILD" != "1" ]] && [[ "$tmpTARGETMODE" != "1" || "$tmpBUILDINSTTEST" == '1' ]] && instto="/boot"

  echo -en "[ \033[32m found at dir: $instto \033[0m ]"

}

patchgrub(){

  GRUBPATCH='0';

  if [[ "$tmpBUILD" != "1" && "$tmpTARGETMODE" != '1' || "$tmpBUILDINSTTEST" == '1' ]]; then
    #[ -f '/etc/network/interfaces' ] || {
    #  echo "Error, Not found interfaces config.";
    #  exit 1;
    #}

    sed -i ''${INSERTGRUB}'i\\n' $GRUBDIR/$GRUBFILE;
    sed -i ''${INSERTGRUB}'r '$remasteringdir'/boot/grub.new' $GRUBDIR/$GRUBFILE;

    sed -i 's/timeout_style=hidden/timeout_style=menu/g' $GRUBDIR/$GRUBFILE;
    sed -i 's/timeout=[0-9]*/timeout=10/g' $GRUBDIR/$GRUBFILE;

    [[ "$tmpBUILDINSTTEST" == '1' ]] && sed -e 's/vmlinuz_1keyddinst/vmlinuz_1keyddlocaltest live/g' -e 's/initrfs_1keyddinst.img/initrfs_1keyddlocaltest.img/g' -i $GRUBDIR/$GRUBFILE;

    [[ -f  $GRUBDIR/grubenv ]] && sed -i 's/saved_entry/#saved_entry/g' $GRUBDIR/grubenv;
  fi

}

restoregrub(){

  [[ -f $GRUBDIR/$GRUBFILE.bak ]] && cp -f $GRUBDIR/$GRUBFILE.bak $GRUBDIR/$GRUBFILE
  [[ -f $GRUBDIR/$GRUBFILE.old ]] && cp -f $GRUBDIR/$GRUBFILE.old $GRUBDIR/$GRUBFILE
  grub-reboot 0

}


function processbasics(){

  kernelimage=$topdir/p/debianbase/dists/buster/main/binary-amd64/deb/linux-image-4.19.0-14-amd64_4.19.171-2_amd64.deb
  kernelimage_arm64=$topdir/p/debianbase/dists/buster/main/binary-arm64/deb/linux-image-4.19.0-14-arm64_4.19.171-2_arm64.deb
  mkdir -p $remasteringdir/initramfs/usr/bin $remasteringdir/initramfs/hehe0 $remasteringdir/initramfs_arm64/usr/bin $remasteringdir/initramfs_arm64/hehe0 $remasteringdir/onekeydevdeskd/01-core $remasteringdir/onekeydevdeskd_arm64/01-core


  if [[ "$tmpTARGETMODE" != '1' ]]; then

    cd $topdir/$remasteringdir/initramfs;
    CWD="$(pwd)"
    #echo -en "[ \033[32m cd to ${CWD##*/} \033[0m ]"

    #echo -en " - busy unpacking tdlcore.xz ..."
    tar Jxf $topdir/$downdir/onekeydevdesk/tdlcore$([ "$tmpHOSTARCH" == '1' -a "$tmpHOSTARCH" != '' ]  && echo -n _arm64).xz -C . >>/dev/null 2>&1
  fi  


  #cp -aR $topdir/$downdir/onekeydevdesk/debian-live ./lib >>/dev/null 2>&1
  #chmod +x ./lib/debian-live/*
  #cp -aR $topdir/$downdir/onekeydevdesk/updates ./lib/modules/4.19.0-14-amd64 >>/dev/null 2>&1


}


preparepreseed(){

  tee -a $topdir/$remasteringdir/initramfs/preseed.cfg $topdir/$remasteringdir/initramfs_arm64/preseed.cfg > /dev/null <<EOF
#pass the lowmem note,but still it may have problems
d-i debian-installer/language string en
d-i debian-installer/country string US
d-i debian-installer/locale string en_US.UTF-8
d-i lowmem/low note
# $([[ "$tmpINSTEMBEDVNC" != '1' ]] && echo d-i debian-installer/framebuffer boolean false) is not needed,we also mentioned and moved it to bootcode before
d-i debian-installer/framebuffer boolean false
d-i console-setup/layoutcode string us
d-i keyboard-configuration/xkb-keymap string us
d-i hw-detect/load_firmware boolean true
d-i netcfg/choose_interface select $IFETH
d-i netcfg/disable_autoconfig boolean true
d-i netcfg/dhcp_failed note
d-i netcfg/dhcp_options select Configure network manually
# d-i netcfg/get_ipaddress string $custIPADDR
d-i netcfg/get_ipaddress string $IPV4
d-i netcfg/get_netmask string $MASK
d-i netcfg/get_gateway string $GATE
d-i netcfg/get_nameservers string 8.8.8.8
d-i netcfg/no_default_route boolean true
d-i netcfg/confirm_static boolean true
d-i mirror/country string manual
#d-i mirror/http/hostname string $IPV4
d-i mirror/http/hostname string $DEBMIRROR
d-i mirror/http/directory string /debianbase
d-i mirror/http/proxy string
d-i apt-setup/services-select multiselect
d-i debian-installer/allow_unauthenticated boolean true
d-i debian-installer/allow_unauthenticated_ssl boolean true
d-i passwd/root-login boolean ture
d-i passwd/make-user boolean false
d-i passwd/root-password-crypted password \$1\$8ASOKotc\$AlIunLy3WT1OjLI85ON7i0
d-i user-setup/allow-password-weak boolean true
d-i user-setup/encrypt-home boolean false
d-i clock-setup/utc boolean true
d-i time/zone string US/Eastern
d-i clock-setup/ntp boolean true
EOF


  [[ "$tmpTARGETMODE" == '0' && "$tmpTARGET" == 'debian' && "$tmpINSTWITHMANUAL" != '1' ]] && tee -a $topdir/$remasteringdir/initramfs/preseed.cfg $topdir/$remasteringdir/initramfs_arm64/preseed.cfg > /dev/null <<EOF
# we mixed the efi and bios togeth in 30atomic
# must not place anna-install network-console here in preseed/early_command but instead in partman/early_command
d-i preseed/early_command string screen -dmS reboot /sbin/reboot -d 300
d-i partman/early_command string count=\`ping -c 5 8.8.8.8 | grep from* | wc -l\`;pid=\`screen -ls|grep -Eo [0-9]*.reboot|grep -Eo [0-9]*\`;[ \$count -ne 0 ] && kill -9 \$pid;chmod 755 /usr/lib/debianinstall-patchs/baseinstaller.sh /usr/lib/debianinstall-patchs/debootstrap.sh /usr/lib/debianinstall-patchs/apt-install.sh /usr/lib/debianinstall-patchs/pkgsel.sh;/usr/lib/debianinstall-patchs/baseinstaller.sh;/usr/lib/debianinstall-patchs/debootstrap.sh;/usr/lib/debianinstall-patchs/apt-install.sh;/usr/lib/debianinstall-patchs/pkgsel.sh;sed -i "1a 1 1 1 free \\\$iflabel{ gpt } \\\$reusemethod{ } method{ biosgrub } ." /lib/partman/recipes-amd64-efi/30atomic;cp -f /lib/partman/recipes-amd64-efi/30atomic /lib/partman/recipes/30atomic;debconf-set partman-auto/disk $([[ "$FORCE1STHDNAME" != '' ]] && echo "/dev/$FORCE1STHDNAME" || echo "\"\$(list-devices disk | head -n1)\"")

d-i partman-auto/method string lvm
d-i partman-auto/choose_recipe select atomic

d-i partman-partitioning/choose_label string gpt
d-i partman-partitioning/default_label string gpt
d-i partman-partitioning/confirm_write_new_label boolean true

d-i partman-md/device_remove_md boolean true
d-i partman-lvm/device_remove_lvm boolean true
d-i partman-auto-lvm/guided_size string max
d-i partman-auto-lvm/new_vg_name string cl
d-i partman-lvm/confirm boolean true
d-i partman-lvm/confirm_nooverwrite boolean true

d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

d-i base-installer/kernel/image string linux-image-4.19.0-14-$([[ "$tmpHOSTARCH" != '1' ]] && echo amd || echo arm)64

tasksel tasksel/first multiselect minimal
d-i pkgsel/update-policy select none
d-i pkgsel/include string openssh-server
d-i pkgsel/upgrade select none

popularity-contest popularity-contest/participate boolean false

d-i grub-installer/only_debian boolean true
d-i grub-installer/bootdev string default
d-i grub-installer/force-efi-extra-removable boolean true

d-i finish-install/reboot_in_progress note
d-i debian-installer/exit/reboot boolean true
d-i preseed/late_command string sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/g' /target/etc/ssh/sshd_config;sed -i "s#$DEBMIRROR/debianbase#http://deb.debian.org/debian#g" /target/etc/apt/sources.list
EOF

  # both inst and buildmode share PIPECMSTR defines but without forcenetcfgstr and force github mirror for buildmode
  # we use both ext2/fat16 duplicated parts cause some machine only regnoice ext2(the ones boot with its own grub instead of on disk grubs)but not fat16
  choosevmlinuz=${IMGMIRROR/xxxxxx/1keydd}/_build/onekeydevdesk/$([ "$tmpHOSTARCH" == '1' -a "$tmpHOSTARCH" != '' ]  && echo -n binary-arm64 || echo -n binary-amd64)/tallbar/vmlinuz$([ "$tmpHOSTARCH" == '1' -a "$tmpHOSTARCH" != '' ]  && echo -n _arm64)
  [[ "$tmpTARGET" == devdeskos* ]] && chooseinitrfs=$TARGETDDURL/initrfs$([ "$tmpHOSTARCH" == '1' -a "$tmpHOSTARCH" != '' ]  && echo -n _arm64).img;chooseonekeydevdeskd=$TARGETDDURL/onekeydevdeskd$([ "$tmpHOSTARCH" == '1' -a "$tmpHOSTARCH" != '' ]  && echo -n _arm64).xz;PIPECMDSTR='(for i in `seq -w 0 999`;do wget -qO- --no-check-certificate '$chooseonekeydevdeskd'_$i; done)|tar Jxv -C sda4 > /var/log/progress & pid=`expr $! + 0`;echo $pid;(for i in `seq -w 0 019`;do wget -qO- --no-check-certificate '$choosevmlinuz'_$i; done)|cat - >> sda2/vmlinuz;(for i in `seq -w 0 049`;do wget -qO- --no-check-certificate '$chooseinitrfs'_$i; done)|cat - >> sda2/initrfs.img';

  # we meant to use live-installer but it is too complicated so we turn to parted
  # there is only grub-efi on arm64,shall we separate preseed?
  # we must put force1sthdname before forcenetcfgstr,because argpositiion 2 is always there but 3 not
  [[ "$tmpTARGETMODE" == '0' && "$tmpINSTWITHMANUAL" != '1' && "$tmpTARGET" == devdeskos* ]] && tee -a $topdir/$remasteringdir/initramfs/preseed.cfg $topdir/$remasteringdir/initramfs_arm64/preseed.cfg > /dev/null <<EOF
# must not place anna-install network-console here in preseed/early_command but instead in partman/early_command
d-i preseed/early_command string screen -dmS reboot /sbin/reboot -d 300
d-i partman/early_command string count=\`ping -c 5 8.8.8.8 | grep from* | wc -l\`;pid=\`screen -ls|grep -Eo [0-9]*.reboot|grep -Eo [0-9]*\`;[ \$count -ne 0 ] && kill -9 \$pid;anna-install parted-udeb fdisk-udeb;chmod 755 /usr/lib/liveinstall-patchs/longrunpipebgcmd_redirectermoniter.sh;/usr/lib/liveinstall-patchs/longrunpipebgcmd_redirectermoniter.sh '$PIPECMDSTR' $([[ "$FORCE1STHDNAME" != '' ]] && echo "/dev/$FORCE1STHDNAME" || echo "\"\$(list-devices disk | head -n1)\"") $([[ "$FORCE1STNICNAME" != '' ]] && echo "$FORCE1STNICNAME" || echo "\"\$(ip route show |grep -o 'default via [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.*' |head -n1 |sed 's/proto.*\|onlink.*//g' |awk '{print \$NF}')\"") $([ "$setNet" == '1' -a "$FORCENETCFGSTR" != '' ] && echo "$FORCENETCFGSTR";[ "$AutoNet" == '1' -a "$IPV4" != '' -a "$MASK" != '' -a "$GATE" != '' ] && echo "$IPV4","$MASK","$GATE")
EOF




  # azure hd need bs=10M or it will fail
  [[ "$UNZIP" == '0' && "$tmpTARGET" != 'debian10r' ]] && PIPECMDSTR='wget -qO- --no-check-certificate '$TARGETDDURL' |stdbuf -oL dd of=$(list-devices disk |head -n1) bs=10M 2> /var/log/progress & pid=`expr $! + 0`;echo $pid';
  [[ "$UNZIP" == '1' && "$tmpTARGET" != 'debian10r' && "$tmpTARGET" != devdeskos* && "$FORCE1STHDNAME" != '' ]] && PIPECMDSTR='wget -qO- --no-check-certificate '$TARGETDDURL' |gunzip -dc |stdbuf -oL dd of=/dev/'$FORCE1STHDNAME' bs=10M 2> /var/log/progress & pid=`expr $! + 0`;echo $pid' || PIPECMDSTR='wget -qO- --no-check-certificate '$TARGETDDURL' |gunzip -dc |stdbuf -oL dd of=$(list-devices disk |head -n1) bs=10M 2> /var/log/progress & pid=`expr $! + 0`;echo $pid';
  [[ "$UNZIP" == '1' && "$tmpTARGET" == 'debian10r' && "$FORCE1STHDNAME" != '' ]] && PIPECMDSTR='(for i in `seq -w 000 699`;do wget -qO- --no-check-certificate '$TARGETDDURL'_$i; done) |tar JOx |stdbuf -oL dd of=/dev/'$FORCE1STHDNAME' bs=10M 2> /var/log/progress & pid=`expr $! + 0`;echo $pid';
  [[ "$UNZIP" == '1' && "$tmpTARGET" == 'debian10r' && "$FORCE1STHDNAME" == '' ]] && PIPECMDSTR='(for i in `seq -w 000 699`;do wget -qO- --no-check-certificate '$TARGETDDURL'_$i; done) |tar JOx |stdbuf -oL dd of=$(list-devices disk |head -n1) bs=10M 2> /var/log/progress & pid=`expr $! + 0`;echo $pid';
  [[ "$UNZIP" == '2' && "$tmpTARGET" != 'debian10r' ]] && PIPECMDSTR='wget -qO- --no-check-certificate '$TARGETDDURL' |tar zOx |stdbuf -oL dd of=$(list-devices disk |head -n1) bs=10M 2> /var/log/progress & pid=`expr $! + 0`;echo $pid';

  # we must put force1sthdname before forcenetcfgstr,because argpositiion 1,2,3,4 is always there(fixedly appear) but 5 not(if not forced,it dont occpy a pos),we pust fixed ones piorr in front
  [[ "$tmpTARGETMODE" == '0' && "$tmpINSTWITHMANUAL" != '1' && "$tmpTARGET" != 'debian' && "$tmpTARGET" != devdeskos* ]] && tee -a $topdir/$remasteringdir/initramfs/preseed.cfg $topdir/$remasteringdir/initramfs_arm64/preseed.cfg > /dev/null <<EOF
# anna-install wget-udeb here?
# must not place anna-install network-console here in preseed/early_command but instead in partman/early_command
d-i preseed/early_command string screen -dmS reboot /sbin/reboot -d 300
d-i partman/early_command string count=\`ping -c 5 8.8.8.8 | grep from* | wc -l\`;pid=\`screen -ls|grep -Eo [0-9]*.reboot|grep -Eo [0-9]*\`;[ \$count -ne 0 ] && kill -9 \$pid;anna-install fdisk-udeb;chmod 755 /usr/lib/ddinstall-patchs/longrunpipebgcmd_redirectermoniter.sh;/usr/lib/ddinstall-patchs/longrunpipebgcmd_redirectermoniter.sh '$PIPECMDSTR' $([[ "$FORCE1STHDNAME" != '' ]] && echo "/dev/$FORCE1STHDNAME" || echo "\"\$(list-devices disk | head -n1)\"") $([[ "$FORCE1STNICNAME" != '' ]] && echo "$FORCE1STNICNAME" || echo "\"\$(ip route show |grep -o 'default via [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.*' |head -n1 |sed 's/proto.*\|onlink.*//g' |awk '{print \$NF}')\"") $([ "$FORCEPOSTDDCTL" != '' ] && echo "$FORCEPOSTDDCTL") $([ "$setNet" == '1' -a "$FORCENETCFGSTR" != '' ] && echo "$FORCENETCFGSTR";[ "$AutoNet" == '1' -a "$IPV4" != '' -a "$MASK" != '' -a "$GATE" != '' ] && echo "$IPV4","$MASK","$GATE")
EOF


  ## cli,sender,src (start firstly)
  [[ "$tmpTARGETMODE" == '2' && "${tmpTARGET:8}" == ':10000' && "$tmpINSTWITHMANUAL" != '1' ]] && PIPECMDSTR='dd if='${tmpTARGET%%:10000}' bs=10M|gzip|nc '$IPV4' 10000 2> /var/log/progress & pid=`expr $! + 0`;echo $pid' && tee -a $topdir/$remasteringdir/initramfs/preseed.cfg $topdir/$remasteringdir/initramfs_arm64/preseed.cfg > /dev/null <<EOF
d-i partman/early_command string chmod 755 /usr/lib/ddinstall-patchs/longrunpipebgcmd_redirectermoniter.sh;/usr/lib/ddinstall-patchs/longrunpipebgcmd_redirectermoniter.sh '$PIPECMDSTR'
EOF

  ## srv,rever,target (startly secondly)
  [[ "$tmpTARGETMODE" == '3' && "${tmpTARGET:0:11}" == '10000:/dev/' && "$tmpINSTWITHMANUAL" != '1' ]] && PIPECMDSTR='nc -l -p 10000|gunzip -dc|stdbuf -oL dd of='${tmpTARGET##10000:}' bs=10M 2> /var/log/progress & pid=`expr $! + 0`;echo $pid' && cat >>$topdir/$remasteringdir/initramfs/preseed.cfg<<EOF
d-i partman/early_command string chmod 755 /usr/lib/ddinstall-patchs/longrunpipebgcmd_redirectermoniter.sh;/usr/lib/ddinstall-patchs/longrunpipebgcmd_redirectermoniter.sh '$PIPECMDSTR'
EOF

  [[ "$tmpTARGETMODE" == '0' && "$tmpINSTWITHMANUAL" == '1' ]] && tee -a $topdir/$remasteringdir/initramfs/preseed.cfg > /dev/null <<EOF
#debian d-i has a bug cuasing bgcmd not running,so we use screen
# must not place anna-install network-console here in preseed/early_command but instead in partman/early_command
d-i preseed/early_command string screen -dmS reboot /sbin/reboot -d 300
d-i partman/early_command string count=\`ping -c 5 8.8.8.8 | grep from* | wc -l\`;pid=\`screen -ls|grep -Eo [0-9]*.reboot|grep -Eo [0-9]*\`;[ \$count -ne 0 ] && kill -9 \$pid;anna-install network-console;sed -e s/network-console/sh/g -e s/installer/sshd/g -e s/x//g -i /etc/passwd;ssh-keygen -b 2048 -t rsa -N '' -f /etc/ssh/ssh_host_rsa_key -q;sed -i "s/PermitEmptyPasswords no/PermitEmptyPasswords yes/g" /etc/ssh/sshd_config;/usr/sbin/sshd;start-shell di-utils-shell/do-shell /bin/sh
EOF

  [[ "$(find /sys/class/net/ -type l ! -lname '*/devices/virtual/net/*' |  wc -l)" -lt 2 ]] && echo -en "[ \033[32m single eth: use $DEFAULTNET \033[0m ]" || echo -en "[ \033[32m multiple eth: use $DEFAULTNET \033[0m ]"
  [[ "$(lsblk -e 7 -e 11 -d | tail -n+2 | wc -l)" -lt 2 ]] && echo -en "[ \033[32m single hd: use `lsblk -e 7 -e 11 -d | tail -n+2 | cut -d" " -f1 |head -n 1` \033[0m ]" || echo -en "[ \033[32m multiple hd:  use `lsblk -e 7 -e 11 -d | tail -n+2 | cut -d" " -f1 |head -n 1` \033[0m ]"

  #if multiple hd force 1sthdname where /boot is
  #if multiple eth force 1stethname where ip is

}


patchpreseed(){

  # dhcp only
  [[ "$AutoNet" == '2' ]] && {
    sed -e '/netcfg\/disable_autoconfig/d' -e '/netcfg\/dhcp_options/d' -e '/netcfg\/get_.*/d' -e '/netcfg\/confirm_static/d' -i $topdir/$remasteringdir/initramfs/preseed.cfg
    sed -e '/netcfg\/disable_autoconfig/d' -e '/netcfg\/dhcp_options/d' -e '/netcfg\/get_.*/d' -e '/netcfg\/confirm_static/d' -i $topdir/$remasteringdir/initramfs_arm64/preseed.cfg
  }

  #[[ "$GRUBPATCH" == '1' ]] && {
  #  sed -i 's/^d-i\ grub-installer\/bootdev\ string\ default//g' $topdir/$remasteringdir/initramfs/preseed.cfg
  #}
  #[[ "$GRUBPATCH" == '0' ]] && {
  #  sed -i 's/debconf-set\ grub-installer\/bootdev.*\"\;//g' $topdir/$remasteringdir/initramfs/preseed.cfg
  #}
  # vncserver need this?
  #[[ "$GRUBPATCH" == '0' ]] && {
  #  sed -i 's/debconf-set\ grub-installer\/bootdev.*\"\;//g' /tmp/boot/preseed.cfg
  #}

  sed -e '/user-setup\/allow-password-weak/d' -e '/user-setup\/encrypt-home/d' -i $topdir/$remasteringdir/initramfs/preseed.cfg
  sed -e '/user-setup\/allow-password-weak/d' -e '/user-setup\/encrypt-home/d' -i $topdir/$remasteringdir/initramfs_arm64/preseed.cfg
  #sed -i '/pkgsel\/update-policy/d' $topdir/$remasteringdir/initramfs/preseed.cfg
  #sed -i 's/umount\ \/media.*true\;\ //g' $topdir/$remasteringdir/initramfs/preseed.cfg

}






# . p/999.utils/ci2.sh

# =================================================================
# Below are main routes
# =================================================================

export PATH=.:./tools:../tools:$PATH
CWD="$(pwd)"
topdir=$CWD
cd $topdir
Outbanner main
[[ $tmpTARGETMODE != 1 && $forcemaintainmode != 1 ]] && echo "Changing current directory to $CWD"

# dir settings
downdir='_tmpdown'
remasteringdir='_tmpremastering'
targetdir='_build'

# below,we put enviroment-forced args(full args logics) prior over manual ones(simplefrontend)

[[ $# -eq 0 ]] && clear && {
Outbanner main
[[ $tmpTARGETMODE != 1 && $forcemaintainmode != 1 ]] && echo -n "Please specify an install target (1-3,98,99 !!!CAUTION,THIS MAY WIPE ALL DATA):"
# bash read don't show prompt while using with exec sudo bash -c "`cat -`" -a "$@",,so we should
[[ $tmpTARGETMODE != 1 && $forcemaintainmode != 1 ]] && read N </dev/tty
[[ $tmpTARGETMODE != 1 && $forcemaintainmode != 1 ]] && echo "Changing current directory to $CWD"
case $N in
  1) echo "Will force nativedi instmode and debian10 target based on your input"; tmpTARGETMODE='0' && tmpTARGET='debian' ;;
  2) echo "Will force live instmode and debianmu target based on your input"; tmpTARGETMODE='0' && tmpTARGET='devdeskos' ;;
  3) echo "Will force dd instmode and debian10r target based on your input"; tmpTARGETMODE='0' && tmpTARGET='debian10r' ;;

  98) clear;Outbanner sub;while [[ -z "$tmpTARGET" ]]; do
  read -p "custom your choice(press control c to interupt,feed the necessary options 1 as last step to end custom): " NN </dev/tty
  case $NN in
    1) read -p "Enter your own tarball directlink (or simply type `echo -e "\033[33mdebian,debianmu,debianmufull,debian10r\033[0m"` to try inbuilt imgs hosted in my hub): " tmpTARGET </dev/tty ;;
    2) read -p "Enter your own FORCEDEBMIRROR directlink (or simply type: `echo -e "\033[33mgithub,gitee\033[0m"` to try inbuilt mirrors hosted in my hub): " FORCEDEBMIRROR </dev/tty;[[ "$FORCEDEBMIRROR" == 'github' ]] && FORCEDEBMIRROR=$autoDEBMIRROR0;[[ "$FORCEDEBMIRROR" == 'gitee' ]] && FORCEDEBMIRROR=$autoDEBMIRROR1 ;;
    3) read -p "Enter your own FORCE1STNICNAME (format: `echo -e "\033[33mensp0\033[0m"`): " FORCE1STNICNAME </dev/tty ;;
    4) read -p "Enter your own FORCENETCFGSTR (format: `echo -e "\033[33m10.211.55.2,255.255.255.240,10.211.55.1\033[0m"`): " FORCENETCFGSTR </dev/tty ;;
    5) read -p "Enter your own FORCE1STHDNAME (format: `echo -e "\033[33mnvme0p1\033[0m"`): " FORCE1STHDNAME </dev/tty ;;
  esac;done;;

  99) echo "Manaual modes opened based on your input,will force instmode and target as dummy, and force hold before reboot to network-console"; tmpTARGETMODE='0' && tmpTARGET='dummy' && tmpINSTWITHMANUAL='1' ;;
  *) [[ $tmpTARGETMODE != 1 && $forcemaintainmode != 1 ]] && echo "Wrong input!" ;;
esac; }

[[ "$(arch)" == "aarch64" ]] && echo Arm64 detected,will force arch as 1 && tmpHOSTARCH='1'
[[ -d /sys/firmware/efi ]] && echo uefi detected,will force gen as 2 && tmpBUILDGENE='2'

while [[ $# -ge 1 ]]; do
  case $1 in
    -n|--forcenetcfgstr)
      shift
      FORCENETCFGSTR="$1"
      [[ -n "$FORCENETCFGSTR" ]] && [[ $tmpTARGETMODE != 1 && $forcemaintainmode != 1 ]] && echo "Netcfgstr forced to some value,will force setnet mode"
      shift
      ;;
    -i|--force1stnicname)
      shift
      FORCE1STNICNAME="$1"
      [[ -n "$FORCE1STNICNAME" ]] && [[ $tmpTARGETMODE != 1 && $forcemaintainmode != 1 ]] && echo "1stnicname forced to some value,will force 1stnic name"
      shift
      ;;
    -m|--forcemirror)
      shift
      FORCEDEBMIRROR="$1"
      [[ "$FORCEDEBMIRROR" == 'github' ]] && FORCEDEBMIRROR=$autoDEBMIRROR0;[[ "$FORCEDEBMIRROR" == 'gitee' ]] && FORCEDEBMIRROR=$autoDEBMIRROR1
      [[ -n "$FORCEDEBMIRROR" ]] && [[ $tmpTARGETMODE != 1 && $forcemaintainmode != 1 ]] && echo "Mirror forced to some value,will override autoselectdebmirror results"
      shift
      ;;
    -p|--force1sthdname)
      shift
      FORCE1STHDNAME="$1"
      [[ -n "$FORCE1STHDNAME" ]] && [[ $tmpTARGETMODE != 1 && $forcemaintainmode != 1 ]] && echo "1sthdname forced to some value,will force 1sthd name"
      shift
      ;;
    -o|--forcepostddctl)
      shift
      FORCEPOSTDDCTL="$1"
      [[ -n "$FORCEPOSTDDCTL" ]] && [[ $tmpTARGETMODE != 1 && $forcemaintainmode != 1 ]] && echo "postddctl forced to some value,will force postddctl (and post process)"
      shift
      ;;
    -b|--build)
      shift
      tmpBUILD="$1"
      #[[ "$tmpBUILD" == '2' ]] && echo "LXC given,will auto inform tmpBUILDCI as 1,this is not by customs" && tmpBUILDCI='1' && tmpTARGETMODE='1' && echo -en "\n" && [[ -z "$tmpBUILDCI" ]] && echo "buildci were empty" && exit 1
      #[[ "$tmpBUILD" != '2' ]] && tmpBUILDCI='0' && tmpTARGETMODE='1'
      shift
      ;;
    -h|--host)
      shift
      tmpHOST="$1"
      case $tmpHOST in
        ''|spt|orc) tmpHOSTMODEL='0' ;;
        az) tmpHOSTMODEL='1' ;;
        sr) tmpHOSTMODEL='2' ;;
        ks|mbp) tmpHOSTMODEL='3' ;; # && [[ -z "$tmpHOSTMODEL" ]] && echo "Hostmodel should be 3 but not set" && exit 1 ;;
        0*)

          for ht in `[[ "$tmpBUILD" -ne '0' ]] && echo "${1##0}" |sed 's/,/\n/g' || echo "${1##0}" |sed 's/,/\'$'\n''/g'`
          do
            HOSTMODLIST+=",""${ht}"
          done
          [[ "$tmpHOST" == '0' ]] && tmpHOSTMODEL='0'
          [[ "$tmpHOST" =~ '0,' ]] && tmpHOSTMODEL='99' && echo "With host modules to be inc in:""$HOSTMODLIST"",will force hostmodel as 99" ;;

        *) echo "Unknown host" && exit 1 ;;
      esac
      shift
      ;;

      # the targetmodel are auto deduced finally here (with hostmodel and tmptarget determined it)
      # for hostmodel,if -h are < 99,it must be in instmode and given as invidude,in buildmode = 99,it is always mixed with 0,and goes after it
    -t|--target)
      shift
      tmpTARGET="$1"
      case $tmpTARGET in
        '') tmpTARGETMODE='0' && tmpTARGET='devdeskos' && [[ $tmpTARGETMODE != 1 && $forcemaintainmode != 1 ]] && echo "Target not defined,will force wgetdd instmode and devdeskos target" ;;
        debianbase|onekeydevdesk) tmpTARGETMODE='1' ;;
        deb) tmpTARGET='debian' && tmpTARGETMODE='0' && [[ $tmpTARGETMODE != 1 && $forcemaintainmode != 1 ]] && echo "deb given,will force nativedi instmode and debian target(currently 10)" ;;
        debian) tmpTARGETMODE='0' && [[ $tmpTARGETMODE != 1 && $forcemaintainmode != 1 ]] && echo "debian given,will force nativedi instmode and debian target(currently 10)" ;;
        lxc*|qemu*) tmpTARGETMODE='1';GENCONTAINERS="$1";PACKCONTAINERS="$1";echo "Standalone container/qemuserver pack mode without building initfs and 01-core" ;;
        debian10r) tmpTARGETMODE='0' ;;
        devdeskos*|debianmu*) tmpTARGET=${1/debianmu/devdeskos}

          for tgt in `[[ "$tmpBUILD" -ne '0' ]] && echo "${tmpTARGET##devdeskos}" |sed 's/,/\n/g' || echo "${tmpTARGET##devdeskos}" |sed 's/,/\'$'\n''/g'`
          do
          [[ $tgt =~ "++" ]] && { GENCONTAINERS+=",""${tgt##++}";PACKCONTAINERS+=",""${tgt##++}"; } || GENCONTAINERS+=",""${tgt##+}"
          done
          [[ "$tmpHOSTMODEL" -lt '99' && "$tmpTARGET" == 'devdeskos' ]] && tmpTARGETMODE='0' && [[ $tmpTARGETMODE != 1 && $forcemaintainmode != 1 ]] && echo "Devdeskos Wgetdd instonly mode detected"
          [[ "$tmpHOSTMODEL" -lt '99' && "${tmpTARGET:0:9}" == "devdeskos" && "${#tmpTARGET}" -gt '9' ]] && tmpTARGETMODE='0' && [[ $tmpTARGETMODE != 1 && $forcemaintainmode != 1 ]] && echo "Devdeskos specialedition Wgetdd instonly mode detected"
          [[ "$tmpHOSTMODEL" == '99' && "$tmpTARGET" == 'devdeskos' ]] && tmpTARGETMODE='1' && echo "Fullgen mode detected"
          [[ "$tmpHOSTMODEL" == '99' && "$tmpTARGET" =~ 'devdeskos,' ]] && tmpTARGET='devdeskos' && tmpTARGETMODE='1' && echo "Fullgen mode detected,with container/qemuserver merge/pack addons:""$GENCONTAINERS" |sed 's/,/ /g' ;;
          #[[ "$tmpHOST" != '2' && "$tmpTARGET" == 'devdeskos' ]] && tmpTARGETMODE=1 || tmpTARGETMODE='0' ;;

          # if -t were given as port:blkdevname,then enter nc servermode(rever,target)
          # if -t were given as port:ip:blkdevname,then enter nc clientmode(sender,src)
        *) echo "$tmpTARGET" |grep -q '^http://\|^ftp://\|^https://\|^10000:/dev/\|^/dev/';[[ $? -ne '0' ]] && echo -e "\033[31mTargetname not known or in blank!\033[0m" && exit 1 || { 
          echo "$tmpTARGET" |grep -q '^http://\|^ftp://\|^https://';[[ $? -eq '0' ]] && [[ $tmpTARGETMODE != 1 && $forcemaintainmode != 1 ]] && echo "Raw urls detected,will override autotargetddurl results and force wgetdd instmode" && tmpTARGETMODE=0;echo "$tmpTARGET" |grep -q '^/dev/';[[ $? -eq '0' ]] && echo "Port:ip:blkdevname detected,will force nccli,sender+dd instmode" && tmpTARGETMODE=2;echo "$tmpTARGET" |grep -q '^10000:/dev/';[[ $? -eq '0' ]] && echo "Port:blkdevname detected,will force ncsrv,rever+dd instmode" && tmpTARGETMODE=3; } ;;
      esac
      shift
      ;;
    -s|--serial)
      shift
      tmpINSTSERIAL="$1"
      [[ "$tmpINSTSERIAL" == '1' ]] && [[ $tmpTARGETMODE != 1 && $forcemaintainmode != 1 ]] && echo "Serial forced,will process serial console after booting"
      shift
      ;;
    -g|--gene)
      shift
      tmpBUILDGENE="$1"
      [[ "$tmpBUILDGENE" == '0' && "$tmpBUILDGENE" != '' ]] && [[ $tmpTARGETMODE == 0 || $tmpTARGETMODE == 1 && $forcemaintainmode != 1 ]] && echo "biosmbr only given,will process biosmbr bootinglogic and disk supports for buildmode or force it in installmode"
      [[ "$tmpBUILDGENE" == '1' && "$tmpBUILDGENE" != '' ]] && [[ $tmpTARGETMODE == 0 || $tmpTARGETMODE == 1 && $forcemaintainmode != 1 ]] && echo "biosgpt only given,will process biosgpt bootinglogic and disk supports for buildmode or force it in installmode"
      [[ "$tmpBUILDGENE" == '2' && "$tmpBUILDGENE" != '' ]] && [[ $tmpTARGETMODE == 0 || $tmpTARGETMODE == 1 && $forcemaintainmode != 1 ]] && echo "uefigpt only given,will process uefigpt bootinglogic and disk supports for buildmode or force it in installmode"
      [[ "$tmpBUILDGENE" == '0,1,2' && "$tmpBUILDGENE" != '' ]] && tmpTARGETMODE='1' && echo "all gens given,will process all bootinglogic and disk supports for buildmode"
      shift
      ;;
    -a|--arch)
      shift
      tmpHOSTARCH="$1"
      [[ "$tmpHOSTARCH" == '0' && "$tmpHOSTARCH" != '' ]] && [[ $tmpTARGETMODE == 0 || $tmpTARGETMODE == 1 && $forcemaintainmode != 1 ]] && echo "Amd64 only given,will process amd64 addon supports for buildmode or force arm in installmode"
      [[ "$tmpHOSTARCH" == '1' && "$tmpHOSTARCH" != '' ]] && [[ $tmpTARGETMODE == 0 || $tmpTARGETMODE == 1 && $forcemaintainmode != 1 ]] && echo "Arm64 only given,will process arm64 addon supports for buildmode or force arm in installmode"
      [[ "$tmpHOSTARCH" == '0,1' && "$tmpHOSTARCH" != '' ]] && tmpTARGETMODE='1' && echo "all archs given,will process all addon supports for buildmode"
      shift
      ;;
    -d|--debug)
      shift
      tmpDEBUG="$1"
      [[ ("$tmpDEBUG" == '1' || "$tmpDEBUG" == '') && "$tmpTARGETMODE" != '1' ]] && tmpTARGET='dummy' && tmpINSTWITHMANUAL='1' && [[ $tmpTARGETMODE != 1 && $forcemaintainmode != 1 ]] && echo "Manual modes enabled in instmode,will force target as dummy, and force hold before reboot to network-console"
      [[ ("$tmpDEBUG" == '1' || "$tmpDEBUG" == '') && "$tmpTARGETMODE" == '1' ]] && tmpBUILDINSTTEST='1' && tmpINSTWITHMANUAL='1' && echo "Debug supports enabled in buildmode,will keep target as its, and force hold before reboot and localinstant boot test"
      [[ ("$tmpBUILDCI" == '1' || "$tmpBUILDCI" == '') && "$tmpDEBUG" == '1' ]] && echo "debug and ci cant coexsits" && exit 1
      shift
      ;;
    -c|--ci)
      shift
      tmpBUILDCI="$1"
      [[ ("$tmpBUILDCI" == '1' || "$tmpBUILDCI" == '') && "$tmpTARGETMODE" == '1' ]] && echo "ci forced in buildmode,will force ci actions"
      [[ ("$tmpBUILDCI" == '1' || "$tmpBUILDCI" == '') && "$tmpDEBUG" == '1' ]] && echo "debug and ci cant coexsits" && exit 1
      shift
      ;;
    --help|*)
      if [[ "$1" != 'error' ]]; then echo -ne "\nInvaild option: '$1'\n\n"; fi
      echo -ne "Usage(args are self explained):\n\t-m/--forcemirror\n\t-n/--forcenetcfgstr\n\t-b/--build\n\t-h/--host\n\t-t/--target\n\t-s/--serial\n\t-g/--gene\n\t-a/--arch\n\t-d/--debug\n\n"
      exit 1;
      ;;
    esac
  done

[[ $tmpTARGETMODE != 1 && $forcemaintainmode == 1 ]] && { echo -e "\033[31m\n维护,脚本无限期闭源或开放，请联系作者\nThe script was invalid in maintaince mode with a undetermined closed/reopen date,please contact the author\n \033[0m"; exit 1; }

#echo -en "\n\033[36m # Checking Prerequisites: \033[0m"

printf "\n ✔ %-40s" "Checking deps: ......"
if [[ "$tmpTARGET" == 'debianbase' && "$tmpTARGETMODE" == '1' ]]; then
  CheckDependence sudo,wget,ar,awk,grep,sed,cut,cat,cpio,curl,gzip,find,dirname,basename,xzcat,zcat,md5sum,sha1sum,sha256sum,grub-reboot;
else
  CheckDependence sudo,wget,ar,awk,grep,sed,cut,cat,cpio,curl,gzip,find,dirname,basename,xzcat,zcat,df;
fi

printf "\n ✔ %-40s" "Selecting Mirrors and Targets: ......" 

AUTODEBMIRROR=`echo -e $(SelectDEBMirror $autoDEBMIRROR0 $autoDEBMIRROR1)|sort -n -k 2 | head -n2 | grep http | sed  -e 's#[[:space:]].*##'`
[[ -n "$AUTODEBMIRROR" && -z "$FORCEDEBMIRROR" ]] && DEBMIRROR=$AUTODEBMIRROR && echo -en "[ \033[32m auto,${DEBMIRROR} \033[0m ]"  # || exit 1
[[ -n "$AUTODEBMIRROR" && -n "$FORCEDEBMIRROR" ]] && DEBMIRROR=$FORCEDEBMIRROR && echo -en "[ \033[32m force,${DEBMIRROR} \033[0m ]"  # || exit 1
[[ -z "$AUTODEBMIRROR" && -z "$FORCEDEBMIRROR" ]] && DEBMIRROR=$autoDEBMIRROR0 && echo -en "[ \033[32m failover,${DEBMIRROR} \033[0m ]"  # || exit 1
# simply select auto target img mirror based on github or nongithub url postfix
[[ "$DEBMIRROR" =~ "/1keyddhubfree-debianbase/raw/master" ]] && IMGMIRROR=${DEBMIRROR/\/1keyddhubfree-debianbase\/raw\/master/}"/xxxxxx/raw/master" || IMGMIRROR=${DEBMIRROR}"/../xxxxxx"

UNZIP=''
IMGSIZE=''
# some inbuilt img support
case $tmpTARGET in
  dummy|debianbase|onekeydevdesk|deb|debian) TARGETDDURL=''
    TARGETDDIMGSIZE='' ;;
  devdeskos*|devdeskosfull|debianmu*|debianmufull) tmpTARGET=${tmpTARGET/debianmu/devdeskos}; [[ "${#tmpTARGET}" -gt '9' && "${tmpTARGET}" != "devdeskosfull" ]] && TARGETDDURL=${IMGMIRROR/xxxxxx/$tmpTARGET}"/"$tmpTARGET"/binary$([ "$tmpHOSTARCH" == '1' -a "$tmpHOSTARCH" != '' ]  && echo -arm64 || echo -amd64)/tallbar" || TARGETDDURL=${IMGMIRROR/xxxxxx/1keydd}"/_build/devdeskos/binary$([ "$tmpHOSTARCH" == '1' -a "$tmpHOSTARCH" != '' ]  && echo -n -arm64 || echo -n -amd64)/tallbar"
    TARGETDDIMGSIZE='' ;;
  #devdeskos) TARGETDDURL=$MIRROR/_build/devdeskos/onekeydevdeskd$([ "$tmpHOSTARCH" == '1' -a "$tmpHOSTARCH" != '' ]  && echo _arm64)
    #[[ "$tmpTARGETMODE" == '0' ]] && CheckTarget $TARGETDDURL
    #[[ -n "$IMGSIZE" && -z "$FORCEMIRRORIMGSIZE" ]] && TARGETDDIMGSIZE=$IMGSIZE
    #[[ -n "$IMGSIZE" && -n "$FORCEMIRRORIMGSIZE" ]] && TARGETDDIMGSIZE=$FORCEMIRRORIMGSIZE ;;
  debian10r) TARGETDDURL=${IMGMIRROR/xxxxxx/1keyddhubfree-$tmpTARGET}"/"$tmpTARGET"estore/binary$([ "$tmpHOSTARCH" == '1' -a "$tmpHOSTARCH" != '' ]  && echo -arm64 || echo -amd64)/"$tmpTARGET"estore$([ "$tmpHOSTARCH" == '1' -a "$tmpHOSTARCH" != '' ]  && echo _arm64).xz"
    [[ "$tmpTARGETMODE" == '0' ]] && CheckTarget $TARGETDDURL"_000"
    [[ -n "$IMGSIZE" && -z "$FORCEMIRRORIMGSIZE" ]] && TARGETDDIMGSIZE=$IMGSIZE
    [[ -n "$IMGSIZE" && -n "$FORCEMIRRORIMGSIZE" ]] && TARGETDDIMGSIZE=$FORCEMIRRORIMGSIZE ;;
  *) TARGETDDURL=$tmpTARGET
    # wedont check "$tmpTARGETMODE" == '1'
    [[ "$tmpTARGETMODE" != '1' ]] && CheckTarget $TARGETDDURL
    [[ -n "$IMGSIZE" && -z "$FORCEMIRRORIMGSIZE" ]] && TARGETDDIMGSIZE=$IMGSIZE
    [[ -n "$IMGSIZE" && -n "$FORCEMIRRORIMGSIZE" ]] && TARGETDDIMGSIZE=$FORCEMIRRORIMGSIZE ;;
esac

sleep 2s

#echo -en "\n\033[36m # Parepare Res: \033[0m"

# under GENMODE we reuse the downdir,but not for INSTMODE
[[ "$tmpTARGETMODE" != '1' ]] && [[ -d $downdir ]] && rm -rf $downdir;
mkdir -p $downdir $downdir/onekeydevdesk

sleep 2s && printf "\n ✔ %-40s" "Retrieving kernel and initrfs: ......"
[[ "$tmpTARGETMODE" != '1' ]] && getbasics down || getbasics copy
#printf "\n ✔ %-40s" "Get optional/necessary deb pkg files to build a debianbase: ...... "
#[[ "$tmpBUILD" != '1' && "$tmpTARGET" == 'debianbase' ]] && getoptpkgs libc,common,wgetssl,extendhd,ddprogress || echo -en "[ \033[32m not debianbase,skipping!! \033[0m ]"
#printf "\n ✔ %-40s" "Get full debs pkg files to build a debianbase: ..... "
#[[ "$tmpBUILD" != '1' && "$tmpTARGET" == 'debianbase' ]] && getfullpkgs || echo -en "[ \033[32m not debianbase,skipping!! \033[0m ]"


#echo -en "\n\033[36m # Remastering all up... \033[0m"

# lsattr and cont delete,then you shoud restart
umount --force $remasteringdir/initramfs/{dev/pts,dev,proc,sys} $remasteringdir/initramfs_arm64/{dev/pts,dev,proc,sys} >/dev/null 2>&1
umount --force $remasteringdir/onekeydevdeskd/01-core/{dev/pts,dev,proc,sys} $remasteringdir/onekeydevdeskd_arm64/01-core/{dev/pts,dev,proc,sys} >/dev/null 2>&1
# we should also umount the top mounted dir here after umount chrootsubdir?
# xxx
[[ -d $remasteringdir ]] && rm -rf $remasteringdir;

sleep 2s && printf "\n ✔ %-40s" "Save and set the netcfg: ......"

interface=''

[[ "$tmpBUILD" != '1' && "$tmpTARGET" != 'debianbase' ]] && parsenetcfg


sleep 2s && printf "\n ✔ %-40s" "Remastering grub: ......"

# we have forcenicname and ln -s tricks instead
# setInterfaceName='0'
# setIPv6='0'

[[ "$tmpBUILD" != '1' && "$tmpTARGETMODE" != '1' && "$tmpTARGET" != 'debianbase' || "$tmpBUILDINSTTEST" == '1' ]] && parsegrub
#[[ "$tmpTARGETMODE" == '1' ]] && [[ "$tmpTARGET" == "devdeskos" ]] && parsegrub


[[ "$tmpDRYRUNREMASTER" == '0' ]] && {

  patchgrub
  processbasics

  sleep 2s && printf "\n ✔ %-40s" "Provisioning /preseed: ......."
  preparepreseed
  patchpreseed

  sleep 2s && printf "\n ✔ %-40s" "Remastering kernel and initrfs: ......"

  [[ "$tmpTARGETMODE" != '1' || "$tmpTARGETMODE" == '1' ]] && {

    if [[ "$tmpTARGETMODE" != '1' ]]; then
      #sleep 2s && printf "\n ✔ %-40s" "Instmode,perform below instmodeonly remastering tasks: ......"
      # nothing to do but showing a hint
      echo -en "[ \033[32m done. \033[0m ]"
    fi

  }
}

#echo -en "\n\033[36m # Finishing... \033[0m"

# rewind the $(pwd)
cd $topdir
mkdir -p $targetdir

printf "\n ✔ %-40s" "Copying vmlinuz to the target: ......"
[[ -d $instto ]] && [[ "$tmpBUILD" != "1" ]] && [[ "$tmpTARGETMODE" != "1" ]] && cp -f $topdir/$downdir/onekeydevdesk/vmlinuz$([ "$tmpHOSTARCH" == '1' -a "$tmpHOSTARCH" != '' ]  && echo -n _arm64) $instto/vmlinuz_1keyddinst && echo -en "[ \033[32m done. \033[0m ]"
[[ "$tmpTARGETMODE" != '1' ]] && sleep 2s && printf "\n ✔ %-40s" "Packaging initrfs to the target: ....." && [[ "$tmpBUILD" != '1' ]] && ( cd $topdir/$remasteringdir/initramfs; find . | cpio -H newc --create --quiet | gzip -9 > $instto/initrfs_1keyddinst.img ) && echo -en "[ \033[32m done. \033[0m ]" # || ( cd $topdir/$remasteringdir/initramfs; find . | cpio -H rpax --create --quiet | gzip -9 > /Volumes/TMPVOL/initrfs_1keyddinst.img )

# if insttest then directly reboot here



#rm -rf $remasteringdir/initramfs;
curl --max-time 5 --silent --output /dev/null https://shellevaluatedcounter.minlearn.org/{dsrkafuu:demo}&add={1}

[[ "$tmpTARGETMODE" != '1' || "$tmpBUILDINSTTEST" == '1' ]] && [[ "$tmpBUILD" != '1' ]] && {

  chown root:root $GRUBDIR/$GRUBFILE
  chmod 444 $GRUBDIR/$GRUBFILE
  printf "\n ✔ %-40s" "Prepare grub-reboot for 1 ......" &&  grub-reboot 1 >/dev/null 2>&1
  # Automatically remove DISK on sigint，note,we should put it in the right place to let it would occur
  trap 'echo; echo -en "[ \033[32m aborting by user, restoring grub \033[0m ]"; restoregrub;exit 1' SIGINT

  printf "\n ✔ %-40s" "All done! `[[ \"\$tmpINSTWITHMANUAL\" == '1' ]] && echo -n \" ctlc to interrupt,or press anykey to reboot \" || echo -n \" ctlc to interrupt,or wait till auto reboot after 20s \"`......"
  echo;echo -en "[ \033[32m after reboot, try below for progressview logviews and dignosisviews: \033[0m ]" && \
  printf "\n 1. %-20s" "`echo -en \" \033[32m open and refresh http://publicIPofthisserver:80(require port 5900 opened) \033[0m \"`" && \
  printf "\n 2. %-20s" "`echo -en \" \033[32m open and refresh http://publicIPofthisserver:8000 \033[0m \"`" && [[ "$tmpINSTWITHMANUAL" == '1' ]] && \
  printf "\n 3. %-20s" "`echo -en \" \033[32m connected to sshd@publicIPofthisserver:22 without passwords \033[0m \"`"

  [[ "$tmpINSTWITHMANUAL" == '1' ]] && { read -n1 </dev/tty;reboot >/dev/null 2>&1; } || { echo;for time in `seq -w 20 -1 0`;do echo -n -e "\b\b$time";sleep 1;done;reboot >/dev/null 2>&1; }
}


  rm -rf readme.md && cp $topdir/readme2.md readme.md
  rm -rf .gitignore && cp $topdir/.gitignore .
  mv aplinfo-pve-6.dat _build
  rm -rf justaplacement

  exit
}
#----------------------------genmode only end-------------------------------


