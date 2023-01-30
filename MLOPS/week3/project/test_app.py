import os
from fastapi.testclient import TestClient
from .app.server import app
import json

os.chdir('project/app')  # why are we in week3 when I run this file which is in project???
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

# learn about predict by checking http://localhost:81/docs#/default/predict_predict_post
# after starting the docker container

def test_root():
    """
    Test the root ("/") endpoint, which just returns a {"Hello": "World"} json response
    """
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"Hello": "World"}


def test_predict_empty():
    """
    Test the "/predict" endpoint, with an empty request body
    """
    response = client.post("/predict/", json={})
    print(response)
    assert response.status_code == 422  # Unprocessable entity

def test_predict_empty2():
    """
    Test the "/predict" endpoint, with an empty request body
    """
    with TestClient(app) as client:

        expected_response = {
            "detail": [
                {
                    "loc": ["body", "source"],
                    "msg": "field required",
                    "type": "value_error.missing",
                },
                {
                    "loc": ["body", "url"],
                    "msg": "field required",
                    "type": "value_error.missing",
                },
                {
                    "loc": ["body", "title"],
                    "msg": "field required",
                    "type": "value_error.missing",
                },
                {
                    "loc": ["body", "description"],
                    "msg": "field required",
                    "type": "value_error.missing",
                },
            ]
        }

        response = client.post("/predict", json={})

        assert response.status_code == 422
        assert response.json() == expected_response

def test_predict_en_lang(capsys):
    # capsys is a pytest fixture used to output to stdout, otherwise pytest will capture prints
    # I wanted to be sure where I was since I had issues with paths at some point

    """
    Test the "/predict" endpoint, with an input text in English (you can use one of the test cases provided in README.md)
    """

    with capsys.disabled():
        print('\nCurrent dir:', os.getcwd())

    with open('../data/requests.json') as f:
        en_sample = json.loads(f.readline())

    response = client.post("/predict/", json=en_sample)

    assert response.json()['label'] == "Entertainment"
    assert response.status_code == 200

def test_predict_en_lang2():
    """
    Test the "/predict" endpoint, with an input text in English (you can use one of the test cases provided in README.md)
    """

    example_en_request = {
        "source": "BBC Technology",
        "url": "http://news.bbc.co.uk/go/click/rss/0.91/public/-/2/hi/business/4144939.stm",
        "title": "System gremlins resolved at HSBC",
        "description": "Computer glitches which led to chaos for HSBC customers on Monday are fixed, the High Street bank confirms.",
    }

    with TestClient(app) as client:

        expected_response = {
            "scores": {
                "Business": 0.4550813006199541,
                "Entertainment": 0.13000071132080063,
                "Health": 0.0325569848804359,
                "Music Feeds": 0.004118625771121733,
                "Sci/Tech": 0.3005428177992646,
                "Software and Developement": 0.011333342939150151,
                "Sports": 0.06041374375941345,
                "Toons": 0.0059524729098594555,
            },
            "label": "Business",
        }

        response = client.post("/predict", json=example_en_request)

        assert response.status_code == 200
        assert response.json() == expected_response

def test_predict_es_lang2():
    """
    Test the "/predict" endpoint, with an input text in Spanish.
    Does the tokenizer and classifier handle this case correctly? Does it return an error?
    """
    example_es_request = {
        "source": "BBC Technology",
        "url": "http://news.bbc.co.uk/go/click/rss/0.91/public/-/2/hi/business/4144939.stm",
        "title": "System gremlins resolved at HSBC",
        "description": "Los problemas informáticos que provocaron el caos para los clientes de HSBC el lunes se solucionaron, confirma el banco High Street.",
    }

    with TestClient(app) as client:

        expected_response = {
            "scores": {
                "Business": 0.6684318758607325,
                "Entertainment": 0.025607350767924364,
                "Health": 0.010837867969510133,
                "Music Feeds": 0.0031166525339851644,
                "Sci/Tech": 0.2549108340173541,
                "Software and Developement": 0.011929905150455944,
                "Sports": 0.02383570430487401,
                "Toons": 0.0013298093951637849,
            },
            "label": "Business",
        }

        response = client.post("/predict", json=example_es_request)

        assert response.status_code == 200
        assert response.json() == expected_response

def test_predict_es_lang():
    """
    Test the "/predict" endpoint, with an input text in Spanish. 
    Does the tokenizer and classifier handle this case correctly? Does it return an error?
    """
    with open('../data/es_requests.json') as f:
        es_sample = json.loads(f.readline())
    response = client.post("/predict/", json=es_sample)

    assert response.json()['label'] == "Entertainment"
    assert response.status_code == 200


def test_predict_non_ascii():
    """
    Test the "/predict" endpoint, with an input text that has non-ASCII characters. 
    Does the tokenizer and classifier handle this case correctly? Does it return an error?
    """
    with open('../data/th_requests.json') as f:
        th_sample = json.loads(f.readline())
    response = client.post("/predict/", json=th_sample)

    assert response.json()['label'] == "Entertainment"
    assert response.status_code == 200