## Generate a keygen and you need to go to github-> setting-> SSH and GPG keys-> New SSH key to add a new key, copy things in ~/.ssh/id_rsa.pub to it
#ssh-keygen -t rsa -C "tianwei@genomics.cn"
## Test if the ssh key works
#ssh -T git@github.com

## Enters the folder you want to push to Github, generated your local database, input your github id and email to the database
#git init
#git config user.name "taylortianwei"
#git config user.email "tianwei@genomics.cn"

## add the files you want to push to github
git add *
git commit  -m  'generate tracking document'

## if the name is already exists, you need to delete it to initialize
#git remote rm BGI-GTD

## push 
#git remote add BGI-GTD git@github.com:taylortianwei/Generate_HTML_Tracking.git
git push -f -u BGI-GTD master
