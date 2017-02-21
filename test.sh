# just a shell test I made for plum

echo "NO ARGUMENT"
plum
echo "WRONG ARGUMENT"
plum asd
echo "HELP"
plum help
echo "INSTALL"
plum install formulator
echo "REMOVE"
plum remove formulator
echo "DOWNLOAD"
plum download formulator .
echo "INSTALL LOCAL"
plum install-local formulator.tar.gz
echo "REMOVE AGAIN"
plum remove formulator
echo "CLEAN UP THE FILE"
rm formulator.tar.gz
echo "RELOAD"
plum reload
echo "LIST"
plum list
