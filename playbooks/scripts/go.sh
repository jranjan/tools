LIVEWIRE=/Users/jyoti.ranjan/Desktop/Jyoti/Livewire
GIT=$LIVEWIRE/git
MYGIT=$LIVEWIRE/my-github

MOKU=$GIT/moku
ACDS=$MOKU/acds

if [ $1 = "live" ]
then
  cd $LIVEWIRE
  pwd
  ls -la
fi 

if [ $1 = "git" ]
then
  cd $GIT
fi 

if [ $1 = "mygit" ]
then
  cd $MYGIT
  pwd
fi 

if [ $1 = "moku" ]
then
  cd $MOKU
  pwd
fi

if [ $1 = "acds" ]
then
  cd $ACDS
  pwd
fi 

