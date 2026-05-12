Please do not copy this file (ReadMe.md) in your demo folder:

Follow below steps and same is mentioned on (https://docs.google.com/document/d/1QS3JgfzolQa_lv1lQmN_9VSDuvsFQkDemtO_okwvRk8/edit?resourcekey=0-ttXikbx0nmE5QQA_RKvjHQ#)

Clone the repo
Once you decide on the repository for your demo, the normal git procedures and commands apply. 
Clone your repository using the below command. This command includes a commit hook that will facilitate submitting CLs.


The following is a sequential example of commands for data-cloud repo:

###############################################################################################################################################
Run glogin or gcert in a shell to log in each day(resource).
git clone sso://cloud-demos/data-cloud && (cd data-cloud && f=`git rev-parse --git-dir`
/hooks/commit-msg ;  mkdir -p $(dirname $f) ; curl -Lo $f https://gerrit-review.googlesource.com/tools/hooks/commit-msg ; chmod +x $f)
###############################################################################################################################################


Make your changes.
To add a new demo to a chosen repository you cloned, create in it a folder with a name you used or are going to use in your go/demos submission, the name you use in git repo and in go/demos should match.



IMPORTANT: The easiest way to create a click-to-deploy enabled demo is to start with a sample_demo folder included in each repo. Copy the contents into your newly created folder. 


###############################################################################################################################################
The sample_demo contains two folders:

1.org_policy - 
 a.backend_config_script.sh - do NOT edit
 b.org_policy.tf - make your org policy changes in this file
 c.variables.tf - do NOT edit
 d.versions.tf - do NOT edit

Edit the org_policy.tf file to change/set organizational policies that are needed to make your demo work in Argolis.
Make policy changes at the project level and not at the Org node. See go/argolis-default-org-policy for details.

2.demo -
 
  a.backends_config_script.sh - do NOT edit
  b.terraform - this folder is the terraform root location with entry point terraform scripts
     1.main.tf - make your changes here
     2.outputs.tf  - remove this file if not used
     3.variables.tf - do NOT edit
      … add more terraform files to complete your demo

###############################################################################################################################################
September 2022:
###############################################################################################################################################

 Added all the resources and Modules to terrform files from all the demos were already been
 completed.

###############################################################################################################################################
Instructions to be followed while implementing your own Demo:
###############################################################################################################################################

1. Please follow the Instructions from the CE GIT guide to implement the demo and
   security best practices.
   https://docs.google.com/document/d/1ETsap96nSwoOTX-koF6FZYyB5QuZCvuD/edit?resourcekey=0-DMRzx8qBUgoaDbZe_TcFPA#

2. Please use complex passwords and it is recommended not to  use simple passwords
   with plain text in the demos.

3. It is not at all recommended to expose the passwords in the text file.

4. make sure you declare local or input variables as per the demo requirements
   and also depends_on meta argument in between the resources.
