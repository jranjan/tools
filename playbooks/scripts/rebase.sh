BRANCH=$1

if [ -z "$BRANCH" ]
then
   BRANCH=master
fi
echo The triggered branch is: $BRANCH

git fetch upstream; 
git checkout master
git rebase upstream/master;
git push origin master
git checkout $BRANCH
git pull origin master
