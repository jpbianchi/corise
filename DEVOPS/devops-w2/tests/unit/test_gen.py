import pytest

from flask import Flask, render_template
from quote_gen.app import app

def test_gen_health():
    """
    Test the "/health" endpoint
    """
    client = app.test_client()
    response = client.get("/health")

    assert response.status_code == 200
    assert response.data == b"healthy", f"Wrong response {response}"

def test_gen_root():
    """
    Test the "/" endpoint
    """
    client = app.test_client()
    response = client.get("/")

    assert response.status_code == 200
    assert b"Quote Generation Service" in response.data

def test_gen_quote():
    """
    Test the "/get_quote" endpoint
    """
    client = app.test_client()
    response = client.get("/quote")

    quotes = [
        "The greatest glory in living lies not in never falling, but in rising every time we fall. -Nelson Mandela",
        "The way to get started is to quit talking and begin doing. -Walt Disney",
        "Your time is limited, so don't waste it living someone else's life. Don't be trapped by dogma – which is living with the results of other people's thinking. -Steve Jobs",
        "If life were predictable it would cease to be life, and be without flavor. -Eleanor Roosevelt",
        "If you look at what you have in life, you'll always have more. If you look at what you don't have in life, you'll never have enough. -Oprah Winfrey",
        "If you set your goals ridiculously high and it's a failure, you will fail above everyone else's success. -James Cameron",
    ]
    assert response.status_code == 200
    assert response.data.decode('utf-8') in quotes
