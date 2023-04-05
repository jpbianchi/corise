Normally, this folder should be a forked repo, so to make it work with gitpod, and have it build a proper container right from the start, I had to copy gitpod.yml, gitpod.Dockerfile and requirements.txt in the root.
Then I deleted them to avoid confusion with other projects.  

BUT it didn't work, there's an issue because of scipy==1.8.0, so I modified it to 1.10.1

# gitpod install python 3.11, but redis wants 3.8.13 as it is in gitpod.yml, so we do this:

pyenv install 3.8.13   # pyenv is a python version manager, it's installed by default in gitpod  
  # redis install is for 3.8.13 so let's use this one
pyenv global 3.8.13   # set the global python version to 3.8.13
python --version   # should give 3.8.13


also, go to course/week2/pipeline_project, and do
source init_env.sh  to setup the PYTHONPATH 