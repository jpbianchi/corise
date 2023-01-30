## Introduction

In the project this week, we will focus on model deployment for the news classification model that we trained in week 1, and evaluated in week 2.

1. We will build a simple web application backend using FastAPI and Uvicorn that wraps our trained model, and exposes an endpoint to make predictions on live traffic that is sent to the endpoint.
2. We will learn how to wrap our application in a Linux container using Docker. This is a standard practice when we want to deploy our application in a cloud environment such as AWS or Google Cloud. 
3. We will test our web application and Docker container by sending it live traffic (on our local machine) and logging the model predictions.
4. We will write some integration tests to test our Docker container is running fine before deployment
5. [advanced & optional] we will prepare to deploy as a serverless function using AWS Lambda, getting it working locally

## [Step 1] Download & Install Prerequisites:

### Download the instructions & starter code:

To get the starter code, you can clone and checkout the Github repo: https://github.com/nihit/corise-mlops. 

Alternatively, you can download the starter code from: https://corise-mlops.s3.us-west-2.amazonaws.com/project3/starter.zip. 

After downloading and unzipping the week 3 starter code, your directory structure should look like this:

```
project
│   README.md
│   Dockerfile
│   requirements.txt
|   test_app.py
|   __init__.py
└───app
│   │   server.py
|   |   classifier.py
│   │   __init__.py
|
└───data
    │   news_classifier.joblib
    |   logs.out
    |   requests.json
```

Go to the `project` directory from the command line. This will be the home directory for your project. All command line commands that follow are from this directory.

### Create a local Python virtual environment, install Python dependencies

Before we can get started with writing any code for the project, we recommend creating a Python virtual environment. If you haven't created virtual environments in Python before, you can refer to [this documentation](https://packaging.python.org/en/latest/guides/installing-using-pip-and-virtual-environments/#creating-a-virtual-environment). 

It needs the following steps (the commands shown below work for MacOS/Unix operating systems. Please refer to the documentation above for Windows):

1. Insall `pip`:
```bash 
$ python3 -m pip install --user --upgrade pip
```

2. Install `virtualenv`:
```bash
$ python3 -m pip install --user virtualenv
```

3. Create virtual environment: 
```bash
$ python3 -m venv mlopsproject
```

4. Activate the virtual environment:
```bash
$ source mlopsproject/bin/activate
```

5. Install the required python dependencies:
```bash
$ python3 -m pip install --user -r requirements.txt
```

### Install Docker

Download and install Docker. You can follow the steps in [this document](https://docs.docker.com/get-docker/). 

If you are new to Docker, we suggest spending some time to get familiar with the Docker command line and dashboard. Docker's [getting started](https://docs.docker.com/get-started/) page is a good resource.

## [Step 2] Create a FastAPI web application to serve model predictions

1. Before getting started on the web application changes, make sure you can run the starter web server code:

```bash
$ cd app
$ uvicorn server:app
```

You should see an output like:
```bash
INFO:     Started server process [5749]
INFO:     Waiting for application startup.
2022-07-21 20:46:59.898 | INFO     | server:startup_event:109 - Setup completed
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
```

When you go to `http://127.0.0.1:8000` from a web browser, you should see this text output:
`{"Hello": "World"}`:

![](https://corise-mlops.s3.us-west-2.amazonaws.com/project3/pic1.png)


2. We are now ready to get started on writing the code! All the required code changes for this project are in `app/server.py` and `app/classifier.py`. Comments in this file will help you understand the changes we need to make to create our web application to make model predictions. Once the code changes are done, you can start the web server again using the command from the above step.

3. Test with an example request:

Option 1: Using the web browser. 

Visit `http://127.0.0.1:8000/docs`. You will see a /predict endpoint: 

![](https://corise-mlops.s3.us-west-2.amazonaws.com/project3/pic2.png)

You can click on "Try it now" which will let you modify the input request. Click on "Execute" to see the model prediction response from the web server:

![](https://corise-mlops.s3.us-west-2.amazonaws.com/project3/pic3.png)

Option 2: Using the command line.

You can construct the POST request and send it to the web server from another tab in the command line as follows:

```bash

$ curl -X 'POST' \
  'http://127.0.0.1:8000/predict' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "source": "<value>",
  "url": "<value>",
  "title": "<value>",
  "description": "<value>"
}'
```

## [Step 3] Containerize the application using Docker

1. Build the Docker Image
  
```bash

$ docker build --platform linux/amd64 -t news-classifier . 
```
darwin/amd64 is also a possible platform but doesn't work here, linux/amd64 works
https://docs.docker.com/build/building/multi-platform/

2. Start the container:

```bash

$ docker run -p 80:80 news-classifier
```

3. Test the Docker container with an example request:

Option 1: Using the web browser: Visit `http://0.0.0.0/docs` and follow the same guidelines as above.

Option 2: Using the command line:

```bash

$ curl -X 'POST' \
  'http://0.0.0.0/predict' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "source": "<value>",
  "url": "<value>",
  "title": "<value>",
  "description": "<value>"
}'

```

## [Step 4] Examining logs

1. Find out the container id of the running container:
```bash
$ docker ps
```

This will return a response like the following:
```bash

CONTAINER ID   IMAGE             COMMAND                  CREATED          STATUS          PORTS                NAMES
b8cca8bdfe95   news-classifier   "uvicorn server:app …"   47 seconds ago   Up 46 seconds   0.0.0.0:80->80/tcp   busy_merkle
```

2. SSH into the container using the container id from above: 

```bash
$ docker exec -it <container id> /bin/sh
```

3. Tail the logs:
```bash

$ tail -f ../data/logs.out
```

4. Now when you send any request to the web server (from the browser, or another tab in the command line), you can see the log output coming through in `logs.out`. As an example, you can test the web server with this requests and make sure you can see the outputs in `logs.out`:

```bash
{
  "source": "BBC Technology",
  "url": "http://news.bbc.co.uk/go/click/rss/0.91/public/-/2/hi/business/4144939.stm",
  "title": "System gremlins resolved at HSBC",
  "description": "Computer glitches which led to chaos for HSBC customers on Monday are fixed, the High Street bank confirms."
}
```

## [Step 5] End-to-end local testing

After verifying that the Docker container is running locally, and we're seeing prediction outputs in `logs.out`, we are ready to run some end-to-end tests! 

For this part, you will use the prepopulated requests in `data/requests.json` to send traffic to the locally running instance of your prediction service. There are 100 requests in this file, and you should see logs for each of them in `logs.out` in the Docker container as you start sending traffic to the service. 

We suggest automating this with a simple bash or Python script (check out the Python `requests` library: `https://pypi.org/project/requests/`). 


## [Step 6][Optional] Testing with Pytest

This part is optional. We've built our web application, and containerized it with Docker. But imagine a team of ML engineers and scientists that needs to maintain, improve and scale this service over time. It would be nice to write some tests to ensure we don't regress! 

  1. `Pytest` is a popular testing framework for Python. If you haven't used it before, take a look at [this page](https://docs.pytest.org/en/7.1.x/getting-started.html) to get started and familiarize yourself with this library.
   
  2. How do we test FastAPI applications with Pytest? Glad you asked, here's two resources to help you get started:
    (i) [Introduction to testing FastAPI](https://fastapi.tiangolo.com/tutorial/testing/)
    (ii) [Testing FastAPI with startup and shutdown events](https://fastapi.tiangolo.com/advanced/testing-events/)
  
  3. Head over to `test_app.py` to get started. As you develop the tests using prompts in this file, you can run `pytest` to run the tests.
   
## [Step 7][Optional] Deploying the Docker Container in AWS

This part is optional. In this last step, we will deploy the Dockerized application to a cloud environment using AWS. 

1. AWS Account setup: 
  
If you already have an account with AWS configured, feel free to use it and skip this step.  If you don’t have an account already, please set up your account at https://aws.amazon.com/. Make sure to choose your region as `us-west-2`.

You can generate access keys for the root user (you) using this guide: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_root-user.html. You’ll see something like this in the IAM console: (**Save this carefully for use in Step 4**).

![](https://corise-mlops.s3.us-west-2.amazonaws.com/project3/aws_setup1.png)


Install the AWS command line utility tool that lets you programmatically access AWS services from your local machine: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html 

Configure the AWS command line tool using this guide before you can start using it: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html. Use the access credentials that you generated in Step 2, and make sure to set the region to `us-west-2`. 


2. Create an ECR Repository: 

ECR is an AWS managed service to store and manage Docker images for easy deployment. Using the AWS web console, you can create a new repository in ECR to manage our news classification application. This is a good reference starter guide to ECR if you haven't used it before: https://docs.aws.amazon.com/AmazonECR/latest/userguide/Repositories.html. The ECR repository will look something like this (it's okay if you don't see any images yet, we haven't pushed any!)

![](https://corise-mlops.s3.us-west-2.amazonaws.com/project3/aws_setup2.png)


3. Push Docker image to ECR from the command line:

You can click on "View Push Commands" on the top right corner of the above screen to see how to push new Docker images to the ECR repository you just created. All these commands need to be run locally in your Gitpod instance:

(i) Retrieve an authentication token and authenticate your Docker client to your registry:
```bash 
aws ecr get-login-password --region <your region> | docker login --username AWS --password-stdin <your aws account id>
```

(ii) Tag your image so you can push the image to this repository:

```bash

docker tag news-classifier:latest <aws account id>/<ecr repository>:latest
```

(iii) Push this image to your newly created AWS repository:

```bash

docker push <aws account id>/<ecr repository>:latest

```

4. Download the Docker image to a new EC2 machine and start the service!