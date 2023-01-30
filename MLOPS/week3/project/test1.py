# https://github.com/kelcol/corise-mlops/blob/kelcol/week3/project/test_app.py

import os
import json
from fastapi.testclient import TestClient
from .app.server import app, PredictResponse


os.chdir('app')
client = TestClient(app)


"""
We've built our web application, and containerized it with Docker.
But imagine a team of ML engineers and scientists that needs to maintain, improve and scale this service over time. 
It would be nice to write some tests to ensure we don't regress! 
  1. `Pytest` is a popular testing framework for Python. If you haven't used it before, take a look at https://docs.pytest.org/en/7.1.x/getting-started.html to get started and familiarize yourself with this library.
  2. How do we test FastAPI applications with Pytest? Glad you asked, here's two resources to help you get started:
    (i) Introduction to testing FastAPI: https://fastapi.tiangolo.com/tutorial/testing/
    (ii) Testing FastAPI with startup and shutdown events: https://fastapi.tiangolo.com/advanced/testing-events/
"""


def test_root():
    """
    [TO BE IMPLEMENTED]
    Test the root ("/") endpoint, which just returns a {"Hello": "World"} json response
    """
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"Hello": "World"}


def test_predict_empty():
    response = client.post(
        "/predict/",
        json={}
    )
    print(response)
    assert response.status_code == 422 # Unprocessable entity


def test_predict_en_lang():
    with open('../data/en_requests.json') as f:
        en_sample = json.loads(f.readline())
    response = client.post(
        "/predict/",
        json=en_sample
    )

    assert response.json()['label'] == "Entertainment"
    assert response.status_code == 200


def test_predict_es_lang():
    with open('../data/es_requests.json') as f:
        es_sample = json.loads(f.readline())
    response = client.post(
        "/predict/",
        json=es_sample
    )

    assert response.json()['label'] == "Entertainment"
    assert response.status_code == 200


def test_predict_non_ascii():
    with open('../data/th_requests.json') as f:
        th_sample = json.loads(f.readline())
    response = client.post(
        "/predict/",
        json=th_sample
    )

    assert response.json()['label'] == "Entertainment"
    assert response.status_code == 200