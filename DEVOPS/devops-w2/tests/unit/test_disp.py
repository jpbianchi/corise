import pytest
#pytestmark = pytest.mark.usefixtures("fix1", "fix2")

from flask import Flask

from quote_disp.app import app

def test_disp_health():
    """
    Test the "/health" endpoint
    """
    client = app.test_client()
    response = client.get("/health")

    assert response.status_code == 200
    assert response.data == b"healthy", f"Wrong response {response}"

def test_disp_root():
    """
    Test the "/" endpoint
    """
    client = app.test_client()
    response = client.get("/")

    assert response.status_code == 200
    assert b"This is the Quote Display Service" in response.data

def test_disp_quote():
    """
    Test the "/get_quote" endpoint
    """
    client = app.test_client()
    response = client.get("/get_quote")

    # quote() needs the server running since it calls "http://gen:5000/quote"...
    # no idea how to start it from pytest, maybe with a fixture, starting the container?
    # so the response is 505 for now
    assert response.status_code == 500

    quotes = [
        "The greatest glory in living lies not in never falling, but in rising every time we fall. -Nelson Mandela",
        "The way to get started is to quit talking and begin doing. -Walt Disney",
        "Your time is limited, so don't waste it living someone else's life. Don't be trapped by dogma – which is living with the results of other people's thinking. -Steve Jobs",
        "If life were predictable it would cease to be life, and be without flavor. -Eleanor Roosevelt",
        "If you look at what you have in life, you'll always have more. If you look at what you don't have in life, you'll never have enough. -Oprah Winfrey",
        "If you set your goals ridiculously high and it's a failure, you will fail above everyone else's success. -James Cameron",
    ]

    # how to test for a quote that is different every time
    # maybe just test some string from the page title like I did for test_root?
    # or try all possibilities