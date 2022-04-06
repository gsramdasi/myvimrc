# set -x
# 
# dirpath=$1
# flist=/tmp/cscope_files.txt
# 
# cd $dirpath
# # find $dirpath -path ./subprojects -prune -a -name "*.c" -o -name "*.h" > $flist
# find $dirpath -name "*.c" -o -name "*.h" | grep -v subprojects > $flist
# cscope -b -i $flist

# ctags $(echo $flist)
# cscope -b -i $flist


dir=$1
rm -f $dir/tags $dir/cscope.out
filelist=$(find $dir -name "*.c" -o -name "*.h")

ctags --fields="nK" $filelist
cscope -Rb

echo "hello"
