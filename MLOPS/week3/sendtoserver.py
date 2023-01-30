import json
import requests
if __name__ == '__main__':
    queries = []
    with open('project/data/requests.json', 'r') as f:
        for n, line in enumerate(f,1):
            queries.append(json.loads(line))
            if n == 10:
                break
    # print(queries)
    endpoint = "http://0.0.0.0:81/predict"  # 81 because I mapped 80 to 81 when I run the docker container (see inside dockerfile) because 80 was already in use
    for n,q in enumerate(queries,1):
        print(n, requests.post(endpoint, data=json.dumps(q)).json())
