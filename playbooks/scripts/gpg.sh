git config --global user.signingkey 3F7C1B51532062C1
git config --global commit.gpgsign true        
git config --global push.gpgsign if-asked
git config --global gpg.program $(which gpg)
