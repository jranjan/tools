cfiles=$(find . -type f -name "*.c")

if [ -z "$cfiles" ]
then
    echo "No file(s) found!"
    exit
fi

for file in $cfiles
do
    ofile = "${file::-1}o"

    echo '-----------------------------------------------------------------'
    echo "Compiling file $ofile"
    echo '-----------------------------------------------------------------'
    gcc -o $ofile -c $file
done 