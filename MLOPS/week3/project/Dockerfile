FROM python:3.9

WORKDIR /project

# Copy over contents from local directory to the path in Docker container
COPY . /project/

# Install python requirements from requirements.txt
RUN pip install --upgrade -r requirements.txt

WORKDIR /project/app

# Start uvicorn server
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "80"]

# run it with docker run -d -p 81:80  news-classifier  (port 80 was already in use)
# then http://localhost:81/docs to see the docs
# docker exec -it 0e2a1cbd3041 /bin/sh to ssh into the container (get id with docker ps)
# tail -f ../data/logs.out   to tail the logs, but that file stays empty... I can see the logs in the container though
