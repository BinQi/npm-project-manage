#!/bin/bash
# ------------------------------------------------------------------
# [Author] wbq
#          auto create patch and apply patch under ./patches
# ------------------------------------------------------------------

#SUBJECT=some-unique-id
VERSION=0.0.0
USAGE="kick <command>\n\n
       Usage:\n\n
       kick create_patch project_name[optional]                    自动在./kick/patches目录下生成本地修改的patch文件\n
       kick apply_patch project_name[optional]                     自动应用最新的patch修改到项目中\n
       kick get_latest_patch_file project_name[optional]           run this project's tests\n
       kick -v                                                     display current version of kick\n
       kick -h                                                     print help message\n
"

# --- Option processing --------------------------------------------
while getopts ":vh" optname
  do
    case "$optname" in
      "v")
        echo "Version $VERSION"
        exit 0;
        ;;
      "h")
        echo -e $USAGE
        exit 0;
        ;;
      "?")
        echo "Unknown option $OPTARG"
        exit 0;
        ;;
      ":")
        echo "No argument value for option $OPTARG"
        exit 0;
        ;;
      *)
        echo "Unknown error while processing options"
        exit 0;
        ;;
    esac
  done

shift $(($OPTIND - 1))

cmd=$1
param=$2
command="$1"

patch_prefix="kick+"
if [ param != "" ]; then
  patch_prefix="${param}+"
fi
patch_suffix=".patch"
patches_dir="./kick/patches/*"
v_main=0
v_major=0
v_junior=0

error_prefix="\033[31m"
error_suffix="\033[0m"
npm_error_code=1
# -----------------------------------------------------------------
#LOCK_FILE=/tmp/${SUBJECT}.lock
#
#if [ -f "$LOCK_FILE" ]; then
#echo "Script is already running"
#exit
#fi

#trap "rm -f $LOCK_FILE" EXIT
#touch $LOCK_FILE

# -----------------------------------------------------------------
function get_latest_patch_file() {
  for file in $patches_dir
  do
    if test -f $file
    then
      file_name=$(basename $file)
      file_base_name=$(basename $file $patch_suffix)
      version_name="${file_base_name##*$patch_prefix}"
#      echo "$version_name"
      t_v=$version_name
      t_v_junior="${t_v##*.}"
      t_v_main="${t_v%%.*}"
      t_v="${t_v#*.}"
      t_v_major="${t_v%%.*}"
#      echo "TT:$t_v_main $t_v_major $t_v_junior  main:$v_main.$v_major.$v_junior"

      if [ "$t_v_main" -ge "$v_main" ]; then
          if [ "$t_v_main" == "$v_main" ]; then
              if [ "$t_v_major" -ge "$v_major" ]; then
                if [ "$t_v_major" == "$v_major" ]; then
                    if [ "$t_v_junior" -ge "$v_junior" ]; then
                       v_junior="$t_v_junior"
                    fi
                else
                  v_junior="$t_v_junior"
                fi
                v_major="$t_v_major"
              fi
          else
            v_major="$t_v_major"
            v_junior="$t_v_junior"
          fi
          v_main="$t_v_main"
      fi
    fi
  done
  echo "latest patch version=$v_main.$v_major.$v_junior"
}

function create_patch() {
  get_latest_patch_file
  ((v_junior++))
  patch_file=$patch_prefix$v_main.$v_major.$v_junior$patch_suffix
  echo "creating patch..."
  git diff HEAD -- . :^.idea :^.idea2 > "./kick/patches/$patch_file"
  if [ $? == 0 ]; then
    echo "patch created: $patch_file"
  else
    echo "${error_prefix}fail to created patch!${error_suffix}"
    exit $npm_error_code
  fi
}

function apply_patch() {
  get_latest_patch_file
  patch_file=$patch_prefix$v_main.$v_major.$v_junior$patch_suffix
  echo "applying patch: $patch_file"
  patch_file_path="./kick/patches/$patch_file"
  # 先reverse再apply，防止已经apply后再次apply失败
  git apply -R "$patch_file_path"
  if git apply "$patch_file_path"; then
      echo "patch applied: $patch_file"
    else
      echo "${error_prefix}fail to apply patch: $patch_file!${error_patch_suffix}"
      exit $npm_error_code
    fi
}

# -----------------------------------------------------------------
# -----------------------------------------------------------------
if [ -n "$(type -t ${command})" ] && [ "$(type -t ${command})" = function ]; then
   ${command}
else
   echo "'${cmd}' is NOT a command";
fi