import requests
import json


def fetch_metrics(url, token):
    response = requests.get(url, auth=("", token))
    response.raise_for_status()
    return response.text
